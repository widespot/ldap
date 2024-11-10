#!/bin/bash

set -e

ETC_PATH=${ETC_PATH:-"/usr/local/etc"}
VAR_PATH=${VAR_PATH:-"/usr/local/var"}

CONFIG_LDIF_FILE_PATH=${CONFIG_LDIF_FILE_PATH:-"${ETC_PATH}/openldap/slapd.ldif"}
CONFIG_KV_FILE_PATH=${CONFIG_KV_FILE_PATH:-"${ETC_PATH}/openldap/slapd.conf"}
CONFIG_DIR_PATH=${CONFIG_DIR_PATH:-"${ETC_PATH}/slapd.d"}
SEED_LDIF_DIR_PATH=${SEED_LDIF_DIR_PATH:-"/seed"}

OLC_DB_MAX_SIZE=${OLC_DB_MAX_SIZE:-"1073741824"}
OLC_SUFFIX=${OLC_SUFFIX:-"dc=example,dc=com"}
OLC_ROOT_DN=${OLC_ROOT_DN:-"cn=admin,${OLC_SUFFIX}"}
OLC_ROOT_PASSWORD=${OLC_ROOT_PASSWORD:-"password"}
OLC_DB_DIRECTORY=${OLC_DB_DIRECTORY:-"/data"}
OLC_ARGS_FILE=${OLC_ARGS_FILE:-"${VAR_PATH}/run/slapd.args"}
OLC_PID_FILE=${OLC_PID_FILE:-"${VAR_PATH}/run/slapd.pid"}
OLS_MONITORING=${OLS_MONITORING:-"FALSE"}

TLS_CA_CERT_FILE_PATH=${TLS_CA_CERT_FILE_PATH:-"${ETC_PATH}/openldap/ca.crt.pem"}
TLS_CA_CERT_KEY_FILE_PATH=${TLS_CA_CERT_KEY_FILE_PATH:-"${ETC_PATH}/openldap/ca.key.pem"}
TLS_CERT_FILE_PATH=${TLS_CERT_FILE_PATH:-"${ETC_PATH}/openldap/server.crt.pem"}
TLS_CERT_KEY_FILE_PATH=${TLS_CERT_KEY_FILE_PATH:-"${ETC_PATH}/openldap/server.key.pem"}
TLS_CERT_CSR_FILE_PATH=${TLS_CERT_CSR_FILE_PATH:-"${ETC_PATH}/openldap/server.csr.pem"}
TLS_CERT_COUNTRY="BE"
TLS_CERT_STATE="Brussels"
TLS_CERT_CITY="Brussels"
TLS_CERT_COMPANY="Example"
TLS_CERT_ORGANIZATION_UNIT="IT"
TLS_CERT_COMMON_NAME="example.com"

CONFIGURE_BASIC_ACL=${CONFIGURE_BASIC_ACL:-"1"}
BUILTIN_MODULES=${BUILTIN_MODULES:=""}
BUILTIN_SCHEMAS=${BUILTIN_SCHEMAS:=""}

echo "# Check TLS cert files ..."
echo " - ${TLS_CA_CERT_FILE_PATH}: $([ -f "${TLS_CA_CERT_FILE_PATH}" ] && echo -n "ok" || echo -n "missing")"
echo " - ${TLS_CERT_KEY_FILE_PATH}: $([ -f "${TLS_CERT_KEY_FILE_PATH}" ] && echo -n "ok" || echo -n "missing")"
echo " - ${TLS_CERT_FILE_PATH}: $([ -f "${TLS_CERT_FILE_PATH}" ] && echo -n "ok" || echo -n "missing")"
if [ ! -f "${TLS_CA_CERT_FILE_PATH}" ] && [ ! -f "${TLS_CERT_FILE_PATH}" ] && [ ! -f "${TLS_CERT_KEY_FILE_PATH}" ]; then
  echo " => none provided, will generate self-signed cert bundle"
  echo ""
  echo "# Generate the files for TLS encryption ..."

  echo -n " - CA private key (${TLS_CA_CERT_KEY_FILE_PATH}) ..."
  openssl genrsa 2048 > "${TLS_CA_CERT_KEY_FILE_PATH}"
  echo " done!"

  SUBJECT="/C=${TLS_CERT_COUNTRY}/ST=${TLS_CERT_STATE}/L=${TLS_CERT_CITY}/O=${TLS_CERT_COMPANY}/OU=${TLS_CERT_ORGANIZATION_UNIT}/CN=${TLS_CERT_COMMON_NAME}"
  echo -n " - CA cert (${TLS_CA_CERT_FILE_PATH}) for ${SUBJECT} ..."
  openssl req -new -x509 -nodes -days 365000 \
    -key "${TLS_CA_CERT_KEY_FILE_PATH}" \
    -out "${TLS_CA_CERT_FILE_PATH}" \
    -subj "${SUBJECT}"
  echo " done!"

  echo -n " - Server private key (${TLS_CERT_KEY_FILE_PATH}) ..."
  openssl genrsa 2048 > "${TLS_CERT_KEY_FILE_PATH}"
  echo " done!"

  echo -n " - Server signing request (${TLS_CERT_CSR_FILE_PATH}) for ${SUBJECT} ..."
  openssl req -new \
    -key "${TLS_CERT_KEY_FILE_PATH}" \
    -out "${TLS_CERT_CSR_FILE_PATH}" \
    -subj "${SUBJECT}"
  echo " done!"
  echo -n " - Server certificate (${TLS_CERT_FILE_PATH}) ..."
  openssl x509 -req -days 365000 -set_serial 01 \
     -in "${TLS_CERT_CSR_FILE_PATH}" \
     -out "${TLS_CERT_FILE_PATH}" \
     -CA "${TLS_CA_CERT_FILE_PATH}" \
     -CAkey "${TLS_CA_CERT_KEY_FILE_PATH}" 2> /dev/null
  echo " done!"

elif [ ! -f "${TLS_CA_CERT_FILE_PATH}" ] || [ ! -f "${TLS_CERT_FILE_PATH}" ] || [ ! -f "${TLS_CERT_KEY_FILE_PATH}" ]; then
  echo " Error, either provide them all or none"
  exit 1
else
  echo " all certificate files provided"
fi

echo ""

if [ -f "$CONFIG_LDIF_FILE_PATH" ]; then
  echo "# slapd configuration ... using existing LDIF file '$CONFIG_LDIF_FILE_PATH'"
  CONFIG_ARG=-l
  CONFIG_FILE_PATH=$CONFIG_LDIF_FILE_PATH
elif [ -f "$CONFIG_KV_FILE_PATH" ]; then
  echo "# slapd configuration ... using existing legacy key/value file '$CONFIG_KV_FILE_PATH'"
  CONFIG_ARG=-F
  CONFIG_FILE_PATH=$CONFIG_KV_FILE_PATH
else
  echo "# slapd configuration ... No slapd file found. Will generate '$CONFIG_LDIF_FILE_PATH' based on environment variable"
  CONFIG_ARG=-l
  CONFIG_FILE_PATH=$CONFIG_LDIF_FILE_PATH

  # Generate the .ldif file
  cat >> $CONFIG_LDIF_FILE_PATH << EOF
#
# Global config
#
dn: cn=config
objectClass: olcGlobal
cn: config
#
olcArgsFile: ${OLC_ARGS_FILE}
olcPidFile: ${OLC_PID_FILE}
olcTLSCACertificateFile: ${TLS_CA_CERT_FILE_PATH}
olcTLSCertificateFile: ${TLS_CERT_FILE_PATH}
olcTLSCertificateKeyFile: ${TLS_CERT_KEY_FILE_PATH}


EOF

  echo " - load core schema"
  cat >> $CONFIG_LDIF_FILE_PATH << EOF
#
# Schema root configuration
#
dn: cn=schema,cn=config
objectClass: olcSchemaConfig
cn: schema

include: file://${ETC_PATH}/openldap/schema/core.ldif
EOF

  if [ ! -z "${BUILTIN_SCHEMAS}" ]; then
    echo " - load extra builtin schemas"
    for str in ${BUILTIN_SCHEMAS//,/ } ; do
      SCHEMA_PATH="${ETC_PATH}/openldap/schema/${str}.ldif"
      echo "   - ${SCHEMA_PATH}"
      echo "include: file://${SCHEMA_PATH}" >> $CONFIG_LDIF_FILE_PATH
    done
  fi
  echo "" >> $CONFIG_LDIF_FILE_PATH
  echo "" >> $CONFIG_LDIF_FILE_PATH

  cat >> $CONFIG_LDIF_FILE_PATH << EOF
#
# Frontend DB configuration
#
dn: olcDatabase=frontend,cn=config
objectClass: olcDatabaseConfig
objectClass: olcFrontendConfig
#
olcDatabase: frontend
EOF

  if [ "1" = "${CONFIGURE_BASIC_ACL}" ]; then
    cat >> $CONFIG_LDIF_FILE_PATH << EOF
olcAccess: to dn.base="" by * read
olcAccess: to dn.base="cn=Subschema" by * read
olcAccess: to *
  by anonymous auth
  by * none


EOF
  else
    echo "\n\n" >> $CONFIG_LDIF_FILE_PATH
  fi

  cat >> $CONFIG_LDIF_FILE_PATH << EOF
#
# Main DB configuration
#
dn: olcDatabase=mdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMdbConfig
#
olcDatabase: mdb
olcDbMaxSize: ${OLC_DB_MAX_SIZE}
olcSuffix: ${OLC_SUFFIX}
olcRootDN: ${OLC_ROOT_DN}
# Cleartext passwords, especially for the rootdn, should
# be avoided.  See slappasswd(8) and slapd-config(5) for details.
# Use of strong authentication encouraged.
olcRootPW: ${OLC_ROOT_PASSWORD}
# The database directory MUST exist prior to running slapd AND
# should only be accessible by the slapd and slap tools.
# Mode 700 recommended.
olcDbDirectory: ${OLC_DB_DIRECTORY}
# Indices to maintain
olcDbIndex: objectClass eq


EOF

  echo " - disable monitoring"
  cat >> $CONFIG_LDIF_FILE_PATH << EOF
#
# Monitoring db configuration
#
dn: olcDatabase=monitor,cn=config
objectClass: olcDatabaseConfig
#
olcDatabase: monitor
olcRootDN: cn=config
olcMonitoring: FALSE


EOF

  if [ ! -z "${BUILTIN_MODULES}" ]; then
    echo " - load builtin modules"
    cat >> $CONFIG_LDIF_FILE_PATH << EOF
#
# Built in modules
#
dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
#
olcModulePath: /usr/local/libexec/openldap
EOF
    for str in ${BUILTIN_MODULES//,/ } ; do
      echo "   - /usr/local/libexec/openldap/${str}.la"
      echo "olcModuleLoad: ${str}.la" >> $CONFIG_LDIF_FILE_PATH
    done
    echo "" >> $CONFIG_LDIF_FILE_PATH
    echo "" >> $CONFIG_LDIF_FILE_PATH
  fi
fi

COMMAND="/usr/local/sbin/slapadd -n 0 -F ${CONFIG_DIR_PATH} ${CONFIG_ARG} ${CONFIG_FILE_PATH}"
echo -n " => Will execute the following command as root: \`$COMMAND\`"
su root -c "$COMMAND"
echo ""
