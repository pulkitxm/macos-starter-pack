#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

SIGNING_DIR="$PWD/.signing"
LOCAL_KEYCHAIN="$SIGNING_DIR/signing.keychain-db"
LOCAL_P12="$SIGNING_DIR/identity.p12"
LOCAL_PASSWORD="$SIGNING_DIR/password"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/signing.sh <command>

  status         show the identity builds will sign with, and what releases will do
  create [NAME]  make a self-signed code signing identity for this project
  import FILE    use an existing .p12 (Developer ID, Apple Development, or your own)
  secrets        upload the project identity and notary key to GitHub Actions secrets
  reset          delete the project identity and its keychain

  resolve        print "identity|keychain|kind" for build scripts
  ci-import      import MACOS_CERT_P12 into a temporary keychain on a CI runner

Builds sign with SIGN_IDENTITY (and SIGN_KEYCHAIN) when set, else the first
Developer ID Application identity, else Apple Development, else the project
identity in .signing/, else ad-hoc. See docs/signing.md.
USAGE
  exit 1
}

app_name() {
  /usr/libexec/PlistBuddy -c 'Print :CFBundleName' Resources/Info.plist
}

kind_of() {
  case "$1" in
    -) echo ad-hoc ;;
    "Developer ID Application"*) echo developer-id ;;
    "Apple Development"* | "Apple Distribution"* | "Mac Developer"*) echo apple-development ;;
    *) echo self-signed ;;
  esac
}

label_of() {
  local identity="$1" keychain="${2:-}" label
  if [ "$identity" = - ]; then echo -; return; fi
  if [ -n "$keychain" ]; then
    label="$(security find-identity -p codesigning "$keychain" 2>/dev/null \
      | awk -F'"' -v id="$identity" 'index($0, id) { print $2; exit }')"
  else
    label="$(security find-identity -p codesigning 2>/dev/null \
      | awk -F'"' -v id="$identity" 'index($0, id) { print $2; exit }')"
  fi
  echo "${label:-$identity}"
}

first_valid_identity() {
  security find-identity -v -p codesigning 2>/dev/null \
    | awk -F'"' -v prefix="$1" 'index($2, prefix) == 1 { print $2; exit }'
}

keychain_identity() {
  security find-identity -p codesigning "$1" 2>/dev/null \
    | awk '$2 ~ /^[0-9A-F]{40}$/ { print $2; exit }'
}

resolve() {
  local identity keychain="" prefix
  if [ -n "${SIGN_IDENTITY:-}" ]; then
    identity="$SIGN_IDENTITY"
    keychain="${SIGN_KEYCHAIN:-}"
  else
    identity=""
    for prefix in "Developer ID Application" "Apple Development"; do
      identity="$(first_valid_identity "$prefix")"
      [ -z "$identity" ] || break
    done
    if [ -z "$identity" ] && [ -f "$LOCAL_KEYCHAIN" ]; then
      security unlock-keychain -p "$(cat "$LOCAL_PASSWORD")" "$LOCAL_KEYCHAIN"
      identity="$(keychain_identity "$LOCAL_KEYCHAIN")"
      keychain="$LOCAL_KEYCHAIN"
    fi
    if [ -z "$identity" ]; then
      identity=-
      keychain=""
    fi
  fi
  printf '%s|%s|%s\n' "$identity" "$keychain" "$(kind_of "$(label_of "$identity" "$keychain")")"
}

import_p12() {
  local p12="$1" password="$2" keychain="$3"
  security create-keychain -p "$password" "$keychain"
  security set-keychain-settings "$keychain"
  security unlock-keychain -p "$password" "$keychain"
  security import "$p12" -k "$keychain" -P "$password" -T /usr/bin/codesign >/dev/null
  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$password" "$keychain" >/dev/null
  [ -n "$(keychain_identity "$keychain")" ] \
    || { echo "$p12 holds no code signing identity" >&2; exit 1; }
}

require_no_local_identity() {
  if [ -e "$SIGNING_DIR" ]; then
    echo "a project identity already exists in .signing/; run scripts/signing.sh reset first" >&2
    exit 1
  fi
  mkdir -p "$SIGNING_DIR"
  chmod 700 "$SIGNING_DIR"
}

create() {
  local name="${1:-$(app_name) Self-Signed}" password work
  require_no_local_identity
  trap 'reset >/dev/null' EXIT
  password="$(/usr/bin/openssl rand -hex 24)"
  work="$(mktemp -d)"
  /usr/bin/openssl req -x509 -newkey rsa:3072 -nodes -days 3650 -subj "/CN=$name" \
    -addext "basicConstraints=critical,CA:false" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" \
    -keyout "$work/key.pem" -out "$work/cert.pem" 2>/dev/null
  /usr/bin/openssl pkcs12 -export -inkey "$work/key.pem" -in "$work/cert.pem" -name "$name" \
    -passout "pass:$password" -out "$LOCAL_P12"
  rm -rf "$work"
  printf '%s' "$password" >"$LOCAL_PASSWORD"
  chmod 600 "$LOCAL_P12" "$LOCAL_PASSWORD"
  import_p12 "$LOCAL_P12" "$password" "$LOCAL_KEYCHAIN"
  trap - EXIT
  echo "created \"$name\" in .signing/ (valid for ten years)"
  echo "local builds now sign with it; run scripts/signing.sh secrets to sign releases with it too"
}

import_file() {
  local file="${1:?import needs the path to a .p12 file}" password
  [ -f "$file" ] || { echo "$file does not exist" >&2; exit 1; }
  password="${P12_PASSWORD:-}"
  if [ -z "$password" ]; then
    read -r -s -p "Password for $(basename "$file"): " password
    echo
  fi
  require_no_local_identity
  trap 'reset >/dev/null' EXIT
  cp "$file" "$LOCAL_P12"
  printf '%s' "$password" >"$LOCAL_PASSWORD"
  chmod 600 "$LOCAL_P12" "$LOCAL_PASSWORD"
  import_p12 "$LOCAL_P12" "$password" "$LOCAL_KEYCHAIN"
  trap - EXIT
  echo "imported \"$(label_of "$(keychain_identity "$LOCAL_KEYCHAIN")" "$LOCAL_KEYCHAIN")\" into .signing/"
}

secrets() {
  command -v gh >/dev/null || { echo "secrets needs the GitHub CLI (gh)" >&2; exit 1; }
  [ -f "$LOCAL_P12" ] \
    || { echo "no project identity yet: run scripts/signing.sh create or import first" >&2; exit 1; }
  base64 <"$LOCAL_P12" | tr -d '\n' | gh secret set MACOS_CERT_P12
  gh secret set MACOS_CERT_PASSWORD <"$LOCAL_PASSWORD"
  echo "uploaded MACOS_CERT_P12 and MACOS_CERT_PASSWORD"
  if [ -n "${NOTARY_KEY_PATH:-}" ]; then
    : "${NOTARY_KEY_ID:?set NOTARY_KEY_ID with NOTARY_KEY_PATH}"
    : "${NOTARY_ISSUER_ID:?set NOTARY_ISSUER_ID with NOTARY_KEY_PATH}"
    gh secret set NOTARY_KEY <"$NOTARY_KEY_PATH"
    printf '%s' "$NOTARY_KEY_ID" | gh secret set NOTARY_KEY_ID
    printf '%s' "$NOTARY_ISSUER_ID" | gh secret set NOTARY_ISSUER_ID
    echo "uploaded NOTARY_KEY, NOTARY_KEY_ID and NOTARY_ISSUER_ID"
  fi
}

reset() {
  if [ -f "$LOCAL_KEYCHAIN" ]; then
    security delete-keychain "$LOCAL_KEYCHAIN" 2>/dev/null || true
  fi
  rm -rf "$SIGNING_DIR"
  echo "removed the project identity"
}

ci_import() {
  if [ -z "${MACOS_CERT_P12:-}" ]; then
    echo "MACOS_CERT_P12 is not set: this release will be signed ad-hoc"
    return
  fi
  : "${MACOS_CERT_PASSWORD:?MACOS_CERT_PASSWORD must accompany MACOS_CERT_P12}"
  : "${RUNNER_TEMP:?ci-import runs on a CI runner}"
  local keychain="$RUNNER_TEMP/signing.keychain-db" p12="$RUNNER_TEMP/signing.p12" identity
  local keychains=()
  printf '%s' "$MACOS_CERT_P12" | base64 --decode >"$p12"
  import_p12 "$p12" "$MACOS_CERT_PASSWORD" "$keychain"
  rm -f "$p12"
  while IFS= read -r line; do
    line="${line//\"/}"
    keychains+=("${line#"${line%%[![:space:]]*}"}")
  done < <(security list-keychains -d user)
  security list-keychains -d user -s "$keychain" "${keychains[@]}"
  identity="$(keychain_identity "$keychain")"
  echo "SIGN_IDENTITY=$identity" >>"${GITHUB_ENV:-/dev/null}"
  echo "SIGN_KEYCHAIN=$keychain" >>"${GITHUB_ENV:-/dev/null}"
  echo "imported \"$(label_of "$identity" "$keychain")\" for signing"
}

status() {
  local identity keychain kind
  IFS='|' read -r identity keychain kind < <(resolve)
  echo "builds sign with: $(label_of "$identity" "$keychain") ($kind)"
  case "$kind" in
    ad-hoc) echo "  runs on this Mac; other Macs need right click > Open the first time" ;;
    self-signed) echo "  stable signature, so macOS keeps permissions across rebuilds; Gatekeeper still warns elsewhere" ;;
    apple-development) echo "  stable Apple signature for your own devices; Gatekeeper still warns elsewhere" ;;
    developer-id) echo "  ready for notarization and distribution" ;;
  esac
  if [ -n "${NOTARY_PROFILE:-}" ] || [ -n "${NOTARY_KEY_ID:-}" ]; then
    echo "notarization: configured locally"
  else
    echo "notarization: not configured locally (NOTARY_PROFILE or NOTARY_KEY_ID)"
  fi
  if command -v gh >/dev/null && gh secret list >/dev/null 2>&1; then
    local configured
    configured="$(gh secret list --json name --jq '.[].name' | tr '\n' ' ')"
    case " $configured " in
      *" MACOS_CERT_P12 "*) echo "GitHub releases: signed with the MACOS_CERT_P12 secret" ;;
      *) echo "GitHub releases: signed ad-hoc (no MACOS_CERT_P12 secret)" ;;
    esac
    case " $configured " in
      *" NOTARY_KEY "*) echo "GitHub releases: notarized when signed with Developer ID" ;;
      *) echo "GitHub releases: not notarized (no NOTARY_KEY secret)" ;;
    esac
  fi
}

case "${1:-}" in
  status) status ;;
  create) create "${2:-}" ;;
  import) import_file "${2:-}" ;;
  secrets) secrets ;;
  reset) reset ;;
  resolve) resolve ;;
  ci-import) ci_import ;;
  *) usage ;;
esac
