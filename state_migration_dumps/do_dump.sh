##
## Creates the dump schema
##
echo todo

##
## Gets the dump from the dump schema
## 
rm -rf ./target
mkdir ./target
pg_dump -U postgres -h localhost -d simple-server_test --schema=simple_dump_data -f ./target/test_dump.sql

##
## Zips the resulting file
##
zip ./target/test_dump.zip ./target/test_dump.sql

##
## todo: put it into S3
##
echo awscli ...

##
## Cleans everythings
##
echo rm -rf ./target

