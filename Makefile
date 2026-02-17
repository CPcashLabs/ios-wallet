SHELL := /bin/bash

DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer
SWIFT_HOME ?= /tmp/swift-home
SWIFT_CACHE_HOME ?= /tmp/swift-cache
SWIFT_MODULE_CACHE ?= /tmp/swift-module-cache
CLANG_MODULE_CACHE ?= /tmp/clang-module-cache
IOS_DERIVED_DATA ?= /tmp/AppShelliOSDerived

SWIFT_ENV = DEVELOPER_DIR=$(DEVELOPER_DIR) \
	HOME=$(SWIFT_HOME) \
	XDG_CACHE_HOME=$(SWIFT_CACHE_HOME) \
	SWIFT_MODULECACHE_PATH=$(SWIFT_MODULE_CACHE) \
	CLANG_MODULE_CACHE_PATH=$(CLANG_MODULE_CACHE)

.PHONY: help swift-build swift-test ios-generate ios-build cli-run registry ci

help:
	@echo "Targets:"
	@echo "  make swift-build   - Build Swift package targets"
	@echo "  make swift-test    - Run Swift package tests"
	@echo "  make cli-run       - Run AppShell CLI"
	@echo "  make ios-generate  - Generate Xcode project via xcodegen"
	@echo "  make ios-build     - Build AppShelliOS for iOS Simulator"
	@echo "  make registry      - Regenerate CLI module registry"
	@echo "  make ci            - Run local CI pipeline"

swift-build:
	$(SWIFT_ENV) swift build

swift-test:
	$(SWIFT_ENV) swift test

ios-generate:
	cd apps/ios/AppShelliOS && xcodegen generate

ios-build:
	cd apps/ios/AppShelliOS && \
	$(SWIFT_ENV) \
	xcodebuild -project AppShelliOS.xcodeproj \
	  -scheme AppShelliOS \
	  -destination 'generic/platform=iOS Simulator' \
	  -derivedDataPath $(IOS_DERIVED_DATA) \
	  CODE_SIGNING_ALLOWED=NO build

cli-run:
	$(SWIFT_ENV) swift run AppShell

registry:
	bash tools/ModuleRegistryPlugin/generate_registry.sh

ci: swift-build swift-test ios-generate ios-build
