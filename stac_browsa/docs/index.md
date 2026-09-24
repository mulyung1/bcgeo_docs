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


## Sample config_local.mjs

This file has two core functions so far:

-  **buildBidxParams** >> to check whether the image/asset is multi band

- **buildTileUrlTemplate** >> builds the tile endpoint for assets

??? note "TODO"

    map color jsons to specific assets via a dictionary

```javascript
// Local overrides loaded on top of config.js via SB_CONFIG (see .env).
const TITILER = "https://titiler.xyz";

// TiTiler's PNG encoder can't handle more than 4 bands, so assets with many
// bands (e.g. the 13-band Landsat composites in this catalog) need an explicit
// RGB band selection. Landsat order: b2=blue, b3=green, b4=red.
const LANDSAT_RGB_BIDX = [4, 3, 2];

function isLandsatComposite(asset, href) {
  const collection = asset.getContext()?.collection ?? null;
  if (collection === "ls8_250_Africa") {
    return true;
  }
  // Same collection's items link assets with an LC8 file name
  return /Comp_LC8_|LC08|LC09/.test(href);
}

function buildBidxParams(asset, href) {
  // Prefer the band metadata if the STAC docs provide it
  const bands = asset.bands ?? asset.getMetadata?.("raster:bands") ?? [];
  if (Array.isArray(bands) && bands.length > 0) {
    if (bands.length <= 3) {
      return "";
    }
    const commonNames = bands.map((b) => (b?.["eo:common_name"] || "").toLowerCase());
    const rgb = ["red", "green", "blue"].map((name) => commonNames.indexOf(name));
    const indexes = rgb.every((i) => i >= 0)
      ? rgb.map((i) => i + 1) // 1-based band indexes
      : [1, 2, 3]; // fall back to the first three bands
    return indexes.map((i) => `&bidx=${i}`).join("");
  }
  // No band metadata: only known multi-band composites get an explicit selection,
  // everything else (e.g. single-band SRTM) is sent without bidx.
  if (isLandsatComposite(asset, href)) {
    return LANDSAT_RGB_BIDX.map((i) => `&bidx=${i}`).join("");
  }
  return "";
}

export default {
  useTileLayerAsFallback: false,
  buildTileUrlTemplate: (asset) => {
    const href = asset.getAbsoluteUrl();
    // Only hand GeoTIFF/COG assets over http(s) to TiTiler;
    // everything else (thumbnails, PNG/JPEG previews, s3:// hrefs, ...)
    // returns null and is rendered as usual.
    if (!href || !/^https?:\/\//i.test(href)) {
      return null;
    }
    const isGeoTiff =
      (asset.type || "").toLowerCase().includes("geotiff") ||
      (asset.roles || []).includes("data");
    if (!isGeoTiff) {
      return null;
    }
    const bidx = buildBidxParams(asset, href);
    return (
      `${TITILER}/cog/tiles/WebMercatorQuad/{z}/{x}/{y}.png?url=` +
      encodeURIComponent(href) +
      bidx
    );
  },
};

```

## References

- [Browsa Configurations](https://github.com/radiantearth/stac-browser/blob/main/docs/options.md#http-basic)

