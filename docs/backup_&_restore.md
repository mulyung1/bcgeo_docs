# Full GeoNode Backup & Restore(B/R).

## Overview

We can extract the Geonode and Geoserver data models via the admin command.

The output of the backup command is a serializable meta-format that is later interpreted by the restore procedure.

This exactly rebuilds the whole structure.

The following resources are extracted and serialised:

- **Geononde** (Base resource Model):
    
    - Layers(vector+raster) 

    - Maps

    - Documents

    - People with credentials

    - Permissions

    - Associated Styles

    - Static data & templates

- **Geoserver** (Catalog)

    - OWS Services configuration and limits

    - Security model along with auth filters configuration, users and credentials

    - Workspaces

    - Stores (datastores+coveragestores)

    - Layers

    - Styles

Two management commands are exposed by this tool, `backup` and `restore`

They allows us to Fully:

- backup GeoNode data and fixtres on a `zip archive`

- backup Geoserver configuration (physical datasets - tables, shps, geotiffs)\

- restore GeoNode & geoserver fixtures & catalog from the zip archive.


!!! warning "Warning"

    For GeoNode to work correctly, this functionality requires the latest `Geoserver Extension <https://build.geo-solutions.it/geonode/geoserver/latest/>_ (2.9.x or greater)`


## Requisites & setup

### Settings

`settings.ini` file must be created before running a b/r.

default files can be found at 

- `geonode/br/management/commands/settings_sample.ini` for classic environment.

- `geonode/br/management/commands/settings_docker_sample.ini` for a docker environment.

_The content is similar in both_

example `settings.ini` file

```text 
[database]
pgdump = pg_dump
pgrestore = pg_restore
psql = psql

[geoserver]
datadir = /geoserver_data/data
# datadir_exclude_file_path = {comma separated list of paths to exclude from geoserver catalog} e.g.: /data,/data/geonode,/geonode
dumpvectordata = yes
dumprasterdata = yes
# data_dt_filter = {cmp_operator} {ISO8601} e.g. > 20019-04-05T24:00
# data_layername_filter = {comma separated list of layernames, optionally with glob syntax} e.g.: tuscany_*,italy
# data_layername_exclude_filter = {comma separated list of layernames, optionally with glob syntax} e.g.: tuscany_*,italy

[fixtures]
apps  = contenttypes,auth,people,groups,account,guardian,admin,actstream,announcements,avatar,assets,base,documents,geoserver,invitations,pinax_notifications,harvesting,services,layers,maps,metadata,oauth2_provider,sites,socialaccount,taggit,tastypie,upload,geonode_themes,geoapps,favorite,geonode_client
dumps = contenttypes,auth,people,groups,account,guardian,admin,actstream,announcements,avatar,assets,base,documents,geoserver,invitations,pinax_notifications,harvesting,services,layers,maps,metadata,oauth2_provider,sites,socialaccount,taggit,tastypie,upload,geonode_themes,geoapps,favorite,geonode_client
```

- The above can be created in any directory accessible by geonode.

- Its path is passed to the b/r procedures using the `-c` (`--config`) argument.

lets closely examine the ini file

### **[database] Section**

```text
[database]
pgdump = pg_dump
pgrestore = pg_restore
psql = psql
```

- _pgdump_; the path of the `pg_dump` local command

- _pgrestore_; the path of the `pg_restore` local command

!!! warning "Warning"

    the above properties are ignored in a case where GeoNode is not configured to use a DataBase as backend

!!! note "Note"

    Db connection settings are taken from `settings.py` and `local_settings.py`conf files

    Ensure they are configured correctly & Db server is accessbile whilst executing a b/r comand


### [geoserver] Section

```text
[geoserver]
datadir = /geoserver_data/data
# datadir_exclude_file_path = {comma separated list of paths to exclude from geoserver catalog} e.g.: /data,/data/geonode,/geonode
dumpvectordata = yes
dumprasterdata = yes
# data_dt_filter = {cmp_operator} {ISO8601} e.g. > 20019-04-05T24:00
# data_layername_filter = {comma separated list of layernames, optionally with glob syntax} e.g.: tuscany_*,italy
# data_layername_exclude_filter = {comma separated list of layernames, optionally with glob syntax} e.g.: tuscany_*,italy
```

this section allows enable/disable a full data b/r of GeoServer.


