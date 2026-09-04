#!/bin/bash
set -euo pipefail
export LC_ALL=C LANG=C
project_dir="$(cd "$(dirname "$0")/.." >/dev/null && pwd)"
"$project_dir/scripts/test.sh"
"$project_dir/scripts/build.sh"
"$project_dir/scripts/sign.sh"

app="$project_dir/build/QuotaDock.app"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app/Contents/Info.plist")"
arch="$(uname -m)"
mkdir -p "$project_dir/dist"
archive="$project_dir/dist/QuotaDock-$version-$build-$arch.zip"
ditto -c -k --sequesterRsrc --keepParent "$app" "$archive"
openssl dgst -sha256 "$archive" > "$archive.sha256"
{
    printf 'product=QuotaDock\nversion=%s\nbuild=%s\narchitecture=%s\n' "$version" "$build" "$arch"
    printf 'signing_identity=%s\n' "${SIGNING_IDENTITY:--}"
    printf 'git_revision=%s\n' "$(git -C "$project_dir" rev-parse --verify HEAD 2>/dev/null || echo unborn)"
    printf '\nGit status (empty means clean):\n'
    git -C "$project_dir" status --short
    printf '\nToolchain:\n'
    xcrun swift --version
    xcrun --show-sdk-path
    sw_vers
} > "$archive.build-info.txt"
printf 'Packaged: %s\n' "$archive"
