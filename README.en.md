# QuotaDock

[中文](README.md) | **English**

Show remaining Codex quota above your avatar on macOS. The liquid shows the remaining share, the number shows the percentage, and the gauge follows the window without blocking clicks.

Current version: 3.1.6 / build 29.

![QuotaDock in six quota states](https://raw.githubusercontent.com/wind8ai/quota-dock/main/docs/images/quota-dock-en.gif?v=bc6f422990d3)

Quota values are simulated. [View the static image](docs/images/quota-dock-en-states.png).

Cyan means at least 50% remains, amber means 20% to below 50%, and red means below 20%. `≤1` means local usage has reached its last percentage point without an explicit plan-limit signal. Extra credits may already be in use; it does not promise more included usage. `0` means a receipt explicitly reports the plan limit; `--` means no valid reading is available.

When receipts show a credit-balance decrease within the same quota period, the tube turns red, cracks across the middle and shows “已扣费” (billed). The warning survives restarts and clears on a new period. It follows recorded charges, cannot predict them and does not stop usage. [View the warning](docs/images/quota-dock-credit-warning-states.png).

## Build and run

Requires macOS 11+, Swift 5.3+, and session logs written by Codex on this Mac. Tested on Apple Silicon. If you need developer tools, run `xcode-select --install` first.

```sh
git clone https://github.com/wind8ai/quota-dock.git
cd quota-dock
./scripts/build.sh
./scripts/sign.sh
open build/QuotaDock.app
```

Signing defaults to ad-hoc; the app is not Apple-notarized. It has no Dock icon and adds no login item. Quit it through Activity Monitor or run `pkill -x QuotaDock`.

## How quota is calculated

Read Codex session logs under `CODEX_HOME/sessions`, defaulting to `~/.codex/sessions`. QuotaDock does not launch the CLI, query quota services or read login tokens.

Read about every 5 seconds while the main window is visible, otherwise every 30 seconds. Use codex quota receipts only, preferring five-hour limits and otherwise weekly. Select by observation time and allow both increases and decreases.

This is the last recorded reading, not a live server query. Keep it while idle and across restarts. After 15 minutes without an update, show a small clock and pause the bubbles. Show `--` only without a reading or after the quota period resets. [View the cached state](docs/images/quota-dock-en-cached-states.png). Logs from multiple accounts may coexist, so they cannot reliably identify the account currently selected in the desktop app.

## Troubleshooting

Check window placement:

```sh
build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose
```

Check the local quota receipt and its age:

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
./scripts/render-states.sh --credit-warning
```

`./scripts/preview-animation.sh` opens an interactive preview. `./scripts/package.sh` tests, builds, signs and packages the app. Build output and runtime data stay out of Git.

## Further reading

- [Window placement, quota source and limitations](docs/behavior.en.md)
- [Native usage-ring implementation notes, in Chinese](docs/native-usage-reference.md)
- [Signing and distribution](docs/releasing.en.md)
- [Changelog](CHANGELOG.en.md)
- [Recreation prompt](docs/recreate-prompt.en.md)
