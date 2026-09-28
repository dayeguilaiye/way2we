SHELL := /bin/bash
GO := $(CURDIR)/tools/go.sh
FLUTTER := $(CURDIR)/tools/flutter.sh
PYTHON ?= .venv-contract/bin/python
DEVICE ?= ios
API_BASE_URL ?= http://127.0.0.1:8080

.PHONY: setup-contract db-up db-stop migrate dev check check-go check-mobile check-contract test-integration mobile build-ios build-android
setup-contract:
	python3 -m venv .venv-contract
	$(PYTHON) -m pip install -r tools/contract-requirements.txt

db-up:
	docker compose up -d --wait db

db-stop:
	docker compose --profile test stop

migrate:
	./tools/local-env.sh bash -c 'cd server && $(GO) run ./cmd/migrate'

dev: db-up
	$(MAKE) migrate
	./tools/local-env.sh bash -c 'cd server && $(GO) run ./cmd/api'

check: check-go check-mobile check-contract

check-go:
	@test -z "$$(find server -name '*.go' -exec "$$( $(GO) env GOROOT)/bin/gofmt" -l {} +)" || (echo 'Run gofmt on Go sources'; exit 1)
	cd server && $(GO) vet ./... && $(GO) test -race ./...

check-mobile:
	cd apps/mobile && dart format --output=none --set-exit-if-changed lib test integration_test
	cd apps/mobile && $(FLUTTER) analyze && $(FLUTTER) test

check-contract:
	$(PYTHON) tools/check_contract.py

test-integration:
	docker compose --profile test up -d --wait db-test
	cd server && TEST_DATABASE_URL='postgres://way2we_test:local-test-only@127.0.0.1:55433/way2we_test?sslmode=disable' $(GO) test -race -tags=integration ./...

mobile:
	cd apps/mobile && $(FLUTTER) run -d $(DEVICE) --dart-define=API_BASE_URL=$(API_BASE_URL) --dart-define=DEV_DIAGNOSTICS=true

build-ios:
	cd apps/mobile && $(FLUTTER) build ios --simulator --debug --dart-define=API_BASE_URL=$(API_BASE_URL) --dart-define=DEV_DIAGNOSTICS=true

build-android:
	cd apps/mobile && $(FLUTTER) build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=DEV_DIAGNOSTICS=true

.PHONY: check-runtime test-mobile-integration
check-runtime:
	API_BASE_URL=$(API_BASE_URL) $(PYTHON) tools/check_runtime_contract.py

test-mobile-integration:
	cd apps/mobile && $(FLUTTER) test integration_test/connection_test.dart -d $(DEVICE) --dart-define=API_BASE_URL=$(API_BASE_URL) --dart-define=DEV_DIAGNOSTICS=true
