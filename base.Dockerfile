ARG DEBIAN_VERSION="12.7"
ARG OPENLDAP_VERSION="2.6.8"

FROM debian:${DEBIAN_VERSION}-slim
ARG OPENLDAP_VERSION

RUN apt-get update && apt-get install -y ca-certificates curl
RUN mkdir /opt/openldap ; mkdir -p /tmp/pkg/cache/ ; cd /tmp/pkg/cache/ ; \
    curl https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-${OPENLDAP_VERSION}.tgz -O ; \
    tar -zxf "openldap-${OPENLDAP_VERSION}.tgz" -C /opt/openldap --no-same-owner --strip-components=1
# gcc: required for ./configure
# libltdl-dev required for --enable-modules
RUN apt-get install -y gcc libltdl-dev
RUN apt-get install -y openssl libssl-dev
WORKDIR /opt/openldap

# ./configure --help
# SLAPD (Standalone LDAP Daemon) Options:
#   --enable-slapd          enable building slapd [yes]
#   --enable-dynacl         enable run-time loadable ACL support (experimental) [no]
#   --enable-aci            enable per-object ACIs (experimental) no|yes|mod [no]
#   --enable-cleartext      enable cleartext passwords [yes]
#   --enable-crypt          enable crypt(3) passwords [no]
#   --enable-spasswd        enable (Cyrus) SASL password verification [no]
#   --enable-modules        enable dynamic module support [no]
#   --enable-rlookups       enable reverse lookups of client hostnames [no]
#   --enable-slapi          enable SLAPI support (experimental) [no]
#   --enable-slp            enable SLPv2 support [no]
#   --enable-wrappers       enable tcp wrapper support [no]
#
# SLAPD Overlay Options:
#   --enable-overlays       enable all available overlays no|yes|mod
#   --enable-accesslog      In-Directory Access Logging overlay no|yes|mod [no]
#   --enable-auditlog       Audit Logging overlay no|yes|mod [no]
#   --enable-autoca         Automatic Certificate Authority overlay no|yes|mod [no]
#   --enable-collect        Collect overlay no|yes|mod [no]
#   --enable-constraint     Attribute Constraint overlay no|yes|mod [no]
#   --enable-dds            Dynamic Directory Services overlay no|yes|mod [no]
#   --enable-deref          Dereference overlay no|yes|mod [no]
#   --enable-dyngroup       Dynamic Group overlay no|yes|mod [no]
#   --enable-dynlist        Dynamic List overlay no|yes|mod [no]
#   --enable-homedir        Home Directory Management overlay no|yes|mod [no]
#   --enable-memberof       Reverse Group Membership overlay no|yes|mod [no]
#   --enable-otp            OTP 2-factor authentication overlay no|yes|mod [no]
#   --enable-ppolicy        Password Policy overlay no|yes|mod [no]
#   --enable-proxycache     Proxy Cache overlay no|yes|mod [no]
#   --enable-refint         Referential Integrity overlay no|yes|mod [no]
#   --enable-remoteauth     Deferred Authentication overlay no|yes|mod [no]
#   --enable-retcode        Return Code testing overlay no|yes|mod [no]
#   --enable-rwm            Rewrite/Remap overlay no|yes|mod [no]
#   --enable-seqmod         Sequential Modify overlay no|yes|mod [no]
#   --enable-sssvlv         ServerSideSort/VLV overlay no|yes|mod [no]
#   --enable-syncprov       Syncrepl Provider overlay no|yes|mod [yes]
#   --enable-translucent    Translucent Proxy overlay no|yes|mod [no]
#   --enable-unique         Attribute Uniqueness overlay no|yes|mod [no]
#   --enable-valsort        Value Sorting overlay no|yes|mod [no]

#  --enable-autoca=mod requires --with-tls=openssl
RUN ./configure \
    --with-tls=openssl \
    --enable-modules=yes \
    --enable-overlays=mod

RUN apt-get install -y build-essential
RUN make depend

RUN apt-get install -y groff-base
RUN make
RUN su root -c 'make install'
