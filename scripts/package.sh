#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleName' Resources/Info.plist)"
APP="dist/$APP_NAME.app"
DMG="dist/$APP_NAME.dmg"
[ -d "$APP" ] || { echo "$APP is missing; run make build-release first" >&2; exit 1; }

IFS='|' read -r IDENTITY KEYCHAIN KIND < <(scripts/signing.sh resolve)

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
ditto "$APP" "$STAGING/$APP_NAME.app"
ln -s /Applications "$STAGING/Applications"
rm -f "$DMG" "$DMG.sha256"
hdiutil create -quiet -volname "$APP_NAME" -srcfolder "$STAGING" -format ULMO "$DMG"

if [ "$IDENTITY" != - ]; then
  SIGN_ARGS=(--force --sign "$IDENTITY")
  if [ -n "$KEYCHAIN" ]; then SIGN_ARGS+=(--keychain "$KEYCHAIN"); fi
  if [ "$KIND" = developer-id ]; then SIGN_ARGS+=(--timestamp); fi
  codesign "${SIGN_ARGS[@]}" "$DMG"
fi

NOTARY=none
if [ "$KIND" = developer-id ]; then
  if [ -n "${NOTARY_PROFILE:-}" ]; then
    NOTARY=profile
  elif [ -n "${NOTARY_KEY_ID:-}" ] && [ -n "${NOTARY_ISSUER_ID:-}" ] \
    && [ -n "${NOTARY_KEY:-}${NOTARY_KEY_PATH:-}" ]; then
    NOTARY=key
    NOTARY_KEY_FILE="${NOTARY_KEY_PATH:-$STAGING/notary-key.p8}"
    [ -n "${NOTARY_KEY_PATH:-}" ] || printf '%s' "$NOTARY_KEY" >"$NOTARY_KEY_FILE"
  else
    echo "notarization skipped: set NOTARY_PROFILE, or NOTARY_KEY_ID, NOTARY_ISSUER_ID and NOTARY_KEY"
  fi
fi

case "$NOTARY" in
  profile)
    xcrun notarytool submit "$DMG" --wait --keychain-profile "$NOTARY_PROFILE"
    ;;
  key)
    xcrun notarytool submit "$DMG" --wait \
      --key "$NOTARY_KEY_FILE" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER_ID"
    ;;
esac
if [ "$NOTARY" != none ]; then
  xcrun stapler staple "$DMG"
  spctl --assess --type open --context context:primary-signature --verbose "$DMG"
fi

verified=0
for attempt in 1 2 3 4 5; do
  if hdiutil verify -quiet "$DMG"; then verified=1; break; fi
  [ "$attempt" -eq 5 ] || sleep 2
done
[ "$verified" = 1 ] || { echo "$DMG failed verification" >&2; exit 1; }

(cd dist && shasum -a 256 "$APP_NAME.dmg" >"$APP_NAME.dmg.sha256")
echo "packaged $DMG ($(du -h "$DMG" | cut -f1 | tr -d ' '), signed $KIND, notarized: $([ "$NOTARY" = none ] && echo no || echo yes))"
