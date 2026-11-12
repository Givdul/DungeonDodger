#!/usr/bin/env bash
# Build the Web export and assemble the phone demo served at
# https://apps.givdul.com/dd.
#
#   tools/build_web_demo.sh ../zones-web/public/dd
#
# A fresh checkout needs `godot --headless --path . --import` first.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT:-godot}"

if [[ $# -ne 1 ]]; then
	echo "usage: $0 <destination folder>" >&2
	exit 64
fi

mkdir -p "$1"
dest="$(cd "$1" && pwd)"
if [[ "$dest" == "/" || "$dest" == "$repo_root" ]]; then
	echo "refusing to write the demo into $dest" >&2
	exit 64
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
out="$work/web"
mkdir -p "$out"

"$godot_bin" --headless --path "$repo_root" --export-release Web "$out/index.html"

# index.wasm is 39,514,754 bytes (37.7 MiB), over Cloudflare's 25 MiB per-file
# limit. Ship it gzipped (9.6 MiB); the page's loader unpacks it into a wasm
# response.
gzip -9 -n -c "$out/index.wasm" > "$out/index.wasm.gz"
rm "$out/index.wasm"

cp "$repo_root/web/icon-192.png" "$out/icon-192.png"
cp "$repo_root/web/icon-512.png" "$out/icon-512.png"
cp "$repo_root/web/qr.svg" "$out/qr.svg"
cp "$repo_root/web/manifest.webmanifest" "$out/manifest.webmanifest"
cp "$repo_root/assets/fonts/PixelOperator8-Bold.ttf" "$out/pixel-operator-8-bold.ttf"

too_big="$(find "$out" -type f -size +26214400c -print -quit)"
if [[ -n "$too_big" ]]; then
	echo "error: $too_big is over Cloudflare's 25 MiB per-file limit" >&2
	exit 1
fi

find "$dest" -mindepth 1 -delete
cp -R "$out/." "$dest/"

echo "Web demo written to $dest"
du -h "$dest"/* | sort -k2
