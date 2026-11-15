#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

exec > >(tee /build/logs/engine.log) 2>&1
tar -C /build -I zstd -xf /build/artifacts/toolchain.tar.zst
tar -C /build -I zstd -xf /build/artifacts/webkit-sdk.tar.zst
SRC=/src BR=/build/br-out OUT=/build/engine-stage/engine \
    ENGINE_BUILD=/build/engine-build STAGE_MESA=0 sh /src/tools/stage-engine.sh
# Archive permissions and symlinks before uploading through Actions.
git -C /src rev-parse HEAD > /build/engine-stage/REVISION
cp /build/logs/input-keys.txt /build/engine-stage/BUILD-INFO
tar -C /build/engine-stage -I 'zstd -T2 -3' -cf /build/artifacts/wpe-engine-softfp.tar.zst .
