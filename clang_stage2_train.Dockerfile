ARG LLVM_VERSION

FROM clang_stage2_instrumented:${LLVM_VERSION} AS stage2-train

ARG PROJECT=clang

# BUILD your project with clang, eg. clang itself
COPY build_scripts/build_${PROJECT}.sh build_${PROJECT}.sh
RUN chmod +x build_${PROJECT}.sh && ./build_${PROJECT}.sh

# Merge profiling data with stage 1 tooling
RUN cd stage2-prof-gen/profiles && \
    ../../stage1/install/bin/llvm-profdata merge -output=clang.profdata *