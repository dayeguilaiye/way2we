#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Explicitly local defaults; only this ignored file overrides them.
set -a
source .env.example
if [[ -f .env.local ]]; then source .env.local; fi
set +a
exec "$@"
