#!/bin/zsh
#
# Render shorts from the same input .mov using shorts-manifest.json.
# Each short uses --start and --duration so they chain without overlap.
#
# Usage:
#   ./render-shorts.sh [input.mov]     # Default: recording.mov
#   ./render-shorts.sh recording.mov
#
# Outputs: shorts/short-01-intro.mp4, shorts/short-02-create.mp4, ...
# Optionally merge: ./render-shorts.sh --merge  # creates shorts/merged.mp4

INPUT="${1:-recording.mov}"
MERGE=0
[[ "$1" == "--merge" ]] && { MERGE=1; INPUT="recording.mov"; }
[[ "$2" == "--merge" ]] && MERGE=1

if [ ! -d "venv" ]; then
    echo "Creating venv..."
    python3 -m venv venv
    source venv/bin/activate
    pip install opencv-python numpy
else
    source venv/bin/activate
fi

if [ ! -f "$INPUT" ]; then
    echo "Input not found: $INPUT"
    exit 1
fi

manifest="shorts-manifest.json"
if [ ! -f "$manifest" ]; then
    echo "Manifest not found: $manifest"
    exit 1
fi

dt=$(date +%Y-%m-%d_%H-%M-%S)
out_dir="shorts"
mkdir -p "$out_dir"

# Render each short
echo "Rendering shorts from $manifest..."
for entry in $(python3 -c "
import json
m = json.load(open('$manifest'))
for i, e in enumerate(m):
    print(f\"{i}:{e['script']}:{e['start']}:{e['duration']}\")
"); do
    IFS=':' read -r idx script_path start duration <<< "$entry"
    base=$(basename "$script_path" .json)
    out_mp4="$out_dir/${base}.mp4"
    out_srt="$out_dir/${base}.srt"
    echo "  $script_path -> $out_mp4 (start=$start, dur=$duration)"
    python3 camera_apply.py "$INPUT" "$script_path" "$out_mp4" \
        --start "$start" --duration "$duration" --srt
done

# Optionally merge
if [ "$MERGE" = 1 ]; then
    echo "Merging shorts..."
    concat_file="$out_dir/concat-${dt}.txt"
    > "$concat_file"
    for entry in $(python3 -c "
import json
m = json.load(open('$manifest'))
for e in m:
    base = 'shorts/' + e['script'].replace('shorts/', '').replace('.json', '')
    print(base + '.mp4')
"); do
        echo "file '$entry'" >> "$concat_file"
    done
    merged="$out_dir/merged-${dt}.mp4"
    ffmpeg -y -f concat -safe 0 -i "$concat_file" -c copy "$merged"
    rm "$concat_file"
    echo "Merged: $merged"
fi
