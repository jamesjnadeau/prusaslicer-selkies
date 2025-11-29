# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

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
    # Packages needed to build PrusaSlicer from source.
    xdg-utils locales locales-all pcmanfm jq curl git bzip2 gpg-agent \
    unzip build-essential autoconf cmake texinfo \
    libgtk-3-dev libdbus-1-dev libwebkit2gtk-4.1-dev \
    # added to support/transition to debian
    libboost-system-dev libboost-thread-dev libboost-program-options-dev libboost-test-dev \
    libgl1 libglx-mesa0 \
    gnupg automake texinfo libtool wget\
    
  # echo "**** install orcaslicer from appimage ****" && \
  # if [ -z ${ORCASLICER_VERSION+x} ]; then \
  #   ORCASLICER_VERSION=$(curl -sX GET "https://api.github.com/repos/OrcaSlicer/OrcaSlicer/releases/latest" \
  #   | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  # fi && \
  # RELEASE_URL=$(curl -sX GET "https://api.github.com/repos/OrcaSlicer/OrcaSlicer/releases/latest"     | awk '/url/{print $4;exit}' FS='[""]') && \
  # DOWNLOAD_URL=$(curl -sX GET "${RELEASE_URL}" | awk '/browser_download_url.*Ubuntu2404/{print $4;exit}' FS='[""]') && \
  # cd /tmp && \
  # curl -o \
  #   /tmp/orca.app -L \
  #   "${DOWNLOAD_URL}" && \
  # chmod +x /tmp/orca.app && \
  # ./orca.app --appimage-extract && \
  # mv squashfs-root /opt/orcaslicer && \
  && localedef -i en_GB -f UTF-8 en_GB.UTF-8 && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
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


# add local files
COPY /root /

# ports and volumes
EXPOSE 3001
VOLUME /config