## Docs Hub — multi-topic MkDocs repo

This repository hosts **multiple documentation topics** under one site:

| Topic | Config | Content | URL path |
|-------|--------|---------|----------|
| Hub (landing page) | `mkdocs.yml` | `docs/` | `/` |
| BCGeo Docs | `bcgeo/mkdocs.yml` | `bcgeo/docs/` | `/bcgeo/` |
| STAC Browser | `stac_browsa/mkdocs.yml` | `stac_browsa/docs/` | `/stac_browsa/` |

Shared theme/extensions live in `shared/mkdocs.base.yml`; each topic config uses
`INHERIT:` to pull it in and only declares its own differences (`site_name`,
`site_url`, palette, `plugins`).

### Setup

```bash
python -m venv .docs_venv
source .docs_venv/bin/activate
pip install -r requirements.txt

export PASSWORD=your_password   # needed by the bcgeo topic (encryptcontent).
                                 # ensure password is strong as it affects encryption quality.
```

### Build / serve everything

```bash
./scripts/build.sh              # builds hub + all topics into ./site
STRICT=1 ./scripts/build.sh     # warnings become errors (used for checking)
python -m http.server -d site 8000   # preview the combined site at http://localhost:8000
```

### Serve a single topic while writing

```bash
mkdocs serve -f bcgeo/mkdocs.yml          # http://127.0.0.1:8000
mkdocs serve -f stac_browsa/mkdocs.yml    # http://127.0.0.1:8001 (pick a free port)
mkdocs serve                              # hub landing page
```

### Adding a new topic

1. Create `mytopic/mkdocs.yml` starting from:
   ```yaml
   INHERIT: ../shared/mkdocs.base.yml
   site_name: My Topic
   site_url: https://cgbenin.landscapealliance.org/mytopic/
   plugins:
     - search
   ```
2. Add content under `mytopic/docs/`.
3. Register it in `scripts/build.sh` (`build_topic mytopic/mkdocs.yml mytopic`)
4. Link it from `docs/index.md` (the hub page).

### Deployment

GitHub Actions (`.github/workflows/ci.yaml`) runs `./scripts/build.sh` and
publishes the combined `site/` directory to the `gh-pages` branch on pushes to
`main`/`master`. The `PASSWORD` repository secret must be set.

### References

- https://www.youtube.com/watch?v=xlABhbnNrfI&t=419s
- https://jameswillett.dev/getting-started-with-material-for-mkdocs/
- https://squidfunk.github.io/mkdocs-material/
