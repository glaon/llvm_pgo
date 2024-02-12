FROM ubuntu:24.04

COPY llvm-project /app/llvm-project

# basic build needs 
RUN apt-get update && apt-get install -y build-essential cmake ninja-build python3

WORKDIR /app/llvm-project/

ENV LLVM_DIR=/app/llvm-project/
ENV CMAKE_GENERATOR=Ninja
ENV CMAKE_BUILD_TYPE=Release

# stage1 build
RUN mkdir stage1 && cd stage1 && cmake -DLLVM_ENABLE_PROJECTS=clang ../llvm && ninja all

# stage2 build with instrumentation
ENV CC=/app/llvm-project/stage1/clang
ENV CXX=/app/llvm-project/stage1/clang++

RUN mkdir stage2 && cd stage2 && cmake -DLLVM_ENABLE_PROJECTS=clang -DLLVM_BUILD_INSTRUMENTED=IR -DLLVM_BUILD_RUNTIME=No ../llvm && ninja all