#!/usr/bin/env bash
# The single-quoted node programs are literal on purpose.
# shellcheck disable=SC2016
# Named test, per platform: installs the packed tarballs into a scratch project,
# as a consumer would, and checks that binaryPath() resolves to an executable
# file that is the unmodified upstream binary, that running it with --version
# prints upstreamVersion, and that it formats and parses a script.
#
#   scripts/smoke.sh <tgzdir> <platform>      e.g. dist/tgz linux-x64
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tgz=$(cd "${1:?usage: smoke.sh <tgzdir> <platform>}" && pwd)
platform=${2:?usage: smoke.sh <tgzdir> <platform>}
upstream=$(jq -er .version "$root/upstream.json")
version=$(bash "$root/scripts/pkgver.sh")
digest=$(jq -er --arg p "$platform" '.assets[$p].digest' "$root/upstream.json")

launcher="$tgz/ai-swfactory-oss-shfmt-$version.tgz"
native="$tgz/ai-swfactory-oss-shfmt-$platform-$version.tgz"

for f in "$launcher" "$native"; do
  test -f "$f" || { echo "smoke: missing $f" >&2; exit 1; }
  if tar -xzOf "$f" package/package.json | jq -e '.scripts // {} | keys | any(test("install"))' >/dev/null; then
    echo "smoke: $f declares an install script" >&2; exit 1
  fi
done

work=$(mktemp -d)
cd "$work"
printf '{"name":"smoke","version":"1.0.0","private":true}\n' >package.json
npm install --no-audit --no-fund "$launcher" "$native"

echo "== npm ls"
npm ls --all || true

echo "== binaryPath(), upstreamVersion and --version"
SHFMT_DIGEST=$digest node -e '
  const { execFileSync } = require("node:child_process");
  const { createHash } = require("node:crypto");
  const fs = require("node:fs");
  const shfmt = require("@ai-swfactory-oss/shfmt");
  const expected = process.argv[1];
  if (shfmt.upstreamVersion !== expected) throw new Error(`upstreamVersion ${shfmt.upstreamVersion} != ${expected}`);
  const bin = shfmt.binaryPath();
  if (!fs.statSync(bin).isFile()) throw new Error(`${bin} is not a file`);
  if (process.platform !== "win32") fs.accessSync(bin, fs.constants.X_OK);
  const sha = `sha256:${createHash("sha256").update(fs.readFileSync(bin)).digest("hex")}`;
  if (sha !== process.env.SHFMT_DIGEST) throw new Error(`${bin} is ${sha}, not the upstream asset ${process.env.SHFMT_DIGEST}`);
  const printed = execFileSync(bin, ["--version"], { encoding: "utf8" }).trim();
  if (printed !== `v${expected}`) throw new Error(`${bin} --version printed ${printed}, expected v${expected}`);
  console.log(bin, printed, sha);
' "$upstream"

echo "== shfmt command: format and parse"
bin="$work/node_modules/.bin/shfmt"
printf 'if true;then echo  hi;fi\n' >in.sh
"$bin" in.sh >out.sh
printf 'if true; then echo hi; fi\n' >expected.sh
diff -u expected.sh out.sh
printf 'a=1\n' | "$bin" --to-json | node -e '
  let s = ""; process.stdin.on("data", d => (s += d)).on("end", () => {
    const ast = JSON.parse(s);
    if (ast.Type !== "File" || !Array.isArray(ast.Stmts) || ast.Stmts.length !== 1) throw new Error(`unexpected AST: ${s}`);
    console.log("--to-json: File with one statement");
  });'

echo "smoke: $platform OK"
