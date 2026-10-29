## Walk down memory lane

Traditionaly, publishing geospatial data meant 

- deploying & maintaining 
    - servers,
    - APIs and
    - databases

- this was good when spatial files could not be queried over the network.

Enter 

- petabyte-sized datasets 
    - impractical to load to memory for analysis
- agents
    - they generate query volumes not supported/designed by/for traditional serving infrastructure.

!!! warning "Consequently, "
    this SDI model is becoming less sustainable.

in recent times, the cloud-native geospatial community  has laid ground work for a new way of building SDIs.

- To organise these petabyte-scale datasets in object storage,

    - **Cloud-optimised file formats** &

    - **STAC metadata** make it possible.

!!! tip "In other words"
    an SDI can now be a bunch of files S3-compatible cloud storage, with no

        - servers

        - databases

        - or custom APIs

### What is Portolan??

- an **open-source specification** and toolkit.

- useful for publishing geospatial data

!!! abstract "In the core,"
    It is a recipe/specification defining the best ways to build a serveless SDI

- Builds on existing standards >> no re-invention

#### 1. The foundation

- is made up of Cloud-optimised formats.

- **Vector data** -> `GeoParquet` && `PMTiles` 

- **Raster data** -> `COG` 

    - Future support for `Zarr` and `COPC`

!!! abstract "The advantage?"

    researchers are able to:

    - <u>cheaply host</u> && <u>share</u> enourmous datasets in object storage 

    - allow users to. efficiently access just the bytes they need.

#### 2. Data organization

- `STAC`, a metadata specification for geospatial data is used to achieve this.

- This means that Portolan Catalogs are consistently
    
    - organised &

    - indexed

- The consistency allows <u>people</u> and <u>agents</u> reliably search & navigate whether present are 10 or millions of files. 

#### 3. Documentation

- All portolan catalogs must include `README`s & `AGENTS.md` files.

- This makes it easy for people and agents to 

    - understand &

    - work with the data.

??? tip "Design Belief system"
    reducing the infrastructure required to publish and maintain SDIs means publishers can spend more energy on
    
    - high quality metadata && 
    
    - docs

Portolan lays out requirments and bestpractioces for CORS issues.

- for instance: for data hosting with no CORS cant be used on a serverless web app

#### 4. Validation

[`rashid`](https://github.com/portolan-sdi/rashid), a validator, 

- checks catalogs against the specification

- reports failures against MUST requirements and warnings angains SHOULD requirements.

- outputs a agent-friendly JSON making it straightforward to identify and fix anything that falls short.

read more about rashid [here](https://github.com/portolan-sdi/rashid)


### <u>What portolan makes possible</u>

As soon as users can query files directly, 

- data publishers don't need to maintain a service that sits between the user and the data 
    
    - eg, geoserver ogc services vs COG & parquet.

For public catalogs. 

- the need for a lot of infrastructure associated with a traditional SDI is eliminated. 

    - servers(geoserver, arcgis)

    - databases(postgis for geospatial data)

    - custom APIs(for data access) plus

    - the operational work required to keep these running

#### - For large dataset publishers, 

this changes both cost and scale.

- National/organizational geoportals can rely on object storage rather than maintaining a separate layer sized for peak demand.


??? tip "COST"
    Cost is cut down to storage and data transfer.

This opens up possibilities to host terabytes of data without paying to operate a dedicated geospatial service.


!!! question "The big Question to city governments, NGOs, researchers, and smaller data producers"

    Why maintain GeoServer, Esri infrastructure, or a custom API just to publish a handful of datasets?

    While files in a bucket lower the technical and financial barriers to geospatial data publishing.



#### - For users

portolan provides 

- a faster, 

- more consistent way to access data.

**<u>Tool integration</u>**

Portolan catalogs use formats that already work out of the box with tools like

- QGIS

- ArcGIS

- DuckDB

- Python

Cloud-optimised formats however, allow faster access than WFS/WMS... endpoints or ESRI servers ever could.

## Implementation

A set of toolsvhave been built to ease publishing and working with portolan.

### 1. rashid

read on rashid in [this section](#4-validation)

### 2. Portolan CLI

The behind the scenes guy that handles:

- ingesting source data,

- converting it into cloud-optimised formats

- managing catalog structure and metadata

- publishing finished catalogs to object storage.

### 3. agent skills

these can orchestrate publication, from start to finish.

an example is `portolan-bootstrap`.

- it can start with 
    
    - a folder of files,

    - a WFS endpoint,

    - an ESRI service or

    - another publication dataset.

- then work through 

    - catalog structure, 
    
    - conversion, 
    
    - documentation

    - visualization,

    - validation and

    - publication.

<figure>
  <video controls preload="metadata" width="100%">
    <source src="https://cloudnativegeo.org/videos/20260902-portolan-demo-one.mp4" type="video/mp4">
    Your browser does not support video. <a href="https://cloudnativegeo.org/videos/20260902-portolan-demo-one.mp4">Download it</a>.
  </video>
  <figcaption>Figure 1. An agent creates and publishes a Portolan catalog from Philadelphia housing data.</figcaption>
</figure>



## References

- [Introducing Portolan](#https://cloudnativegeo.org/blog/2026/09/introducing-portolan/)

- [Rashid the validator](#https://github.com/portolan-sdi/rashid)