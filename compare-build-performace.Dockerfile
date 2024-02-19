ARG IMAGE

FROM $IMAGE as builder

ARG PROJECT=clang
ARG LLVM_MAJOR_VERSION=17

# use stage 1 profiler
ENV CC=stage2-pgo-lto/install/bin/clang
ENV CXX=stage2-pgo-lto/install/bin/clang++

COPY build_scripts/build_${PROJECT}.sh build_${PROJECT}.sh
RUN chmod +x build_${PROJECT}.sh && /bin/time ./build_${PROJECT}.sh

RUN mv stage2-pgo-lto/install/bin/clang stage2-pgo-lto/install/bin/clang.org

ENV CC=stage2-pgo-lto/install/bin/clang
ENV CXX=stage2-pgo-lto/install/bin/clang++




###################################################################################################
# Compare 

#https://chromium.googlesource.com/native_client/nacl-llvm-project-v10/+/9471902eff782d9fd95f5ce77b2a7193c8d0ac4c/bolt/docs/OptimizingClang.md

# mv and symlink
#$ mv $CPATH/clang-7 $CPATH/clang-7.org
#$ ln -fs $CPATH/clang-7.bolt $CPATH/clang-7

# compare runs can be done like:
# $ ln -fs $CPATH/clang-7.org $CPATH/clang-7
# $ ninja clean && /bin/time -f %e ninja clang -j48
# 202.72
# $ ln -fs $CPATH/clang-7.bolt $CPATH/clang-7
# $ ninja clean && /bin/time -f %e ninja clang -j48
# 180.11