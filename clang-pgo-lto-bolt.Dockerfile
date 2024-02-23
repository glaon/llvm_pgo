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

###################################################################################################
# stage1 build without instrumentation
FROM llvm_base as stage1

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

###################################################################################################
# stage2 instrumented
FROM stage1 as stage2-instrumented

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


###################################################################################################
# stage2 train stage
FROM stage2-instrumented as stage2-train

ARG PROJECT=clang

# BUILD your project with clang, eg. clang itself
COPY build_scripts/build_${PROJECT}.sh build_${PROJECT}.sh
RUN chmod +x build_${PROJECT}.sh && ./build_${PROJECT}.sh

# Merge profiling data with stage 1 tooling
RUN cd stage2-prof-gen/profiles && \
    ../../stage1/install/bin/llvm-profdata merge -output=clang.profdata *


###################################################################################################
FROM stage1 as stage2-pgo-lto

RUN mkdir stage2-pgo-lto

COPY --from=stage2-train /llvm-project/stage2-prof-gen/profiles/clang.profdata /llvm-project/stage2-pgo-lto/clang.profdata

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

###################################################################################################
FROM stage2-pgo-lto as stage3-bolt

ARG LINUX_KERNEL_VERSION=v6.6.10
ARG PROJECT=clang

# Get prerequisites for perf
RUN apt-get update && apt-get install -y wget pkg-config \
    git curl make bison flex elfutils libelf-dev libdw-dev libaudit-dev xz-utils \
    systemtap-sdt-dev libunwind-dev libssl-dev libslang2-dev python3-dev libzstd-dev \
    libzstd-dev libbabeltrace-ctf-dev libcap-dev python3-setuptools libpfm4-dev \
    libperl-dev libtraceevent-dev libbfd-dev gcc g++ \
    && rm -rf /var/lib/apt/lists/* 

# Build perf
RUN mkdir /perf && mkdir /src && cd /src && git clone --depth 1 --branch=$LINUX_KERNEL_VERSION git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git && \
    cd linux-stable/tools/perf && make O=/perf/ && rm -rf /src

# Run a typical workload, eg. compiling clang itself again
COPY build_scripts/build_${PROJECT}.sh build_${PROJECT}.sh
RUN chmod +x build_${PROJECT}.sh && sysctl kernel.perf_event_paranoid=-1 && /perf/perf record -e cycles:u -j any,u -- ./build_${PROJECT}.sh

RUN export MAJOR=$(echo $LLVM_VERSION | cut -f1 -d.)

# Merge profiling data
RUN cd stage3 && ../stage1/install/bin/perf2bolt ../stage2-prof-use-lto/install/bin/clang-$MAJOR -p perf.data -o clang-$MAJOR.fdata -w clang-$MAJOR.yaml

# Rebuild clang pgo here; can be used as drop-in replacement for stage2-prof-use-lto
RUN cd stage3 && ../stage1/install/bin/llvm-bolt \
    -o ../stage2-prof-use-lto/install/bin/clang-$MAJOR.bolt -b clang-$MAJOR.yaml \
    -reorder-blocks=ext-tsp -reorder-functions=hfsort+ -split-functions \
    -split-all-cold -dyno-stats -icf=1 -use-gnu-stack