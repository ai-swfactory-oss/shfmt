#!/usr/bin/env bash
# Moves the repository to the latest mvdan/sh release: rewrites upstream.json
# (version, Go toolchain, per-asset sha256 from the GitHub API digests) and the
# version of every package. Prints the new version, or nothing if already current.
# Needs GH_TOKEN for the gh CLI.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

release=$(gh api repos/mvdan/sh/releases/latest)
tag=$(jq -r .tag_name <<<"$release")
version=${tag#v}
[ "$version" = "$(upstream_version)" ] && exit 0

# "Binaries built on `go version go1.27.1 linux/amd64` with: ..."
go=$(jq -r .body <<<"$release" | grep -o 'go version go[0-9][0-9.]*' | head -1 | cut -d' ' -f3)
if [ -z "$go" ]; then
  echo "::error::$tag release notes do not name the Go version the binaries were built with" >&2
  exit 1
fi

new=$(jq -n --arg v "$version" --arg go "$go" '{version: $v, revision: 0, go: $go, assets: {}}')
for p in "${PLATFORMS[@]}"; do
  os=${p%-*}
  arch=${p#*-}
  [ "$arch" = x64 ] && arch=amd64
  name="shfmt_${tag}_${os}_${arch}"
  digest=$(jq -r --arg n "$name" '.assets[] | select(.name == $n) | .digest // empty' <<<"$release")
  case "$digest" in
    sha256:*) ;;
    *) echo "::error::$tag has no sha256 digest for asset $name" >&2; exit 1 ;;
  esac
  new=$(jq --arg p "$p" --arg n "$name" --arg d "${digest#sha256:}" '.assets[$p] = {name: $n, sha256: $d}' <<<"$new")
done
jq . <<<"$new" >"$UPSTREAM"

"$ROOT/scripts/set-version.sh"
echo "$version"
