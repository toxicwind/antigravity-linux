SHELL := /usr/bin/env bash

INSTALLER := ./antigravity-installer.sh
BATS      := $(shell command -v bats 2>/dev/null || echo bats)
SC        := $(shell command -v shellcheck 2>/dev/null || echo shellcheck)

.PHONY: help lint test test-local verify install uninstall update ci clean

# ── Default ────────────────────────────────────────────────────────────────
help: ## Show this help
	@awk 'BEGIN{FS=":.*##"} /^[a-zA-Z_-]+:.*##/{printf "  \033[36m%-14s\033[0m %s\n",$$1,$$2}' $(MAKEFILE_LIST)

# ── Linting ────────────────────────────────────────────────────────────────
lint: ## Run shellcheck on all shell files
	$(SC) -x -e SC1090,SC1091 $(INSTALLER)
	$(SC) -x -e SC1090,SC1091 lib/*.sh
	$(SC) -x -e SC1090,SC1091 tests/test_helper.bash
	@echo "✓ shellcheck passed"

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
clean: ## Remove temp files and bats helpers
	@find . -name '*.tmp' -delete 2>/dev/null || true
	@echo "✓ clean"
