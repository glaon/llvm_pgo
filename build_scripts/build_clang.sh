# assumes that clang is already available!
mkdir stage2-train && cd stage2-train && cmake ../llvm \
    -DLLVM_ENABLE_PROJECTS="clang" \
    -DLLVM_USE_LINKER=lld \
    -DCMAKE_INSTALL_PREFIX=./install && ninja install