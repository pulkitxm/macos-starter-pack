#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

PLIST=Resources/Info.plist
MAX_BINARY_BYTES="${MAX_BINARY_BYTES:-500000}"

read_plist() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$2"
}

fail() {
  echo "verify: $*" >&2
  exit 1
}

APP_NAME="$(read_plist CFBundleName "$PLIST")"
EXECUTABLE="$(read_plist CFBundleExecutable "$PLIST")"
APP="dist/$APP_NAME.app"
BINARY="$APP/Contents/MacOS/$EXECUTABLE"
BUILT_PLIST="$APP/Contents/Info.plist"

[ -d "$APP" ] || fail "$APP is missing; run make build-release first"
[ -x "$BINARY" ] || fail "$BINARY is not executable"
file -b "$BINARY" | grep -q '^Mach-O 64-bit executable' || fail "$BINARY is not a Mach-O executable"
plutil -lint -s "$BUILT_PLIST" || fail "$BUILT_PLIST is malformed"
[ "$(read_plist CFBundleIdentifier "$BUILT_PLIST")" = "$(read_plist CFBundleIdentifier "$PLIST")" ] \
  || fail "the bundle identifier differs from $PLIST"
[ -f "$APP/Contents/Resources/AppIcon.icns" ] || fail "the app icon is missing"

VERSION="$(read_plist CFBundleShortVersionString "$BUILT_PLIST")"
BUILD="$(read_plist CFBundleVersion "$BUILT_PLIST")"
[ -z "${APP_VERSION:-}" ] || [ "$VERSION" = "$APP_VERSION" ] \
  || fail "built version $VERSION, expected $APP_VERSION"
[ -z "${APP_BUILD:-}" ] || [ "$BUILD" = "$APP_BUILD" ] \
  || fail "built build number $BUILD, expected $APP_BUILD"

codesign --verify --deep --strict "$APP" || fail "the code signature does not verify"

SIZE="$(stat -f %z "$BINARY")"
[ "$SIZE" -le "$MAX_BINARY_BYTES" ] \
  || fail "the binary is $SIZE bytes, over the $MAX_BINARY_BYTES byte budget"

AUTHORITY="$(codesign -dvv "$APP" 2>&1 | sed -n 's/^Authority=//p' | head -1)"
echo "verified $APP: version $VERSION ($BUILD), $SIZE byte binary, signed by ${AUTHORITY:-ad-hoc}"
