#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
expected="$(cat "$root/.flutter-version")"
actual="$(flutter --version --machine | python3 -c 'import sys,json; print(json.load(sys.stdin)["frameworkVersion"])')"
if [[ "$actual" != "$expected" ]]; then
  echo "Flutter $expected required; found $actual. See docs/engineering/foundation.md." >&2
  exit 1
fi
exec flutter "$@"
