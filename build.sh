#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Mitigate infinite recursion by avoiding recursive submodule updates
# and explicitly running it only for the immediate children.
git -c submodule.recurse=false -C "$SCRIPT_DIR" submodule update --init

# Automatically clean the workspace
rm -f "$SCRIPT_DIR"/sgvm "$SCRIPT_DIR"/sgvmc "$SCRIPT_DIR"/*.c "$SCRIPT_DIR"/.tmp_sgvmc.c

export SAGE_PATH="$SCRIPT_DIR/src:$SCRIPT_DIR/.deps/SageLang/core/lib"
export SAGE_BIN="$SCRIPT_DIR/.deps/SageLang/core/sage"

# Suppress overlength string warnings from generated C code
export CFLAGS_EXTRA="-Wno-overlength-strings"

# Pass extra CFLAGS if provided
if [ -n "$SAGE_CFLAGS" ]; then
    export CFLAGS_EXTRA="$CFLAGS_EXTRA $SAGE_CFLAGS"
fi

# Ensure Sage binary exists, build if it doesn't
if [ ! -x "$SAGE_BIN" ]; then
    make -C "$SCRIPT_DIR/.deps/SageLang"
fi

$SAGE_BIN --compile sgvm.sage -o sgvm
$SAGE_BIN --compile sgvmc.sage -o sgvmc
