#!/bin/bash

[[ -n "$1" ]] || { echo "Usage: $0 <app_bundle_path>"; exit 1; }
[[ -d "$1" ]] || { echo "App bundle not found: $1"; exit 1; }

APP_BUNDLE_PATH=$1

APP_NAME="Cumulus"
VOLUME_NAME="$APP_NAME"
VOLUME_PATH="/Volumes/$VOLUME_NAME"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DMG_DIR="$SCRIPT_DIR/dmg"
TMP_DIR="/tmp/$APP_NAME"

# Create the DMG output directory if needed
[ -d "$DMG_DIR" ] || mkdir "$DMG_DIR"

TIMESTAMP="$(date +%s)"
TEMP_DMG_NAME="$APP_NAME-$TIMESTAMP-temp.dmg"
TEMP_DMG_PATH="$DMG_DIR/$TEMP_DMG_NAME"
FINAL_DMG_NAME="$APP_NAME-$TIMESTAMP.dmg"
FINAL_DMG_PATH="$DMG_DIR/$FINAL_DMG_NAME"

# Eject any $APP_NAME volumes that may already be mounted
if [ -d "$VOLUME_PATH" ]; then
    echo "Ejecting $VOLUME_PATH"
    echo '
       tell application "Finder"
         tell disk "'$VOLUME_NAME'"
            eject
            delay 5
         end tell
       end tell
    ' | osascript
fi

mkdir "$TMP_DIR"
hdiutil create -srcfolder "$TMP_DIR" -volname "$VOLUME_NAME" -fs HFS+ \
      -fsargs "-c c=64,a=16,e=16" -format UDRW -size 100m "$TEMP_DMG_PATH"
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG_PATH" | \
        egrep '^/dev/' | sed 1q | awk '{print $1}')
sleep 5
cp -r "$APP_BUNDLE_PATH" "$VOLUME_PATH"
ln -s "/Applications" "$VOLUME_PATH/Applications"
rm -r "$TMP_DIR"

echo '
   tell application "Finder"
     tell disk "'$VOLUME_NAME'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {150, 150, 650, 240}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set position of item "'$APP_NAME'.app" to {150, 100}
           set position of item "Applications" to {350, 100}
           set icon size of theViewOptions to 128
           update without registering applications
           delay 5
           eject
     end tell
   end tell
' | osascript

chmod -Rf go-w "$VOLUME_PATH"
sync
sync
hdiutil detach "$DEVICE"
hdiutil convert "$TEMP_DMG_PATH" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG_PATH"
rm -f "$TEMP_DMG_PATH"

open "$DMG_DIR"