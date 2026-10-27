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

## References

- []
