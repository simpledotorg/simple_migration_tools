# Database Dump Utility

This utility provides support for taking a dump from an existing PostgreSQL database.  
It will create two separate files: a **schema file** and a **data dump** file.

---

## 📥 How to Run the Script

Run the following command:

```bash
./do_dump.sh {db_username} {db_host} {database_name}
```

**Arguments:**
- `{db_username}` — the PostgreSQL username
- `{db_host}` — the database host
- `{database_name}` — the name of the database to dump

> 💡 Be sure to replace placeholders with actual values when running the script.

---

## 📦 Output

The script will generate a zip file named `database_dump.zip` inside the `target/` directory.

After extracting the zip file, you will find:
- `data_dump.sql` — contains all the table data
- `structure.sql` — contains the schema (table definitions, indexes, etc.)

---

## 🔄 How to Restore the Dump

To restore these files to another PostgreSQL database, use the following commands in order:

```bash
# Step 1: Load the data
psql -U {username} -h {host_name} -d {database_name} -f /path_to_file/data_dump.sql

# Step 2: Load the schema
psql -U {username} -h {host_name} -d {database_name} -f /path_to_file/structure.sql
```

> ⚠️ **Important:**  
> Always load the data first and the schema second.  
> This avoids issues with foreign key constraints and ensures a smooth import process.

---

## 🚀 Final Step

After restoring the data and schema:
- Restart your server or application.
- You should now see the new data reflected in your system or dashboards.

---

## 📝 Additional Notes

- Make sure the target database (`{database_name}`) already exists before running the restore commands.
- The user must have the necessary privileges to create tables and insert data.
- If you're restoring on production or a critical environment, make a backup beforehand.

---

## 📂 Example

```bash
./do_dump.sh postgres localhost my_database

# To restore
psql -U postgres -h localhost -d my_database -f ./target/data_dump.sql
psql -U postgres -h localhost -d my_database -f ./target/structure.sql
```

---
