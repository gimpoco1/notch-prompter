
<img width="120" height="120" alt="Notch Prompter Logo" src="https://github.com/user-attachments/assets/e0139f23-623a-48cd-afcb-cafb93b4b8b6" />

# Notch Prompter

This project is now a **Swift** macOS app. It runs as:
- a **control window** (SwiftUI)
- a **notch overlay panel** (NSPanel at status-bar level)

## Run

```bash
./run.sh
```

This builds a native binary and launches it.

## Share app (local distribution)

Build a shareable `.app` and zip it:

```bash
./package.sh
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

Edit `config.json` to change the default values (notch size, overlay size, speed, etc.).

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

- `NotchPrompter.swift` — full app (overlay + control UI)
- `run.sh` — build & run script
- `config.json` — defaults
