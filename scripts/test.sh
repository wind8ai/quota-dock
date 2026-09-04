#!/bin/bash
set -euo pipefail
export LC_ALL=C LANG=C
project_dir="$(cd "$(dirname "$0")/.." >/dev/null && pwd)"
mkdir -p "$project_dir/.build"
test_dir="$(mktemp -d "$project_dir/.build/tests.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -Onone -target "$(uname -m)-apple-macosx11.0" \
    "$project_dir"/Sources/QuotaCore/*.swift \
    "$project_dir"/Tests/QuotaCoreTests/*.swift \
    -o "$test_dir/QuotaCoreTests"
"$test_dir/QuotaCoreTests"
