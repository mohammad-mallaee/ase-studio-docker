# ASE Studio, gem5 and the RISC-V compiler in one image, used from a browser.
# Works for linux/amd64 and linux/arm64 (Apple Silicon).

ARG SIMULATOR_REF=main
ARG GEM5_REF=stable

########## Stage 1: compile gem5 (the slow part) ##########
FROM ubuntu:22.04 AS gem5-build
ARG GEM5_REF
ARG BUILD_JOBS=4

# Same packages as the course's utils/Linux/Ubuntu/gem5_dep.sh for Ubuntu 22,
# without the tools only needed for committing to gem5 or using its Tk GUI.
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential ca-certificates git m4 scons zlib1g-dev libprotobuf-dev \
      protobuf-compiler libprotoc-dev libgoogle-perftools-dev python3-dev \
      libboost-all-dev pkg-config

RUN git clone --depth 1 --branch "${GEM5_REF}" \
      https://github.com/cad-polito-it/gem5.git /gem5

# --ignore-style skips gem5's interactive git-hook prompt, which has no terminal
# to answer it here. Lower BUILD_JOBS if the compiler runs out of memory.
RUN cd /gem5 \
    && scons --ignore-style build/RISCV/gem5.opt -j"${BUILD_JOBS}" \
    && find build -type f ! -name gem5.opt -delete

########## Stage 2: what students actually download ##########
FROM ubuntu:22.04
ARG SIMULATOR_REF
ARG XPACK_VERSION=14.3.0-1

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git make python3 socat zlib1g libprotobuf23 \
      libgoogle-perftools4 libpython3.10 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 1000 student \
    && mkdir -p /opt/ase /data \
    && chown student:student /opt/ase /data
USER student

# ASE Studio refuses to start unless these are real Git checkouts on the
# expected branches, so they are kept as clones rather than copied files.
RUN git clone --branch "${SIMULATOR_REF}" --recurse-submodules \
      https://github.com/cad-polito-it/ase_riscv_gem5_sim.git /opt/ase/sim

# Tools go in the default locations from setup_default, so nothing needs
# configuring. A prebuilt compiler replaces hours of building riscv-gnu-toolchain.
RUN mkdir -p /opt/ase/sim/tools
COPY --from=gem5-build --chown=student:student /gem5 /opt/ase/sim/tools/gem5
RUN set -e; \
    case "$(uname -m)" in \
      x86_64) arch=x64 ;; \
      aarch64) arch=arm64 ;; \
      *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
    esac; \
    name="xpack-riscv-none-elf-gcc-${XPACK_VERSION}-linux-${arch}.tar.gz"; \
    url="https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v${XPACK_VERSION}/${name}"; \
    cd /tmp; \
    curl -fsSLO "${url}"; \
    curl -fsSLO "${url}.sha"; \
    sha256sum -c "${name}.sha"; \
    mkdir -p /opt/ase/sim/tools/riscv-toolchain; \
    tar -xzf "${name}" -C /opt/ase/sim/tools/riscv-toolchain --strip-components=1; \
    rm -f "${name}" "${name}.sha"

# Fail the build now, not on a student's machine, if a library is missing or
# the compiler rejects the flags ASE Studio uses.
RUN set -e; \
    cd /opt/ase/sim; \
    if ldd tools/gem5/build/RISCV/gem5.opt | grep "not found"; then exit 1; fi; \
    printf '.globl _start\n_start:\n  li a0, 0\n  li a7, 93\n  ecall\n' > /tmp/t.s; \
    tools/riscv-toolchain/bin/riscv-none-elf-gcc -march=rv32imafd_zicsr_zifencei \
      -mabi=ilp32d -mno-relax -nostdlib -o /tmp/t.elf /tmp/t.s; \
    rm -f /tmp/t.s /tmp/t.elf

COPY start.sh /opt/ase/start.sh

WORKDIR /opt/ase/sim
ENV ASE_STUDIO_HOST_ROOT=/opt/ase/sim
EXPOSE 8765
VOLUME /data
ENTRYPOINT ["bash", "/opt/ase/start.sh"]
