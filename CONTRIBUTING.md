# Contributing

Thanks for helping out. This guide covers setup, the checks every change must pass, and how pull
requests are reviewed.

## Setup

1. Install Xcode 16 or later. The Makefile uses `/Applications/Xcode*.app` when `xcode-select`
   points at the Command Line Tools.
2. Install the hygiene and security tools with Homebrew:

   ```sh
   make tools
   ```

   `make ci-hygiene` also runs `markdownlint-cli2` through `npx`, so Node.js is needed for it.
3. Build and launch the app:

   ```sh
   make run
   ```

## Checks

Run the same checks CI runs before you open a pull request:

| Command | What it runs |
| --- | --- |
| `make ci` | `swift format` lint, the no-comments check, the tests, a release build, bundle verification and the DMG |
| `make ci-hygiene` | yamllint, markdownlint, actionlint, zizmor and lychee |
| `make ci-security` | gitleaks, semgrep and trivy |
| `make ci-all` | All of the above |

Run `make format` to apply `swift format` before committing.

## Code style

- No comments in code. Names and structure carry the meaning. `make comments` fails on any
  comment in Swift, shell, Python, YAML, TOML or the Makefile. Only functional directives such as
  `// swift-tools-version` and shebangs are allowed.
- Keep the app dependency-free and small. `make verify` fails when the release binary grows past
  its size budget.
- Add or update tests in `Tests/AppCoreTests` for every behavior change.

## Pull requests

- Keep each pull request focused on one change.
- Titles follow [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`,
  `docs:`, `ci:`, `chore:` and so on, starting lowercase and ending without a full stop. The
  `pr.yml` workflow checks this.
- Describe what changed and why in one line.
- Screenshots in pull requests must use sample data only.

## Releases

Maintainers cut releases with the Release workflow (`make release BUMP=patch`). See
[docs/signing.md](docs/signing.md) for how releases are signed and notarized.
