#!/usr/bin/env bash
# Builds shfmt from source, exactly as upstream builds its release binaries:
#   CGO_ENABLED=0 go build -trimpath -ldflags="-w -s" ./cmd/shfmt
# from the mvdan/sh tag in upstream.json (which must resolve to the pinned
# commit), with the Go version upstream.json names (which `go version` must
# report). Fills the platform packages with bin/shfmt (mode 755), LICENSE
# (mvdan/sh) and LICENSE-go (the Go standard library is statically linked),
# leaves the binaries in dist/assets/, and compares each with the digest of the
# corresponding upstream release asset. A mismatch is reported, not fatal.
# Writes the comparison to dist/comparison.md.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

tag="v$(upstream_version)"
commit=$(upstream_commit)
go=$(go_version)
src="$ROOT/dist/src"
assets="$ROOT/dist/assets"

have=$(go env GOVERSION)
if [ "$have" != "$go" ]; then
  echo "::error::upstream.json names $go but the toolchain is $have" >&2
  exit 1
fi

rm -rf "$src"
git clone -q --branch "$tag" https://github.com/mvdan/sh.git "$src"
head=$(git -C "$src" rev-parse HEAD)
if [ "$head" != "$commit" ]; then
  echo "::error::$tag resolves to $head, upstream.json pins $commit" >&2
  exit 1
fi
test -z "$(git -C "$src" status --porcelain)"

mkdir -p "$assets"
cp "$src/LICENSE" "$assets/LICENSE"
curl -fsSL --retry 3 -o "$assets/LICENSE-go" "https://raw.githubusercontent.com/golang/go/$go/LICENSE"

matches=0
{
  echo "| asset | our build sha256 | upstream release sha256 | |"
  echo "|---|---|---|---|"
} >"$ROOT/dist/comparison.md"
for p in "${PLATFORMS[@]}"; do
  name=$(asset_name "$p")
  (cd "$src" && CGO_ENABLED=0 GOOS=$(goos "$p") GOARCH=$(goarch "$p") \
    go build -trimpath -ldflags="-w -s" -o "$assets/$name" ./cmd/shfmt)
  ours=$(sha256_of "$assets/$name")
  theirs=$(upstream_sha256 "$p")
  if [ "$ours" = "$theirs" ]; then
    mark=identical
    matches=$((matches + 1))
  else
    mark=differs
    echo "::warning::$name: our build $ours differs from the upstream release asset $theirs"
  fi
  echo "| $name | \`$ours\` | \`$theirs\` | $mark |" >>"$ROOT/dist/comparison.md"
  echo "built $name $ours ($mark from upstream)"

  pkg="$ROOT/packages/shfmt-$p"
  mkdir -p "$pkg/bin"
  cp "$assets/$name" "$pkg/bin/shfmt"
  chmod 755 "$pkg/bin/shfmt"
  cp "$assets/LICENSE" "$assets/LICENSE-go" "$pkg/"
done
cp "$assets/LICENSE" "$assets/LICENSE-go" "$ROOT/packages/shfmt/"
echo "$matches/${#PLATFORMS[@]}" >"$ROOT/dist/matches"
echo "$matches of ${#PLATFORMS[@]} builds are byte-identical to the upstream release assets"
