#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Explicitly local defaults; only this ignored file overrides them.
set -a
source .env.example
if [[ -f .env.local ]]; then source .env.local; fi
if [[ "$AUTH_SECRET_FILE" != /* ]]; then AUTH_SECRET_FILE="$PWD/$AUTH_SECRET_FILE"; fi
set +a
exec "$@"
