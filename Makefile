# =============================================================================
# Makefile - agent-development-rules
# =============================================================================

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

SCRIPTS_DIR := scripts
TESTS_DIR := tests

# =============================================================================
# Validation (self-check)
# =============================================================================

.PHONY: lint
lint: ## Run shellcheck on all scripts
	@echo "Running shellcheck..."
	shellcheck -x --exclude=SC1091 $(SCRIPTS_DIR)/sync.sh $(SCRIPTS_DIR)/validate.sh
	@echo "Running shellcheck on libraries..."
	shellcheck --shell=bash $(SCRIPTS_DIR)/lib/common.sh $(SCRIPTS_DIR)/lib/sync.sh
	@echo "Running shellcheck on test files..."
	@if ls $(TESTS_DIR)/*.bats 1>/dev/null 2>&1; then \
		shellcheck --shell=bash $(TESTS_DIR)/*.bats; \
	else \
		echo "  No .bats files found, skipping"; \
	fi
	@echo "✓ shellcheck passed"

.PHONY: fmt-check
fmt-check: ## Check shell script formatting
	@echo "Running shfmt check..."
	shfmt -d -i 4 -ci $(SCRIPTS_DIR)/sync.sh $(SCRIPTS_DIR)/validate.sh $(SCRIPTS_DIR)/lib/common.sh $(SCRIPTS_DIR)/lib/sync.sh
	@echo "Checking test file formatting..."
	@if ls $(TESTS_DIR)/*.bats 1>/dev/null 2>&1; then \
		shfmt -d -i 4 -ci $(TESTS_DIR)/*.bats; \
	else \
		echo "  No .bats files found, skipping"; \
	fi
	@echo "✓ shfmt passed"

.PHONY: fmt
fmt: ## Format shell scripts in-place
	shfmt -w -i 4 -ci $(SCRIPTS_DIR)/sync.sh $(SCRIPTS_DIR)/validate.sh $(SCRIPTS_DIR)/lib/common.sh $(SCRIPTS_DIR)/lib/sync.sh
	@if ls $(TESTS_DIR)/*.bats 1>/dev/null 2>&1; then \
		shfmt -w -i 4 -ci $(TESTS_DIR)/*.bats; \
	fi

.PHONY: test
test: ## Run bats tests
	@echo "Running bats tests..."
	bats $(TESTS_DIR)/
	@echo "✓ tests passed"

.PHONY: validate
validate: ## Run manifest validation
	@echo "Running manifest validation..."
	$(SCRIPTS_DIR)/validate.sh
	@echo "✓ validation passed"

# =============================================================================
# Sync
# =============================================================================

.PHONY: sync
sync: ## Sync rules to all enabled agents
	$(SCRIPTS_DIR)/sync.sh

.PHONY: sync-dry
sync-dry: ## Dry-run sync (show what would happen)
	$(SCRIPTS_DIR)/sync.sh --dry-run

.PHONY: list
list: ## List available agents
	$(SCRIPTS_DIR)/sync.sh --list

# =============================================================================
# Full pipeline
# =============================================================================

.PHONY: check
check: lint fmt-check validate test ## Run full validation chain (lint → fmt → validate → test)
	@echo ""
	@echo "✓ All checks passed"

# =============================================================================
# Help
# =============================================================================

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
