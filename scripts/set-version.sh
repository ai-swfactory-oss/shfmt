#!/usr/bin/env bash
# Writes the version upstream.json implies into every package.json and pins the
# launcher's optionalDependencies to it exactly. Run after editing upstream.json
# by hand (for example to bump "revision" for a re-pack).
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

v=$(package_version)
edit() {
  local tmp
  tmp=$(mktemp)
  jq "${@:2}" "$1" >"$tmp"
  mv "$tmp" "$1"
}

for p in "${PLATFORMS[@]}"; do
  edit "$ROOT/packages/shfmt-$p/package.json" --arg v "$v" '.version = $v'
done
edit "$ROOT/packages/shfmt/package.json" --arg v "$v" \
  '.version = $v | .optionalDependencies |= with_entries(.value = $v)'
