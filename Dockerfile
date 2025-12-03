# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble AS builder
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
    && apt-get install --no-install-recommends -y -q \
        # Packages needed to build PrusaSlicer from source.
        xdg-utils locales locales-all pcmanfm jq curl git bzip2 gpg-agent \
        unzip build-essential autoconf cmake texinfo \
        libgtk-3-dev libdbus-1-dev libwebkit2gtk-4.1-dev \
        libboost-system-dev libboost-thread-dev libboost-program-options-dev libboost-test-dev \
        libgl1 libglx-mesa0 \
        gnupg automake texinfo libtool wget libgmp-dev 

# build prusa-slicer from source
WORKDIR /opt/PrusaSlicer
RUN latestSlic3r=$(curl -SsL https://api.github.com/repos/prusa3d/PrusaSlicer/releases/latest | jq -r '.zipball_url') && wget ${latestSlic3r} -O /tmp/PrusaSlicer.zip \
  && unzip /tmp/PrusaSlicer.zip -d /tmp/extracted \
  && mv /tmp/extracted/* ./src \
  && rm /tmp/PrusaSlicer.zip && rmdir /tmp/extracted \
  && cd /opt/PrusaSlicer/src/deps \
  && mkdir build && cd build \
  && sed -i 's|https://gmplib.org/download|https://ftp.gnu.org/gnu|g' /opt/PrusaSlicer/src/deps/+GMP/GMP.cmake \
  && cmake .. -DDEP_WX_GTK3=ON && make 
  # && cd /opt/PrusaSlicer/src \
WORKDIR /opt/PrusaSlicer/src
RUN mkdir build && cd build \
  && cmake .. -DSLIC3R_STATIC=1 -DSLIC3R_GTK=3 -DSLIC3R_PCH=OFF -DCMAKE_PREFIX_PATH=$(pwd)/../deps/build/destdir/usr/local \
  && make -j4 \
  && cd /opt/PrusaSlicer \
  && rm -rf src/deps/build src/build/tests


FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble AS runtime

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="jamesjnadeau"

# title
ENV TITLE=PrusaSlicer \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    NO_GAMEPAD=true

# install packages
RUN \
  echo "**** add icon ****" && \
  curl -o \
    /usr/share/selkies/www/icon.png \
    https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/orcaslicer-logo.png && \
  echo "**** install packages ****" && \
  add-apt-repository ppa:xtradeb/apps && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install --no-install-recommends -y -q \
    firefox \
    gstreamer1.0-alsa \
    gstreamer1.0-gl \
    gstreamer1.0-gtk3 \
    gstreamer1.0-libav \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-qt5 \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    libgstreamer-plugins-bad1.0 \
    libwebkit2gtk-4.1-0 \
    libwx-perl \ 
  && printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /config/.cache \
    /config/.launchpadlib \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# make prints directory available easily
RUN echo "file:///prints prints" >> /config/.gtk-bookmarks

# copy in build prusa slicer
COPY --from=builder /opt/PrusaSlicer /opt/PrusaSlicer

# add local files
COPY /root /

# ports and volumes
EXPOSE 3001
# users home directory
VOLUME /config 
# storage for 3 models
VOLUME /prints
