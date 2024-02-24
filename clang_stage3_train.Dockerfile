ARG LLVM_VERSION
ARG PROJECT

FROM clang_stage2_pgo_lto:${PROJECT}_${LLVM_VERSION} as stage3-bolt

ARG LINUX_KERNEL_VERSION=v6.6.10
ARG PROJECT

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