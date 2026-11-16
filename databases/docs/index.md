## PostgreSQL commands

### restore a db
1. Create the database

```sql
create database <dbname>;

create user victor;

alter user victor with superuser;

-- assign user a pass
alter user victor set password to '';

-- assign db to new user
alter database <dbname> with owner to victor;

```

2. restore the db from dump file

```sql 
psql -U [username] -d [database_name] -f [path_to_backup_file.sql]
```

```sql
pg_restore -U [username] -d [database_name] [path_to_dump_file]

```
