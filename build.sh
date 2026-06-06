#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export SAGE_PATH="$SCRIPT_DIR/src:$SCRIPT_DIR/.deps/SageLang/core/lib"
export SAGE_BIN="$SCRIPT_DIR/.deps/SageLang/core/sage"

# Suppress overlength string warnings from generated C code
export CFLAGS_EXTRA="-Wno-overlength-strings"

# Pass extra CFLAGS if provided
if [ -n "$SAGE_CFLAGS" ]; then
    export CFLAGS_EXTRA="$CFLAGS_EXTRA $SAGE_CFLAGS"
fi

$SAGE_BIN --compile sgvm.sage -o sgvm
$SAGE_BIN --compile sgvmc.sage -o sgvmc
