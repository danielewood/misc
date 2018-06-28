#!/bin/bash

#.SYNOPSIS
# Check-IPAStatus.sh polls FreeIPA servers on specified domain and generates a JSON format output.

#.DESCRIPTION
# Check-IPAStatus.sh generates JSON displaying current reachability status for NTP, LDAP, and NIS services.

#.NOTES
# License: Unlicense/CCZero/WTFPL/Public Domain
# Author: Daniel Wood / https://github.com/danielewood
#
# Needed packages for CentOS:
# yum -y install ntpdate yp-tools openldap-clients

#.LINK
# https://github.com/danielewood/misc/tree/master/shell

#.VERSION
# Version: 20180627

# User Variables:
NIS_DOMAIN='mte.contoso.com'
IPA_DOMAIN='mte.contoso.com'
IPA_BASE_DN='cn=users,cn=accounts,dc=mte,dc=contoso,dc=com'
TARGET_USER='sgeadmin'

# Begin Script
list=`host -t srv _ldap._tcp.$IPA_DOMAIN`; returncode=$?
list=`echo "$list" | awk -F' 389 ' '{print $2}'`
#list=`echo "$list" | grep -E 'elis'` 
#list=`echo "$list" | grep -E 'elis|aptos'` 
list=`echo "$list" | grep -v -E '^ipa'` 
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
        #echo "$server: NIS UP"
        nisstatus='online'
    else
        #echo "$server: NIS DN"
        nisstatus='offline'
    fi

    ldapsearch -x -h $server -b "uid=$TARGET_USER,$IPA_BASE_DN" &>1 /dev/null; returncode=$?
    if [[ $returncode = 0 ]]; then
        #echo "$server: LDAP UP"
        ldapstatus='online'
    else
        #echo "$server: LDAP DN"
        ldapstatus='offline'
    fi
    
    offset=`ntpdate -q $server 2>/dev/null`; returncode=$?
    offset=`echo "$offset" | grep stratum | awk -F', offset ' '{print $2}' | awk -F', delay ' '{print $1}'`
    if [[ $returncode = 0 ]]; then
        #echo "$server: TIME UP"
        ntpstatus='online'
    else
        #echo "$server: TIME DN"
        ntpstatus='offline'
    fi
    #echo "$server: OFFSET ${offset#-}"
    
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
