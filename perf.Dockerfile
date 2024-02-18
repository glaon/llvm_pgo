FROM ubuntu:22.04 as perf-base

ARG LINUX_KERNEL_VERSION=v6.6.10

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y wget pkg-config \
    git curl make bison flex elfutils libelf-dev libdw-dev libaudit-dev xz-utils \
    systemtap-sdt-dev libunwind-dev libssl-dev libslang2-dev python3-dev libzstd-dev \
    libzstd-dev libbabeltrace-ctf-dev libcap-dev python3-setuptools libpfm4-dev \
    libperl-dev libtraceevent-dev libbfd-dev gcc g++ \
    && rm -rf /var/lib/apt/lists/* 

RUN mkdir /perf && mkdir /src && cd /src && git clone --depth 1 --branch=$LINUX_KERNEL_VERSION git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git && \
    cd linux-stable/tools/perf && make O=/perf/ && rm -rf /src

RUN /perf/perf --help