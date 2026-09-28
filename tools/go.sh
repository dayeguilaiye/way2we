#!/usr/bin/env bash
set -euo pipefail
exec env -u GOROOT GOTOOLCHAIN=go1.27.1 go "$@"
