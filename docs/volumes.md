# Volumes


| Volume (actual name) | Containers that mount it | In‑container path(s) | Purpose |
|----------------------|--------------------------|----------------------|--------------------------------|
| `bcgeo-statics` (bcgeo-statics) | django, celery, geonode (nginx), geoserver | `/mnt/volumes/statics` | • `static/` – collected Django static assets<br>• `assets/` – permanent uploaded files (shapefiles, GeoTIFFs, PDFs, videos)<br>• `uploaded/thumbs/` – layer/document thumbnails<br>• `uploaded/tmp_*/` – raw upload files<br>• `worker@*.state`, `geonode_init.lock` – init/health flags |
| `bcgeo-gsdatadir` (bcgeo-gsdatadir) | django, celery, geoserver, data-dir-conf | `/geoserver_data/data` | • `workspaces/geonode/` – published layers<br>• `gwc/` – GeoWebCache tile cache<br>• `gwc-layers/` – cache definitions<br>• `security/` – authentication & authorisation (OAuth2, role service, passwords)<br>• `geofence/` – access rules<br>• `printing/` – MapFish print config<br>• `styles/` – default SLD styles<br>• `logs/` – logging profiles & geoserver.log<br>• `geonode/geonode_initialized` – sync flag|
| `bcgeo-dbdata` (bcgeo-dbdata) | db (PostGIS) | `/var/lib/postgresql/data` | Full PostgreSQL data directory (`base/`, `global/`, `pg_wal/`, `pg_hba.conf`, `postgresql.conf`, `postmaster.pid`). Contains GeoNode DB and PostGIS data. |
| `bcgeo-redisdata` (bcgeo-redisdata) | redis | `/data` | Redis persistent snapshot (RDB/AOF). Stores Celery task queues and caching data. |
| `bcgeo-nginxconfd` (bcgeo-nginxconfd) | geonode (nginx) | `/etc/nginx` | Nginx configuration files (`nginx.conf`, `sites-enabled/`, etc.) |
| `/~certs`(currently a bind mount)  | geonode (nginx) | `/geonode-certificates` | SSL/TLS certificates (e.g., `la_fullchain.crt`, `la_private.key`) |
| `bcgeo-data` (bcgeo-data) | django, celery, geoserver | `/data` | Empty – unused (bcgeo media is in the statics volume) |
| `bcgeo-backup-restore` (bcgeo-backup-restore) | django, celery, geoserver | `/backup_restore` | Empty – staging for GeoNode backup ZIPs |
| `bcgeo-dbbackups` (bcgeo-dbbackups) | db (PostGIS) | `/pg_backups` | Empty – target for pg_dump backups |
| `bcgeo-tmp` (bcgeo-tmp) | django, celery, geoserver | `/tmp` | Temporary files (processing artefacts, WPS jobs, etc.) |


## From named volumes to bind mounts

GeoNode ships with docker managed volumes - `Named volumes`.

These are prone to destruction especially when faced by the `docker compose down -v` command

We thus chose to adopt bind mounts - volumes we manage


In this implementation, we will:

1. Stop GeoNode.
2. Create all destination directories.
3. Copy every existing Docker named volume into its corresponding directory.
4. Verify the copies.
5. Create docker-compose.override.yaml.
6. Validate the merged Compose configuration.
7. Start GeoNode using the bind mounts.
8. Verify that the containers are actually using the host directories.


## 1. Stop Geoonode

in project root, where compose yaml file lives,

```zsh
docker compose down
```
## 2. Create new host directories

we will use:
```zsh
cd /opt/.../bcgeo_volumes
```

create the dirs

```zsh
sudo mkdir -p /opt/.../bcgeo_volumes/{bcgeo-statics,bcgeo-nginxconfd,bcgeo-nginxcerts,bcgeo-gsdatadir,bcgeo-dbdata,bcgeo-dbbackups,bcgeo-backup-restore,bcgeo-data,bcgeo-tmp,bcgeo-redisdata}
```

## 3. Copy existing named volumes into these directories

### 3.1 GeoServer data

```zsh
sudo docker run --rm \
  -v geonode_project-gsdatadir:/source:ro \
  -v /opt/.../bcgeo_volumes/bcgeo-gsdatadir:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```

### 3.2 PostgreSQL backups

```zsh
sudo docker run --rm \
  -v geonode_project-dbbackups:/source:ro \
  -v /opt/.../bcgeo_volumes/bcgeo-dbbackups:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```

### 3.3 PostgreSQL db

Run this script to back up the dbs, not the volume.

  - pointing to the volumes will create an error on container start up when django does its migrations

Create an empty volume directory

??? abstract "db_backups.sh"
    ```zsh
    #!/bin/bash

    # The script backs up the data weekly and retains two backup copies: one from the previous week and one from two weeks ago.
    # Each time the script runs, the two-week-old backup is deleted, the previous week’s backup is renamed as the older copy, and the new backup is saved as the latest copy.


    # Define the base directory where all database backups are stored
    directory='/opt/.../bcgeo_volumes/initial_dbs'

    # Create an array containing the database backup subdirectories
    # find searches the _.50, _.245, and _.125 directories for immediate subdirectories
    # sed removes the base directory path, leaving only the database directory names
    #databases=($(find "$directory"_.50 "$directory"_.245 "$directory"_.125 -mindepth 1 -maxdepth 1 -type d | sed "s|$directory||"))
    databases=($(find "$directory"bcgeo_db "$directory"bcgeo_geodata -mindepth 1 -maxdepth 1 -type d | sed "s|$directory||"))
    # Define the databases that need to be backed up
    backups=(
      # Format:
      # ssh_port:ssh_db_host:db:pg_user:dest_dir:db_host:container:db_type:source_file

      # Back up the bcgeo PostgreSQL database from the Docker container db4bcgeo
      #"ssh_port:sysadmin2@source_ip:bcgeo:postgres:/path/to/destination/directory:docker:db4bcgeo:postgres:none"
      #"22:mulyung1@172.28.70.154:project:postgres:/home/mulyung1/backups/bcgeo_db:docker:db4geonode_project:postgres:none"
      #"4326:victor@172.28.99.154:bcgeo_data:postgres:/home/victor:docker:db4bcgeo:postgres:none"
      "22:victor@137.255.13.66:project:postgres:/opt/.../bcgeo_volumes/initial_dbs/bcgeo_db:docker:db4geonode_project:postgres:none"

      # Back up the bcgeo_geodata PostgreSQL database from the Docker container db4bcgeo
      #"ssh_port:sysadmin2@source_ip:bcgeo_geodata:postgres:/path/to/destination/directory:docker:db4bcgeo:postgres:none"
      #"22:mulyung1@172.28.70.154:project_data:postgres:/home/mulyung1/backups/bcgeo_geodata:docker:db4geonode_project:postgres:none"
      #"4326:victor@172.28.99.154:bcgeo_geodata:postgres:/home/victor:docker:db4bcgeo:postgres:none"
      "22:victor@137.255.13.66:project_data:postgres:/opt/.../bcgeo_volumes/initial_dbs/bcgeo_geodata:docker:db4geonode_project:postgres:none"
    )


    # Get the date representing the previous week
    last_week=$(date -d "last week" +"%Y-%m-%d")

    # Get today's date, which is used for the new backup filename
    this_week=$(date -d "today" +"%Y-%m-%d")

    # Get the date from 14 days ago, which identifies backups that should be deleted
    two_weeks_ago=$(date -d "-14 days" +"%Y-%m-%d")


    # Function to rename the previous week's latest backups to old backups
    function rename_to_old(){

      # Print a blank line for readability
      echo -e "\n"

      # Display a header showing which backups are being renamed
      echo "**************************************";
      echo "Renaming latest dumps for $last_week to old";
      echo "**************************************";

      # Loop through each database backup directory
      for db in "${databases[@]}"; do

        # Build the full path to the database backup directory
        subdir_path="${directory}${db}"

        # Find all latest SQL backups from the previous week
        # Read each matching filename one at a time
        while IFS= read -r latest_file; do

        # Replace "_latest.sql" with "_old.sql" in the filename
        # This changes the previous week's latest backup into an old backup
        old_file="${latest_file/${last_week}_latest.sql/${last_week}_old.sql}"

          # Check that the latest backup file exists
          if [[ -f "$latest_file" ]]; then

            # Display the rename operation
            echo "Renaming $latest_file -> $old_file"

            # Rename the latest backup to the old backup
            mv "$latest_file" "$old_file"
          fi

        # Find only files matching the previous week's latest backup naming pattern
        done < <(find "$subdir_path" -maxdepth 1 -type f -name "*_${last_week}_latest.sql")
      done

      # Display a completion message
      echo "**************************************";
      echo "Latest Dumps renamed";
      echo "**************************************";
    }



    # Function to remove backups that are two weeks old
    function remove_old_dumps() {

      # Display a header showing which backups will be removed
      echo "**************************************";
      echo "Removing Old dumps for $two_weeks_ago";
      echo "**************************************";

      # Loop through each database backup directory
      for db in "${databases[@]}"; do

        # Build the full path to the database backup directory
        subdir_path="${directory}${db}"

        # Find all old SQL backups from two weeks ago
        # Read each matching filename one at a time
        while IFS= read -r old_file; do

          # Check that the old backup file exists
          if [[ -f "$old_file" ]]; then

            # Display the file that will be removed
            echo "Removing $old_file"

            # Delete the two-week-old backup
            rm "$old_file"
          fi

        # Find only files matching the two-week-old backup naming pattern
        done < <(find "$subdir_path" -maxdepth 1 -type f -name "*_${two_weeks_ago}_old.sql")
      done

      # Display a completion message
      echo "**************************************";
      echo "Old dumps removed";
      echo "**************************************";
    }




    # Backup function
    # Creates PostgreSQL database dumps remotely and saves them on the local backup server
    function backup_postgres() {

      # Print a blank line for readability
      echo -e "\n"

      # Display a header indicating that new backups are being created
      echo "**************************************";
      echo "Running new dumps and transferring them";
      echo "**************************************";

      # Loop through every database defined in the backups array
      for entry in "${backups[@]}"; do

        # Split the backup configuration entry into individual variables
        IFS=":" read -r ssh_port ssh_db_host db pg_user dest_dir db_host container db_type source_dir <<< "$entry"

        # Define the filename for the new PostgreSQL backup
        # The filename contains the database name, current date, and "latest"
        local_file="${dest_dir}/${db}_${this_week}_latest.sql"

        # Define the filename for a SQLite backup, if required
        sqlite3_local_file="${dest_dir}/${db}_${this_week}_latest.sqlite"

        # Check if the database is PostgreSQL running directly on the remote host
        if [[ "$db_host" == "host" && "$db_type" == "postgres" ]]; then

            # Display which database is being backed up
            echo "[$ssh_db_host] Creating dump for DB: $db as Postgres user: $pg_user..."

            # Connect to the remote server over SSH
            # Run pg_dump remotely
            # Redirect the resulting SQL dump to the local backup file
            ssh -p "$ssh_port" "$ssh_db_host" \
                "pg_dump -U $pg_user -d $db" > "$local_file"

        # Check if the PostgreSQL database is running inside a Docker container
        elif [[ "$db_host" == "docker" && "$db_type" == "postgres" ]]; then

            # Display which database is being backed up
            echo "[$ssh_db_host] Creating dump for DB: $db as Postgres user: $pg_user..."

            # Connect to the remote server over SSH
            # Run pg_dump inside the specified Docker container
            # Redirect the SQL dump to the local backup file
            ssh -p "$ssh_port" "$ssh_db_host" \
                "docker exec ${container} pg_dump -U ${pg_user} ${db}" > "$local_file"

        fi

        # Display that processing for this remote database host has finished
        echo "[$ssh_db_host] Finished backup. Exiting DB host session."
      done

      # Display a completion message after all databases have been processed
      echo "**************************************";
      echo "Dumps run and transfer complete;";
      echo "**************************************";
    }



    # Main function containing the overall backup process
    function main(){

      # Print a blank line for readability
      echo -e "\n"

      # Display the start of the backup process and the current backup date
      echo "----------------------------------------"
      echo "Starting db backups for $this_week";
      echo "----------------------------------------"

      # First rename last week's latest backups to old backups
      rename_to_old

      # Create the new database backups
      backup_postgres

      # Find all newly created backups for the current week
      latest_dumps=$(find "$directory" -type f -name "*_${this_week}_latest.sql")

      # Find all old backups that were renamed from last week
      old_dumps=$(find "$directory" -type f -name "*_${last_week}_old.sql")

      # Count the number of newly created backups
      latest_count=$(echo "$latest_dumps" | wc -l)

      # Count the number of old backups
      old_count=$(echo "$old_dumps" | wc -l)

      # Compare the number of new backups with the number of old backups
      # The old backups are removed only if the counts match
      if [[ "$latest_count" -eq "$old_count" ]]; then

        # Display that the backup counts match
        echo -e "\n"
        echo "Counts match — removing old dumps..."

        # Remove the backups from two weeks ago
        remove_old_dumps

      else

        # If the counts do not match, do not remove the old backups
        # This provides a basic safety check to avoid deleting backups unnecessarily
        echo "Counts don't match - Failed to remove old dumps"
      fi

      # Print a blank line for readability
      echo -e "\n"

      # Display that the backup process has completed
      echo "----------------------------------------"
      echo "Database for $this_week" are complete;
      echo "----------------------------------------"

    }

    # Execute the main backup function
    main
    ```

Run the script like

```zsh
bash db_backups.sh
```

### 3.4 Static files
```zsh
sudo docker run --rm \
  -v geonode_project-statics:/source:ro \
  -v /opt/.../bcgeo_volumes/bcgeo-statics:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```
### 3.5 Nginx configuration
```zsh
sudo docker run --rm \
  -v geonode_project-nginxconfd:/source:ro \
  -v /opt/.../bcgeo_volumes/bcgeo-nginxconfd:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```
### 3.6 Nginx certificates
```zsh
sudo docker run --rm \
  -v /geonode_project-nginxcerts:/source:ro \
  -v /opt/.../bcgeo_volumes/bcgeo-nginxcerts:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```

### 3.7 Backup/restore
```zsh
sudo docker run --rm \
  -v /geonode_project-backup-restore:/source:ro \
  -v /opt/.../bcgeo_volumes/bcgeo-backup-restore:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```

### 3.8 Data
```zsh
sudo docker run --rm \
  -v /geonode_project-data:/source:ro \
  -v /opt/.../bcgeo_volumes/bcgeo-data:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```

### 3.9 tmp
```zsh
sudo docker run --rm \
  -v /geonode_project-tmp:/source:ro \
  -v /opt/.../bcgeo_volumes/bcgeo-tmp:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```
### 3.10 Redis

```zsh
sudo docker run --rm \
  -v /geonode_project-redisdata:/source:ro \
  -v /opt/.../bcgeo_volumes/bcgeo-redisdata:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```

## 4. Verify all copied directories

```zsh
sudo du -sh /opt/.../bcgeo_volumes/*
```

```py 
4.0K	/opt/.../bcgeo_volumes/backup-restore
4.0K	/opt/.../bcgeo_volumes/data
4.0K	/opt/.../bcgeo_volumes/dbbackups
158M	/opt/.../bcgeo_volumes/dbdata
2.7M	/opt/.../bcgeo_volumes/geoserver-data
20K	    /opt/.../bcgeo_volumes/nginx-certificates
80K	    /opt/.../bcgeo_volumes/nginx-confd
104K	/opt/.../bcgeo_volumes/redisdata
386M	/opt/.../bcgeo_volumes/statics
88K	    /opt/.../bcgeo_volumes/tmp
```
their sizes and docker managed volumes should be clser like:

```zsh
docker system df -v
```

Local Volumes space usage:

```py
VOLUME NAME                      LINKS     SIZE
bcgeo-tmp              0         938B
bcgeo-data             0         0B
bcgeo-nginxconfd       0         24.24kB
bcgeo-backup-restore   0         0B
bcgeo-dbbackups        0         0B
bcgeo-dbdata           0         165.4MB
bcgeo-gsdatadir        0         1.529MB
bcgeo-nginxcerts       0         2.827kB
bcgeo-redisdata        0         118.5kB
bcgeo-statics          0         399.6MB

```

## 5. Create the docker-compose.override.yaml file

```yaml
services:

  django:
    volumes:
      - /opt/.../bcgeo_volumes/bcgeo-statics:/mnt/volumes/statics
      - /opt/.../bcgeo_volumes/bcgeo-geoserver-data:/geoserver_data/data
      - /opt/.../bcgeo_volumes/bcgeo-backup-restore:/backup_restore
      - /opt/.../bcgeo_volumes/bcgeo-data:/data
      - /opt/.../bcgeo_volumes/bcgeo-tmp:/tmp

  celery:
    volumes:
      - /opt/.../bcgeo_volumes/bcgeo-statics:/mnt/volumes/statics
      - /opt/.../bcgeo_volumes/bcgeo-geoserver-data:/geoserver_data/data
      - /opt/.../bcgeo_volumes/bcgeo-backup-restore:/backup_restore
      - /opt/.../bcgeo_volumes/bcgeo-data:/data
      - /opt/.../bcgeo_volumes/bcgeo-tmp:/tmp

  nginx:
    volumes:
      - /opt/.../bcgeo_volumes/bcgeo-nginxconfd:/etc/nginx
      - /opt/.../bcgeo_volumes/bcgeo-nginxcerts:/geonode-certificates
      - /opt/.../bcgeo_volumes/bcgeo-statics:/mnt/volumes/statics

  letsencrypt:
    volumes:
      - /opt/.../bcgeo_volumes/bcgeo-nginxcerts:/geonode-certificates

  geoserver:
    volumes:
      - /opt/.../bcgeo_volumes/bcgeo-statics:/mnt/volumes/statics
      - /opt/.../bcgeo_volumes/bcgeo-geoserver-data:/geoserver_data/data
      - /opt/.../bcgeo_volumes/bcgeo-backup-restore:/backup_restore
      - /opt/.../bcgeo_volumes/bcgeo-data:/data
      - /opt/.../bcgeo_volumes/bcgeo-tmp:/tmp

  # data-dir-conf:
  #   volumes:
  #     - /opt/.../bcgeo_volumes/geoserver-data:/geoserver_data/data

  db:
    volumes:
      - /opt/.../bcgeo_volumes/bcgeo-dbdata:/var/lib/postgresql/data
      - /opt/.../bcgeo_volumes/bcgeo-dbbackups:/pg_backups

  redis:
    volumes:
      - /opt/.../bcgeo_volumes/bcgeo-redisdata:/data
```

## 6. Validate the merged compose configuration

run:
```zsh
docker compose config
```
You expect to see volumes as **bind mounts** now pointing to our directories:

```yaml linenums="254"
    image: geonode_project/nginx:1.28.0-v1
    networks:
      default: null
    ports:
      - mode: ingress
        target: 80
        published: "80"
        protocol: tcp
      - mode: ingress
        target: 443
        published: "443"
        protocol: tcp
    restart: unless-stopped
    volumes:
      - type: bind
        source: /opt/.../bcgeo_volumes/nginx-confd
        target: /etc/nginx
        bind: {}
      - type: bind
        source: /opt/.../bcgeo_volumes/nginx-certificates
        target: /geonode-certificates
        bind: {}
      - type: bind
        source: /opt/.../bcgeo_volumes/statics
        target: /mnt/volumes/statics
        bind: {}
  redis:
    container_name: redis4geonode_project
    healthcheck:
      test:
        - CMD
        - redis-cli
        - ping
      timeout: 3s
      interval: 20s
      retries: 3
      start_period: 5s
    image: redis:7-alpine
    networks:
      default: null
    restart: unless-stopped
    volumes:
      - type: bind
        source: /opt/.../bcgeo_volumes/redisdata
        target: /data
        bind: {}
networks:
  default:
    name: geonode_project_default
x-common-django:
  depends_on:
    db:
      condition: service_healthy
    memcached:
      condition: service_healthy
    redis:
      condition: service_healthy
  env_file:
    - .env
  image: geonode_project/geonode:master
  restart: unless-stopped
  volumes:
    - ./src:/usr/src/project
    - statics:/mnt/volumes/statics
    - geoserver-data-dir:/geoserver_data/data
    - backup-restore:/backup_restore
    - data:/data
    - tmp:/tmp


```

## 7. Start GeoNode with the bind mounts

```zsh
docker compose up -d
```

## 8. Verify the actual container mounts

once containers are running,

```zsh
docker inspect db4geonode_project --format '{{json .Mounts}}' | jq
```

you will see:

```yaml
[
  {
    "Type": "bind",
    "Source": "/opt/.../bcgeo_volumes/dbbackups",
    "Destination": "/pg_backups",
    "Mode": "rw",
    "RW": true,
    "Propagation": "rprivate"
  },
  {
    "Type": "bind",
    "Source": "/opt/.../bcgeo_volumes/dbdata",
    "Destination": "/var/lib/postgresql/data",
    "Mode": "rw",
    "RW": true,
    "Propagation": "rprivate"
  }
]

```

Our project structure now looks like::

```zsh
/opt/.../Benin_Geoportal/
│
├── docker-compose.yml
├── docker-compose.override.yaml
├── Dockerfile
├── src/
│
└── bcgeo_volumes/
    │
    ├── statics/
    ├── nginx-confd/
    ├── nginx-certificates/
    ├── geoserver-data/
    ├── dbdata/
    ├── dbbackups/
    ├── backup-restore/
    ├── data/
    ├── tmp/
    └── redisdata/

```
