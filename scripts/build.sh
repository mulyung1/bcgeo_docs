#!/usr/bin/env bash
#
# Build every MkDocs project in this repo into one combined site directory.
#
#   ./site/index.html          <- hub (root mkdocs.yml)
#   ./site/bcgeo/              <- topic: BCGeo docs
#   ./site/stac_browsa/        <- topic: STAC Browser
#
# Usage:
#   ./scripts/build.sh
#
# Environment:
#   PASSWORD     required to build the bcgeo topic (encryptcontent plugin)
#   SITE_DIR     override output directory (default: site)
#   STRICT       set to 1 to build with --strict (warnings become errors)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SITE_DIR="${SITE_DIR:-site}"
# Resolve to an absolute path: mkdocs resolves a relative --site-dir against the
# CONFIG file's directory (not the cwd), which would scatter topic output.
case "$SITE_DIR" in
  /*) ;;
  *) SITE_DIR="$ROOT/$SITE_DIR" ;;
esac
STRICT_FLAG=""
if [ "${STRICT:-0}" = "1" ]; then
  STRICT_FLAG="--strict"
fi

if [ -z "${PASSWORD:-}" ]; then
  echo "WARNING: PASSWORD is not set - the bcgeo topic needs it for the encryptcontent plugin." >&2
  echo "         export PASSWORD=your_password and re-run if the bcgeo build fails." >&2
fi

# Build order matters: `mkdocs build` CLEANS its site_dir first, so the hub
# (whose site_dir is the combined ./site root) must build BEFORE the topics —
# each topic build only cleans its own ./site/<topic> subdir afterwards.
build_topic() {
  local config="$1"
  local name="$2"
  echo "==> Building topic '${name}' (${config})"
  mkdocs build -f "$config" --site-dir "$SITE_DIR/$name" $STRICT_FLAG
}

echo "==> Cleaning ${SITE_DIR}/"
rm -rf "$SITE_DIR"

echo "==> Building hub (mkdocs.yml)"
mkdocs build --site-dir "$SITE_DIR" $STRICT_FLAG

build_topic bcgeo/mkdocs.yml bcgeo
build_topic stac_browsa/mkdocs.yml stac_browsa

echo "==> Done. Combined site in ${SITE_DIR}/:"
find "$SITE_DIR" -maxdepth 2 -name index.html | sort
