#!/bin/bash
SAGE=./.deps/SageLang/core/sage
$SAGE --emit-vm bench_loop.sage -o bench_loop.svm
./sagevm compile bench_loop.svm
time ./sagevm run bench_loop.svm.sgvm
