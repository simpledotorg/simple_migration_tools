USER_NAME=$1
HOST_NAME=$2
DB_NAME=$3

rm -rf ./target
mkdir ./target

# Creates the dump schema
echo "Creating simple_dump_data schema"
psql -U "$USER_NAME" -h "$HOST_NAME" -d "$DB_NAME" -f ./create_dump_schema.sql
echo "simple_dump_data schema creation completed"

## Creates the data dump file
echo "Creating dump file"
pg_dump -U "$USER_NAME" -h "$HOST_NAME" -d "$DB_NAME" --no-owner --schema=simple_dump_data -f ./target/data_dump.sql
echo "Dump file creation completed"

#Replace schema name to public in the dump file
sed -i '' 's/simple_dump_data/public/g' ./target/data_dump.sql

#Adding the ltree extension
sed -i '' '29a\
CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;\
\
' ./target/data_dump.sql

# Zips the resulting file
echo "Creating zip"
cp ./structure.sql ./target/structure.sql
zip ./target/database_dump.zip ./target/data_dump.sql ./target/structure.sql
echo "Zip completed"

# ##
# ## todo: put it into S3
# ##
# echo awscli ...

## Drop the simple_dump_schema from the database
echo "Dropping simple_dump_data schema from the database"
psql -U "$USER_NAME" -h "$HOST_NAME" -d "$DB_NAME" -c "DROP SCHEMA IF EXISTS simple_dump_data CASCADE;"

# ##
# ## Cleans everythings
# ##
# echo rm -rf ./target

