# ============================================================================
# SGVM Build System
# ============================================================================

SHELL := /bin/bash

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------

SAGE_REPO ?= https://github.com/Night-Traders-Dev/SageLang.git
SAGE_DIR  ?= .deps/SageLang

SAGE_BIN  ?= $(SAGE_DIR)/core/sage

# Dynamically resolve Sage lib directory
SAGE_LIB_DIR := $(shell \
	if [ -d "$(SAGE_DIR)/lib" ]; then \
		realpath "$(SAGE_DIR)/lib"; \
	elif [ -d "$(SAGE_DIR)/core/lib" ]; then \
		realpath "$(SAGE_DIR)/core/lib"; \
	fi \
)

# Final runtime search path
SAGE_PATH := ./src$(if $(SAGE_LIB_DIR),:$(SAGE_LIB_DIR))

# ----------------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------------

all: bootstrap sgvm sgvmc

# ----------------------------------------------------------------------------
# Bootstrap SageLang
# ----------------------------------------------------------------------------

bootstrap:
	@if [ ! -d "$(SAGE_DIR)" ]; then \
		echo "[BOOTSTRAP] Cloning SageLang..."; \
		git clone --depth=1 $(SAGE_REPO) $(SAGE_DIR); \
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

# ----------------------------------------------------------------------------
# SGVM
# ----------------------------------------------------------------------------

sgvm: sgvm.sage src/sgvm_vm.sage src/sgvm_core.sage
	@echo "[BUILD] sgvm"
	SAGE_PATH="$(SAGE_PATH)" \
	$(SAGE_BIN) --compile sgvm.sage -o sgvm

# ----------------------------------------------------------------------------
# SGVMC
# ----------------------------------------------------------------------------

sgvmc: sgvmc.sage src/sgvm_compiler.sage src/sgvm_core.sage
	@echo "[BUILD] sgvmc"
	SAGE_PATH="$(SAGE_PATH)" \
	$(SAGE_BIN) --compile sgvmc.sage -o sgvmc

# ----------------------------------------------------------------------------
# Clean
# ----------------------------------------------------------------------------

clean:
	rm -f sgvm sgvmc .tmp.svm

distclean: clean
	rm -rf .deps

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

install: all
	install -m 755 sgvm /usr/local/bin/sgvm
	install -m 755 sgvmc /usr/local/bin/sgvmc

# ----------------------------------------------------------------------------
# Debug Helpers
# ----------------------------------------------------------------------------

print-env:
	@echo "SAGE_DIR      = $(SAGE_DIR)"
	@echo "SAGE_BIN      = $(SAGE_BIN)"
	@echo "SAGE_LIB_DIR  = $(SAGE_LIB_DIR)"
	@echo "SAGE_PATH     = $(SAGE_PATH)"

# ----------------------------------------------------------------------------

.PHONY: all bootstrap clean distclean install print-env
