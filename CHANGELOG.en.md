# Changelog

[中文](CHANGELOG.md) | **English**

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
