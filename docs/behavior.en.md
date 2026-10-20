# Window placement and quota rules

[中文](behavior.md) | **English**

## Window placement

The gauge is 32 × 96 pt. Its center is 26 pt from the target window's left edge, and its bottom is 52 pt above the avatar, reserving 44 pt for the update/download button. The panel offsets are 10 pt from the left and 89 pt from the bottom. Numbers use a white monospaced heavy font up to 13 pt; longer values shrink to fit.

The target must be an on-screen normal-level window owned by `ChatGPT` or `Codex`, at least 800 pt wide and 600 pt tall. Floating mini/pet windows are excluded. The gauge hides when no main window is found. These offsets match the current account-bar layout; future layout changes may require an update to `Sources/QuotaCore/BadgeLayout.swift`.

Initial discovery prefers the largest eligible window, then retains that window identity across foreground and Space changes. The gauge hides while the target is offscreen and rediscovers after it closes. Initial selection remains a geometry heuristic and cannot identify every special dialog.

While the main window is visible, actual panel visibility is checked once per second. The first two failed checks reorder the panel; the third closes it and creates a new native panel while retaining the meter view, quota and animation. Recovery pauses for ten seconds after recreation. Healthy visibility or a hidden target resets the failure count. Healthy panels are not repeatedly reordered, and hidden targets never trigger recovery.

Run `build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose` for read-only diagnostics. Exit codes: 0 means the panel is at the expected position of the largest visible candidate; 1 means missing or misplaced; 2 means no visible main window (possibly another Space); 3 means the query failed. It launches no second gauge and prints no titles, chats or account data. With multiple main windows, the largest candidate may differ from the tracked window; compare the reported window IDs.

Earlier live checks covered a main window owned by ChatGPT, including visibility while mini is enabled. File pickers, multiple displays, and fullscreen transitions in 3.0.5 still require manual acceptance. Regression tests cover a file picker preceding a larger main window.

## Readings and cache

The reader checks the 12 most recently modified JSONL session files, reading at most the final 2 MB of each. It accepts `primary.used_percent` from `event_msg / token_count` records with `limit_id=codex`. Both `payload.rate_limits` and `payload.info.rate_limits` are supported.

Fractional values are retained internally and displayed as rounded whole numbers from 0 to 100, without a percent sign. Integer source readings do not gain invented precision. If a timestamp cannot be parsed, the file modification time is used.

Cycles are identified by `resets_at`, with a 120-second tolerance for jitter. Across files, the reader selects the newest cycle, then its latest observation. The cache only decreases within a cycle; a newer cycle may increase the value.

The cache stores up to five readings under `quota-history-v2` for bundle identifier `com.ben.codex-quota-badge`. When a precise reading first replaces a legacy integer cache, it may correct a rounding difference of less than 0.5 percentage points. Once the precision marker is written, the decrease-only rule resumes. Upgrades do not clear the cache.

## Limitations

Only existing local receipts are read. A 30-second refresh does not provide real-time server quota. The cache is not partitioned by account, and not every window layout is recognized. Positioning uses fixed account-bar geometry rather than avatar pixel detection. A file whose tail cannot be decoded as UTF-8 is skipped for that read.
