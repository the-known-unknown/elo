.DEFAULT_GOAL := help

APP_NAME   := Elo
BUNDLE     := build/$(APP_NAME).app
BUNDLE_ID  := com.tku.elo
LOG_FILTER := 'eventMessage CONTAINS "[Elo]"'

.PHONY: help build run go fresh dev run-logs logs history reset check-cert sig clean

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

build: ## Build the signed .app bundle
	./build_app.sh

run: ## Launch the built bundle (background agent)
	open "$(BUNDLE)"

go: build run ## Build, then launch

fresh: reset build run ## Reset Accessibility, rebuild, and launch (clean slate)

dev: ## Fast run via `swift run` — logs inline, but NOT for Accessibility features
	swift run

run-logs: build ## Build + run the bundle binary in this terminal (logs inline + real bundle identity)
	"$(BUNDLE)/Contents/MacOS/$(APP_NAME)"

logs: ## Stream Elo logs live (Ctrl-C to stop)
	log stream --predicate $(LOG_FILTER) --info

history: ## Show Elo logs from the last 5 minutes
	log show --predicate $(LOG_FILTER) --info --last 5m

reset: ## Reset the Accessibility permission (forces a fresh grant)
	tccutil reset Accessibility $(BUNDLE_ID)

check-cert: ## Verify the 'Elo Dev' code-signing identity exists
	@security find-identity -v -p codesigning | grep "Elo Dev" \
		|| echo "⚠  'Elo Dev' code-signing certificate not found (builds will be ad-hoc)."

sig: ## Show the built bundle's code signature
	@codesign -dvvv "$(BUNDLE)" 2>&1 | grep -Ei "Signature=|Authority=" || true

clean: ## Remove build artifacts (.build and build/)
	rm -rf .build build
