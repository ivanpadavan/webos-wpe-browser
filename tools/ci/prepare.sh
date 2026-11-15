#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

# Never remove tools from a developer machine or a self-hosted runner.
[[ ${GITHUB_ACTIONS:-} == true && ${RUNNER_ENVIRONMENT:-} == github-hosted ]]
sudo rm -rf /usr/local/lib/android /usr/share/dotnet /opt/ghc /usr/local/.ghcup
sudo mkdir -p /build
sudo chown "$(id -u):$(id -g)" /build
sudo ln -s "$GITHUB_WORKSPACE" /src
mkdir -p /build/logs /build/artifacts
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    build-essential cmake ninja-build meson pkg-config bison flex gperf \
    help2man texinfo libtool libtool-bin autoconf automake gawk libncurses-dev \
    python3 python3-dev python3-venv unzip wget curl ca-certificates rsync bc \
    file patch perl cpio git ruby unifdef xz-utils bzip2 lzip zstd gettext \
    patchelf libssl-dev
df -h /build
available_kb=$(df -Pk /build | awk 'NR == 2 {print $4}')
(( available_kb >= 30 * 1024 * 1024 )) || {
    echo 'At least 30 GiB free is required for this build.' >&2
    exit 1
}
