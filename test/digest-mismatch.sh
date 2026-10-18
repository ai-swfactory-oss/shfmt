#!/usr/bin/env bash
# Named test: a release asset whose sha256 does not match the digest pinned in
# upstream.json fails scripts/fetch.sh, which the build runs before it stages,
# packs or publishes anything, and leaves no asset behind. The same asset with
# its true digest is accepted, so the check is not vacuous. Runs offline: the
# "release" is a local file.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

mkdir -p "$work/release"
printf 'not really shfmt\n' >"$work/release/shfmt_v9.9.9_linux_amd64"
printf 'Copyright (c) 2016, Daniel Martí. All rights reserved.\n' >"$work/release/LICENSE"
true_digest=$(sha256 "$work/release/shfmt_v9.9.9_linux_amd64")
wrong_digest=$(printf '%064d' 0)

manifest() { # <digest>
  jq -n --arg d "sha256:$1" \
    '{version: "9.9.9", repack: 0, assets: {"linux-x64": {name: "shfmt_v9.9.9_linux_amd64", digest: $d}}}'
}

fetch() { # <manifest file> <outdir>
  UPSTREAM_JSON=$1 UPSTREAM_BASE_URL="file://$work/release" UPSTREAM_LICENSE_URL="file://$work/release/LICENSE" \
    bash "$root/scripts/fetch.sh" "$2"
}

manifest "$wrong_digest" >"$work/wrong.json"
set +e
fetch "$work/wrong.json" "$work/out-wrong" >"$work/wrong.log" 2>&1
rc=$?
set -e
cat "$work/wrong.log"
test "$rc" -ne 0 || { echo "digest-mismatch: fetch accepted an asset whose digest does not match" >&2; exit 1; }
grep -q 'sha256 mismatch for shfmt_v9.9.9_linux_amd64' "$work/wrong.log" || { echo "digest-mismatch: the failure does not name the mismatch" >&2; exit 1; }
test ! -e "$work/out-wrong/assets/shfmt_v9.9.9_linux_amd64" || { echo "digest-mismatch: the mismatching asset was left behind" >&2; exit 1; }
test ! -e "$work/out-wrong/linux-x64" || { echo "digest-mismatch: the mismatching binary was extracted" >&2; exit 1; }

manifest "$true_digest" >"$work/true.json"
fetch "$work/true.json" "$work/out-true"
cmp "$work/release/shfmt_v9.9.9_linux_amd64" "$work/out-true/linux-x64/shfmt"

echo "digest-mismatch: OK"
