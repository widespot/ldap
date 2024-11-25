ARG DEBIAN_VERSION="12.7"
ARG OPENLDAP_VERSION="2.6.8"
ARG BASE_IMAGE

FROM ${BASE_IMAGE:-ghcr.io/widespot/ldap:${OPENLDAP_VERSION}-deb${DEBIAN_VERSION}-build} AS build

RUN rm /usr/local/etc/openldap/slapd.ldif \
  && rm /usr/local/etc/openldap/slapd.conf

FROM debian:${DEBIAN_VERSION}-slim

COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /usr/local/etc /usr/local/etc
COPY --from=build /usr/local/include /usr/local/include
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /usr/local/libexec /usr/local/libexec
COPY --from=build /usr/local/sbin /usr/local/sbin
COPY --from=build /usr/local/share/man /usr/local/share/man

# openssl: required for TLS certificate generation
# libltdl7: required after "--enable-modules" was added in ./configure
RUN apt-get -y update \
    && apt-get install --no-install-recommends -y openssl libltdl7 \
    && rm -rf /var/lib/apt/lists/*

# Create run directories
RUN mkdir -p /data \
    && mkdir -p /usr/local/var/run/ \
    && mkdir -p /usr/local/etc/slapd.d \
    && mkdir -p /usr/local/etc/certs

WORKDIR /

COPY entrypoint.sh entrypoint.sh
COPY config.sh config.sh

RUN chmod +x entrypoint.sh && chmod +x config.sh

ENTRYPOINT ["./entrypoint.sh"]
