# Building Wren

Needs Docker, the webOS NDK (for the UI) and about 30 GB of disk; the first WebKit build takes a few hours.
Build outputs go to `~/webos-browser-build/` outside the repository.

```sh
git submodule update --init && third_party/patches/apply-kit-patches.sh
docker build -t webos-browser-build:1 docker/

# Engine: toolchain + Buildroot (WebKit with the softfp JIT; it also stages the engine once)
bash tools/build-softfp-jit.sh start          # detached; `status` shows progress

# Licences of the engine's packages, then (re)stage the engine with its libraries and licences
docker/run.sh 'make -C /build/buildroot O=/build/br-out BR2_EXTERNAL=/src/buildroot-external WPEB_SOFTFP_JIT=y legal-info'
docker/run.sh 'OUT=/src/build/engine-stage-jit/engine ENGINE_BUILD=/build/engine-build sh /src/tools/stage-engine.sh'

# UI app + engine → ipk
cd browser && ./build.sh webos                # build/webos-release/dist/org.sostk.wpebrowser_<version>_arm.ipk
```

- `STAGE_MESA=1` bundles Mesa (software rendering, +30 MB), `STAGE_GST_TOOLS=1` the GStreamer command-line tools.
- `./build.sh` alone builds and tests the UI on the desktop (`cmake --preset host-debug`, `ctest --preset host-debug`
  in `browser/`).
- Check a package against LG firmware images offline:
  `third_party/webos-native-app-kit/tools/fw-check.py --min-release 1.0.0 <ipk>` (needs the webosbrew firmware symbol
  inventory; see the kit's docs).

See [NOTES.md](../NOTES.md) for the toolchain details.

## Licences in the package

The ipk bundles open-source libraries under their own licences:
- the UI's (SDL, libwebp, libass, …): in the package's `licenses/` folder;
- the engine's (WebKit: LGPL-2.1+/BSD; GStreamer, GLib, libsoup, FFmpeg: LGPL; ICU, SQLite, and the rest of its
  Buildroot packages): in `engine/licenses/`, one folder per package with `manifest.csv` (package, version,
  licence, source). These come from Buildroot's `make … legal-info`, which `tools/stage-engine.sh` expects to
  have been run.

## GitHub Actions

`Build WPE engine` runs for relevant PRs/pushes on `ubuntu-24.04`. It can also
be started manually from Actions once the workflow is on the default branch.
Fork PRs may require a maintainer to approve the run.

There are three separately cached stages:

| Stage | Rebuilt when these inputs change |
|---|---|
| Toolchain | crosstool-NG/configuration or runner preparation |
| WebKit SDK | Toolchain key, Buildroot configuration/patches, extra headers or DRM adapter |
| Engine runtime | WebKit SDK key, `engine/`, `common/` or staging scripts |

Only exact cache keys are restored. A missing/evicted cache rebuilds that stage;
changes propagate to downstream keys. For example, an `engine/src` change reuses
the toolchain and WebKit, while a WebKit patch rebuilds the SDK and engine.
Each job summary records its input key and whether the result came from cache.
The WebKit SDK contains installed headers, libraries and host tools; it excludes
the intermediate object tree. All jobs use the same `/build` prefix.

Buildroot is pinned to `cdd3776b4ea728fdda5fcde708e25d0a092e6864` (WPE WebKit
2.50.5). The first run can take several hours. Logs are uploaded even on failure.
The `engine` artifact contains a tar archive preserving modes/symlinks and a
SHA-256 checksum. Its embedded `REVISION` records the commit that built it;
cached binaries can therefore carry an older revision with identical build inputs.

This is an engine runtime for SHM testing, not an IPK: the UI and webOS NDK
direct-presentation backend are not built here. The workflow neither deploys
to a TV nor publishes a release. Runner preparation removes preinstalled SDKs
only on disposable GitHub-hosted runners.
