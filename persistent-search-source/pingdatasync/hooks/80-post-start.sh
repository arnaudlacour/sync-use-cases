#!/usr/bin/env sh
${VERBOSE} && set -x

# shellcheck source=/dev/null
test -f "${HOOKS_DIR}/pingcommon.lib.sh" && . "${HOOKS_DIR}/pingcommon.lib.sh"

wait-for localhost:${LDAP_PORT} -t 900 -- modrate --hostname pingdirectory --port ${LDAP_PORT}  --atttribute description --ratePerSecond 1 --entryDN "cn=user.[0-9],ou=People,dc=example,dc=com"