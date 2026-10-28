# Changelog

[中文](CHANGELOG.md) | **English**

## 3.1.6 · build 29

- Turn the tube red, draw a jagged fracture and show a billed label when receipts report a credit-balance decrease within the same quota period. Pause liquid animation while warning.
- Compare decimal balances. Initial, unchanged and increasing balances do not trigger. Reconstruct debit history in receipt order; retain the warning through idle time and restarts, and clear it on a new period.
- Add debit status and last known balance to diagnostics, regression tests for receipt order, period isolation, persistence and native rendering, plus a synthetic warning preview.

## 3.1.5 · build 28

- Show `≤1` when a local receipt reports 100% used without an explicit plan-limit signal, rather than claiming exhaustion or exactly 1% remaining. Extra credits may already be charged.
- Keep positive remainders at a minimum display of `1` instead of rounding values below 0.5% to `0`. Show zero only with `rate_limit_reached_type=rate_limit_reached`.
- Persist exhaustion evidence while supporting older caches. Add display text and confirmation status to diagnostics, with endpoint, cache and native redraw regression tests.

## 3.1.4 · build 27

- Move the gauge up another 32 pt to clear the update button and its tooltip above the avatar, keeping the remaining-quota number visible.
- Keep the 36 × 104 pt size and horizontal position. Update layout regression tests and positioning documentation in both languages.

## 3.1.3 · build 26

- Keep the last quota after 15 idle minutes, mark it with a small clock and pause bubbles instead of clearing it.
- Persist receipts per log directory across restarts. Accept newer increases or decreases; failed reads retain an in-period cache.
- Stop showing old values at reset without guessing a refill to 100%. Keep CLI-free mode.
- Add cache, directory isolation, reset and read-only diagnostic tests, plus cached-state previews.

## 3.1.2 · build 25

- Restore local JSONL receipts after persistent CLI routing and request failures, as requested. No CLI launch or quota API call.
- Select the latest codex observation by timestamp; support fractional timestamps, nested fields and truncated tails without decrease-only filtering.
- Show unknown after 15 minutes or at reset. Do not use a persistent quota cache.
- Retain visible 5-second and hidden 30-second reads; remove network backoff and report local source and receipt age in diagnostics.

## 3.1.1 · build 24

- Reduce quota polling from 30 to 5 seconds while the main window is visible; retain 30 seconds while hidden.
- Recheck immediately on reveal and use common RunLoop modes for the timer.
- Back off failures up to 60 seconds and reset on success. Requests remain exclusive; server quota calculations are unchanged.

## 3.1.0 · build 23

- Read account limits through the official Codex app-server `account/rateLimits/read` every 30 seconds instead of scanning JSONL files.
- Prefer the codex bucket and select the five-hour window by duration, otherwise the weekly window. Exclude Spark.
- Accept authoritative increases and decreases; remove the old decrease-only cache and log reader.
- Show `--` on failure, after one minute, or at reset. Refresh after wake.
- Check account identity before and after reads; bound process lifetime and add account-redacted `--diagnose-quota` output.
- Requires a local Codex CLI signed in with ChatGPT. No token reading or private native HTTP/push calls. Desktop-selected and CLI accounts may differ.

## 3.0.9 · build 22

- Raise the gauge another 18 pt to separate it from the native usage ring; resize to 36 × 104 pt.
- Use cyan for healthy quota, a stronger outline and monospaced heavy numbers up to 15 pt with a stronger diffuse black shadow, without an outline or background plate.
- Refresh bilingual six-state previews with a schematic native ring.
- Preserve quota reading, caching, window anchoring and panel recovery behavior.

## 3.0.8 · build 21

- Recreate the native panel after three failed visibility checks instead of indefinitely reordering the same invisible window; apply a ten-second cooldown.
- Preserve the meter view, quota and animation while closing the old panel. Skip recovery when the main window is hidden.
- Replace the short Space-transition retry window with the continuous recovery policy.
- Add recovery sequence tests, a 20-replacement native lifecycle test and read-only `--diagnose` output.

## 3.0.7 · build 20

- Check actual panel visibility once per second while the main window is visible, restoring panels lost after fullscreen or Space transitions despite AppKit reporting visibility.
- Correct the window-ID lookup API usage to preserve the tracked main window instead of receiving empty descriptions.

## 3.0.6 · build 19

- Move the gauge up by 44 pt to reserve space for the update/download button above the avatar.

## 3.0.5 · build 18

- Retain the selected main window across foreground and Space changes instead of adopting a file picker.
- Hide while the tracked window is temporarily offscreen; rediscover after it closes, preferring the largest eligible window on discovery.
- Add a regression case with a file picker in front of its main window.

## 3.0.4 · build 17

- Briefly restore panel ordering after Space/display changes and update positioning in common RunLoop modes.

## 3.0.3 · build 16

- Show whole numbers without decimals or a percent sign, using a heavy font up to 13 pt.
- Move the gauge up by 2 pt, leaving an 8 pt gap above the avatar.

## 3.0.2 · build 15

- Preserve fractional source values in the reader and cache, with legacy integer-cache compatibility.
- Display one decimal place. Version 3.0.3 switches back to whole numbers following source-data checks and visual feedback.

## 3.0.1 · build 14

- Fix the gauge disappearing when mini/pet mode creates a large transparent floating window that was mistaken for the main window.
- Restrict main-window selection to the normal window level.

## 3.0 · build 13

- Replace the horizontal account-bar badge with a vertical liquid gauge above the avatar.
- Add surface waves, rising bubbles, a 0.6-second level transition, and Reduce Motion support.

## 2.1 · build 12

- Show a horizontal whole-number badge beside the account name, refreshing local Codex quota every 30 seconds.
- Keep the cache across restarts, exclude Spark, and tolerate 120 seconds of reset-time jitter.
