#!/bin/bash
export SAGE_PATH="./src:/root/Devel/SageVM/.deps/SageLang/core/lib"
export SAGE_BIN="./.deps/SageLang/core/sage"
$SAGE_BIN --compile sgvm.sage -o sgvm
