#!/bin/bash
set -euo pipefail
export LC_ALL=C LANG=C
project_dir="$(cd "$(dirname "$0")/.." >/dev/null && pwd)"
mkdir -p "$project_dir/.build" "$project_dir/docs/images"
preview_dir="$(mktemp -d "$project_dir/.build/preview.XXXXXX")"
trap 'rm -rf "$preview_dir"' EXIT
# Compile the production view directly without application timers or quota reads.
cp "$project_dir/scripts/state-preview.swift" "$preview_dir/main.swift"
xcrun swiftc -target "$(uname -m)-apple-macosx11.0" \
    "$project_dir/Sources/QuotaDock/QuotaMeterView.swift" "$preview_dir/main.swift" \
    -o "$preview_dir/render-states"
"$preview_dir/render-states" "$project_dir/docs/images/quota-states-v3.png" \
    "$project_dir/docs/images/account-bar-v3-reference.png"
