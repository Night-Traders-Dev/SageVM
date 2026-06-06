# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------

SAGE_DIR  = .deps/SageLang
SAGE_REPO = https://github.com/Night-Traders-Dev/SageLang.git
SAGE_BIN  = $(SAGE_DIR)/core/sage

# ----------------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------------

all: bootstrap
	@echo "[BUILD] Building SageVM..."
	./build.sh

# ----------------------------------------------------------------------------
# Bootstrap SageLang
# ----------------------------------------------------------------------------

bootstrap:
	@if [ ! -f "$(SAGE_DIR)/Makefile" ]; then \
		echo "[BOOTSTRAP] Initializing SageLang submodule..."; \
		git submodule update --init --recursive; \
	fi

	@if [ ! -d "$(SAGE_DIR)" ]; then \
		echo ""; \
		echo "[ERROR] SageLang submodule missing."; \
		echo "Run:"; \
		echo "    git submodule add $(SAGE_REPO) $(SAGE_DIR)"; \
		echo ""; \
		exit 1; \
	fi

	@echo "[BOOTSTRAP] Building SageLang..."
	@$(MAKE) -C $(SAGE_DIR)

	@if [ ! -x "$(SAGE_BIN)" ]; then \
		echo ""; \
		echo "[ERROR] Sage binary not found:"; \
		echo "        $(SAGE_BIN)"; \
		echo ""; \
		exit 1; \
	fi
