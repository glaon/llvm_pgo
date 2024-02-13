FROM ubuntu:24.04

ARG LLVM_VERSION

# basic build requiremnets for LLVM/Clang
RUN apt-get update && apt-get install -y build-essential cmake ninja-build python3 git \
    && rm -rf /var/lib/apt/lists/* 

COPY checkout_llvm.sh /checkout_llvm.sh
RUN ./checkout_llvm.sh $LLVM_VERSION && rm checkout_llvm.sh

WORKDIR /llvm-project/

ENV LLVM_DIR=/llvm-project/
ENV CMAKE_GENERATOR=Ninja
ENV CMAKE_BUILD_TYPE=Release

# TODO rename stages!

# stage0 build without instrumentation
RUN mkdir stage1 && cd stage1 && cmake -DLLVM_ENABLE_PROJECTS=clang ../llvm && cmake --build .

# stage1 build compiler
ENV CC=/llvm-project/stage1/clang
ENV CXX=/llvm-project/stage1/clang++
ENV LLVM_PROFDATA=/llvm-project/stage2/llvm-profdata

RUN ls /llvm-project/stage1/

# stage1 build with instrumentation
RUN mkdir stage2 && cd stage2 && cmake -DLLVM_ENABLE_PROJECTS=clang -DLLVM_BUILD_INSTRUMENTED=IR -DLLVM_BUILD_RUNTIME=No ../llvm && ninja all

# stage2 ready compiler
ENV CC=/llvm-project/stage2/clang
ENV CXX=/llvm-project/stage2/clang++