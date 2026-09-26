# Signing and releases

Every build is signed, and every release works, whether or not you have an Apple Developer
account. You pick how far to go: ad-hoc out of the box, a stable identity of your own, or a
Developer ID that Apple notarizes.

## How a build picks its identity

`build.sh` and `scripts/package.sh` ask `scripts/signing.sh resolve` which identity to use. The
first match wins:

| Order | Identity | Where it comes from |
| --- | --- | --- |
| 1 | `SIGN_IDENTITY`, with `SIGN_KEYCHAIN` when set | The environment. `SIGN_IDENTITY=-` forces ad-hoc. Releases set these from the `MACOS_CERT_P12` secret. |
| 2 | The first valid `Developer ID Application` identity | Your keychains, for example installed by Xcode |
| 3 | The first valid `Apple Development` identity | Your keychains |
| 4 | The project identity | `.signing/`, made by `make signing-create` or `make signing-import` |
| 5 | Ad-hoc | Nothing else was found |

The app is always signed with the hardened runtime. A Developer ID signature also gets a secure
timestamp, and the DMG is signed with the same identity whenever it is not ad-hoc.

## What each option means

| Identity | On your Mac | On other Macs |
| --- | --- | --- |
| Ad-hoc | Runs. The signature changes every build, so macOS forgets permissions you granted. | Gatekeeper blocks the first launch; see [Opening a build that is not notarized](#opening-a-build-that-is-not-notarized). |
| Self-signed project identity | Runs, and the signature stays stable, so permissions survive rebuilds. | Same as ad-hoc: Gatekeeper warns on the first launch. |
| Apple Development | Stable Apple signature for your own devices. | Gatekeeper warns on the first launch. |
| Developer ID Application | Stable signature. | With notarization, opens with no warning. |

Check what your setup will do at any time:

```sh
make signing
```

It prints the identity builds sign with and, when the GitHub CLI can see the repository, whether
releases will be signed and notarized.

## Local commands

| Command | What it does |
| --- | --- |
| `make signing` | Show the identity builds sign with and what releases will do |
| `make signing-create NAME="My App Signing"` | Create a self-signed code signing identity in `.signing/`, valid for ten years. Without `NAME` it is called `<App> Self-Signed`. |
| `make signing-import P12=~/Downloads/cert.p12` | Use an existing `.p12` as the project identity. It asks for the password, or reads `P12_PASSWORD`. |
| `make signing-secrets` | Upload the project identity, and optionally a notary key, to the repository's GitHub Actions secrets |
| `make signing-reset` | Delete the project identity and its keychain |

`.signing/` holds `identity.p12`, its password and a dedicated keychain. It is git-ignored and is
never added to your login keychain search list; builds pass it to `codesign` directly.

## Signing releases

The Release workflow reads these repository secrets. All of them are optional: with none set, the
release is signed ad-hoc and published as usual.

| Secret | Value |
| --- | --- |
| `MACOS_CERT_P12` | The signing certificate and private key as a `.p12`, base64 encoded |
| `MACOS_CERT_PASSWORD` | The `.p12` password |
| `NOTARY_KEY` | The contents of an App Store Connect API key (`AuthKey_XXXXXXXXXX.p8`) |
| `NOTARY_KEY_ID` | That key's ID |
| `NOTARY_ISSUER_ID` | The issuer ID shown above the keys list in App Store Connect |

Any certificate works for `MACOS_CERT_P12`: Developer ID, Apple Development, or the self-signed
project identity. Notarization only runs when the certificate is a Developer ID Application
certificate and all three notary secrets are set.

The quickest way to set them is from your machine with the GitHub CLI signed in:

```sh
make signing-create
make signing-secrets
```

or, with a certificate you already have:

```sh
make signing-import P12=~/Downloads/DeveloperID.p12
make signing-secrets
```

`make signing-secrets` uploads whatever identity is in `.signing/`, so import a certificate first
if you want releases signed with it.

### Exporting a Developer ID certificate

1. Create a **Developer ID Application** certificate in your Apple Developer account, or in Xcode
   under Settings, Accounts, Manage Certificates.
2. Open Keychain Access, select **login**, then **My Certificates**.
3. Find `Developer ID Application: Your Name (TEAMID)`, expand it to check the private key is
   there, right-click the certificate and choose **Export**.
4. Save it as a `.p12` with a password, then run
   `make signing-import P12=path/to/cert.p12` and `make signing-secrets`.

### Notarization with an App Store Connect API key

1. In [App Store Connect](https://appstoreconnect.apple.com/access/integrations/api), open Users
   and Access, Integrations, App Store Connect API, and create a team key with the **Developer**
   role.
2. Download the `.p8` file (it can be downloaded only once) and note the key ID and the issuer ID.
3. Upload the key together with the certificate:

   ```sh
   NOTARY_KEY_PATH=~/Downloads/AuthKey_ABC123DEFG.p8 \
   NOTARY_KEY_ID=ABC123DEFG \
   NOTARY_ISSUER_ID=00000000-0000-0000-0000-000000000000 \
   make signing-secrets
   ```

The Release workflow then submits the DMG with `xcrun notarytool`, staples the ticket, and checks
it with `spctl`.

### Notarizing locally

`make dmg` notarizes too when the build is signed with a Developer ID and credentials are set.
Store them once in your keychain:

```sh
xcrun notarytool store-credentials starter-notary \
  --key ~/Downloads/AuthKey_ABC123DEFG.p8 --key-id ABC123DEFG --issuer 00000000-0000-0000-0000-000000000000
NOTARY_PROFILE=starter-notary make dmg
```

`NOTARY_KEY_ID`, `NOTARY_ISSUER_ID` and `NOTARY_KEY_PATH` (or `NOTARY_KEY` with the key contents)
work instead of a profile.

## Opening a build that is not notarized

macOS blocks the first launch of a downloaded app that Apple has not notarized. Any of these opens
it:

- Right-click the app in Finder, choose **Open**, then confirm.
- Try to open it once, then go to System Settings, Privacy and Security, and click **Open Anyway**.
- Remove the quarantine flag in Terminal:

  ```sh
  xattr -dr com.apple.quarantine /Applications/Starter.app
  ```

## How CI proves it

Every CI run builds the DMG ad-hoc and uploads it as an artifact. It then creates a throwaway
self-signed identity, imports it with `scripts/signing.sh ci-import` exactly as the Release
workflow imports `MACOS_CERT_P12`, builds and packages again, and checks that both the app and the
DMG carry that signature. A change that breaks release signing fails the pull request, without
any real certificate in the repository.
