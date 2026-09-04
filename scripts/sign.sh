#!/bin/bash
set -euo pipefail
export LC_ALL=C LANG=C
project_dir="$(cd "$(dirname "$0")/.." >/dev/null && pwd)"
app="$project_dir/build/QuotaDock.app"
identity="${SIGNING_IDENTITY:--}"
test -x "$app/Contents/MacOS/QuotaDock" || { echo 'Run scripts/build.sh first.' >&2; exit 1; }

if [[ "$identity" == '-' ]]; then
    codesign --force --sign - --timestamp=none "$app"
else
    codesign --force --sign "$identity" --timestamp --options runtime "$app"
fi
codesign --verify --strict --verbose=2 "$app"
codesign --display --verbose=2 "$app"
