#!/usr/bin/env bash
# Builds the Windows executable (build/windows/ReverendInsanity.exe) from Linux or macOS.
# Downloads Godot 4.5.1 and its export templates into tools/.godot-cache on first run.
# Usage: tools/build.sh            build the Windows exe
#        tools/build.sh test       also run the logic tests, UI smoke test and a scripted playthrough
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER="4.5.1"
CACHE="$ROOT/tools/.godot-cache"
URL="https://github.com/godotengine/godot/releases/download/${VER}-stable"
mkdir -p "$CACHE"

case "$(uname -s)" in
  Linux)  BIN_ZIP="Godot_v${VER}-stable_linux.x86_64.zip"; BIN="$CACHE/Godot_v${VER}-stable_linux.x86_64";
          TPL_DIR="$HOME/.local/share/godot/export_templates/${VER}.stable" ;;
  Darwin) BIN_ZIP="Godot_v${VER}-stable_macos.universal.zip"; BIN="$CACHE/Godot.app/Contents/MacOS/Godot";
          TPL_DIR="$HOME/Library/Application Support/Godot/export_templates/${VER}.stable" ;;
  *) echo "Use tools/build.ps1 on Windows"; exit 1 ;;
esac
GODOT="${GODOT:-$BIN}"

if [ ! -x "$GODOT" ]; then
  echo "Downloading Godot $VER..."
  curl -fsSL -o "$CACHE/$BIN_ZIP" "$URL/$BIN_ZIP"
  (cd "$CACHE" && unzip -oq "$BIN_ZIP")
  chmod +x "$GODOT" || true
fi
if [ ! -f "$TPL_DIR/windows_release_x86_64.exe" ]; then
  echo "Downloading export templates (about 1 GB, once)..."
  curl -fsSL -o "$CACHE/templates.tpz" "$URL/Godot_v${VER}-stable_export_templates.tpz"
  mkdir -p "$TPL_DIR"
  unzip -oq "$CACHE/templates.tpz" "templates/windows_release_x86_64.exe" "templates/windows_debug_x86_64.exe" "templates/version.txt" -d "$CACHE/tpl"
  cp "$CACHE/tpl/templates/"* "$TPL_DIR/"
  rm -rf "$CACHE/tpl" "$CACHE/templates.tpz"
fi

cd "$ROOT/game"
echo "Importing assets..."
timeout 600 "$GODOT" --headless --path . --import >/dev/null 2>&1 || true

if [ "${1:-}" = "test" ]; then
  echo "Running logic tests..."
  timeout 600 "$GODOT" --headless --path . --script res://tests/run_tests.gd
  echo "Running scripted playthroughs..."
  timeout 1200 "$GODOT" --headless --path . --script res://tests/playthrough.gd -- 3 1000
  echo "Running the UI smoke test..."
  timeout 600 "$GODOT" --headless --path . --script res://tests/ui_smoke.gd -- "" 20
fi

mkdir -p "$ROOT/build/windows"
echo "Exporting Windows build..."
timeout 900 "$GODOT" --headless --path . --export-release "Windows Desktop" "$ROOT/build/windows/ReverendInsanity.exe"
test -f "$ROOT/build/windows/ReverendInsanity.exe"
ls -lh "$ROOT/build/windows/"
echo "Done: build/windows/ReverendInsanity.exe"
