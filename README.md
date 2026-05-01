SpeedS@ver - Game Speed-runs as your Screensaver. 
---

TAS as your macOS screensaver.

This is a fork of [orta/SpeedS-ver](https://github.com/orta/SpeedS-ver) - the original by **Orta Therox** (2013), All the credit and the idea belong to him. This is a swift rewrite for modern macOS.

## What it does

Streams TAS speed-runs from [archive.org](https://archive.org/): ~4,400 runs across 62 systems.

## Install

Grab the latest `SpeedS.saver.zip` from [Releases](../../releases), unzip, double-click `SpeedS.saver`. macOS opens **System Settings → Screen Saver** with SpeedS@ver selected.

## Build from source

```sh
xcodebuild -project SpeedS.xcodeproj -scheme SpeedS -configuration Release build
open build/Release/
```

## Develop

Open `SpeedS.xcodeproj`, run the **Bootstrap** scheme. Shortcuts: `⌘,` for settings and `⌘N` to next video.

## Updating the metadata

`tools/regen_metadata.py` re-fetches the TASVideos publication list from their public API and rewrites `metadata.json`.

## Credits

Original screensaver, idea, and metadata: **[Orta Therox](https://github.com/orta)**, 2013.
Modernization: 2026. MIT licensed (see [LICENSE](./LICENSE)).
