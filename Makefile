# Makefile for MatrixOne Documentation
# =====================================

.PHONY: help install serve build clean lint lint-fix test

# Default target
.DEFAULT_GOAL := help

# Python executable
PYTHON := python3
PIP := pip3

# Node.js package manager - check if pnpm is available in PATH or common locations
PNPM := $(shell which pnpm 2>/dev/null || (test -f "$(HOME)/.local/share/pnpm/pnpm" && echo "$(HOME)/.local/share/pnpm/pnpm") || echo "")

# MkDocs executable
MKDOCS := mkdocs

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)MatrixOne Documentation - Available Commands$(NC)"
	@echo "$(BLUE)=============================================$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

install: ## Install all dependencies (Python + Node.js)
	@echo "$(BLUE)Installing Python dependencies...$(NC)"
	$(PIP) install -r requirements.txt
	@echo "$(GREEN)✓ Python dependencies installed$(NC)"
	@echo "$(BLUE)Installing Node.js dependencies...$(NC)"
	@PNPM_CHECK="$(PNPM)"; \
	if [ -z "$$PNPM_CHECK" ]; then \
		PNPM_CHECK="$$(which pnpm 2>/dev/null || [ -f "$$HOME/.local/share/pnpm/pnpm" ] && echo "$$HOME/.local/share/pnpm/pnpm" || echo "")"; \
	fi; \
	if [ -z "$$PNPM_CHECK" ] || [ ! -f "$$PNPM_CHECK" ] 2>/dev/null; then \
		echo "$(RED)Error: pnpm is not installed$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Please install pnpm first using one of these methods:$(NC)"; \
		echo ""; \
		echo "$(BLUE)Option 1 (recommended - user install):$(NC)"; \
		echo "  curl -fsSL https://get.pnpm.io/install.sh | sh -"; \
		echo "  source ~/.bashrc  # or ~/.zshrc"; \
		echo ""; \
		echo "$(BLUE)Option 2 (if you have npm):$(NC)"; \
		echo "  npm install -g pnpm"; \
		echo ""; \
		echo "$(BLUE)Option 3 (if you have corepack):$(NC)"; \
		echo "  corepack enable"; \
		echo "  corepack prepare pnpm --activate"; \
		echo ""; \
		echo "$(YELLOW)After installation, run 'make install' again.$(NC)"; \
		exit 1; \
	fi
	$(PNPM) install
	@echo "$(GREEN)✓ Node.js dependencies installed$(NC)"
	@echo "$(GREEN)✓ All dependencies installed successfully!$(NC)"

install-python: ## Install Python dependencies only
	@echo "$(BLUE)Installing Python dependencies...$(NC)"
	$(PIP) install -r requirements.txt
	@echo "$(GREEN)✓ Python dependencies installed$(NC)"

install-node: ## Install Node.js dependencies only
	@echo "$(BLUE)Installing Node.js dependencies...$(NC)"
	@if [ -z "$(PNPM)" ]; then \
		echo "$(RED)Error: pnpm is not installed$(NC)"; \
		echo "$(YELLOW)Please install pnpm first:$(NC)"; \
		echo "  Option 1 (recommended): curl -fsSL https://get.pnpm.io/install.sh | sh -"; \
		echo "  Option 2: npm install -g pnpm"; \
		echo "  Option 3: corepack enable && corepack prepare pnpm --activate"; \
		echo ""; \
		echo "After installation, restart your terminal or run:"; \
		echo "  export PNPM_HOME=\"\$$HOME/.local/share/pnpm\""; \
		echo "  export PATH=\"\$$PNPM_HOME:\$$PATH\""; \
		exit 1; \
	fi
	$(PNPM) install
	@echo "$(GREEN)✓ Node.js dependencies installed$(NC)"

serve: ## Start local development server (with auto-reload)
	@echo "$(BLUE)Starting MkDocs development server...$(NC)"
	@echo "$(YELLOW)Access at: http://127.0.0.1:8000$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	@echo ""
	$(MKDOCS) serve

serve-custom: ## Start server on custom address (use ADDR=0.0.0.0:8080)
	@echo "$(BLUE)Starting MkDocs server on $(ADDR)...$(NC)"
	$(MKDOCS) serve -a $(ADDR)

build: ## Build static documentation site
	@echo "$(BLUE)Building documentation site...$(NC)"
	$(MKDOCS) build
	@echo "$(GREEN)✓ Documentation built successfully!$(NC)"
	@echo "$(YELLOW)Output directory: site/$(NC)"

build-strict: ## Build with strict mode (fail on warnings)
	@echo "$(BLUE)Building documentation with strict mode...$(NC)"
	$(MKDOCS) build --strict
	@echo "$(GREEN)✓ Documentation built successfully (strict mode)!$(NC)"

clean: ## Clean build artifacts and caches
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	rm -rf site/
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Cleaned build artifacts$(NC)"

lint: ## Run linting checks (markdown and punctuation)
	@echo "$(BLUE)Running linting checks...$(NC)"
	@if [ -z "$(PNPM)" ]; then \
		echo "$(RED)Error: pnpm is not installed$(NC)"; \
		echo "$(YELLOW)Please run 'make install' first to install dependencies$(NC)"; \
		exit 1; \
	fi
	$(PNPM) run lint
	@echo "$(GREEN)✓ Linting completed!$(NC)"

lint-fix: ## Auto-fix linting issues
	@echo "$(BLUE)Auto-fixing linting issues...$(NC)"
	@if [ -z "$(PNPM)" ]; then \
		echo "$(RED)Error: pnpm is not installed$(NC)"; \
		echo "$(YELLOW)Please run 'make install' first to install dependencies$(NC)"; \
		exit 1; \
	fi
	$(PNPM) run lint:fix
	@echo "$(GREEN)✓ Linting fixes applied!$(NC)"

test: lint ## Run all tests (currently just linting)
	@echo "$(GREEN)✓ All tests passed!$(NC)"

check: ## Quick check (build + lint)
	@echo "$(BLUE)Running quick check...$(NC)"
	@$(MAKE) lint
	@$(MAKE) build-strict
	@echo "$(GREEN)✓ Quick check completed!$(NC)"

deploy: ## Deploy documentation (requires proper setup)
	@echo "$(BLUE)Deploying documentation...$(NC)"
	$(MKDOCS) gh-deploy
	@echo "$(GREEN)✓ Documentation deployed!$(NC)"

new-page: ## Create new documentation page (use PAGE=path/to/page.md)
	@if [ -z "$(PAGE)" ]; then \
		echo "$(RED)Error: PAGE variable required$(NC)"; \
		echo "$(YELLOW)Usage: make new-page PAGE=docs/MatrixOne/Tutorial/my-page.md$(NC)"; \
		exit 1; \
	fi
	@mkdir -p $$(dirname $(PAGE))
	@if [ -f "$(PAGE)" ]; then \
		echo "$(RED)Error: File $(PAGE) already exists$(NC)"; \
		exit 1; \
	fi
	@echo "# Page Title\n\n## Overview\n\nYour content here.\n" > $(PAGE)
	@echo "$(GREEN)✓ Created new page: $(PAGE)$(NC)"
	@echo "$(YELLOW)Don't forget to add it to mkdocs.yml!$(NC)"

validate: ## Validate mkdocs.yml configuration
	@echo "$(BLUE)Validating mkdocs.yml...$(NC)"
	@$(PYTHON) -c "import yaml; yaml.safe_load(open('mkdocs.yml'))" && \
		echo "$(GREEN)✓ mkdocs.yml is valid$(NC)" || \
		(echo "$(RED)✗ mkdocs.yml has errors$(NC)" && exit 1)

list-files: ## List all documentation files
	@echo "$(BLUE)Documentation files:$(NC)"
	@find docs/MatrixOne -name "*.md" | sort

count-pages: ## Count total documentation pages
	@echo "$(BLUE)Total documentation pages:$(NC)"
	@find docs/MatrixOne -name "*.md" | wc -l | xargs echo "$(GREEN)" | xargs echo "$(NC)"

watch: ## Watch for changes and rebuild (alternative to serve)
	@echo "$(BLUE)Watching for changes...$(NC)"
	@echo "$(YELLOW)Building on file changes$(NC)"
	while true; do \
		$(MKDOCS) build; \
		sleep 2; \
	done

version: ## Show installed versions
	@echo "$(BLUE)Installed versions:$(NC)"
	@echo "  Python:  $$($(PYTHON) --version 2>&1 | cut -d' ' -f2)"
	@echo "  pip:     $$($(PIP) --version | cut -d' ' -f2)"
	@echo "  Node:    $$(node --version 2>/dev/null || echo 'Not installed')"
	@echo "  pnpm:    $$($(PNPM) --version 2>/dev/null || echo 'Not installed')"
	@echo "  MkDocs:  $$($(MKDOCS) --version 2>&1 | cut -d' ' -f3 || echo 'Not installed')"

upgrade: ## Upgrade dependencies
	@echo "$(BLUE)Upgrading Python dependencies...$(NC)"
	$(PIP) install --upgrade -r requirements.txt
	@echo "$(BLUE)Upgrading Node.js dependencies...$(NC)"
	@if [ -z "$(PNPM)" ]; then \
		echo "$(RED)Error: pnpm is not installed$(NC)"; \
		echo "$(YELLOW)Please run 'make install' first to install dependencies$(NC)"; \
		exit 1; \
	fi
	$(PNPM) update
	@echo "$(GREEN)✓ Dependencies upgraded!$(NC)"

dev: install serve ## Setup dev environment and start server
	@echo "$(GREEN)✓ Development environment ready!$(NC)"

