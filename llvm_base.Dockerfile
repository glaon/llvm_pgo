FROM ubuntu:22.04 as llvm_base

ARG LLVM_VERSION

ENV DEBIAN_FRONTEND=noninteractive

# basic build requiremnets for LLVM/Clang
RUN apt-get update && apt-get install -y build-essential cmake ninja-build python3 git \
    && rm -rf /var/lib/apt/lists/* 

COPY checkout_llvm.sh /checkout_llvm.sh
RUN ./checkout_llvm.sh $LLVM_VERSION && rm checkout_llvm.sh

WORKDIR /llvm-project/

ENV LLVM_DIR=/llvm-project/
ENV CMAKE_GENERATOR=Ninja
ENV CMAKE_BUILD_TYPE=Release