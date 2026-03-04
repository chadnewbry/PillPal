# PillPal — App Store Screenshots Guide

## Overview

This guide covers capturing raw screenshots for App Store marketing images. The `screenshots/koubou.yaml` config pairs each raw screenshot with a title, subtitle, and gradient background for final compositing.

## Required Screenshots

| # | Filename | What to Capture | Title | Subtitle |
|---|----------|----------------|-------|----------|
| 1 | `raw/01_today_view.png` | Today tab with 3-4 medications listed, mix of taken/pending | Your Daily Pills | See today's medications at a glance — never miss a dose |
| 2 | `raw/02_week_view.png` | Week tab showing full 7-day schedule with color-coded pills | Plan Your Week | A simple weekly overview of every medication |
| 3 | `raw/03_history.png` | History tab with adherence chart and recent log entries | Track Your Progress | See your adherence history and stay on track |
| 4 | `raw/04_settings.png` | Settings screen showing accessibility options (large text, VoiceOver) | Made For You | Large text, VoiceOver, and accessibility built in |

## How to Capture

1. **Open the Simulator** — Use iPhone 15 Pro (for 6.7" class screenshots).
2. **Set up sample data** — Add 3-4 medications with varied schedules so views look populated.
3. **Navigate to the screen** listed in the table above.
4. **Capture** — Press `⌘ + S` in the Simulator, or use:
   ```bash
   xcrun simctl io booted screenshot screenshots/raw/01_today_view.png
   ```
5. **Repeat** for each screen.

## Editing Titles & Subtitles

All marketing copy lives in `screenshots/koubou.yaml`. Edit the `title` and `subtitle` fields for any screen — no need to re-capture screenshots.

## Tips

- Use **Light Mode** for screenshots (cleaner on App Store).
- Hide the status bar clock or set it to **9:41** for a polished look.
- Ensure the simulator has **no notch artifacts** in the capture.
- Place raw PNGs in `screenshots/raw/` — Koubou reads from there.
