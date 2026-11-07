<#
.SYNOPSIS
  Windows equivalent of the Makefile. Same command names.

.EXAMPLE
  ./setup.ps1             # first run after clone (same as: ./setup.ps1 setup)
  ./setup.ps1 watch
  ./setup.ps1 run-dev
  ./setup.ps1 feature -Name orders -Model order -Lite
  ./setup.ps1 screen -Name order_detail -Feature orders -Stateful
#>
param(
  [Parameter(Position = 0)]
  [ValidateSet('setup', 'hooks', 'gen', 'watch', 'l10n', 'run-dev', 'run-staging', 'run-prod', 'format',
    'analyze', 'test', 'check', 'feature', 'screen', 'icons', 'apk-dev', 'apk-staging', 'aab-prod', 'clean')]
  [string]$Command = 'setup',
  [string]$Name,
  [string]$Model,
  [string]$Feature,
  [switch]$Lite,
  [switch]$Stateful
)

Set-Location $PSScriptRoot

# Success is judged by exit code only: Dart/Flutter print progress on stderr, which
# Windows PowerShell would otherwise treat as an error when output is redirected.
function Invoke-Step([string]$Line) {
  Write-Host "> $Line" -ForegroundColor Cyan
  $ErrorActionPreference = 'Continue'
  Invoke-Expression $Line 2>&1 | ForEach-Object { "$_" }
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed: $Line" -ForegroundColor Red
    exit $LASTEXITCODE
  }
}

function Invoke-Gen {
  Invoke-Step 'fvm flutter gen-l10n'
  Invoke-Step 'fvm dart run build_runner build'
}

function Invoke-Run([string]$Flavor) {
  Invoke-Gen
  Invoke-Step "fvm flutter run --flavor $Flavor -t lib/main_$Flavor.dart"
}

$mason = 'fvm dart pub global run mason_cli:mason'

switch ($Command) {
  'setup' {
    Invoke-Step 'fvm install'
    Invoke-Step 'fvm flutter pub get'
    Invoke-Gen
    Invoke-Step 'fvm dart pub global activate mason_cli'
    Invoke-Step "$mason get"
    if (Test-Path .git) { & $PSCommandPath hooks } else { Write-Host 'Not a git repo yet: run ./setup.ps1 hooks after git init' -ForegroundColor Yellow }
  }
  'hooks' {
    Invoke-Step 'git config core.hooksPath .githooks'
    # Brick template paths are long; Windows git needs this to check them out.
    Invoke-Step 'git config core.longpaths true'
  }
  'gen' { Invoke-Gen }
  'watch' { Invoke-Step 'fvm dart run build_runner watch' }
  'l10n' { Invoke-Step 'fvm flutter gen-l10n' }
  'run-dev' { Invoke-Run 'dev' }
  'run-staging' { Invoke-Run 'staging' }
  'run-prod' { Invoke-Run 'prod' }
  'format' { Invoke-Step 'fvm dart fix --apply --code=always_use_package_imports --code=directives_ordering'; Invoke-Step 'fvm dart run tool/format_check.dart --fix' }
  'analyze' { Invoke-Step 'fvm dart analyze --fatal-infos' }
  'test' { Invoke-Step 'fvm flutter test' }
  'check' {
    Invoke-Step 'fvm dart run tool/format_check.dart'
    Invoke-Step 'fvm dart run tool/l10n_check.dart'
    Invoke-Step 'fvm dart analyze --fatal-infos'
    Invoke-Step 'fvm flutter test'
  }
  'feature' {
    if (-not $Name -or -not $Model) { throw 'Usage: ./setup.ps1 feature -Name orders -Model order [-Lite]' }
    Invoke-Step "$mason make feature --name $Name --model $Model --lite $($Lite.IsPresent.ToString().ToLower())"
    Invoke-Step 'fvm dart fix --apply --code=always_use_package_imports --code=directives_ordering'; Invoke-Step 'fvm dart run tool/format_check.dart --fix'
    Invoke-Gen
  }
  'screen' {
    if (-not $Name -or -not $Feature) { throw 'Usage: ./setup.ps1 screen -Name order_detail -Feature orders [-Stateful]' }
    Invoke-Step "$mason make screen --name $Name --feature $Feature --stateful $($Stateful.IsPresent.ToString().ToLower())"
    Invoke-Step 'fvm dart fix --apply --code=always_use_package_imports --code=directives_ordering'; Invoke-Step 'fvm dart run tool/format_check.dart --fix'
    Invoke-Gen
  }
  'icons' { Invoke-Step 'fvm dart run flutter_launcher_icons' }
  'apk-dev' { Invoke-Gen; Invoke-Step 'fvm flutter build apk --debug --flavor dev -t lib/main_dev.dart' }
  'apk-staging' { Invoke-Gen; Invoke-Step 'fvm flutter build apk --release --flavor staging -t lib/main_staging.dart' }
  'aab-prod' { Invoke-Gen; Invoke-Step 'fvm flutter build appbundle --release --flavor prod -t lib/main_prod.dart --obfuscate --split-debug-info=build/symbols/android' }
  'clean' {
    Invoke-Step 'fvm flutter clean'
    Get-ChildItem lib, test -Recurse -Include *.g.dart, *.freezed.dart | Remove-Item -Force
    Remove-Item -Recurse -Force lib/gen, lib/l10n/generated -ErrorAction SilentlyContinue
  }
}
