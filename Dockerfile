# syntax=docker/dockerfile:1

# FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble
FROM ghcr.io/linuxserver/baseimage-selkies:alpine322

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
  echo "**** install packages ****" && \
    # Packages needed to build PrusaSlicer from source.
  apk add --no-cache \
    # locales locales-all
    xdg-utils pcmanfm jq curl git bzip2 gpg-agent \
    unzip build-base autoconf cmake texinfo \
    # libgtk-3-dev libdbus-1-dev libwebkit2gtk-4.1-dev \
    gtk+3.0-dev \
    #libboost-system-dev libboost-thread-dev libboost-program-options-dev libboost-test-dev \
    boost-dev dbus-dev \
    # libgl1 libglx-mesa0 \
    mesa-dev \
    gnupg automake texinfo libtool wget\
  && printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  rm -rf \
    /config/.cache \
    /config/.launchpadlib \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# build prusa-slicer from source
WORKDIR /opt/PrusaSlicer
RUN latestSlic3r=$(curl -SsL https://api.github.com/repos/prusa3d/PrusaSlicer/releases/latest | jq -r '.zipball_url') && wget ${latestSlic3r} -O /tmp/PrusaSlicer.zip \
  && unzip /tmp/PrusaSlicer.zip -d /tmp/extracted \
  && mv /tmp/extracted/* ./src \
  && rm /tmp/PrusaSlicer.zip && rmdir /tmp/extracted \
  && cd /opt/PrusaSlicer/src/deps \
  && mkdir build && cd build \
  && cmake .. -DDEP_WX_GTK3=ON && make \
  && cd /opt/PrusaSlicer/src \
  && mkdir build && cd build \
  && cmake .. -DSLIC3R_STATIC=1 -DSLIC3R_GTK=3 -DSLIC3R_PCH=OFF -DCMAKE_PREFIX_PATH=$(pwd)/../deps/build/destdir/usr/local \
  && make -j4 \
  && cd /opt/PrusaSlicer \
  && rm -rf src/deps/build src/build/tests

# make prints directory available easily
RUN echo "file:///prints prints" >> /config/.gtk-bookmarks


# add local files
COPY /root /

# ports and volumes
EXPOSE 3001
# users home directory
VOLUME /config 
# storage for 3 models
VOLUME /prints