#!/bin/bash
# run as root
# Adapted from: https://computingforgeeks.com/how-to-reset-freeipa-admin-password-as-root-user/

# Set your new password here:
PASS='khgriuonbsvilNuvbLKUHBIRLBVSRIPLVNIUSBUsEGdgsVPISBVER'

INSTANCE=$(find /etc/dirsrv/ -maxdepth 1 -type d -regex ".*slapd.*" | sed 's|/etc/dirsrv/slapd-||')
sudo /sbin/stop-dirsrv ${INSTANCE}
echo $INSTANCE
NEWDIRMGRPASS=$(sudo /usr/bin/pwdhash ${PASS})
cat "/etc/dirsrv/slapd-${INSTANCE}/dse.ldif" > "/etc/dirsrv/slapd-${INSTANCE}/dse.ldif.old"
# sed twice (N; and N;N;) to account for line wraps or not in the ldif
cat "/etc/dirsrv/slapd-${INSTANCE}/dse.ldif.old" | \
    sed -e '/nsslapd-rootpw/{ N;N; s|nsslapd-rootpw.*nsslapd|nsslapd-rootpw\nnsslapd| }' | \
    sed -e '/nsslapd-rootpw/{ N; s|nsslapd-rootpw.*nsslapd|nsslapd-rootpw\nnsslapd| }' | \
    sed -e "s|nsslapd-rootpw|nsslapd-rootpw\:\ ${NEWDIRMGRPASS}|" > "/etc/dirsrv/slapd-${INSTANCE}/dse.ldif"

/sbin/start-dirsrv ${INSTANCE}
ldapsearch -x -D "cn=directory manager" -w ${PASS} -s base -b "" "objectclass=*"
