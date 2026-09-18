# STAC Browser customisation


## Overview

STAC Browser exposes a wide variety of configuration options.

The following ways to set config options are possible:

- Load an external config file via SB_CONFIG

- To Set environment variables, all options need a SB_ prefix.

!!! tip "cheat code"

    To enable the usage of a local configuration file, follow these steps:

    Create a .env file with the following content:

    ``` text
    SB_CONFIG=config.local.mjs
    ```
    Create a config.local.mjs and add options from the config.js as needed, for example:

    ```text
    export default {
      catalogUrl: 'https://stac.example.com'
    }
    ```

    Run the browser with these custom settings.
    ```text
    SB_CONFIG=config.local.mjs npm start
    ```

The override order for the configuration looks like:

`config.js` (lowest priority) -> config from `SB_CONFIG`(our own) -> `SB_*` env vars -> `runtime-config.js` (highest priority)



## Mapping

All the mapping-related options are passed through to ol-stac.

### buildTileURLtemplate

- enables the usage of a tile server, e.g titiler

- SSR

    - It allows rendering imagery such as (cloud-optimized) GeoTiffs through a tile server instead of doing the visualization on the client-side.

- `Titiler` will be default if `useTileLayerAsFallback` is set to `false`




## References

- [Browsa Configurations](https://github.com/radiantearth/stac-browser/blob/main/docs/options.md#http-basic)

