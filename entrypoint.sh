#!/bin/bash

set -o errexit
set -o pipefail

if [ ! -f /.config ]; then
  ./config.sh
  touch /.config

  ETC_PATH=${ETC_PATH:-"/usr/local/etc"}
  CONFIG_DIR_PATH=${CONFIG_DIR_PATH:-"${ETC_PATH}/slapd.d"}

  if [ -d /seed ]; then
    echo "# Found a /seed directory. Start seed phase"
    for i in /seed/*.ldif; do
      if [ "$i" = "/seed/*.ldif" ]; then
        echo "  ... but no .ldif found there"
        break
      fi
      if [ ! -f "$i" ]; then
        echo " - skip $i"
      else
        case $i in
        *.add.ldif) C="/usr/local/sbin/slapadd -n 2 -F ${CONFIG_DIR_PATH} -l ${i}";;
        *.modify.ldif) C="/usr/local/sbin/slapmodify -n 2 -F ${CONFIG_DIR_PATH} -l ${i}";;
        *) continue;;
        esac
        echo " - ${C}... "
        $C
      fi
    done
    echo " => seed phase completed"
  else
    echo "# no /seed directory found. Skipping init seed phase "
  fi
  echo ""
fi

su root -c '/usr/local/libexec/slapd -h "ldap:/// ldaps:///" -F /usr/local/etc/slapd.d -d 0'
