#!/usr/bin/env bash
set -euo pipefail

# build_apk.sh - Local helper to build Android APKs for this Flutter app.
#
# Usage:
#   ./build_apk.sh [--debug|--profile|--release] [--split-per-abi] [--flavor NAME] [--target lib/main.dart]
# Examples:
#   ./build_apk.sh --debug
#   ./build_apk.sh --release --split-per-abi
#   ./build_apk.sh --release --flavor prod --target lib/main.dart
#
# Notes:
# - Release build here is UNSIGNED unless you have signing configured in android/key.properties.
# - Output location:
#     Debug:  build/app/outputs/flutter-apk/app-debug.apk
#     Profile: build/app/outputs/flutter-apk/app-profile.apk
#     Release: build/app/outputs/flutter-apk/app-release.apk (or per-ABI splits)
#
# Requirements:
# - Flutter SDK on PATH
# - Android SDK installed (for building APK)

MODE="debug"
SPLIT_ABI="false"
FLAVOR=""
TARGET="lib/main.dart"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug) MODE="debug"; shift ;;
    --profile) MODE="profile"; shift ;;
    --release) MODE="release"; shift ;;
    --split-per-abi) SPLIT_ABI="true"; shift ;;
    --flavor) FLAVOR="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    -h|--help)
      sed -n '1,60p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

command -v flutter >/dev/null 2>&1 || { echo "Error: flutter not found in PATH"; exit 1; }

echo "==> Flutter version"
flutter --version

echo "==> flutter pub get"
flutter pub get

BUILD_ARGS=("build" "apk")
case "$MODE" in
  debug) BUILD_ARGS+=("--debug") ;;
  profile) BUILD_ARGS+=("--profile") ;;
  release) BUILD_ARGS+=("--release") ;;
  *) echo "Invalid MODE: $MODE"; exit 1 ;;
 esac

if [[ -n "$FLAVOR" ]]; then
  BUILD_ARGS+=("--flavor" "$FLAVOR")
fi

if [[ -n "$TARGET" ]]; then
  BUILD_ARGS+=("--target" "$TARGET")
fi

if [[ "$SPLIT_ABI" == "true" ]]; then
  BUILD_ARGS+=("--split-per-abi")
fi

set -x
flutter "${BUILD_ARGS[@]}"
set +x

echo
OUTPUT_DIR="build/app/outputs/flutter-apk"
if [[ -d "$OUTPUT_DIR" ]]; then
  echo "==> Build outputs in $OUTPUT_DIR:"
  ls -lh "$OUTPUT_DIR"
fi

echo "==> Done. Signing note: release APK is unsigned unless android signing is configured."
