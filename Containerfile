FROM ghcr.io/ublue-os/bluefin-dx:stable

COPY system_files /
COPY build_files /tmp
COPY build.sh /tmp/build.sh

RUN mkdir -p /var/lib/alternatives && \
    /tmp/build.sh && \
    ostree container commit
