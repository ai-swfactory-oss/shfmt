#!/usr/bin/env bash
set -euo pipefail
manifest=${UPSTREAM_JSON:-$(cd "$(dirname "$0")/.." && pwd)/packages/shfmt/src/upstream.json}
jq -er 'if (.repack // 0) > 0 then "\(.version)-r.\(.repack)" else .version end' "$manifest"
