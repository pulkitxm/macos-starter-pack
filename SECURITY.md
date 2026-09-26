# Security Policy

## Supported Versions

Security fixes are applied to the latest published release and the `main` branch.

| Version | Supported |
| --- | --- |
| Latest release | Yes |
| `main` | Yes |
| Older releases | No |

## Reporting a Vulnerability

Do not open a public issue for a suspected vulnerability. Open the repository's **Security** tab
and choose **Report a vulnerability** to use GitHub's private vulnerability reporting, so the
report and follow-up remain confidential.

Include the affected version, macOS version, reproduction steps, expected and observed behavior,
potential impact, and any suggested mitigation. Remove credentials, signing certificates, private
keys and personal data from the report.

The maintainer aims to acknowledge a complete report within three business days and to share an
initial assessment within seven business days. Please allow time for a fix and coordinated
disclosure before publishing details.

## Scope

Reports are especially useful when they show a way to ship a release that was not built from the
repository, a leak of signing or notarization secrets from the workflows, or a signature or
checksum check that fails open.
