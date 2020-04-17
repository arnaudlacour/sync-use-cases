#!/usr/bin/env sh
${VERBOSE} && set -x

# shellcheck source=/dev/null
test -f "${HOOKS_DIR}/pingcommon.lib.sh" && . "${HOOKS_DIR}/pingcommon.lib.sh"

wait-for pingdirectory:${LDAP_PORT}
wait-for localhost:${LDAP_PORT}

# waaaaaaaaitaminit
sleep 60

modrate \
    --hostname pingdirectory \
    --port ${LDAP_PORT} \
    --entryDN "cn=user.[0-9],ou=People,dc=example,dc=com" \
    --atttribute description \
    --ratePerSecond 1