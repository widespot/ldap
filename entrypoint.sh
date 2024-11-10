#!/bin/bash

set -o errexit
set -o pipefail

if [ ! -f /opt/slapd/.config ]; then
  ./config.sh
  touch /opt/slapd/.config
fi

ETC_PATH=${ETC_PATH:-"/usr/local/etc"}
CONFIG_DIR_PATH=${CONFIG_DIR_PATH:-"${ETC_PATH}/slapd.d"}

if [ -d /seed ]; then
  echo "# Found a /seed directory. Start seed phase"
  for i in /seed/*.ldif; do
    if [ ! -f "$i" ]; then
      echo " - skip $i"
    else
      C="/usr/local/sbin/slapadd -n 1 -F ${CONFIG_DIR_PATH} -l ${i}"
      echo " - ${C}... "
      /usr/local/sbin/slapadd -n 1 -F ${CONFIG_DIR_PATH} -l ${i}
    fi
  done
else
  echo "# no /seed directory found. Skipping init seed phase "
fi
echo ""

su root -c '/usr/local/libexec/slapd -F /usr/local/etc/slapd.d -d 0'
