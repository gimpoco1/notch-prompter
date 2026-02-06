# Notch Prompter (Swift)

This project is now a **Swift** macOS app. It runs as:
- a **control window** (SwiftUI)
- a **notch overlay panel** (NSPanel at status-bar level)

## Run

```bash
./native/run.sh
```

This builds a native binary and launches it.

## Share app (local distribution)

Build a shareable `.app` and zip it:

```bash
./native/package.sh
```

Send `dist/NotchPrompter.zip` :
1. Unzip it.
2. Move `Notch Prompter.app` to `/Applications` (optional).
3. First run: right-click the app and choose **Open** (Gatekeeper prompt).

If macOS blocks it, run:
```bash
xattr -dr com.apple.quarantine "/Applications/Notch Prompter.app"
```

## Default Settings

Edit `native/config.json` to change the default values (notch size, overlay size, speed, etc.).

Example:
```json
{
  "width": 520,
  "height": 72,
  "notchWidth": 220,
  "notchHeight": 28,
  "speed": 28,
  "fontSize": 22
}
```

If you break the JSON, the app will fall back to built-in defaults.

## Files

- `native/NotchPrompter.swift` — full app (overlay + control UI)
- `native/run.sh` — build & run script
- `native/config.json` — defaults
