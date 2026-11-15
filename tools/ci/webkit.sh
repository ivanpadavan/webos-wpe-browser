#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

buildroot_revision=cdd3776b4ea728fdda5fcde708e25d0a092e6864

exec > >(tee /build/logs/webkit.log) 2>&1
tar -C /build -I zstd -xf /build/artifacts/toolchain.tar.zst
git init /build/buildroot
git -C /build/buildroot fetch --depth 1 https://github.com/buildroot/buildroot.git "$buildroot_revision"
git -C /build/buildroot checkout --detach FETCH_HEAD
[[ $(git -C /build/buildroot rev-parse HEAD) == "$buildroot_revision" ]]
mk() {
    make -C /build/buildroot O=/build/br-out BR2_EXTERNAL=/src/buildroot-external \
        WPEB_SOFTFP_JIT=y BR2_JLEVEL=4 "$@"
}
mk webos_browser_defconfig
# Limit cache growth on hosted runners and use the Buildroot source mirror first.
/build/buildroot/utils/config --file /build/br-out/.config \
    --set-str BR2_CCACHE_INITIAL_SETUP '--max-size=2G' \
    --set-str BR2_PRIMARY_SITE 'https://sources.buildroot.net'
mk olddefconfig
cp /build/br-out/.config /build/logs/buildroot.config
mk toolchain
# The project's 4.4 toolchain predates the dma-buf header used by WebKit's GBM code.
install -m 644 /src/toolchain/extra-headers/linux/dma-buf.h \
    /build/br-out/staging/usr/include/linux/dma-buf.h
mk
wk=/build/br-out/build/wpewebkit-2.50.5
test -f "$wk/.stamp_built"
grep -q 'supportsBGRAReadback' "$wk/Source/WebKit/WebProcess/WebPage/CoordinatedGraphics/AcceleratedSurface.cpp"
grep -q '^ENABLE_JIT:BOOL=ON' "$wk/CMakeCache.txt"
cp "$wk/CMakeCache.txt" /build/logs/webkit-CMakeCache.txt
mk legal-info
test -f /build/br-out/legal-info/manifest.csv
# Keep the installed SDK/runtime, not the large intermediate object tree.
# Absolute toolchain references remain valid because every job uses /build.
tar -C /build -I 'zstd -T2 -3' -cf /build/artifacts/webkit-sdk.tar.zst \
    br-out/host br-out/staging br-out/target br-out/legal-info br-out/.config
