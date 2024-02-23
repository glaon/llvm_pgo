ARG LLVM_VERSION

FROM llvm_repo:${LLVM_VERSION} as stage1

RUN mkdir stage1 && cd stage1 && cmake ../llvm \
     -DLLVM_ENABLE_PROJECTS="clang;lld;bolt" \
     -DLLVM_ENABLE_RUNTIMES="compiler-rt" \
     -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
     -DCOMPILER_RT_BUILD_XRAY=OFF \
     -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
     -DCMAKE_INSTALL_PREFIX=./install && ninja install

# stage2 compiler
ENV CC=/llvm-project/stage1/bin/clang
ENV CXX=/llvm-project/stage1/bin/clang++