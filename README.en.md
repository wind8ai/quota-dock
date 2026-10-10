# QuotaDock

[中文](README.md) | **English**

A macOS liquid gauge for your remaining Codex quota. It sits above your avatar, follows the main window, and lets mouse clicks pass through.

![QuotaDock in six simulated quota states](https://raw.githubusercontent.com/wind8ai/quota-dock/main/docs/images/quota-dock-en.gif?v=5bbcde937f56)

Current version: **3.0.5 / build 18**. Green means at least 50% remains, amber means 20% to below 50%, and red means below 20%. `0` leaves a thin red line; `--` means no reading or cached value is available. The preview uses simulated values.

## Build and run

Requires macOS 11 or later and Apple Command Line Tools or Xcode with Swift 5.3 or later. The app has no third-party dependencies and has been built and tested on Apple Silicon.

```sh
xcode-select --install  # Skip if developer tools are already installed

git clone https://github.com/wind8ai/quota-dock.git
cd quota-dock
./scripts/build.sh
./scripts/sign.sh
open build/QuotaDock.app
```

The app does not appear in the Dock or register a login item. To quit, end `QuotaDock` in Activity Monitor or run:

```sh
pkill -x QuotaDock
```

## How it works

Every 30 seconds, QuotaDock reads the primary `limit_id=codex` quota from local `token_count` events in `~/.codex/sessions`. It excludes the separate Spark quota, makes no quota-service requests, and does not modify the ChatGPT/Codex app bundle.

Remaining quota is `100 - used_percent`, rounded to a whole number for display. The cache survives restarts and supplies the last value when no fresh reading is available. Readings can lag actual usage, and the cache is not separated by account.

The liquid has two surface waves and rising bubbles. Level changes take about 0.6 seconds. Animation pauses when the target window is hidden and stays still when macOS Reduce Motion is enabled.

## Development

```sh
./scripts/test.sh                     # 33 regression cases
./scripts/preview-animation.sh        # Synthetic readings; close the window to quit
./scripts/render-states.sh --english --animate  # English preview; requires FFmpeg
./scripts/package.sh                  # Test, build, sign, ZIP, and checksum
```

Build output, archives, caches, and runtime data are excluded from Git. Signing defaults to ad-hoc; no Apple-notarized binary is currently published.

- [Window placement, quota rules, and limitations](docs/behavior.en.md)
- [Build, signing, and distribution](docs/releasing.en.md)
- [Changelog](CHANGELOG.en.md)
- [A prompt to recreate QuotaDock with Codex](docs/recreate-prompt.en.md)
