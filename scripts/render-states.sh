#!/bin/bash
set -euo pipefail
export LC_ALL=C LANG=C
project_dir="$(cd "$(dirname "$0")/.." >/dev/null && pwd)"
asset_name="quota-dock"
language_arg=--chinese
animate=false
cache_arg=""
credit_arg=""
for option in "$@"; do
    case "$option" in
        --english) asset_name="quota-dock-en"; language_arg=--english ;;
        --animate) animate=true ;;
        --cached) cache_arg=--cached ;;
        --credit-warning) credit_arg=--credit-warning ;;
        *) echo "Usage: $0 [--english] [--animate] [--cached] [--credit-warning]" >&2; exit 1 ;;
    esac
done
if [ -n "$cache_arg" ]; then asset_name="${asset_name}-cached"; fi
if [ -n "$credit_arg" ]; then asset_name="${asset_name}-credit-warning"; fi
mkdir -p "$project_dir/.build" "$project_dir/docs/images"
preview_dir="$(mktemp -d "$project_dir/.build/preview.XXXXXX")"
trap 'rm -rf "$preview_dir"' EXIT
# Compile the production view directly without application timers or quota reads.
cp "$project_dir/scripts/state-preview.swift" "$preview_dir/main.swift"
xcrun swiftc -target "$(uname -m)-apple-macosx11.0" \
    "$project_dir/Sources/QuotaCore/BadgeLayout.swift" \
    "$project_dir/Sources/QuotaCore/QuotaMeterAnimation.swift" \
    "$project_dir/Sources/QuotaCore/QuotaDisplayValue.swift" \
    "$project_dir/Sources/QuotaDock/QuotaMeterView.swift" "$preview_dir/main.swift" \
    -o "$preview_dir/render-states"
"$preview_dir/render-states" "$project_dir/docs/images/$asset_name-states.png" \
    "$project_dir/docs/images/sidebar-reference.png" "$language_arg" "$cache_arg" "$credit_arg"
if $animate; then
    command -v ffmpeg >/dev/null || { echo 'Animated export requires ffmpeg.' >&2; exit 1; }
    mkdir -p "$preview_dir/frames"
    "$preview_dir/render-states" "$preview_dir/frames" \
        "$project_dir/docs/images/sidebar-reference.png" --frames "$language_arg" "$cache_arg" "$credit_arg"
    ffmpeg -hide_banner -loglevel error -y -framerate 20 \
        -i "$preview_dir/frames/frame-%03d.png" \
        -filter_complex '[0:v]split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=sierra2_4a' \
        -loop 0 "$project_dir/docs/images/$asset_name.gif"
    printf '%s\n' "$project_dir/docs/images/$asset_name.gif"
fi
