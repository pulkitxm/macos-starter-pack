#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

usage() {
  cat >&2 <<'USAGE'
usage: ./build.sh [--release] [--no-open]

  --release   optimized, stripped build for distribution
  --no-open   build only, do not launch

Writes dist/<App>.app, named after CFBundleName in Resources/Info.plist.
APP_VERSION and APP_BUILD stamp the bundle version without touching the source.
The signing identity comes from scripts/signing.sh; see docs/signing.md.
USAGE
  exit 1
}

RELEASE=0
OPEN=1
while [ $# -gt 0 ]; do
  case "$1" in
    --release) RELEASE=1 ;;
    --no-open) OPEN=0 ;;
    *) usage ;;
  esac
  shift
done

resolve_developer_dir() {
  local candidate
  candidate="${DEVELOPER_DIR:-$(xcode-select -p 2>/dev/null)}"
  if [ -x "$candidate/usr/bin/xcodebuild" ]; then echo "$candidate"; return; fi
  for candidate in /Applications/Xcode*.app/Contents/Developer; do
    if [ -x "$candidate/usr/bin/xcodebuild" ]; then echo "$candidate"; return; fi
  done
  xcode-select -p
}
DEVELOPER_DIR="$(resolve_developer_dir)"
export DEVELOPER_DIR

PLIST=Resources/Info.plist
APP_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleName' "$PLIST")"
EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$PLIST")"

if [ "$RELEASE" = 1 ]; then
  CONFIG=release
  swift build -c release --product "$EXECUTABLE" -Xswiftc -Osize
else
  CONFIG=debug
  swift build -c debug --product "$EXECUTABLE"
fi
BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"

APP="dist/$APP_NAME.app"
rm -rf dist
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/$EXECUTABLE" "$APP/Contents/MacOS/$EXECUTABLE"
cp "$PLIST" "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

if [ -n "${APP_VERSION:-}" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" "$APP/Contents/Info.plist"
fi
if [ -n "${APP_BUILD:-}" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $APP_BUILD" "$APP/Contents/Info.plist"
fi

if [ "$RELEASE" = 1 ]; then
  strip -rSTx "$APP/Contents/MacOS/$EXECUTABLE"
fi

IFS='|' read -r IDENTITY KEYCHAIN KIND < <(scripts/signing.sh resolve)
SIGN_ARGS=(--force --sign "$IDENTITY" --options runtime)
if [ -n "$KEYCHAIN" ]; then SIGN_ARGS+=(--keychain "$KEYCHAIN"); fi
if [ "$KIND" = developer-id ]; then SIGN_ARGS+=(--timestamp); fi
codesign "${SIGN_ARGS[@]}" "$APP"
echo "built $APP ($CONFIG, signed $KIND)"

if [ "$OPEN" = 1 ]; then
  pkill -f "$PWD/$APP/Contents/MacOS/" 2>/dev/null || true
  open "$APP"
fi
