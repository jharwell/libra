FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive

################################################################################
# Bootstrap
################################################################################
RUN set -ex
RUN apt-get update && apt-get upgrade -y
RUN apt-get update && apt-get install dialog apt-utils -y
RUN apt-get update && apt-get install -y wget gpg curl && \
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | \
    gpg --dearmor -o /usr/share/keyrings/kitware-archive-keyring.gpg && \
    echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ noble main' > /etc/apt/sources.list.d/kitware.list && \
    apt-get update

################################################################################
# Add Compiler Repositories
################################################################################
# LLVM/Clang repository (Ubuntu 24.04 Noble only has 14+)
RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | \
    gpg --dearmor -o /usr/share/keyrings/llvm-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/noble/ llvm-toolchain-noble-17 main" > /etc/apt/sources.list.d/llvm-17.list && \
    echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/noble/ llvm-toolchain-noble-18 main" > /etc/apt/sources.list.d/llvm-18.list && \
    echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/noble/ llvm-toolchain-noble-19 main" > /etc/apt/sources.list.d/llvm-19.list && \
    echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/noble/ llvm-toolchain-noble-20 main" > /etc/apt/sources.list.d/llvm-20.list && \
    echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/noble/ llvm-toolchain-noble main" > /etc/apt/sources.list.d/llvm-latest.list && \
    apt-get update

################################################################################
# Install GCC/G++ versions 9-14
################################################################################
RUN apt-get update && apt-get install -y \
    gcc-9 g++-9 \
    gcc-10 g++-10 \
    gcc-11 g++-11 \
    gcc-12 g++-12 \
    gcc-13 g++-13 \
    gcc-14 g++-14

# Set up alternatives for gcc/g++
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 90 --slave /usr/bin/g++ g++ /usr/bin/g++-9 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100 --slave /usr/bin/g++ g++ /usr/bin/g++-10 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 110 --slave /usr/bin/g++ g++ /usr/bin/g++-11 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 120 --slave /usr/bin/g++ g++ /usr/bin/g++-12 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 130 --slave /usr/bin/g++ g++ /usr/bin/g++-13 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 140 --slave /usr/bin/g++ g++ /usr/bin/g++-14

################################################################################
# Install Clang/Clang++ versions 17-19
################################################################################
# Install each version separately to avoid python3-clang conflicts
# We use --no-install-recommends to skip python bindings
RUN apt-get update && apt-get install -y --no-install-recommends \
    clang-17 \
    clang++-17 \
    libc++-17-dev \
    libc++abi-17-dev \
    libclang-rt-17-dev \
    llvm-17 \
    llvm-17-tools \
    clang-tidy-17 \
    clang-format-17 \
    clang-tools-17


RUN apt-get update && apt-get install -y --no-install-recommends \
    clang-18 \
    clang++-18 \
    libc++-18-dev \
    libc++abi-18-dev \
    libclang-rt-18-dev \
    llvm-18 \
    llvm-18-tools \
    clang-tidy-18 \
    clang-format-18 \
    clang-tools-18

RUN apt-get update && apt-get install -y --no-install-recommends \
    clang-19 \
    clang++-19 \
    libc++-19-dev \
    libc++abi-19-dev \
    libclang-rt-19-dev \
    llvm-19 \
    llvm-19-tools \
    clang-tidy-19 \
    clang-format-19 \
    clang-tools-19


################################################################################
# Set up Clang alternatives
################################################################################
RUN for ver in 17 18 19; do \
        clang_lib_base="/usr/lib/llvm-$ver/lib/clang/$ver/lib"; \
        update-alternatives --install /usr/bin/clang clang /usr/bin/clang-$ver 90 --slave /usr/bin/clang++ clang++ /usr/bin/clang++-$ver; \
        if [ -d "$clang_lib_base/linux" ]; then \
            cd "$clang_lib_base" && \
            for triple in x86_64-pc-linux-gnu x86_64-unknown-linux-gnu x86_64-linux-gnu; do \
                if [ ! -e "$triple" ]; then \
                    ln -sf linux "$triple"; \
                fi \
            done \
        fi \
    done

################################################################################
# Install Intel oneAPI (icx/icpx) - Last few versions
################################################################################
# Add Intel oneAPI repository
RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | \
    gpg --dearmor -o /usr/share/keyrings/oneapi-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | \
    tee /etc/apt/sources.list.d/oneAPI.list && \
    apt-get update

# Install Intel oneAPI Base Toolkit (includes icx/icpx)
# Note: Versions may vary - check availability with: apt-cache search intel-oneapi-compiler
RUN apt-get update && apt-get install -y \
    intel-oneapi-compiler-dpcpp-cpp-2025.0

# Create symbolic links for easier access
RUN if [ -d "/opt/intel/oneapi/compiler/2025.0" ]; then \
        ln -sf /opt/intel/oneapi/compiler/2025.0/bin/icx /usr/local/bin/icx-2025.0 && \
        ln -sf /opt/intel/oneapi/compiler/2025.0/bin/icpx /usr/local/bin/icpx-2025.0; \
    fi

# Set default to latest version
RUN if [ -x "/usr/local/bin/icx-2025.0" ]; then \
        ln -sf /usr/local/bin/icx-2025.0 /usr/local/bin/icx && \
        ln -sf /usr/local/bin/icpx-2025.0 /usr/local/bin/icpx; \
    elif [ -d "/opt/intel/oneapi/compiler/latest" ]; then \
        ln -sf /opt/intel/oneapi/compiler/latest/bin/icx /usr/local/bin/icx && \
        ln -sf /opt/intel/oneapi/compiler/latest/bin/icpx /usr/local/bin/icpx; \
    fi

################################################################################
# Install LIBRA packages
################################################################################
# Core
RUN apt-get update && apt-get install -y \
    git \
    ssh \
    curl \
    make \
    cmake \
    git-extras \
    lintian \
    gcovr \
    lcov \
    python3-pip \
    file \
    graphviz \
    doxygen \
    cppcheck \
    cmake-format

RUN pip3 install --break-system-packages \
    sphinx \
    sphinx-rtd-theme \
    sphinx-argparse \
    sphinx-tabs \
    sphinx-last-updated-by-git \
    sphinxcontrib-doxylink \
    graphviz

################################################################################
# Environment Setup
################################################################################
# Add Intel oneAPI environment variables (for default version)
ENV ONEAPI_ROOT=/opt/intel/oneapi
ENV PATH="${ONEAPI_ROOT}/compiler/latest/bin:${PATH}"
ENV LD_LIBRARY_PATH="${ONEAPI_ROOT}/compiler/latest/lib:${LD_LIBRARY_PATH}"

# Cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Verify installations
RUN echo "=== Verification ===" && \
    gcc --version | head -1 && \
    g++ --version | head -1 && \
    clang --version | head -1 && \
    cmake --version | head -1 && \
    (icx --version 2>&1 | head -1 || echo "Intel icx not available") && \
    echo "=== Build complete ==="

WORKDIR /workspace
