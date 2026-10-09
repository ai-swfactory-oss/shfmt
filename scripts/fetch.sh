#!/usr/bin/env bash
# Downloads the upstream release binaries named in upstream.json, verifies each
# against its recorded sha256 (the GitHub API asset digest), and fills the
# platform packages: bin/shfmt (mode 755), LICENSE (mvdan/sh) and LICENSE-go
# (the Go standard library is statically linked into the binary).
# Also leaves the raw upstream files in dist/assets/ for the GitHub release.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

tag="v$(upstream_version)"
go=$(go_version)
assets="$ROOT/dist/assets"
mkdir -p "$assets"

curl -fsSL --retry 3 -o "$assets/LICENSE" "https://raw.githubusercontent.com/mvdan/sh/$tag/LICENSE"
curl -fsSL --retry 3 -o "$assets/LICENSE-go" "https://raw.githubusercontent.com/golang/go/$go/LICENSE"

for p in "${PLATFORMS[@]}"; do
  name=$(asset_name "$p")
  want=$(asset_sha256 "$p")
  curl -fsSL --retry 3 -o "$assets/$name" "https://github.com/mvdan/sh/releases/download/$tag/$name"
  got=$(sha256_of "$assets/$name")
  if [ "$got" != "$want" ]; then
    echo "::error::$name: sha256 $got does not match upstream.json $want" >&2
    exit 1
  fi
  echo "verified $name $got"

  pkg="$ROOT/packages/shfmt-$p"
  mkdir -p "$pkg/bin"
  cp "$assets/$name" "$pkg/bin/shfmt"
  chmod 755 "$pkg/bin/shfmt"
  cp "$assets/LICENSE" "$pkg/LICENSE"
  cp "$assets/LICENSE-go" "$pkg/LICENSE-go"
done
cp "$assets/LICENSE" "$ROOT/packages/shfmt/LICENSE"
cp "$assets/LICENSE-go" "$ROOT/packages/shfmt/LICENSE-go"
