# QuotaDock

[中文](README.md) | **English**

A macOS liquid gauge for your remaining Codex quota. It sits above your avatar, follows the main window, and lets mouse clicks pass through.

![QuotaDock in six simulated quota states](https://raw.githubusercontent.com/wind8ai/quota-dock/main/docs/images/quota-dock-en.gif?v=5479cd90a0a4)

Current version: **3.1.0 / build 23**. Cyan means at least 50% remains, amber means 20% to below 50%, and red means below 20%. `0` leaves a thin red line; `--` means no reading or cached value is available. The preview uses simulated values and a schematic native ring.

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

Every 30 seconds, query account limits through the local Codex CLI's official app-server protocol. Prefer the five-hour window, otherwise weekly. Use only the codex bucket, not Spark, credits or reserve.

Remaining quota is `100 - usedPercent`, rounded for display. New server values may increase or decrease. Failure, a reading older than one minute, or a reset shows `--`. No session-log scanning or persistent quota fallback. Each query has a timeout and cleans up its child process.

Runtime requires a Codex CLI signed in with ChatGPT. Locate it through PATH, common installation paths, or the installed Codex/ChatGPT app. No direct token reading, model task or desktop app modification. The desktop-selected account may differ from the CLI account; compare the same identity and period.

The liquid has two surface waves and rising bubbles. Level changes take about 0.6 seconds. Animation pauses when the target window is hidden and stays still when macOS Reduce Motion is enabled.

## Development

```sh
./scripts/test.sh                     # 25 core/offline protocol regression cases
bash scripts/test-app.sh              # Native panel lifecycle: 20 replacements preserve quota and animation
build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose  # Read-only window diagnostics
build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose-quota  # Live account quota (requires login and network)
./scripts/preview-animation.sh        # Synthetic readings; close the window to quit
./scripts/render-states.sh --english --animate  # English preview; requires FFmpeg
./scripts/package.sh                  # Test, build, sign, ZIP, and checksum
```

Build output, archives, caches, and runtime data are excluded from Git. Signing defaults to ad-hoc; no Apple-notarized binary is currently published.

- [Window placement, quota rules, and limitations](docs/behavior.en.md)
- [Build, signing, and distribution](docs/releasing.en.md)
- [Changelog](CHANGELOG.en.md)
- [A prompt to recreate QuotaDock with Codex](docs/recreate-prompt.en.md)
