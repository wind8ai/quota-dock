#!/bin/bash
set -euo pipefail
export LC_ALL=C LANG=C
project_dir="$(cd "$(dirname "$0")/.." >/dev/null && pwd)"
app="$project_dir/build/QuotaDock.app"

# Only replace this script's generated bundle. Never touch installed/legacy apps.
mkdir -p "$project_dir/build"
staging="$(mktemp -d "$project_dir/build/.bundle.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
mkdir -p "$staging/QuotaDock.app/Contents/MacOS"
cp "$project_dir/Resources/Info.plist" "$staging/QuotaDock.app/Contents/Info.plist"
xcrun swiftc -O -target "$(uname -m)-apple-macosx11.0" \
    "$project_dir"/Sources/QuotaCore/*.swift \
    "$project_dir"/Sources/QuotaDock/*.swift \
    -o "$staging/QuotaDock.app/Contents/MacOS/QuotaDock"
chmod 755 "$staging/QuotaDock.app/Contents/MacOS/QuotaDock"
plutil -lint "$staging/QuotaDock.app/Contents/Info.plist"
rm -rf "$app"
mv "$staging/QuotaDock.app" "$app"
printf 'Built: %s\n' "$app"
