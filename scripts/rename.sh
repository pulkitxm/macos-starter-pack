#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

NAME="${1:-}"
BUNDLE_ID="${2:-}"
PLIST=Resources/Info.plist

usage() {
  echo "usage: make rename NAME=MyApp BUNDLE_ID=com.example.myapp" >&2
  echo "$1" >&2
  exit 1
}

[[ "$NAME" =~ ^[A-Za-z][A-Za-z0-9]*$ ]] || usage "NAME must be letters and digits, starting with a letter"
[[ "$BUNDLE_ID" =~ ^[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z0-9-]+)+$ ]] \
  || usage "BUNDLE_ID must be reverse DNS, like com.example.myapp"

for key in CFBundleName CFBundleDisplayName CFBundleExecutable; do
  /usr/libexec/PlistBuddy -c "Set :$key $NAME" "$PLIST"
done
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$PLIST"

sed -i '' "s/^let appName = \".*\"$/let appName = \"$NAME\"/" Package.swift
grep -qx "let appName = \"$NAME\"" Package.swift || { echo "could not update Package.swift" >&2; exit 1; }

echo "renamed the app to $NAME ($BUNDLE_ID); run make run to see it"
