SELECTED_DEV_DIR := $(shell xcode-select -p 2>/dev/null)
ifneq ($(wildcard $(SELECTED_DEV_DIR)/usr/bin/xcodebuild),)
  DEVELOPER_DIR := $(SELECTED_DEV_DIR)
else
  DEVELOPER_DIR := $(firstword $(wildcard /Applications/Xcode*.app/Contents/Developer) $(SELECTED_DEV_DIR))
endif
export DEVELOPER_DIR

SWIFT_SOURCES := Package.swift Sources Tests
CHROME ?= /Applications/Google Chrome.app/Contents/MacOS/Google Chrome
BUMP ?= patch

.PHONY: run build build-release test lint format comments verify dmg ci ci-hygiene ci-security \
	ci-all tools release icon rename signing signing-create signing-import signing-secrets \
	signing-reset clean

run:
	./build.sh

build:
	./build.sh --no-open

build-release:
	./build.sh --release --no-open

test:
	swift test

lint:
	swift format lint --strict --parallel --recursive $(SWIFT_SOURCES)

format:
	swift format --in-place --parallel --recursive $(SWIFT_SOURCES)

comments:
	python3 scripts/check-comments.py

verify:
	scripts/verify.sh

dmg: build-release verify
	scripts/package.sh

ci: lint comments test dmg

ci-hygiene:
	yamllint --strict .
	npx --yes markdownlint-cli2@0.23.3
	actionlint
	zizmor --persona=pedantic --min-severity=high --format=plain .github/workflows
	lychee --config lychee.toml './**/*.md'

ci-security:
	gitleaks git --no-banner --redact .
	semgrep scan --error --config p/swift --config p/secrets --config p/github-actions --config p/bash .
	trivy fs --scanners vuln,secret,misconfig --severity CRITICAL,HIGH --exit-code 1 --ignore-unfixed \
	  --skip-dirs .build --skip-dirs dist .

ci-all: ci ci-hygiene ci-security

tools:
	brew install yamllint actionlint zizmor lychee gitleaks semgrep trivy

release:
	gh workflow run release.yml --ref main -f bump=$(BUMP)

icon:
	@set -eu; \
	work="$$(mktemp -d)"; \
	"$(CHROME)" --headless --disable-gpu --hide-scrollbars --allow-file-access-from-files \
	  --force-color-profile=srgb --default-background-color=00000000 --window-size=1024,1024 \
	  --screenshot="$$work/icon.png" "file://$(CURDIR)/Resources/AppIcon.svg" >/dev/null 2>&1; \
	mkdir "$$work/AppIcon.iconset"; \
	for size in 16 32 128 256 512; do \
	  sips -z $$size $$size "$$work/icon.png" --out "$$work/AppIcon.iconset/icon_$${size}x$${size}.png" >/dev/null; \
	  sips -z $$((size * 2)) $$((size * 2)) "$$work/icon.png" \
	    --out "$$work/AppIcon.iconset/icon_$${size}x$${size}@2x.png" >/dev/null; \
	done; \
	iconutil -c icns "$$work/AppIcon.iconset" -o Resources/AppIcon.icns; \
	rm -rf "$$work"

rename:
	scripts/rename.sh "$(NAME)" "$(BUNDLE_ID)"

signing:
	scripts/signing.sh status

signing-create:
	scripts/signing.sh create "$(NAME)"

signing-import:
	scripts/signing.sh import "$(P12)"

signing-secrets:
	scripts/signing.sh secrets

signing-reset:
	scripts/signing.sh reset

clean:
	rm -rf .build dist
