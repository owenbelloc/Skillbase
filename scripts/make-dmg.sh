#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP="$ROOT/dist/Skillbase.app"
if [[ ! -d "$APP" ]]; then
  echo "Missing $APP — run scripts/package-app.sh first." >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Info.plist")"
VOL="Skillbase"
STAGE="$ROOT/dist/dmg-stage"
RW="$ROOT/dist/.Skillbase-rw.dmg"
DMG="$ROOT/dist/Skillbase-${VERSION}.dmg"

rm -rf "$STAGE"
rm -f "$RW" "$DMG"
mkdir -p "$STAGE"
ditto "$APP" "$STAGE/Skillbase.app"
ln -s /Applications "$STAGE/Applications"

if [[ -n "${CI:-}" ]]; then
  hdiutil create \
    -volname "$VOL" \
    -srcfolder "$STAGE" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG"
  rm -rf "$STAGE"
  echo "→ DMG $DMG"
  exit 0
fi

hdiutil create -volname "$VOL" -srcfolder "$STAGE" -ov -fs HFS+ -format UDRW "$RW" >/dev/null

if [[ -d "/Volumes/$VOL" ]]; then
  hdiutil detach "/Volumes/$VOL" -quiet || true
  sleep 1
fi

ATTACH_OUT="$(hdiutil attach -readwrite -noverify -noautoopen "$RW")"
DEVICE="$(echo "$ATTACH_OUT" | awk '/Apple_HFS|GUID_partition_scheme/ {dev=$1} END {print dev}')"
MOUNT="/Volumes/$VOL"

for _ in {1..25}; do
  [[ -d "$MOUNT/Skillbase.app" ]] && break
  sleep 0.2
done

osascript <<EOF
tell application "Finder"
  tell disk "$VOL"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {280, 140, 920, 520}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 112
    delay 0.6
    set position of item "Skillbase.app" of container window to {160, 170}
    set position of item "Applications" of container window to {480, 170}
    update without registering applications
    delay 1
    close
  end tell
end tell
EOF

sync
hdiutil detach "$DEVICE" -quiet
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null
rm -f "$RW"
rm -rf "$STAGE"

echo "→ DMG $DMG"
