ARG LLVM_VERSION
ARG PROJECT

FROM clang_stage2_train_${PROJECT}:${LLVM_VERSION} as train

ARG LLVM_VERSION

FROM clang_stage1:${LLVM_VERSION} as stage2-pgo-lto

RUN mkdir stage2-pgo-lto

COPY --from=train /llvm-project/stage2-prof-gen/profiles/clang.profdata /llvm-project/stage2-pgo-lto/clang.profdata

RUN git clone --branch 0.21 --depth=1 https://github.com/include-what-you-use/include-what-you-use.git /iwyu/

# option to optimize with bolt
ENV LDFLAGS="-Wl,-q"

RUN cd stage2-pgo-lto && cmake ../llvm \
    -DLLVM_ENABLE_PROJECTS="clang;lld;bolt;clang-tools-extra" \
    -DLLVM_ENABLE_LTO=Full \
    -DLLVM_PROFDATA_FILE=clang.profdata \
    -DLLVM_USE_LINKER=lld \
    -DLLVM_PARALLEL_LINK_JOBS=2 \
    -DCMAKE_CXX_FLAGS="-Wno-profile-instr-unprofiled -Wno-profile-instr-out-of-date" \
    -DLLVM_EXTERNAL_PROJECTS=iwyu \
    -DLLVM_EXTERNAL_IWYU_SOURCE_DIR=/iwyu/ \
    -DCMAKE_INSTALL_PREFIX=./install && ninja install

# stage2 compiler with pgo, lto and prepared for bold optimization
ENV CC=/llvm-project/stage2-pgo-lto/bin/clang
ENV CXX=/llvm-project/stage2-pgo-lto/bin/clang++