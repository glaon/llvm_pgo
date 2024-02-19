#!/usr/bin/env bash

SCRIPT_PATH=$(realpath $(dirname $0))

VERSION=$1

# shallow-checkout a specifc llvm version
git clone --branch llvmorg-$VERSION --depth=1 https://github.com/llvm/llvm-project.git ${SCRIPT_PATH}/llvm-project