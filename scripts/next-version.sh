#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

BUMP="${1:-patch}"
LATEST="$(git tag --list 'v*' --sort=-version:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1 || true)"
IFS=. read -r MAJOR MINOR PATCH <<<"${LATEST#v}"
MAJOR="${MAJOR:-0}"
MINOR="${MINOR:-0}"
PATCH="${PATCH:-0}"

case "$BUMP" in
  patch) PATCH=$((PATCH + 1)) ;;
  minor) MINOR=$((MINOR + 1)) PATCH=0 ;;
  major) MAJOR=$((MAJOR + 1)) MINOR=0 PATCH=0 ;;
  *) echo "usage: scripts/next-version.sh [patch|minor|major]" >&2; exit 1 ;;
esac

VERSION="$MAJOR.$MINOR.$PATCH"
if git rev-parse -q --verify "refs/tags/v$VERSION" >/dev/null; then
  echo "v$VERSION already exists" >&2
  exit 1
fi

echo "tag=v$VERSION"
echo "version=$VERSION"
echo "build=$(git rev-list --count HEAD)"
