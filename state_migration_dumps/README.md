This utility provides support for taking a dump from an exisiting database
It will create a schema file and data_dump file separately.

To run the script
./do_dum.sh {db_username} {db_host} {database_name}

Note:- provide username, host and database_name of the database from where the dump has to be taken

This will generate a zip named "database_dump.zip" inside the target folder.
Extract this zip which contains two file namely data_dump.sql and structure.sql

To restore these files over to the deired database, run the following commands
psql -U {{username}} -h {{host_name}} -d {{database_name}} -f /path_to_file/data_dump.sql
psql -U {{username}} -h {{host_name}} -d {{database_name}} -f /path_to_file/structure.sql

Note:- It is important to first load the data and then create entire db schema. This will prevent and report any possible issues with the foreign key constraints.

Restart the server. New data should be available now on the dashboards.
