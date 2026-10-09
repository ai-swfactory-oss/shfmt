# Shared helpers, sourced by the other scripts. Requires jq.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
UPSTREAM="$ROOT/upstream.json"
SCOPE="@ai-swfactory-oss"
PLATFORMS=(linux-x64 linux-arm64 darwin-x64 darwin-arm64)

upstream_version() { jq -r .version "$UPSTREAM"; }
go_version() { jq -r .go "$UPSTREAM"; }

# The npm version: the upstream version, or <upstream>-r.<n> for a re-pack.
package_version() {
  local v r
  v=$(jq -r .version "$UPSTREAM")
  r=$(jq -r .revision "$UPSTREAM")
  if [ "$r" = 0 ]; then echo "$v"; else echo "$v-r.$r"; fi
}

asset_name() { jq -r --arg p "$1" '.assets[$p].name' "$UPSTREAM"; }
asset_sha256() { jq -r --arg p "$1" '.assets[$p].sha256' "$UPSTREAM"; }

sha256_of() {
  if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi
}
