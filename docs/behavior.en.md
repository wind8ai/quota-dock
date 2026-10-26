# Window placement and quota rules

[中文](behavior.md) | **English**

## Window placement

The gauge is 36 × 104 pt. Its center is 26 pt from the target window's left edge, and its bottom is 70 pt above the avatar. Panel offsets are 8 pt from the left and 107 pt from the bottom: 18 pt higher than 3.0.8, leaving roughly 20 pt of visual separation from the native usage ring in the current layout. Numbers use a white monospaced heavy font with a diffuse black shadow (4 pt blur radius) up to 15 pt directly over the liquid without a background plate; longer values shrink to fit. Cyan means at least 50%, amber means 20% to below 50%, red means below 20%, and unavailable readings use a neutral gray outline.

The target must be an on-screen normal-level window owned by `ChatGPT` or `Codex`, at least 800 pt wide and 600 pt tall. Floating mini/pet windows are excluded. The gauge hides when no main window is found. These offsets match the current account-bar layout; future layout changes may require an update to `Sources/QuotaCore/BadgeLayout.swift`.

Initial discovery prefers the largest eligible window, then retains that window identity across foreground and Space changes. The gauge hides while the target is offscreen and rediscovers after it closes. Initial selection remains a geometry heuristic and cannot identify every special dialog.

While the main window is visible, actual panel visibility is checked once per second. The first two failed checks reorder the panel; the third closes it and creates a new native panel while retaining the meter view, quota and animation. Recovery pauses for ten seconds after recreation. Healthy visibility or a hidden target resets the failure count. Healthy panels are not repeatedly reordered, and hidden targets never trigger recovery.

Run `build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose` for read-only diagnostics. Exit codes: 0 means the panel is at the expected position of the largest visible candidate; 1 means missing or misplaced; 2 means no visible main window (possibly another Space); 3 means the query failed. It launches no second gauge and prints no titles, chats or account data. With multiple main windows, the largest candidate may differ from the tracked window; compare the reported window IDs.

Earlier live checks covered a main window owned by ChatGPT, including visibility while mini is enabled. File pickers, multiple displays, and fullscreen transitions in 3.0.5 still require manual acceptance. Regression tests cover a file picker preceding a larger main window.

## Source and freshness

Use a local Codex CLI signed in with ChatGPT and the official stdio `account/rateLimits/read` method. Read at launch and every 30 seconds. Each read uses a short-lived child with a 15-second communication timeout; close stdin first and terminate only that child if necessary. No HTTP listener or model task is started.

Prefer `rateLimitsByLimitId.codex`. Only when that map is absent, accept a legacy result explicitly identified as codex. Select 300 minutes (five hours) by duration, otherwise 10080 minutes (weekly). Do not infer a period from the primary slot or use Spark, credits or reserve. Other window lengths currently produce unknown.

Remaining quota is `100 - usedPercent`, preserving source fractions and displaying rounded integers. New server values may increase or decrease. Failure shows `--`; an in-memory reading expires after 60 seconds or at resetsAt, whichever comes first. Never infer a refill to 100%. Wake clears the old display and refreshes.

Version 3.1.0 removes the JSONL reader, QuotaStabilizer and persistent quota cache. Any old `quota-history-v2` preference is ignored, not used as fallback.

## Authentication and diagnostics

Look for codex on PATH and common CLI installation paths, then inside the installed Codex/ChatGPT app. Missing CLI, absent ChatGPT login, API-key-only auth, incompatible protocol or unsupported quota windows produce unknown. The tool never logs in, switches accounts or reads token files itself.

Before and after the quota read, compare the email and plan type returned by account/read. Keep these only in memory, never in diagnostics or cache. This API does not expose the full desktop-selected account/workspace identity, so the comparison cannot prove that desktop and CLI accounts match.

```sh
build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose-quota
```

Exit 0 reports source, period, remaining quota, observation time and reset time. Exit 1 reports a bounded error category, without email, tokens or credit balances.

## Limitations

A service snapshot is more direct than session logs but still polled about every 30 seconds, not equivalent to native push freshness. Compare the same account and period at similar observation times. The single gauge does not display both windows, credits or reserve. Positioning remains fixed account-bar geometry rather than avatar pixel detection; existing multi-display and long-running acceptance limits remain.
