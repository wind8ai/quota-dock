#!/bin/bash
set -euo pipefail
export LC_ALL=C LANG=C
project_dir="$(cd "$(dirname "$0")/.." >/dev/null && pwd)"
mkdir -p "$project_dir/.build" "$project_dir/docs/images"
preview_dir="$(mktemp -d "$project_dir/.build/preview.XXXXXX")"
trap 'rm -rf "$preview_dir"' EXIT
# Reuse the production view verbatim, without starting its window tracker or timers.
awk '/^private struct ScreenCoordinateConverter/ { exit } { print }' \
    "$project_dir/Sources/QuotaDock/main.swift" > "$preview_dir/main.swift"
cat "$project_dir/scripts/state-preview.swift" >> "$preview_dir/main.swift"
xcrun swiftc -target "$(uname -m)-apple-macosx11.0" \
    "$project_dir/Sources/QuotaCore/BadgeLayout.swift" "$preview_dir/main.swift" \
    -o "$preview_dir/render-states"
"$preview_dir/render-states" "$project_dir/docs/images/quota-states.png"
