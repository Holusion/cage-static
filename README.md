


# Build

## Prerequisites: multi-platform builder

The build command uses `--platform linux/amd64,linux/arm64,linux/arm/v7` with a local file output. The default `docker` builder driver does **not** support this — it only builds for the host platform and cannot export multi-platform results to `type=local`. You will get:

```
ERROR: failed to build: Multi-platform build is not supported for the docker driver.
Switch to a different driver, or turn on the containerd image store, and try again.
```

Create a one-time builder using the `docker-container` driver (which runs BuildKit in a container and supports multi-platform + local export):

```bash
docker buildx create --name multiarch --driver docker-container --use
docker buildx inspect --bootstrap   # pulls the BuildKit image and starts the container
```

To verify cross-arch emulation is available (required for arm64/armhf builds on an amd64 host):

```bash
docker run --rm --privileged tonistiigi/binfmt --install all
```

You only need to do the above once. After that, and on subsequent sessions, just make sure the builder is selected:

```bash
docker buildx use multiarch
```

## Build command

```bash
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 --output=type=local,dest=dist .
mv dist/linux_amd64/cage dist/cage-amd64
mv dist/linux_arm64/cage dist/cage-arm64
mv dist/linux_arm_v7/cage dist/cage-armhf
```

# Runtime dependencies

The cage binary is built with as many static libraries as possible (`default_library = 'static'`, `prefer_static = 'true'`). However, some system libraries remain dynamically linked.

## Statically linked (built from source as meson subprojects)

See `subprojects/*.wrap` for the exact versions of the statically linked libraries built from source as meson subprojects. These are all statically linked into the cage binary, so no runtime dependencies on these libraries remain.

## Statically linked (system `.a` archives found at build time)

| Library | Version |
|---|---|
| libffi | 3.4.4 |
| libpciaccess | 0.17 |
| glib-2.0 | 2.74.6 |
| libpng | 1.6.39 |
| zlib | (bundled via libpng/pciaccess) |
| libpcre2-8 | (bundled via glib) |
| All xcb-* (xcb, xcb-dri3, xcb-present, xcb-render, xcb-renderutil, xcb-shm, xcb-xfixes, xcb-xinput, xcb-composite, xcb-ewmh, xcb-icccm, xcb-res) | 1.15 |
| libXau, libXdmcp | (bundled via xcb) |

## Dynamically linked (required at runtime on the target system)

These are the shared libraries the cage binary requires at runtime. They are identical across amd64, arm64, and armv7 (armv7 additionally requires `libgcc_s.so.1`).

### Direct dependencies

| Library | SONAME | Min version (from symbol versioning) | Debian 12 package |
|---|---|---|---|
| glibc | `libc.so.6`, `libm.so.6` | GLIBC_2.34 | `libc6` (>= 2.34) |
| Mesa EGL | `libEGL.so.1` | — | `libegl1` |
| Mesa GBM | `libgbm.so.1` | — | `libgbm1` |
| Mesa GLESv2 | `libGLESv2.so.2` | — | `libgles2` |
| Vulkan loader | `libvulkan.so.1` | — | `libvulkan1` |
| libudev | `libudev.so.1` | LIBUDEV_183 | `libudev1` (>= 183) |
| libsystemd | `libsystemd.so.0` | — | `libsystemd0` |
| libinput | `libinput.so.10` | LIBINPUT_1.19 | `libinput10` (>= 1.19) |

### Transitive dependencies (pulled in by the above)

These are not directly linked by cage, but required at runtime because the direct dependencies above load them:

| Library | Pulled in by |
|---|---|
| `libGLdispatch.so.0` | libEGL, libGLESv2 |
| `libdrm.so.2` | libgbm, libEGL |
| `libwayland-server.so.0` | libEGL, libgbm |
| `libexpat.so.1` | libwayland-server |
| `libmtdev.so.1` | libinput |
| `libevdev.so.2` | libinput |
| `libwacom.so.9` | libinput |
| `libffi.so.8` | libwayland-server |
| `libcap.so.2` | libsystemd |
| `libgcrypt.so.20` | libsystemd |
| `liblzma.so.5` | libsystemd |
| `libzstd.so.1` | libsystemd |
| `liblz4.so.1` | libsystemd |
| `libgpg-error.so.0` | libgcrypt |
| `libgudev-1.0.so.0` | libwacom |
| `libgobject-2.0.so.0` | libgudev |
| `libglib-2.0.so.0` | libgobject, libgudev |
| `libpcre2-8.so.0` | libglib |

### Runtime executable

| Program | Version | Notes |
|---|---|---|
| Xwayland | >= 22.1.9 | Spawned at runtime for X11 app support. |


# Test patches
To easily test existing patches and develop new ones, run :

```bash
export REF="v0.2.1"
if test -d cage; then
  cd cage
  git fetch origin "$REF"
  git checkout "$REF"
else
  git clone --filter=blob:none --branch "$REF" https://github.com/cage-kiosk/cage.git
cd cage
fi
git am ../patches/*.patch
```

# Patch development
To develop a new patch, start from a fresh clone with all patches applied (see above)

```bash
# from repo root, outputs patches numbered in the patches/ folder
rm -rf patches/*
(cd cage && git format-patch --output-directory ../patches $REF..HEAD --start-number 001)
```


# Maintenance & troubleshooting
- If a `git am` fails, inspect the failing patch with:

```bash
git am --show-current-patch=diff
```

Or to get more interactive context, try to apply the patch using `git apply --index "../patches/[...]"` and inspect the resulting index and working tree to understand the failure.


- If whitespace or trivial hunks cause failures, try `git am --3way --whitespace=nowarn` to allow three-way merges and ignore whitespace-only differences.


