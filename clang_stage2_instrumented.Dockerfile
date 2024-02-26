ARG LLVM_VERSION

FROM clang_stage1:${LLVM_VERSION} AS stage2-instrumented

# use stage1 clang
ENV CC=/llvm-project/stage1/bin/clang
ENV CXX=/llvm-project/stage1/bin/clang++
ENV LLVM_PROFDATA=/llvm-project/stage0/bin/llvm-profdata

RUN mkdir stage2-prof-gen && cd stage2-prof-gen && cmake ../llvm \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_USE_LINKER=lld \
    -DLLVM_PARALLEL_LINK_JOBS=2 \
    -DLLVM_BUILD_INSTRUMENTED=ON \
    -DCMAKE_INSTALL_PREFIX=./install && ninja install

# stage2 compiler with instrumentation
ENV CC=/llvm-project/stage2-prof-gen/bin/clang
ENV CXX=/llvm-project/stage2-prof-gen/bin/clang++
