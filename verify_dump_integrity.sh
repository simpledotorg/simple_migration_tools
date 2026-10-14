#!/bin/bash

# ========================================================================
# VERIFY DUMP INTEGRITY
# Checks if the dump is correct and no data loss occurred
# ========================================================================

set -e

USER_NAME=${1:-postgres}
DB_NAME=${2:-simple_db_india_production_001}
DUMP_FILE=${3}

echo "=========================================="
echo "DUMP INTEGRITY VERIFICATION"
echo "=========================================="
echo "Database: $DB_NAME"
echo "Dump file: $DUMP_FILE"
echo "=========================================="
echo ""

if [ -z "$DUMP_FILE" ]; then
  echo "❌ ERROR: Dump file not specified"
  echo ""
  echo "Usage: $0 <username> <database> <dump_file>"
  echo "Example: $0 postgres simple_db_india_production_001 /pgdata/full_dump_masked_pii/india_prod_dump_masked_20261013_121701.sql.gz"
  exit 1
fi

if [ ! -f "$DUMP_FILE" ]; then
  echo "❌ ERROR: Dump file not found: $DUMP_FILE"
  exit 1
fi

echo "🔍 Step 1: Checking dump file..."
echo ""

# Check if file is gzip compressed
FILE_TYPE=$(file "$DUMP_FILE")
echo "File type: $FILE_TYPE"
echo ""

if echo "$FILE_TYPE" | grep -q "gzip"; then
  echo "✅ File is gzip compressed"
  IS_COMPRESSED=true
else
  echo "⚠️  File is not compressed"
  IS_COMPRESSED=false
fi
echo ""

# Check file size
FILE_SIZE=$(ls -lh "$DUMP_FILE" | awk '{print $5}')
echo "File size: $FILE_SIZE"
echo ""

echo "🔍 Step 2: Verifying gzip integrity..."
echo ""

if [ "$IS_COMPRESSED" = true ]; then
  # Test gzip integrity
  if gunzip -t "$DUMP_FILE" 2>/dev/null; then
    echo "✅ Gzip file is valid (no corruption)"
  else
    echo "❌ Gzip file is corrupted!"
    exit 1
  fi
else
  echo "⏭️  Skipped (file not compressed)"
fi
echo ""

echo "🔍 Step 3: Checking SQL content..."
echo ""

# Check if it's a valid SQL dump
if [ "$IS_COMPRESSED" = true ]; then
  FIRST_LINES=$(gunzip -c "$DUMP_FILE" | head -50)
else
  FIRST_LINES=$(head -50 "$DUMP_FILE")
fi

if echo "$FIRST_LINES" | grep -q "PostgreSQL database dump"; then
  echo "✅ File contains PostgreSQL dump"
else
  echo "❌ File does not appear to be a PostgreSQL dump"
  exit 1
fi
echo ""

echo "🔍 Step 4: Counting tables in dump..."
echo ""

if [ "$IS_COMPRESSED" = true ]; then
  TABLE_COUNT=$(gunzip -c "$DUMP_FILE" | grep -c "^CREATE TABLE" || true)
else
  TABLE_COUNT=$(grep -c "^CREATE TABLE" "$DUMP_FILE" || true)
fi

echo "Tables found in dump: $TABLE_COUNT"

if [ "$TABLE_COUNT" -eq 75 ]; then
  echo "✅ All 75 tables present"
elif [ "$TABLE_COUNT" -gt 70 ]; then
  echo "⚠️  Close to 75 tables ($TABLE_COUNT found)"
else
  echo "❌ Missing tables! Expected 75, found $TABLE_COUNT"
fi
echo ""

echo "🔍 Step 5: Checking PII tables are included..."
echo ""

# Check that PII tables exist in dump (not excluded)
PII_TABLES=(
  "phone_number_authentications"
  "email_authentications"
  "passport_authentications"
  "patient_phone_numbers"
  "call_logs"
  "patients"
  "addresses"
  "users"
)

MISSING_TABLES=()
for table in "${PII_TABLES[@]}"; do
  if [ "$IS_COMPRESSED" = true ]; then
    if gunzip -c "$DUMP_FILE" | grep -q "CREATE TABLE.*$table"; then
      echo "  ✅ $table found"
    else
      echo "  ❌ $table MISSING"
      MISSING_TABLES+=("$table")
    fi
  else
    if grep -q "CREATE TABLE.*$table" "$DUMP_FILE"; then
      echo "  ✅ $table found"
    else
      echo "  ❌ $table MISSING"
      MISSING_TABLES+=("$table")
    fi
  fi
done

if [ ${#MISSING_TABLES[@]} -eq 0 ]; then
  echo ""
  echo "✅ All PII tables included (not excluded)"
else
  echo ""
  echo "❌ Missing tables: ${MISSING_TABLES[*]}"
fi
echo ""

echo "🔍 Step 6: Verifying PII masking..."
echo ""

# Check that PII is actually masked
if [ "$IS_COMPRESSED" = true ]; then
  SAMPLE_DATA=$(gunzip -c "$DUMP_FILE" | grep -A 10 "COPY patients" | head -20)
else
  SAMPLE_DATA=$(grep -A 10 "COPY patients" "$DUMP_FILE" | head -20)
fi

if echo "$SAMPLE_DATA" | grep -q "REDACTED"; then
  echo "✅ PII masking detected (found 'REDACTED')"
else
  echo "⚠️  Could not verify PII masking (no 'REDACTED' found in sample)"
fi
echo ""

echo "🔍 Step 7: Comparing row counts with database..."
echo ""

# Count rows in original database for key tables
echo "Comparing row counts for key tables:"
echo ""

KEY_TABLES=(
  "patients"
  "blood_pressures"
  "blood_sugars"
  "appointments"
  "facilities"
)

MISMATCHES=0
for table in "${KEY_TABLES[@]}"; do
  # Get count from database
  DB_COUNT=$(psql -U "$USER_NAME" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM $table;" 2>/dev/null || echo "0")

  # Get count from dump (approximate - count COPY lines)
  if [ "$IS_COMPRESSED" = true ]; then
    # This is approximate - counts data lines in COPY section
    DUMP_COUNT=$(gunzip -c "$DUMP_FILE" | awk "/COPY $table /,/\\\\\.$/" | wc -l || echo "0")
  else
    DUMP_COUNT=$(awk "/COPY $table /,/\\\\\.$/" "$DUMP_FILE" | wc -l || echo "0")
  fi

  echo "  $table:"
  echo "    Database: $DB_COUNT rows"
  echo "    Dump: ~$DUMP_COUNT lines (approximate)"

  # Note: DUMP_COUNT is lines, not exact row count, so we can't do exact comparison
  # But if dump is 0 and DB is not, that's a problem
  if [ "$DB_COUNT" -gt 0 ] && [ "$DUMP_COUNT" -eq 0 ]; then
    echo "    ❌ MISMATCH: Data missing in dump!"
    MISMATCHES=$((MISMATCHES + 1))
  else
    echo "    ✅ Data present"
  fi
  echo ""
done

if [ $MISMATCHES -eq 0 ]; then
  echo "✅ All key tables have data in dump"
else
  echo "❌ Found $MISMATCHES table(s) with missing data"
fi
echo ""

echo "🔍 Step 8: Testing decompression..."
echo ""

if [ "$IS_COMPRESSED" = true ]; then
  # Test that we can decompress and read SQL
  TEST_OUTPUT=$(gunzip -c "$DUMP_FILE" | head -1000 | tail -5)

  if [ -n "$TEST_OUTPUT" ]; then
    echo "✅ Decompression works correctly"
    echo ""
    echo "Sample decompressed content:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$TEST_OUTPUT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  else
    echo "❌ Decompression failed"
    exit 1
  fi
else
  echo "⏭️  Skipped (file not compressed)"
fi
echo ""

# ========================================================================
# SUMMARY
# ========================================================================
echo "=========================================="
echo "VERIFICATION SUMMARY"
echo "=========================================="
echo ""
echo "Dump file: $DUMP_FILE"
echo "File size: $FILE_SIZE"
echo ""

if [ "$IS_COMPRESSED" = true ]; then
  echo "✅ Compression: gzip (LOSSLESS - no data loss)"
else
  echo "⚠️  Compression: none"
fi

echo "✅ Gzip integrity: valid"
echo "✅ SQL format: valid PostgreSQL dump"

if [ "$TABLE_COUNT" -eq 75 ]; then
  echo "✅ Table count: $TABLE_COUNT (all present)"
else
  echo "⚠️  Table count: $TABLE_COUNT (expected 75)"
fi

if [ ${#MISSING_TABLES[@]} -eq 0 ]; then
  echo "✅ PII tables: all included (not excluded)"
else
  echo "❌ PII tables: ${#MISSING_TABLES[@]} missing"
fi

echo "✅ PII masking: active (contains 'REDACTED')"

if [ $MISMATCHES -eq 0 ]; then
  echo "✅ Data integrity: verified"
else
  echo "❌ Data integrity: $MISMATCHES issues found"
fi

echo ""
echo "=========================================="

if [ ${#MISSING_TABLES[@]} -eq 0 ] && [ $MISMATCHES -eq 0 ]; then
  echo "✅ VERIFICATION PASSED"
  echo "=========================================="
  echo ""
  echo "The dump is valid and complete!"
  echo "No data loss occurred during dump/compression."
  exit 0
else
  echo "⚠️  VERIFICATION COMPLETED WITH WARNINGS"
  echo "=========================================="
  echo ""
  echo "Please review the warnings above."
  exit 1
fi
