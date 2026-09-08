## Introduction

Lets add custom basemaps into geonode.

GeoNode's mapping client is Mapstore

Mapstore is an 

- opensource WebGis Framework as well as 
- a standard geoportal product.

It manages and shares 

- web-based maps
- dashboards &
- stories online

It is map agnostic

- this allows it to work with different mapping libraries
- it supports mapping engines like
    - OpenLayers
    - Leaflet.JS
    - Cesium 3D viewer

Read more on mapstore [here](https://docs.mapstore.geosolutionsgroup.com/en/latest/)


## Geononde Mapstore client
This module is geonode's mapping UI

It is important as most of the customizaation done inside a geonode-project are overiddes based on file locations

### 3 Arms of the client

**1. client**

- this directory contains all source code needed for the mapstore app

**2. static/mapstore**

- all compiled static files used by geonode via the `django.geononde_mapstore_client` module reside here.

**3. templates**

- all the html django templates used by ui are found here.

```text
geonode_mapstore_client/
|-- ...
|-- client/
|    |-- ...
|    |-- js/
|    |-- MapStore2/
|    |-- themes/
|    |    +-- geonode/
|    |-- ...
|    |-- .env.sample
|    |-- package.json
|    +-- version.txt
|-- static/
|    |-- ...
|    +-- mapstore/
|    |    |-- ...
|    |    |-- configs/
|    |    |    |-- ...
|    |    |    +-- localConfig.json
|    |    |-- dist/
|    |    |    +-- ... 
|    |    |-- extensions/
|    |    |    +-- index.json
|    |    |-- gn-translations/
|    |    |-- img/
|    |    |-- ms-translations/
|    |    |-- symbols/
|    |    +-- version.txt
|-- templates/
|    +-- geonode-mapstore-client/
|-- ...
```

### Javascript files 

- `geonode_mapstore_client/client/js/`  - contains all `js` ans `jsx` files needed to build the app
    - targetted by `babel loader`.
    - hence can use `javascript es6` features inside `.js` and `.jsx` files.

- these files are compiled with the `npm run compile script` 
    -  the bundle is copied in the `static/mapstore/dist` directory.
- this allows it be available from geonode templates

Folder naming follows Mapstores naming convention

Directories are 


## References

- [Geosolutions Mapstore Intro](https://docs.mapstore.geosolutionsgroup.com/en/latest/)
- [Structure of the client](https://training.geonode.geosolutionsgroup.com/master/GN4/mapstore_client/002_CLIENT_STRUCTURE.html)
- []()