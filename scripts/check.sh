#!/usr/bin/env bash
# Fails unless every package.json carries the version upstream.json implies,
# the launcher pins each platform package to exactly that version, and no
# package declares an install script.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

want=$(package_version)
fail=0
check() {
  if [ "$2" != "$3" ]; then echo "::error::$1: expected $3, found $2" >&2; fail=1; fi
}

main="$ROOT/packages/shfmt/package.json"
check "packages/shfmt version" "$(jq -r .version "$main")" "$want"
for p in "${PLATFORMS[@]}"; do
  pj="$ROOT/packages/shfmt-$p/package.json"
  check "packages/shfmt-$p version" "$(jq -r .version "$pj")" "$want"
  check "packages/shfmt-$p name" "$(jq -r .name "$pj")" "$SCOPE/shfmt-$p"
  check "optionalDependencies $SCOPE/shfmt-$p" "$(jq -r --arg n "$SCOPE/shfmt-$p" '.optionalDependencies[$n]' "$main")" "$want"
done
check "optionalDependencies count" "$(jq '.optionalDependencies | length' "$main")" "${#PLATFORMS[@]}"

for pj in "$ROOT"/packages/*/package.json; do
  scripts=$(jq -r '(.scripts // {}) | keys | map(select(test("install|prepare|prepack|postpack"))) | join(",")' "$pj")
  check "$pj lifecycle scripts" "$scripts" ""
done

exit "$fail"
