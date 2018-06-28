#!/bin/bash

#.SYNOPSIS
# Check-IPAStatus.sh polls FreeIPA servers on specified domain and generates a JSON format output.

#.DESCRIPTION
# Check-IPAStatus.sh generates JSON displaying current FreeIPA reachability status for NTP, LDAP, and NIS services.

#.NOTES
# License: Unlicense / CCZero / WTFPL / Public Domain
# Author: Daniel Wood / https://github.com/danielewood
#
# Needed packages for CentOS:
# yum -y install ntpdate yp-tools openldap-clients bind-utils

#.LINK
# https://github.com/danielewood/misc/tree/master/shell

#.VERSION
# Version: 20180627

#.EXAMPLE
# user@host:~$ ./Check-IPAStatus.sh
#{
#   "date": "1530163266",
#   "nis domain": "mte.contoso.com",
#   "ipa domain": "contoso.com",
#   "server": {
#     "pegasi.mte.contoso.com": [
#        {"service": "NIS", "status": "online"},
#        {"service": "LDAP", "status": "online"},
#        {"service": "NTP", "status": "online"},
#        {"service": "NTP", "offset": "-0.000005"}
#     ],
#     "gamma.mte.contoso.com": [
#        {"service": "NIS", "status": "online"},
#        {"service": "LDAP", "status": "online"},
#        {"service": "NTP", "status": "online"},
#        {"service": "NTP", "offset": "-0.000368"}
#     ]
#   }
#}


# User Defined Variables:
NIS_DOMAIN='mte.contoso.com'
IPA_DOMAIN='contoso.com'
IPA_BASE_DN='cn=users,cn=accounts,dc=mte,dc=contoso,dc=com'
TARGET_USER='sgeadmin' #Any valid username

# Begin Script
list=`host -t srv _ldap._tcp.$IPA_DOMAIN`; returncode=$?
list=`echo "$list" | awk -F' 389 ' '{print $2}'`
if [[ $returncode != 0 ]]; then
    echo "{
   \"date\": \"`date +%s`\",    
   \"nis domain\": \"$NIS_DOMAIN\",
   \"ipa domain\": \"$IPA_DOMAIN\",
   \"server\": \"unable to resolve\"
}"
    exit
fi
      
JSON="{
   \"date\": \"`date +%s`\",    
   \"nis domain\": \"$NIS_DOMAIN\",
   \"ipa domain\": \"$IPA_DOMAIN\",
   \"server\": {"

while read -r line; do
    server=`echo $line | sed 's/\.$//'`
    nis=`ypcat -d $NIS_DOMAIN -k passwd -h $server 2> /dev/null`; returncode=$?
    nis=`echo "$nis" | grep "$TARGET_USER $TARGET_USER" | awk -F':' '{print $2}'`
    if [[ $returncode = 0 ]]; then
        nisstatus='online'
    else
        nisstatus='offline'
    fi

    ldapsearch -x -h $server -b "uid=$TARGET_USER,$IPA_BASE_DN" &>1 /dev/null; returncode=$?
    if [[ $returncode = 0 ]]; then
        ldapstatus='online'
    else
        ldapstatus='offline'
    fi
    
    offset=`ntpdate -q $server 2>/dev/null`; returncode=$?
    offset=`echo "$offset" | grep stratum | awk -F', offset ' '{print $2}' | awk -F', delay ' '{print $1}'`
    if [[ $returncode = 0 ]]; then
        ntpstatus='online'
    else
        ntpstatus='offline'
    fi

JSON+="
     \"$server\": [
        {\"service\": \"NIS\", \"status\": \"$nisstatus\"},
        {\"service\": \"LDAP\", \"status\": \"$ldapstatus\"},
        {\"service\": \"NTP\", \"status\": \"$ldapstatus\"},
        {\"service\": \"NTP\", \"offset\": \"$offset\"}
     ],"

done <<< "$list"

JSON=`echo "$JSON" | sed '$ s/,$//'`
JSON+="
   }
}"
echo "$JSON"
exit 
