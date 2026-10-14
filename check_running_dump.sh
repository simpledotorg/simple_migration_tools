#!/bin/bash

# ========================================================================
# CHECK RUNNING DUMP SCRIPT
# Verifies which dump script is running and its status
# ========================================================================

echo "=========================================="
echo "DUMP SCRIPT STATUS CHECK"
echo "=========================================="
echo ""

# Check for running dump processes
DUMP_PROCESSES=$(ps aux | grep -E "dump_streaming|dump_script" | grep -v grep)

if [ -z "$DUMP_PROCESSES" ]; then
  echo "❌ No dump script is currently running"
  echo ""
  echo "To start a dump, run:"
  echo "  nohup /tmp/dump_streaming.sh postgres localhost simple_db_india_production_001 > /tmp/dump_streaming.log 2>&1 &"
  exit 1
fi

echo "✅ Dump script is RUNNING"
echo ""
echo "Process details:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$DUMP_PROCESSES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Determine which script is running
if echo "$DUMP_PROCESSES" | grep -q "dump_streaming"; then
  SCRIPT_NAME="dump_streaming.sh"
  SCRIPT_TYPE="STREAMING (with on-the-fly compression)"
  LOG_FILE="/tmp/dump_streaming.log"
  echo "Script: $SCRIPT_NAME"
  echo "Type: $SCRIPT_TYPE"
  echo "✅ CORRECT SCRIPT (saves disk space)"
elif echo "$DUMP_PROCESSES" | grep -q "dump_script"; then
  SCRIPT_NAME="dump_script_v2.sh"
  SCRIPT_TYPE="STANDARD (compress after dump)"
  LOG_FILE="/tmp/dump.log"
  echo "Script: $SCRIPT_NAME"
  echo "Type: $SCRIPT_TYPE"
  echo "⚠️  WARNING: Uses more disk space!"
else
  SCRIPT_NAME="Unknown"
  SCRIPT_TYPE="Unknown"
  LOG_FILE="/tmp/*.log"
  echo "Script: $SCRIPT_NAME"
  echo "Type: $SCRIPT_TYPE"
fi
echo ""

# Check output files
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "OUTPUT FILES:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for compressed files
COMPRESSED_FILES=$(ls -lh /pgdata/full_dump_masked_pii/*.sql.gz 2>/dev/null)
if [ -n "$COMPRESSED_FILES" ]; then
  echo "Compressed dump files (.sql.gz):"
  echo "$COMPRESSED_FILES"
  echo ""
else
  echo "No compressed files (.sql.gz) found yet"
  echo ""
fi

# Check for uncompressed files
UNCOMPRESSED_FILES=$(ls -lh /pgdata/full_dump_masked_pii/*.sql 2>/dev/null)
if [ -n "$UNCOMPRESSED_FILES" ]; then
  echo "Uncompressed dump files (.sql):"
  echo "$UNCOMPRESSED_FILES"
  echo ""
else
  echo "No uncompressed files (.sql) found"
  echo ""
fi

# Check disk space
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "DISK SPACE:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
df -h /pgdata
echo ""

AVAILABLE_GB=$(df -h /pgdata | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE_GB" -lt 300 ]; then
  echo "⚠️  WARNING: Less than 300 GB available!"
  echo "   Consider stopping and using streaming version"
else
  echo "✅ Sufficient disk space available"
fi
echo ""

# Check log file
if [ -f "$LOG_FILE" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "RECENT LOG OUTPUT:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  tail -20 "$LOG_FILE"
  echo ""
fi

# Check if completed
if [ -f "$LOG_FILE" ]; then
  if grep -q "DUMP COMPLETED" "$LOG_FILE" 2>/dev/null; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 DUMP COMPLETED SUCCESSFULLY!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Next steps:"
    echo "1. Verify dump integrity:"
    echo "   ./verify_dump_integrity.sh postgres simple_db_india_production_001 /pgdata/full_dump_masked_pii/india_prod_dump_masked_*.sql.gz"
    echo ""
    echo "2. Copy to local machine:"
    echo "   kubectl cp simple-v1/simple-instance1-7cl2-0:/pgdata/full_dump_masked_pii/india_prod_dump_masked_*.sql.gz ./dump.sql.gz"
    exit 0
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STATUS: Dump in progress..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To monitor progress:"
echo "  tail -f $LOG_FILE"
echo ""
echo "To watch file size:"
echo "  watch -n 30 'ls -lh /pgdata/full_dump_masked_pii/*.sql.gz 2>/dev/null && df -h /pgdata'"
echo ""
