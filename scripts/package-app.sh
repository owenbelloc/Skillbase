#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "→ Building Skillbase"
swift build -c release --product Skillbase

BIN="$(swift build -c release --show-bin-path)/Skillbase"
APP="$ROOT/dist/Skillbase.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Skillbase"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

if command -v sips >/dev/null && [[ -f "$ROOT/Resources/AppIcon.png" ]]; then
  mkdir -p "$ROOT/.iconset"
  for size in 16 32 128 256 512; do
    sips -z $size $size "$ROOT/Resources/AppIcon.png" --out "$ROOT/.iconset/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z $double $double "$ROOT/Resources/AppIcon.png" --out "$ROOT/.iconset/icon_${size}x${size}@2x.png" >/dev/null
  done
  iconutil -c icns "$ROOT/.iconset" -o "$APP/Contents/Resources/AppIcon.icns"
  rm -rf "$ROOT/.iconset"
fi

ZIP="$ROOT/dist/Skillbase-macOS.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "→ Packed $APP"
echo "→ Archive $ZIP"
echo "  open \"$APP\""
