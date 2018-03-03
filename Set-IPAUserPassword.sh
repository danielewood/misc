#!/bin/bash
# This script will:
# - enforce NTP time sync between IPA servers
# - reset a user's password
# - allow immediate use of network shares without user having to change their password again
# - reset their password expiration to 2037
# - verify NIS and IPA password replication between all three directory servers



IPA_DOMAIN='contoso.com'
NIS_DOMAIN='contoso.com'
IPA_SRV1='IPA1'
IPA_SRV2='IPA2'
IPA_SRV3='IPA3'
TIMESERVER='time.contoso.com'
DIR_MNGR_PASS='P@ssw0rd!'
IPA_BASE_DN='cn=users,cn=accounts,dc=contoso,dc=com'
SANITIZE_OUTPUT=1

sanitize_for_publication () {
  if [ $SANITIZE_OUTPUT = 1 ]; then
    echo "$1" | sed 's/YOURCOMPANY/CONTOSO/g' | sed 's/yourcompany/contoso/g' | sed 's/lastname/pruitt/g' | sed 's/Lastname/Pruitt/g'
  else
    echo "$1"
  fi
}

ipa_srv1=`echo $IPA_SRV1 | tr '[:upper:]' '[:lower:]'`
ipa_srv2=`echo $IPA_SRV2 | tr '[:upper:]' '[:lower:]'`
ipa_srv3=`echo $IPA_SRV3 | tr '[:upper:]' '[:lower:]'`

##################
### Set Colors ###
##################
red=`tput setaf 1;tput bold`
green=`tput setaf 2;tput bold`
yellow=`tput setaf 3;tput bold`
blue=`tput setaf 4;tput bold`
magenta=`tput setaf 5;tput bold`
cyan=`tput setaf 6;tput bold`
white=`tput setaf 7;tput bold`
reset=`tput sgr0`


OK_BOX="[`tput setaf 2`  OK  `tput sgr0`]"
FAIL_BOX="[`tput setaf 1` FAIL `tput sgr0`]"


#echo "$OK_BOX"
#echo "$FAIL_BOX"

####################################################################
### Check Input to make sure a username and password were passed ###
####################################################################
while getopts u:p: option
do
 case "${option}"
 in
 u) TARGET_USER=${OPTARG};;
 p) TARGET_USER_PASSWORD=${OPTARG};;
 esac
done

case ${TARGET_USER-} in '') echo "$0 $1 $2 $3 $4
${red}No username was entered.${reset}
Usage: ${green}$0 -u username -p 'pa\$\$word'${reset}" >&2; exit 1;; esac

case ${TARGET_USER_PASSWORD-} in '') echo "$0
${red}No password was entered.${reset}
Usage: ${green}$0 -u username -password 'pa\$\$word'${reset}" >&2; exit 1;; esac

if ! [[ $TARGET_USER_PASSWORD =~ ^[a-zA-Z] ]]; then echo "${red}Error:${reset} Password ${yellow}$TARGET_USER_PASSWORD${reset} does not begin with a letter" ; exit; fi
if [ ${#TARGET_USER_PASSWORD} -le 5 ]; then echo "${red}Error:${reset} Password ${yellow}$TARGET_USER_PASSWORD${reset} is too short" ; exit; fi

if [ $TARGET_USER_PASSWORD = 'random' ]; then
  TARGET_USER_PASSWORD="E4`< /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo`"
fi


###############################################################
### Check for clock skew and correct if more than 5 seconds ###
###############################################################
printf '%-59s' "Checking $IPA_SRV1 time sync:"
IPA_SRV1_OFFSET=999999
IPA_SRV1_OFFSET=`ntpdate -q $TIMESERVER 2> /dev/null | grep 'time server' | awk -F'offset ' '{print $2}' |  grep -E -o '[0-9]+\.[0-9]+' | awk -F'.' '{print $1}'`
if [ $IPA_SRV1_OFFSET -lt 5 ]; then
  echo "$OK_BOX"
else
  echo "$FAIL_BOX"
  echo "${red}WARNING: $IPA_SRV1 has clock skew greater than 5 seconds detected!${reset}"
  printf '%-59s' "Resyncing time on $IPA_SRV1..."
  SANITIZE=`sudo /sbin/service ntpd stop ; sudo /usr/sbin/ntpdate $TIMESERVER ; sudo /sbin/service ntpd start`
  if grep -q " offset " <<<"$SANITIZE"; then
    echo "$OK_BOX"
  else
    echo "$FAIL_BOX"
  fi
  sanitize_for_publication "$SANITIZE"
fi

#echo "$IPA_SRV1_OFFSET"



printf '%-59s' "Checking $IPA_SRV2 time sync:"
IPA_SRV2_OFFSET=999999
IPA_SRV2_OFFSET=`ntpdate -q $ipa_srv2.$IPA_DOMAIN 2> /dev/null | grep 'time server' | awk -F'offset ' '{print $2}' |  grep -E -o '[0-9]+\.[0-9]+' | awk -F'.' '{print $1}'`
if [ $IPA_SRV2_OFFSET -lt 5 ]; then
  echo "$OK_BOX"
else
  echo "$FAIL_BOX"
  echo "${red}WARNING: $IPA_SRV2 has clock skew greater than 5 seconds detected!${reset}"
  printf '%-59s' "Resyncing time on $IPA_SRV2..."
  SANITIZE=`ssh -t $ipa_srv2.$IPA_DOMAIN "sudo /sbin/service ntpd stop ; sudo /usr/sbin/ntpdate $TIMESERVER ; sudo /sbin/service ntpd start" 2> /dev/null`
  if grep -q " offset " <<<"$SANITIZE"; then
    echo "$OK_BOX"
  else
    echo "$FAIL_BOX"
  fi
  sanitize_for_publication "$SANITIZE"
fi

printf '%-59s' "Checking $IPA_SRV3 time sync:"
IPA_SRV3_OFFSET=999999
IPA_SRV3_OFFSET=`ntpdate -q $ipa_srv3.$IPA_DOMAIN 2> /dev/null | grep 'time server' | awk -F'offset ' '{print $2}' |  grep -E -o '[0-9]+\.[0-9]+' | awk -F'.' '{print $1}'`
if [ $IPA_SRV3_OFFSET -lt 5 ]; then
  echo "$OK_BOX"
else
  echo "$FAIL_BOX"
  echo "${red}WARNING: $IPA_SRV3 has clock skew greater than 5 seconds detected!${reset}"
  printf '%-59s' "Resyncing time on $IPA_SRV3..."
  SANITIZE=`ssh -t $ipa_srv3.$IPA_DOMAIN "sudo /sbin/service ntpd stop ; sudo /usr/sbin/ntpdate $TIMESERVER ; sudo /sbin/service ntpd start" 2> /dev/null`
  if grep -q " offset " <<<"$SANITIZE"; then
    echo "$OK_BOX"
  else
    echo "$FAIL_BOX"
  fi
  sanitize_for_publication "$SANITIZE"
fi

#exit 1

############################################################################
###  Login and Reset User's Password to the one passed from command line ###
############################################################################
echo $DIR_MNGR_PASS | kinit admin &> /dev/null
#ipa pwpolicy-show --user=$TARGET_USER
#ipa user-show $TARGET_USER
#ipa user-status $TARGET_USER

echo "Resetting ${green}$TARGET_USER${reset}'s password to '${green}$TARGET_USER_PASSWORD${reset}'"
SANITIZE=`echo $TARGET_USER_PASSWORD | ipa user-mod $TARGET_USER --password`
sanitize_for_publication "$SANITIZE"

######################################################################################################
### Function to encode URL in format so password with special characters will not cause exceptions ###
######################################################################################################
rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER)
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

##########################################################
### curl submit to self-service password reset portal. ###
### The reset portal will clear the flag requiring     ###
### a user to change their password on the next login. ###
##########################################################
CURL_OUTPUT=`curl "https://$ipa_srv1.$IPA_DOMAIN/ipa/session/change_password" --data "user=$TARGET_USER&old_password=$( rawurlencode "$TARGET_USER_PASSWORD" )&new_password=$( rawurlencode "$TARGET_USER_PASSWORD" )" 2> /dev/null`
CURL_STATUS=`echo "$CURL_OUTPUT" | grep '\<h1' | sed -e 's/<[^>]*>//g'`


echo "---------------------"
printf '%-59s' "Resetting Password on ($IPA_SRV1) Self-Service Reset Page:"
if [ "$CURL_STATUS" = "Password change successful" ]; then
  echo "$OK_BOX"
else
  echo "$FAIL_BOX"
  echo "${red}ERROR: `echo "$CURL_OUTPUT" | grep '\<strong' | sed -e 's/<[^>]*>//g'`${reset}"
  echo "${red}RAW CURL OUTPUT${reset}"
  echo "$CURL_OUTPUT"
  exit 1
fi
echo "---------------------"


#######################################################################################
### Create .ldif and submit to $IPA_SRV1 to change password expiration date to 2037 ###
#######################################################################################
# Set new expiration date for account
EXPDATE="20371231`date -u +%H%M%S`Z"

cat > /tmp/krbpasswordreset.ldif <<DELIM
dn: uid=$TARGET_USER,$IPA_BASE_DN
changetype: modify
replace: krbpasswordexpiration
krbpasswordexpiration: $EXPDATE

DELIM

printf '%-59s' "Setting New Kerberos Password Expiration on $IPA_SRV1:"
echo ""
SANITIZE=`ldapmodify -x -D "cn=directory manager" -vv -f /tmp/krbpasswordreset.ldif -w $DIR_MNGR_PASS -h $ipa_srv1.$IPA_DOMAIN 2> /dev/null`
sanitize_for_publication "$SANITIZE"

rm -f /tmp/krbpasswordreset.ldif

#ldapsearch -Y GSSAPI -b "$IPA_BASE_DN" | grep "uid\=$TARGET_USER" -A90 | sed -n '/#/q;p'

############################
### Check NIS Sync Status ###
#############################

echo "---------------------"
echo -n "Syncing IPA (NIS) Servers.."
x=60
while [ $x -gt 30 ]; do
  echo -n "."
  sleep 0.2s
  NIS_HASH_IPA_SRV1=`ypcat -d $NIS_DOMAIN -k passwd -h $ipa_srv1.$IPA_DOMAIN | grep "$TARGET_USER $TARGET_USER" | awk -F':' '{print $2}'` 2> /dev/null
  NIS_HASH_IPA_SRV2=`ypcat -d $NIS_DOMAIN -k passwd -h $ipa_srv2.$IPA_DOMAIN | grep "$TARGET_USER $TARGET_USER" | awk -F':' '{print $2}'` 2> /dev/null
  NIS_HASH_IPA_SRV3=`ypcat -d $NIS_DOMAIN -k passwd -h $ipa_srv3.$IPA_DOMAIN | grep "$TARGET_USER $TARGET_USER" | awk -F':' '{print $2}'` 2> /dev/null
  width=`expr $x - 29`
  x=`expr $x - 1`
  if [ "$NIS_HASH_IPA_SRV2" = "$NIS_HASH_IPA_SRV1" ] && [ "$NIS_HASH_IPA_SRV3" = "$NIS_HASH_IPA_SRV1" ]; then
    x=0
  fi
done
printf "%-${width}s"


# test error handling by uncommenting this:
# NIS_HASH_IPA_SRV1='fUJ.3an2UYVN6'


if [ "$NIS_HASH_IPA_SRV2" = "$NIS_HASH_IPA_SRV1" ] && [ "$NIS_HASH_IPA_SRV3" = "$NIS_HASH_IPA_SRV1" ]; then
  echo "$OK_BOX"
else
  echo "$FAIL_BOX"
  echo "${red}WARNING: NIS did not replicate in time, investigate IPA sync status${reset}"
  SANITIZE=`/usr/sbin/ipa-replica-manage -v list $ipa_srv1.$IPA_DOMAIN`
  sanitize_for_publication "$SANITIZE"
  echo "${yellow}Consider running the following command on $IPA_SRV2/$IPA_SRV3:${reset}"
  SANITIZE=`echo "ipa-replica-manage re-initialize --from $ipa_srv1.$IPA_DOMAIN"`
  sanitize_for_publication "$SANITIZE"
fi

echo "---------------------"
printf '%20s ' "User:"; echo $TARGET_USER
printf '%20s ' "$IPA_SRV1 Hash:"; echo -n "${green}$NIS_HASH_IPA_SRV1${reset}"; printf '%44s\n' "$OK_BOX";
printf '%20s ' "$IPA_SRV2 Hash:"; if [ "$NIS_HASH_IPA_SRV2" = "$NIS_HASH_IPA_SRV1" ]; then echo -n "${green}$NIS_HASH_IPA_SRV2${reset}"; printf '%44s\n' "$OK_BOX"; else echo -n "${red}$NIS_HASH_IPA_SRV2${reset}"; printf '%44s\n' "$FAIL_BOX"; fi
printf '%20s ' "$IPA_SRV3 Hash:"; if [ "$NIS_HASH_IPA_SRV3" = "$NIS_HASH_IPA_SRV1" ]; then echo -n "${green}$NIS_HASH_IPA_SRV3${reset}"; printf '%44s\n' "$OK_BOX"; else echo -n "${red}$NIS_HASH_IPA_SRV3${reset}"; printf '%44s\n' "$FAIL_BOX"; fi
echo "---------------------"





##############################
### Check LDAP Sync Status ###
##############################

echo -n "Syncing IPA (LDAP) Servers."
x=60
while [ $x -gt 30 ]; do
  echo -n "."
  sleep 0.2s
  KRB_EXP_IPA_SRV1=`ldapsearch -Y GSSAPI -b "uid=$TARGET_USER,$IPA_BASE_DN" -w $DIR_MNGR_PASS -h $ipa_srv1.$IPA_DOMAIN krbPasswordExpiration 2> /dev/null | grep 'krbPasswordExpiration\:' | awk -F'krbPasswordExpiration: ' '{print $2}'`
  KRB_EXP_IPA_SRV2=`ldapsearch -Y GSSAPI -b "uid=$TARGET_USER,$IPA_BASE_DN" -w $DIR_MNGR_PASS -h $ipa_srv2.$IPA_DOMAIN krbPasswordExpiration 2> /dev/null | grep 'krbPasswordExpiration\:' | awk -F'krbPasswordExpiration: ' '{print $2}'`
  KRB_EXP_IPA_SRV3=`ldapsearch -Y GSSAPI -b "uid=$TARGET_USER,$IPA_BASE_DN" -w $DIR_MNGR_PASS -h $ipa_srv3.$IPA_DOMAIN krbPasswordExpiration 2> /dev/null | grep 'krbPasswordExpiration\:' | awk -F'krbPasswordExpiration: ' '{print $2}'`
  width=`expr $x - 29`
  x=`expr $x - 1`
  if [ "$KRB_EXP_IPA_SRV1" = "$EXPDATE" ] && [ "$KRB_EXP_IPA_SRV2" = "$EXPDATE" ] && [ "$KRB_EXP_IPA_SRV3" = "$EXPDATE" ]; then
    x=0
  fi
done

# test error handling by uncommenting this:
#EXPDATE="5"

printf "%-${width}s"
if [ "$KRB_EXP_IPA_SRV1" = "$EXPDATE" ] && [ "$KRB_EXP_IPA_SRV2" = "$EXPDATE" ] && [ "$KRB_EXP_IPA_SRV3" = "$EXPDATE" ]; then
  echo "$OK_BOX"
else
  echo "$FAIL_BOX"
  echo "${red}WARNING: IPA did not replicate in time, investigate IPA sync status${reset}"
  SANITIZE=`/usr/sbin/ipa-replica-manage -v list $ipa_srv1.$IPA_DOMAIN`
  sanitize_for_publication "$SANITIZE"
  echo "---------------------"
  echo "${yellow}Consider running the following command on $IPA_SRV2/$IPA_SRV3:${reset}"
  SANITIZE=`echo "ipa-replica-manage re-initialize --from $ipa_srv1.$IPA_DOMAIN"`
  sanitize_for_publication "$SANITIZE"
fi

echo "---------------------"
printf '%21s' "User: "; echo "$TARGET_USER"
printf '%21s' "Target Expiration: "; echo "$EXPDATE"
printf '%21s' "$IPA_SRV1 Expiration: "; if [ "$KRB_EXP_IPA_SRV1" = "$EXPDATE" ]; then echo -n "${green}$KRB_EXP_IPA_SRV1${reset}"; printf '%42s\n' "$OK_BOX"; else echo -n "${red}$KRB_EXP_IPA_SRV1${reset}"; printf '%42s\n' "$FAIL_BOX"; fi
EXPDATE=$KRB_EXP_IPA_SRV1
printf '%21s' "$IPA_SRV2 Expiration: "; if [ "$KRB_EXP_IPA_SRV2" = "$EXPDATE" ]; then echo -n "${green}$KRB_EXP_IPA_SRV2${reset}"; printf '%42s\n' "$OK_BOX"; else echo -n "${red}$KRB_EXP_IPA_SRV2${reset}"; printf '%42s\n' "$FAIL_BOX"; fi
printf '%21s' "$IPA_SRV3 Expiration: "; if [ "$KRB_EXP_IPA_SRV3" = "$EXPDATE" ]; then echo -n "${green}$KRB_EXP_IPA_SRV3${reset}"; printf '%42s\n' "$OK_BOX"; else echo -n "${red}$KRB_EXP_IPA_SRV3${reset}"; printf '%42s\n' "$FAIL_BOX"; fi
echo "---------------------"
