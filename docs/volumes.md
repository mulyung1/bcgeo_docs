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
sudo mkdir -p /opt/geo_django_dev/.dev/volumes/{bcgeo-statics,bcgeo-nginx-confd,bcgeo-nginx-certs,bcgeo-gsdatadir,bcgeo-dbdata,bcgeo-dbbackups,bcgeo-backup-restore,bcgeo-data,bcgeo-tmp,bcgeo-redisdata}
```

## 3. Copy existing named volumes into these directories

### 3.1 GeoServer data

```zsh
sudo docker run --rm \
  -v bcgeo-gsdatadir:/source:ro \
  -v /opt/geo_django_dev/.dev/volumes/bcgeo-gsdatadir:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```

### 3.2 PostgreSQL

```zsh
  sudo docker run --rm \
  -v bcgeo-dbdata:/source:ro \
  -v /opt/geo_django_dev/.dev/volumes/bcgeo-dbdata:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```

### 3.3 PostgreSQL backups
```zsh

sudo docker run --rm \
  -v bcgeo-dbbackups:/source:ro \
  -v /opt/geo_django_dev/.dev/volumes/dbbackups:/destination \
  alpine sh -c 'cp -a /source/. /destination/'

```

### 3.4 Static files
```zsh
sudo docker run --rm \
  -v bcgeo-statics:/source:ro \
  -v /opt/geo_django_dev/.dev/volumes/bcgeo-statics:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```
### 3.5 Nginx configuration
```zsh
sudo docker run --rm \
  -v bcgeo-nginxconfd:/source:ro \
  -v /opt/geo_django_dev/.dev/volumes/bcgeo-nginxconfd:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```
### 3.6 Nginx certificates
```zsh
sudo docker run --rm \
  -v bcgeo-nginxcerts:/source:ro \
  -v /opt/geo_django_dev/.dev/volumes/nginxcerts:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```

### 3.7 Backup/restore
```zsh
sudo docker run --rm \
  -v bcgeo-backup-restore:/source:ro \
  -v /opt/geo_django_dev/.dev/volumes/bcgeo-backup-restore:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```

### 3.8 Data
```zsh
sudo docker run --rm \
  -v bcgeo-data:/source:ro \
  -v /opt/geo_django_dev/.dev/volumes/bcgeo-data:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```

### 3.9 tmp
```zsh
sudo docker run --rm \
  -v bcgeo-tmp:/source:ro \
  -v /opt/geo_django_dev/.dev/volumes/bcgeo-tmp:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```
### 3.10 Redis

```zsh
sudo docker run --rm \
  -v bcgeo-redisdata:/source:ro \
  -v /opt/geo_django_dev/.dev/volumes/bcgeo-redisdata:/destination \
  alpine sh -c 'cp -a /source/. /destination/'
```

## 4. Verify all copied directories

```zsh
sudo du -sh /opt/geo_django_dev/.dev/volumes/*
```

```py 
4.0K	/opt/geo_django_dev/.dev/volumes/backup-restore
4.0K	/opt/geo_django_dev/.dev/volumes/data
4.0K	/opt/geo_django_dev/.dev/volumes/dbbackups
158M	/opt/geo_django_dev/.dev/volumes/dbdata
2.7M	/opt/geo_django_dev/.dev/volumes/geoserver-data
20K	    /opt/geo_django_dev/.dev/volumes/nginx-certificates
80K	    /opt/geo_django_dev/.dev/volumes/nginx-confd
104K	/opt/geo_django_dev/.dev/volumes/redisdata
386M	/opt/geo_django_dev/.dev/volumes/statics
88K	    /opt/geo_django_dev/.dev/volumes/tmp
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
      - /opt/geo_django_dev/.dev/volumes/statics:/mnt/volumes/statics
      - /opt/geo_django_dev/.dev/volumes/geoserver-data:/geoserver_data/data
      - /opt/geo_django_dev/.dev/volumes/backup-restore:/backup_restore
      - /opt/geo_django_dev/.dev/volumes/data:/data
      - /opt/geo_django_dev/.dev/volumes/tmp:/tmp

  celery:
    volumes:
      - /opt/geo_django_dev/.dev/volumes/statics:/mnt/volumes/statics
      - /opt/geo_django_dev/.dev/volumes/geoserver-data:/geoserver_data/data
      - /opt/geo_django_dev/.dev/volumes/backup-restore:/backup_restore
      - /opt/geo_django_dev/.dev/volumes/data:/data
      - /opt/geo_django_dev/.dev/volumes/tmp:/tmp

  nginx:
    volumes:
      - /opt/geo_django_dev/.dev/volumes/nginx-confd:/etc/nginx
      - /opt/geo_django_dev/.dev/volumes/nginx-certificates:/geonode-certificates
      - /opt/geo_django_dev/.dev/volumes/statics:/mnt/volumes/statics

  letsencrypt:
    volumes:
      - /opt/geo_django_dev/.dev/volumes/nginx-certificates:/geonode-certificates

  geoserver:
    volumes:
      - /opt/geo_django_dev/.dev/volumes/statics:/mnt/volumes/statics
      - /opt/geo_django_dev/.dev/volumes/geoserver-data:/geoserver_data/data
      - /opt/geo_django_dev/.dev/volumes/backup-restore:/backup_restore
      - /opt/geo_django_dev/.dev/volumes/data:/data
      - /opt/geo_django_dev/.dev/volumes/tmp:/tmp

  data-dir-conf:
    volumes:
      - /opt/geo_django_dev/.dev/volumes/geoserver-data:/geoserver_data/data

  db:
    volumes:
      - /opt/geo_django_dev/.dev/volumes/dbdata:/var/lib/postgresql/data
      - /opt/geo_django_dev/.dev/volumes/dbbackups:/pg_backups

  redis:
    volumes:
      - /opt/geo_django_dev/.dev/volumes/redisdata:/data
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
        source: /opt/geo_django_dev/.dev/volumes/nginx-confd
        target: /etc/nginx
        bind: {}
      - type: bind
        source: /opt/geo_django_dev/.dev/volumes/nginx-certificates
        target: /geonode-certificates
        bind: {}
      - type: bind
        source: /opt/geo_django_dev/.dev/volumes/statics
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
        source: /opt/geo_django_dev/.dev/volumes/redisdata
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
    "Source": "/opt/geo_django_dev/.dev/volumes/dbbackups",
    "Destination": "/pg_backups",
    "Mode": "rw",
    "RW": true,
    "Propagation": "rprivate"
  },
  {
    "Type": "bind",
    "Source": "/opt/geo_django_dev/.dev/volumes/dbdata",
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



## **Backups Philosophy**

BCGeo runs on a dockerised environment.

As a result, volumes keep data persistent across container restarts.

The backups will serve as our reference point. 

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


## References

- [Set up ssh keys](https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server)

- 