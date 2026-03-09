SHELL := /usr/bin/env bash

INSTALLER := ./antigravity-installer.sh
BATS      := $(shell command -v bats 2>/dev/null || echo bats)
SC        := $(shell command -v shellcheck 2>/dev/null || echo shellcheck)
CACHE_DIR := .make_cache

.PHONY: help lint lint-shell lint-json test test-all test-local verify install uninstall update ci clean

# ── Default ────────────────────────────────────────────────────────────────
help: ## Show this help
	@awk 'BEGIN{FS=":.*##"} /^[a-zA-Z_-]+:.*##/{printf "  \033[36m%-14s\033[0m %s\n",$$1,$$2}' $(MAKEFILE_LIST)

# ── Linting ────────────────────────────────────────────────────────────────
$(CACHE_DIR):
	@mkdir -p $(CACHE_DIR)

lint: lint-shell lint-json ## Run all linters

lint-shell: $(CACHE_DIR) ## Run shellcheck with caching
	@if [ "$(INSTALLER)" -nt "$(CACHE_DIR)/shellcheck" ]; then \
		$(SC) -x -e SC1090,SC1091 $(INSTALLER) && \
		$(SC) -x -e SC1090,SC1091 lib/*.sh && \
		$(SC) -x -e SC1090,SC1091 tests/test_helper.bash && \
		touch $(CACHE_DIR)/shellcheck && \
		echo "✓ shellcheck passed"; \
	else \
		echo "✓ shellcheck (cached)"; \
	fi

lint-json: $(CACHE_DIR) ## Lint all JSON files with caching
	@FILES=$$(find . -name "*.json" -not -path "*/node_modules/*" -not -path "*/workspace/*" -not -path "*/usr/*"); \
	if [ -z "$$FILES" ]; then echo "✓ no json files to lint"; exit 0; fi; \
	NEED_LINT=0; \
	if [ ! -f $(CACHE_DIR)/jsonlint ]; then NEED_LINT=1; \
	else for f in $$FILES; do if [ "$$f" -nt "$(CACHE_DIR)/jsonlint" ]; then NEED_LINT=1; break; fi; done; fi; \
	if [ "$$NEED_LINT" -eq 1 ]; then \
		echo "$$FILES" | xargs -n1 python3 -m json.tool > /dev/null && \
		touch $(CACHE_DIR)/jsonlint && \
		echo "✓ json lint passed"; \
	else \
		echo "✓ json lint (cached)"; \
	fi

# ── Tests ──────────────────────────────────────────────────────────────────
test: ## Run CI-tagged bats tests (mocked, no real system deps)
	$(BATS) --filter-tags ci tests/

test-all: ## Run every bats test including local-tagged ones
	$(BATS) tests/

test-local: ## Run the real full-system integration check (requires sudo/Arch)
	@bash tests/local/verify_install.sh

# ── Full CI simulation ──────────────────────────────────────────────────────
ci: lint test ## Simulate what GitHub Actions runs (lint + mocked tests)

# ── Installer ops ──────────────────────────────────────────────────────────
install: ## Install or update Antigravity to latest
	bash $(INSTALLER)

uninstall: ## Remove Antigravity
	bash $(INSTALLER) --uninstall

update: ## Pull latest installer from Git, then install
	@REPO_DIR="$$(git rev-parse --show-toplevel)" && \
	  git -C "$$REPO_DIR" pull --ff-only && \
	  bash $(INSTALLER)

# ── Verification ─────────────────────────────────────────────────────────
verify: ## Run local post-install verification (real system checks)
	@bash tests/local/verify_install.sh

# ── Utilities ─────────────────────────────────────────────────────────────
clean: ## Remove temp files and cache
	@rm -rf $(CACHE_DIR)
	@find . -name '*.tmp' -delete 2>/dev/null || true
	@echo "✓ clean"
