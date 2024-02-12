#!/usr/bin/env bash

SCRIPT_PATH=$(realpath $(dirname $0))

# shallow-checkout the current latest
git clone --depth=1 https://github.com/llvm/llvm-project.git ${SCRIPT_PATH}/llvm-project