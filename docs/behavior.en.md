# Window placement and quota rules

[中文](behavior.md) | **English**

## Window placement

The gauge is 36 × 104 pt. Its center is 26 pt from the target window's left edge, and its bottom is 70 pt above the avatar. Panel offsets are 8 pt from the left and 107 pt from the bottom: 18 pt higher than 3.0.8, leaving roughly 20 pt of visual separation from the native usage ring in the current layout. Numbers use a white monospaced heavy font with a diffuse black shadow (4 pt blur radius) up to 15 pt directly over the liquid without a background plate; longer values shrink to fit. Cyan means at least 50%, amber means 20% to below 50%, red means below 20%, and unavailable readings use a neutral gray outline.

The target must be an on-screen normal-level window owned by `ChatGPT` or `Codex`, at least 800 pt wide and 600 pt tall. Floating mini/pet windows are excluded. The gauge hides when no main window is found. These offsets match the current account-bar layout; future layout changes may require an update to `Sources/QuotaCore/BadgeLayout.swift`.

Initial discovery prefers the largest eligible window, then retains that window identity across foreground and Space changes. The gauge hides while the target is offscreen and rediscovers after it closes. Initial selection remains a geometry heuristic and cannot identify every special dialog.

While the main window is visible, actual panel visibility is checked once per second. The first two failed checks reorder the panel; the third closes it and creates a new native panel while retaining the meter view, quota and animation. Recovery pauses for ten seconds after recreation. Healthy visibility or a hidden target resets the failure count. Healthy panels are not repeatedly reordered, and hidden targets never trigger recovery.

Run `build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose` for read-only diagnostics. Exit codes: 0 means the panel is at the expected position of the largest visible candidate; 1 means missing or misplaced; 2 means no visible main window (possibly another Space); 3 means the query failed. It launches no second gauge and prints no titles, chats or account data. With multiple main windows, the largest candidate may differ from the tracked window; compare the reported window IDs.

Earlier live checks covered a main window owned by ChatGPT, including visibility while mini is enabled. On 2026-10-20 the user confirmed fullscreen switching and file-picker behavior in 3.0.8. Regression tests cover a file picker preceding a larger main window. Multiple displays, display hot-plugging and extended sleep/wake behavior still lack comprehensive manual acceptance.

## Source and freshness

Version 3.1.2 restores local log reading and removes the CLI subprocess and JSON-RPC quota path. Read `~/.codex/sessions`, or sessions under CODEX_HOME when set. Do not change proxy settings, login state or the Codex app.

Inspect the 12 most recently modified JSONL files, reading up to the final 2 MB of each. Accept only event_msg / token_count records with limit_id=codex, supporting payload.rate_limits and payload.info.rate_limits. Select window_minutes=300, otherwise 10080. Do not assume primary means weekly or include Spark.

Select the newest ISO 8601 observation timestamp, with or without fractional seconds. Never use file modification time as observation time. Skip truncated or incomplete JSON lines. If the newest record has expired, do not resurrect an older reset window.

Remaining quota is 100 - used_percent, preserving fractions and rounding for display. Allow corrected values to rise. After 15 minutes, retain the number, show a small clock and pause the bubbles. Do not retain a reading past resets_at or infer a refill to 100%. Show unknown when no reading exists for the current period.

Read at a minimum interval of 5 seconds while visible and 30 seconds while hidden. Check scheduling every second; reads never overlap. Missing local data no longer triggers network-style backoff. Wake clears the old display and reads again.

Persist the last receipt in app preferences, scoped by session directory, and restore it after restart. Older records cannot overwrite newer ones; a failed read does not erase an in-period cache. Preserve the original observation timestamp. Reject expired or invalid values and never import quota-history-v2. Diagnostics read the cache without changing it.

## Diagnostics

```sh
build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose-quota
```

Exit 0 reports local-session-log, period, last quota, observation time and age, with recent-local-observation or cached-local-observation status. Exit 1 means no usable reading in the current period. No conversation text, filenames, email or tokens are printed.

## Limitations

Logs update only when Codex writes quota receipts. Idle sessions, usage on other devices or missing receipts can differ from the native live ring. The clock marks a reading older than 15 minutes, not a current server value.

Logs from different accounts can coexist, so the current desktop account cannot be reliably identified. Searching only 12 file tails can miss other receipts. Directory-scoped caching does not identify accounts that share one directory.

Account queries can run without a chat task. A new probe succeeded, but that does not establish that the intermittent CLI failures are fixed. The user chose to keep CLI-free mode, so this release does not query the server automatically. Existing window-placement, multi-display and sleep/wake acceptance limits remain unchanged.
