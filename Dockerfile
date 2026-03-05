FROM debian:12-slim AS build
#debian 12 "bookworm" is required to have a recent-enough built-in meson.
# backports are required for a recent-enough libdrm

ENV DEBIAN_FRONTEND=noninteractive
ENV GIT_TERMINAL_PROMPT=0

# Install build tools
RUN  apt-get -qqy update \
  && apt-get -qqy --no-install-recommends install \
    git \
    ca-certificates \
    build-essential \
    cmake \
    pkgconf \
    ninja-build \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
  && rm -rf /var/lib/apt/lists/*

# Install meson from pip because wlroots tends to require an up to date version
RUN pip3 install --break-system-packages --no-cache-dir meson

# Wayland build-deps
# They are all wayland-scanner dependencies that are no longer required once the build completes
RUN  apt-get -qqy update \
&& apt-get -qqy --no-install-recommends install \
  libexpat1-dev \
  libffi-dev \
&& rm -rf /var/lib/apt/lists/*

# libdrm build dependencies
RUN  apt-get -qqy update \
&& apt-get -qqy --no-install-recommends install \
  libpciaccess-dev \
&& rm -rf /var/lib/apt/lists/*


# wlroots build-deps (https://packages.debian.org/source/bookworm/wlroots)
RUN  apt-get -qqy update \
&& apt-get -qqy --no-install-recommends install \
  libavformat-dev \
  libavcodec-dev \
  libcap-dev \
  libvulkan-dev \
  glslang-tools \
  libegl1-mesa-dev \
  libgbm-dev \
  libgles2-mesa-dev \
  libinput-dev \
  libpixman-1-dev \
  libpng-dev \
  libseat-dev \
  libsystemd-dev\
  libxcb1-dev \
  libxcb-composite0-dev \
  libxcb-dri3-dev \
  libxcb-icccm4-dev \
  libxcb-image0-dev \
  libxcb-present-dev \
  libxcb-render0-dev \
  libxcb-render-util0-dev \
  libxcb-res0-dev \
  libxcb-xfixes0-dev \
  libxcb-xinput-dev \
  libx11-xcb-dev \
  libxkbcommon-dev \
  hwdata \
  xwayland \
  libxcb-ewmh-dev \
&& rm -rf /var/lib/apt/lists/*

ARG CAGE_REPO="https://github.com/cage-kiosk/cage"
ARG CAGE_REF="v0.2.1"

RUN git clone --depth 1 --filter=blob:none --branch "${CAGE_REF}" "${CAGE_REPO}" "/cage"

WORKDIR /cage



COPY "subprojects" "/cage/subprojects"

COPY "patches" "/cage/patches"

# Copy build 
COPY "meson_options.ini" "/cage"
# Apply patches. We don't use meson's own patch mechanism because we also want to patch meson files.
RUN find "/cage/patches" -type f -name "*.patch" | sort | xargs git apply


RUN meson setup build --native-file meson_options.ini

RUN ninja -C build

FROM scratch
COPY --from=build /cage/build /
