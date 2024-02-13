#!/usr/bin/env bash

SCRIPT_PATH=$(realpath $(dirname $0))

VERSION=$1

# shallow-checkout the current latest
git clone --branch llvmorg-$VERSION --depth=1 https://github.com/llvm/llvm-project.git ${SCRIPT_PATH}/llvm-project