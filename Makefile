# Common commands. Windows without make: use ./setup.ps1 <command> (same names).
# Everything goes through fvm so the pinned Flutter version (.fvmrc) is used.

FLUTTER := fvm flutter
DART := fvm dart
MASON := $(DART) pub global run mason_cli:mason

.PHONY: help setup hooks gen watch l10n run-dev run-staging run-prod format analyze test check \
        feature screen icons apk-dev apk-staging aab-prod ipa-prod clean

help: ## List commands
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

setup: ## First run after clone: SDK, packages, codegen, mason bricks
	fvm install
	$(FLUTTER) pub get
	$(MAKE) gen
	$(DART) pub global activate mason_cli
	$(MASON) get
	@if [ -d .git ]; then $(MAKE) hooks; else echo "Not a git repo yet: run make hooks after git init"; fi

hooks: ## Install the pre-commit hook (format, analyze, l10n on staged files)
	git config core.hooksPath .githooks

gen: ## Generate code once (riverpod, freezed, json, routes, assets, l10n)
	$(FLUTTER) gen-l10n
	$(DART) run build_runner build

watch: ## Regenerate on every save. Keep it running while you code.
	$(DART) run build_runner watch

l10n: ## Regenerate translations after editing lib/l10n/*.arb
	$(FLUTTER) gen-l10n

run-dev: gen ## Run the dev flavor
	$(FLUTTER) run --flavor dev -t lib/main_dev.dart

run-staging: gen ## Run the staging flavor
	$(FLUTTER) run --flavor staging -t lib/main_staging.dart

run-prod: gen ## Run the prod flavor
	$(FLUTTER) run --flavor prod -t lib/main_prod.dart

format: ## Format Dart code
	$(DART) fix --apply --code=always_use_package_imports --code=directives_ordering
	$(DART) run tool/format_check.dart --fix

analyze: ## Static analysis incl. riverpod_lint (dart analyze runs plugins; flutter analyze does not)
	$(DART) analyze --fatal-infos

test: ## All tests, including the architecture test
	$(FLUTTER) test

check: ## What CI runs: format check, l10n check, analyze, test
	$(DART) run tool/format_check.dart
	$(DART) run tool/l10n_check.dart
	$(DART) analyze --fatal-infos
	$(FLUTTER) test

feature: ## New feature: make feature name=orders model=order lite=false
	$(MASON) make feature --name $(name) --model $(model) --lite $(or $(lite),false)
	$(DART) fix --apply --code=always_use_package_imports --code=directives_ordering
	$(DART) run tool/format_check.dart --fix
	$(MAKE) gen

screen: ## New screen: make screen name=order_detail feature=orders stateful=false
	$(MASON) make screen --name $(name) --feature $(feature) --stateful $(or $(stateful),false)
	$(DART) fix --apply --code=always_use_package_imports --code=directives_ordering
	$(DART) run tool/format_check.dart --fix
	$(MAKE) gen

icons: ## Launcher icons for every flavor (put images in assets/launcher/ first)
	$(DART) run flutter_launcher_icons

apk-dev: gen ## Debug APK, dev flavor
	$(FLUTTER) build apk --debug --flavor dev -t lib/main_dev.dart

apk-staging: gen ## Release APK, staging flavor
	$(FLUTTER) build apk --release --flavor staging -t lib/main_staging.dart

aab-prod: gen ## Play Store bundle, prod flavor
	$(FLUTTER) build appbundle --release --flavor prod -t lib/main_prod.dart --obfuscate --split-debug-info=build/symbols/android

ipa-prod: gen ## App Store build, prod flavor (macOS)
	$(FLUTTER) build ipa --release --flavor prod -t lib/main_prod.dart --obfuscate --split-debug-info=build/symbols/ios

clean: ## Remove build outputs and generated code
	$(FLUTTER) clean
	find lib test -name '*.g.dart' -o -name '*.freezed.dart' | xargs rm -f
	rm -rf lib/gen lib/l10n/generated
