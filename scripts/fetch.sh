#!/usr/bin/env bash
# Downloads the upstream shfmt release binaries named in upstream.json and
# verifies each against its pinned sha256 digest. A binary whose digest does
# not match is deleted and the script exits 1, so nothing unverified is staged,
# packed or published.
#
#   scripts/fetch.sh <outdir> [platform ...]     (default: every platform)
#
# UPSTREAM_JSON overrides the manifest (default: upstream.json at the root);
# UPSTREAM_BASE_URL and UPSTREAM_LICENSE_URL override where the release assets
# and the LICENSE are downloaded from (the tests point them at local files).
#
# Result: <outdir>/assets/<asset name>   (the original upstream binary)
#         <outdir>/<platform>/shfmt[.exe] (the same bytes, executable)
#         <outdir>/LICENSE                (mvdan/sh's LICENSE at the tag)
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
manifest=${UPSTREAM_JSON:-$root/upstream.json}
out=${1:?usage: fetch.sh <outdir> [platform ...]}
shift

if [ "$#" -gt 0 ]; then
  platforms=("$@")
else
  read -r -a platforms <<<"$(jq -r '.assets | keys | join(" ")' "$manifest")"
fi

version=$(jq -er .version "$manifest")
base=${UPSTREAM_BASE_URL:-https://github.com/mvdan/sh/releases/download/v$version}

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

mkdir -p "$out/assets"
for platform in "${platforms[@]}"; do
  name=$(jq -er --arg p "$platform" '.assets[$p].name' "$manifest")
  digest=$(jq -er --arg p "$platform" '.assets[$p].digest' "$manifest")
  case "$digest" in
    sha256:*) expected=${digest#sha256:} ;;
    *) echo "fetch: $platform: digest '$digest' is not sha256:<hex>" >&2; exit 1 ;;
  esac

  asset="$out/assets/$name"
  echo "fetch: $platform <- $base/$name"
  curl -fsSL --retry 3 --retry-delay 5 -o "$asset" "$base/$name"

  actual=$(sha256 "$asset")
  if [ "$actual" != "$expected" ]; then
    echo "fetch: $platform: sha256 mismatch for $name" >&2
    echo "  expected $expected" >&2
    echo "  actual   $actual" >&2
    rm -f "$asset"
    exit 1
  fi
  echo "fetch: $platform: sha256 $actual OK"

  case "$platform" in
    win32-*) binary=shfmt.exe ;;
    *) binary=shfmt ;;
  esac
  dest="$out/$platform"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp "$asset" "$dest/$binary"
  chmod 755 "$dest/$binary"
done

license_url=${UPSTREAM_LICENSE_URL:-https://raw.githubusercontent.com/mvdan/sh/v$version/LICENSE}
curl -fsSL --retry 3 --retry-delay 5 -o "$out/LICENSE" "$license_url"
grep -q 'Daniel Mart' "$out/LICENSE" || { echo "fetch: the LICENSE at mvdan/sh v$version is not the expected one" >&2; exit 1; }
