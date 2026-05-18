#!/bin/bash
# Archive 직전에 실행되어 Version.xcconfig 의 BUILD_NUMBER 를 1 증가시킵니다.
set -euo pipefail

ROOT="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
VERSION_FILE="${ROOT}/Version.xcconfig"

if [ ! -f "$VERSION_FILE" ]; then
  echo "error: Version.xcconfig not found at ${VERSION_FILE}" >&2
  exit 1
fi

current=$(grep -E '^BUILD_NUMBER[[:space:]]*=' "$VERSION_FILE" | sed -E 's/^BUILD_NUMBER[[:space:]]*=[[:space:]]*//' | tr -d '[:space:]')

if [ -z "$current" ] || ! [[ "$current" =~ ^[0-9]+$ ]]; then
  echo "error: Invalid BUILD_NUMBER in Version.xcconfig" >&2
  exit 1
fi

next=$((current + 1))

if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' -E "s/^BUILD_NUMBER[[:space:]]*=.*/BUILD_NUMBER = ${next}/" "$VERSION_FILE"
else
  sed -i -E "s/^BUILD_NUMBER[[:space:]]*=.*/BUILD_NUMBER = ${next}/" "$VERSION_FILE"
fi

echo "Build number bumped: ${current} → ${next} (${VERSION_FILE})"
