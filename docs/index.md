# Documentation Hub

Welcome! This repository hosts documentation for several topics. Each topic is its
own MkDocs project, built and published together under one site.

## Topics

| Topic | Description |
|-------|-------------|
| [BCGeo Docs](/bcgeo/) | Tech notes for the Benin Climate Geoportal (BCGeo) — GeoNode customizations, production ops, SSO, backups and more. Password protected. |
| [STAC Browser](/stac_browsa/) | Research & development notes for the STAC Browser. |

## Running locally

```bash
python -m venv .docs_venv && source .docs_venv/bin/activate
pip install -r requirements.txt
export PASSWORD=your_password   # required by the BCGeo topic
./scripts/build.sh              # build every site into ./site
```

See the [README](https://github.com/mulyung1/bcgeo_docs) for serving a single topic.
