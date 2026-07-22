.DEFAULT_GOAL := help

APP_NAME   := Elo
BUNDLE     := build/$(APP_NAME).app
BUNDLE_ID  := com.tku.elo
LOG_FILE   := $(HOME)/Library/Logs/Elo/elo.log

.PHONY: help build run go fresh dev run-logs go-logs logs logs-recent logs-clear reset check-cert sig clean

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

build: ## Build the signed .app bundle
	./build_app.sh

run: ## Launch the built bundle (background agent)
	open "$(BUNDLE)"

go: build run ## Build, then launch

go-logs: build run logs ## Build, launch (detached), then tail logs live

fresh: reset build run ## Reset Accessibility, rebuild, and launch (clean slate)

dev: ## Fast run via `swift run` — logs inline, but NOT for Accessibility features
	swift run

run-logs: build ## Build + run the bundle binary in this terminal (logs inline + real bundle identity)
	"$(BUNDLE)/Contents/MacOS/$(APP_NAME)"

logs: ## Tail the Elo log file live (Ctrl-C to stop)
	@mkdir -p "$(dir $(LOG_FILE))" && touch "$(LOG_FILE)"
	tail -f "$(LOG_FILE)"

logs-recent: ## Show the last 100 lines of the Elo log file
	@mkdir -p "$(dir $(LOG_FILE))" && touch "$(LOG_FILE)"
	tail -n 100 "$(LOG_FILE)"

logs-clear: ## Empty the Elo log file
	@: > "$(LOG_FILE)" && echo "Cleared $(LOG_FILE)"

reset: ## Reset the Accessibility permission (forces a fresh grant)
	tccutil reset Accessibility $(BUNDLE_ID)

check-cert: ## Verify the 'Elo Dev' code-signing identity exists
	@security find-identity -v -p codesigning | grep "Elo Dev" \
		|| echo "⚠  'Elo Dev' code-signing certificate not found (builds will be ad-hoc)."

sig: ## Show the built bundle's code signature
	@codesign -dvvv "$(BUNDLE)" 2>&1 | grep -Ei "Signature=|Authority=" || true

clean: ## Remove build artifacts (.build and build/)
	rm -rf .build build
