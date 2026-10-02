#!/bin/bash
set -euo pipefail
export LC_ALL=C LANG=C
project_dir="$(cd "$(dirname "$0")/.." >/dev/null && pwd)"
mkdir -p "$project_dir/.build"
preview_dir="$(mktemp -d "$project_dir/.build/animation.XXXXXX")"
trap 'rm -rf "$preview_dir"' EXIT
cp "$project_dir/scripts/animation-preview.swift" "$preview_dir/main.swift"
xcrun swiftc -target "$(uname -m)-apple-macosx11.0" \
    "$project_dir/Sources/QuotaCore/BadgeLayout.swift" \
    "$project_dir/Sources/QuotaCore/QuotaMeterAnimation.swift" \
    "$project_dir/Sources/QuotaCore/QuotaDisplayValue.swift" \
    "$project_dir/Sources/QuotaDock/QuotaMeterView.swift" "$preview_dir/main.swift" \
    -o "$preview_dir/animation-preview"
"$preview_dir/animation-preview" "$@"
