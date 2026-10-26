# QuotaDock

[中文](README.md) | **English**

Show remaining Codex quota above your avatar on macOS. The liquid shows the remaining share, the number shows the percentage, and the gauge follows the window without blocking clicks.

Current version: 3.1.1 / build 24.

![QuotaDock in six quota states](https://raw.githubusercontent.com/wind8ai/quota-dock/main/docs/images/quota-dock-en.gif?v=bc6f422990d3)

Quota values are simulated. [View the static image](docs/images/quota-dock-en-states.png).

Cyan means at least 50% remains, amber means 20% to below 50%, and red means below 20%. `0` means exhausted; `--` means no valid reading is available.

## Build and run

Requires macOS 11+, Swift 5.3+, and a Codex CLI signed in with ChatGPT. Tested on Apple Silicon. If you need developer tools, run `xcode-select --install` first.

```sh
git clone https://github.com/wind8ai/quota-dock.git
cd quota-dock
./scripts/build.sh
./scripts/sign.sh
open build/QuotaDock.app
```

Signing defaults to ad-hoc; the app is not Apple-notarized. It has no Dock icon and adds no login item. Quit it through Activity Monitor or run `pkill -x QuotaDock`.

## How quota is calculated

The local Codex CLI queries the server through `account/rateLimits/read`. The gauge shows the five-hour allowance when available, otherwise weekly. It excludes Spark, credits and reserve.

Queries run about every 5–6 seconds while the main window is visible, or every 30 seconds while hidden. API response time adds to that delay, so this does not match native push timing. Failed queries back off up to 60 seconds. Requests never overlap.

Remaining quota is `100 - usedPercent`, rounded for display. A failed read, a reading older than one minute, or a reset changes the display to `--`. The app does not use old session logs or a persistent quota cache.

The CLI and desktop app may use different accounts. Compare the same account and period when checking the native ring. QuotaDock does not read tokens directly or start model tasks.

## Troubleshooting

Check window placement:

```sh
build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose
```

Check account quota with a working login and network connection:

```sh
build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose-quota
```

## Development

Run the core and native panel tests:

```sh
./scripts/test.sh
bash scripts/test-app.sh
```

Generate both preview languages with FFmpeg installed:

```sh
./scripts/render-states.sh --animate
./scripts/render-states.sh --english --animate
```

`./scripts/preview-animation.sh` opens an interactive preview. `./scripts/package.sh` tests, builds, signs and packages the app. Build output and runtime data stay out of Git.

## Further reading

- [Window placement, quota source and limitations](docs/behavior.en.md)
- [Native usage-ring implementation notes, in Chinese](docs/native-usage-reference.md)
- [Signing and distribution](docs/releasing.en.md)
- [Changelog](CHANGELOG.en.md)
- [Recreation prompt](docs/recreate-prompt.en.md)
