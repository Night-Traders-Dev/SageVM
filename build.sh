#!/bin/bash
export SAGE_PATH="./src:/root/Devel/SageVM/.deps/SageLang/core/lib"
export SAGE_BIN="./.deps/SageLang/core/sage"

# Pass extra CFLAGS if provided
if [ -n "$SAGE_CFLAGS" ]; then
    export CFLAGS_EXTRA="$SAGE_CFLAGS"
fi

$SAGE_BIN --compile sgvm.sage -o sgvm
$SAGE_BIN --compile sgvmc.sage -o sgvmc
