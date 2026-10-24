#!/bin/bash
# Capture README screenshots from the current build without touching real notes.
# The app runs in snapshot mode against a throwaway data folder and asks this
# script to grab the two glass panels straight from the screen, because
# behind-window vibrancy does not survive an in-process view snapshot.
set -euo pipefail
cd "$(dirname "$0")/.."

output=${1:-"$PWD/.build/snapshots"}
app='dist/Kodmoz Writer.app'
rm -rf "$output"
mkdir -p "$output"

bash build-app.sh >/dev/null

handled=0
"$app/Contents/MacOS/FocusWriter" --snapshot "$output" >/dev/null 2>&1 &
pid=$!
while kill -0 "$pid" 2>/dev/null; do
    if [[ -f "$output/capture.request" ]]; then
        IFS= read -r rect < "$output/capture.request"
        target=$(sed -n '2p' "$output/capture.request")
        if [[ -n "$rect" && -n "$target" ]]; then
            screencapture -x -R"$rect" "$target" || true
            handled=$((handled + 1))
        fi
        rm -f "$output/capture.request"
        : > "$output/capture.done"
    fi
    sleep 0.1
done
wait "$pid" || true

for name in writing sidebar settings link; do
    [[ -s "$output/$name.png" ]] || { echo "Missing $name.png" >&2; exit 1; }
done
echo "Captured $handled panels plus writing/sidebar in $output"
