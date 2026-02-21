# camera_script_editor

Post-production pipeline for the Color Palette Maker demo video.

## Overview

This folder contains two tools:

1. **Teleprompter** — a React/Vite app (`src/App.jsx`) for scripting and directing the screen recording beat by beat
2. **camera_apply.py** — a Python script that applies zoom, pan, easing, and subtitles to a full-resolution recording using a camera script JSON

## Requirements

### Node (Teleprompter app)
- Node.js 18+

### Python (Post-processing)
Python 3.8+ is required. FFmpeg is also required (for audio muxing and merge). Create a virtual environment and install dependencies:

```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install opencv-python numpy
```

Verify the install:
```bash
python3 -c "import cv2, numpy; print('cv2', cv2.__version__, '/ numpy', numpy.__version__)"
```

## Setup

### Teleprompter app
```bash
npm install
npm run dev
```
Opens at http://localhost:5173

### Post-processing
Create and activate the virtual environment as described in Requirements above. The venv is activated automatically by `doit.sh`.

## Workflow

1. **Direct** — run the teleprompter app, review each beat's zoom/focus/transition settings
2. **Export** — save the script as `camera-script.json` in the project root (or use the shorts in `shorts/`)
3. **Record** — use QuickTime to capture the palette-maker app at full resolution (static, no zoom)
4. **Process** — run `doit.sh` to apply the camera script and generate the final video:

```bash
./doit.sh
```

This will:
- Timestamp and archive the camera script used
- Apply zoom, pan, easing, and burned-in subtitles to the recording
- Write `output-*.mp4` and `output-*.srt` to the `archive/` folder
- Open the result in QuickTime for review

## Files

| File | Description |
|------|-------------|
| `camera_apply.py` | Post-processing script |
| `camera-script.json` | Full camera script (edit between runs) |
| `shorts/` | Per-short scripts (short-01-intro.json, etc.) |
| `shorts-manifest.json` | Start + duration for each short (chain without overlap) |
| `render-shorts.sh` | Render all shorts; use --merge to concatenate |
| `doit.sh` | One-command render + archive + review (full script) |
| `recording.mov` | Full-resolution QuickTime capture |
| `index.html` | Teleprompter entry point |
| `venv/` | Python virtual environment (not committed to git) |
| `src/App.jsx` | Teleprompter React app |
| `archive/` | Timestamped outputs from each render run |

## Multiple shorts (start + duration)

To create multiple shorts from the same recording, use `--start` and `--duration`:

```bash
python3 camera_apply.py recording.mov shorts/short-01-intro.json shorts/short-01-intro.mp4 --start 0 --duration 12
python3 camera_apply.py recording.mov shorts/short-02-create.json shorts/short-02-create.mp4 --start 12 --duration 18
# ... each short's start = previous start + previous duration
```

Use `render-shorts.sh` to process all shorts from `shorts-manifest.json`:

```bash
./render-shorts.sh recording.mov           # Renders shorts/short-01-intro.mp4, short-02-create.mp4, ...
./render-shorts.sh recording.mov --merge   # Renders all shorts, then merges to shorts/merged-*.mp4
```

`shorts-manifest.json` defines non-overlapping segments (script, start, duration). Adjust start/duration to match your recording.

## camera_apply.py options

```
python3 camera_apply.py input.mov script.json output.mp4 [options]

--start 0           Start time in seconds within input (default: 0; requires --duration when > 0)
--duration 30       Output duration in seconds (required with --start; else uses full input length)
--fps 30            Output frame rate (default: match input)
--no-subs           Skip burned-in subtitles
--srt               Also write .srt subtitle file
--sub-size 36       Subtitle font size (default: 36)
--sub-opacity 0.75  Subtitle bar opacity 0-1 (default: 0.75)
```
