
# **Backups and restoration**


## Overview

BCGeo runs on a dockerised environment.

As a result, volumes keep data persistent across container restarts.

The backups will serve to bring up newer geonode instances based on old data.

!!! tip "How?"

    with future GeoNode updates, we will simply point to the new/updated containers to these volumes and everything should be live.

We will backup the volumes **incrementally**.

- This means only new changes will be written.

- Older files will remain untouched

### **Prequisites**

To run the backup script, you will need to setup:


- ssh-keys between backup server and VM

- a cron job to run the script.

### **Backup script**

??? abstract "volumes_backup.sh"

    ```zsh
    #!/bin/bash

    ## This script runs on the backup server and incrementally backs up Docker volumes
    ## from a remote source server.
    ##
    ## Incremental backup means only new or changed files are transferred.
    ## Files that have not changed are not transferred again, which saves time
    ## and reduces network and storage usage.
    ##
    ## You can put it in a cronjob to automate it at intervals of your choice.
    ## Example:
    ## 0 3 * * 5 /path/to/script/benin_volumes.sh > /path/to/logs/benin_volumes.log


    # Exit immediately if a command fails, an unset variable is used,
    # or any command in a pipeline fails
    set -euo pipefail


    # Define the username used to connect to the source server
    #SOURCE_USER="user_in_source_host"
    SOURCE_USER="victor"

    # Define the IP address or hostname of the source server
    #SOURCE_HOST="source_ip"
    SOURCE_HOST="172.28.99.154"

    # Define the port VM is configured to listen on
    SOURCE_SSH_PORT="4326"

    # Define the path to the custom ssh key
    #SSH_KEY="path/to/your/custom/ssh/key"
    SSH_KEY="~/.ssh/ed25519_cgbenin_key"

    # Define the ssh port geonode vm is configured to l
    # Define the destination directory where the backups will be stored
    # This directory is located on the backup server running this script
    #BACKUP_DIR="volume_destination_in_backup_server"
    BACKUP_DIR="/home/mulyung1/backups"


    # Define the Docker volumes that need to be backed up
    VOLUMES=(
        "bcgeo-data"
        "bcgeo-dbdata"
        "bcgeo-dbbackups"
        "bcgeo-gsdatadir"
        "bcgeo-statics"
        "bcgeo-backup-restore"
        "bcgeo-nginxconfd"
        "bcgeo-redisdata"
    )


    # Loop through each Docker volume in the VOLUMES array
    for volume in "${VOLUMES[@]}"; do

        # Display the name of the volume currently being backed up
        echo "Backing up: $volume"

        # Use rsync to incrementally copy the volume data from the source server
        # to the backup server.
        #
        # -a = archive mode, preserves file attributes and directory structure
        # -v = verbose, displays the files being processed
        # -z = compresses data during transfer
        # -e = specifies SSH as the remote shell and the SSH port
        #
        # rsync compares the source and destination files and transfers
        # only new or changed files instead of copying everything again.
        rsync -avz --rsync-path="sudo rsync" -e "ssh -i ${SSH_KEY} -p ${SOURCE_SSH_PORT}" \
            "${SOURCE_USER}@${SOURCE_HOST}:/var/lib/docker/volumes/${volume}/_data/" \
            "$BACKUP_DIR/$volume/"

        # Display that the current volume backup completed successfully
        echo "✓ $volume completed"
    done


    # Display that all selected Docker volumes have been backed up successfully
    echo "All selected volumes backed up successfully."
    ```
This bash script will:

1. Run as a cron job on the backup server

2. Require the variables:
    - VM IP

    - VM user

        - With permissions to read and write the volumes

    - Backup directory(volumes destination on backup server)

    - SSH key location

    - Volume names


### **Setup ssh key pair**

#### **generate ssh keys**

on backupsever generate the public private key pairs

```zsh
ssh-keygen -t ed25519 -f /Users/victor/.ssh/ed25519_bcgeo_key
```
#### **copy pub key to vm**

- copy the public to bcgeo vm

```zsh
ssh-copy-id -i /path/to/ssh_key.pub -p <ssh_port> <username>@<vm_ip>

ssh-copy-id -i /Users/victor/.ssh/ed25519_bcgeo_key.pub -p 22 mulyung1@172.28.71.2
```

#### **set permissions**

set proper permissions on the key, to avoid ssh rejecting the keys

- on back up server

```zsh
chmod 600 /Users/victor/.ssh/ed25519_bcgeo_key
chown $(whoami) /Users/victor/.ssh/ed25519_bcgeo_key
```

- on vm run

```zsh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

!!! note "Remember"

    When running from cron, $HOME may differ from your interactive shell, so always use an absolute path for the key (which we did above).


## Run the backup script.

```zsh
bash volumes_backup.sh
```

## Restoration

We cannot point to volume directories especially for the databases and get it up and running.

in that case, we take database backups.

These will be restored in target setup.

The steps are like:

- Backup the dbs using the script below

??? abstract "database_backups.sh"

    ```zsh
    #!/bin/bash

    # The script backs up the data weekly and retains two backup copies: one from the previous week and one from two weeks ago.
    # Each time the script runs, the two-week-old backup is deleted, the previous week’s backup is renamed as the older copy, and the new backup is saved as the latest copy.


    # Define the base directory where all database backups are stored
    directory='/home/mulyung1/backups'

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
      "22:mulyung1@172.28.70.154:project:postgres:/home/mulyung1/backups/bcgeo_db:docker:db4geonode_project:postgres:none"
      #"4326:victor@172.28.99.154:bcgeo_data:postgres:/home/victor:docker:db4bcgeo:postgres:none"

      # Back up the bcgeo_geodata PostgreSQL database from the Docker container db4bcgeo
      #"ssh_port:sysadmin2@source_ip:bcgeo_geodata:postgres:/path/to/destination/directory:docker:db4bcgeo:postgres:none"
      "22:mulyung1@172.28.70.154:project_data:postgres:/home/mulyung1/backups/bcgeo_geodata:docker:db4geonode_project:postgres:none"
      #"4326:victor@172.28.99.154:bcgeo_geodata:postgres:/home/victor:docker:db4bcgeo:postgres:none"
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

- start only the db container

```zsh
docker compose up db -d
```

- copy sql dumps into db container

```zsh
docker cp /path/to/dumps.sql <container_name>:/destination/path/inside/vm
```

- Open a terminal in the db container

```zsh
docker exec -it <container_name> bash
```

- Create a db with same name as db we are backing up

```sql
create database bcgeo_data;

create database bcgeo_geodata;
```

- Restore these dbs

```sql
psql -U postgres -d <geonode_db_name> -f <backup.sql>

psql -U postgres -d <geoserver_db_name> -f <backup.sql>
```

## References

- [Set up ssh keys](https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server)

- 