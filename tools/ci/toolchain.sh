#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

ctng_version=1.27.0
ctng_sha512=2201106561a199ebaddd238ed5158f62f63787333b87d2692aa726ad21bc90b08483deed7257fc35af995e355cfb567d7550b5ea171259ec5a0e0c3bee3b3ca2

mkdir -p /build/ctng /build/tarballs
cd /build/ctng
exec > >(tee /build/logs/toolchain.log) 2>&1
curl --fail --location --retry 3 --connect-timeout 30 \
    "https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-$ctng_version/crosstool-ng-$ctng_version.tar.xz" \
    -o ctng.tar.xz
printf '%s  ctng.tar.xz\n' "$ctng_sha512" | sha512sum --check
tar -xf ctng.tar.xz
cd "crosstool-ng-$ctng_version"
./configure --prefix=/build/ctng-install
make -j4
make install
mkdir /build/ctng-config
cd /build/ctng-config
cp /src/toolchain/ct-ng.defconfig .config
/build/ctng-install/bin/ct-ng olddefconfig
cp .config /build/logs/toolchain.config
/build/ctng-install/bin/ct-ng build.4
/build/x-tools/arm-webos-linux-gnueabi/bin/arm-webos-linux-gnueabi-gcc --version
tar -C /build -I 'zstd -T2 -3' -cf /build/artifacts/toolchain.tar.zst x-tools
