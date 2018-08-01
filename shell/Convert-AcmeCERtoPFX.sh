#/bin/bash

#.DESCRIPTION
# Convert-AcmeCERtoPFX.sh creates a Windows compatible PFX for each "acme.sh" generated Let's Encrypt Certificate.
# Output PFX filenames and Certificate Friendly Names are the same. They will be "Domain-StartDate-EndDate"

#.NOTES
# License: Unlicense / CCZero / WTFPL / Public Domain
# Author: Daniel Wood / https://github.com/danielewood

#.LINK
# https://github.com/danielewood/misc/tree/master/shell

#.VERSION
# Version: 20180731

#User Variables
CERT_HOME='~/.acme.sh/'
PFX_PASSWORD='P@S5W0rd!'

#Begin Script
CERT_HOME=`eval echo $CERT_HOME`
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color
while read -r config; do
	CERT_PATH="`echo $config | sed 's%/[^/]*$%%'`"
	[ ! -f $CERT_PATH/fullchain.cer ] && continue
	CERT_CN="`grep 'Le_Domain=' $config | awk -F\' '{print $2}'`"
	CERT_NOTBEFORE="$(date -d "`openssl x509 -in $CERT_PATH/$CERT_CN.cer -noout -text | grep 'Not Before:' | awk -F'Before: ' '{print $2}'`" +"%Y%m%d")"
	CERT_NOTAFTER="$(date -d "`openssl x509 -in $CERT_PATH/$CERT_CN.cer -noout -text | grep 'Not After :' | awk -F'After : ' '{print $2}'`" +"%Y%m%d")"
	CERT_FRIENDLYNAME="$CERT_CN-$CERT_NOTBEFORE-$CERT_NOTAFTER"

	printf "${BLUE}---${NC}\n"
	[ ! $CERT_NOTAFTER ] && printf "Could not evaluate certificate for {RED}$CERT_PATH/$CERT_CN.cer${NC}, skipping...\r\n" && continue
	[ -f $CERT_PATH/$CERT_FRIENDLYNAME.pfx ] && printf "${RED}$CERT_PATH/$CERT_FRIENDLYNAME.pfx${NC} already exists, skipping...\r\n" && continue

	openssl pkcs12 -inkey $CERT_PATH/$CERT_CN.key -in $CERT_PATH/$CERT_CN.cer -certfile $CERT_PATH/fullchain.cer -name $CERT_FRIENDLYNAME -export -out $CERT_PATH/$CERT_FRIENDLYNAME.pfx -password pass:"$PFX_PASSWORD"
	openssl pkcs12 -info -in $CERT_PATH/$CERT_FRIENDLYNAME.pfx -password pass:$PFX_PASSWORD -nokeys -clcerts 2>/dev/null grep '^subject='
	CERT_SANS="`openssl x509 -in $CERT_PATH/$CERT_CN.cer -noout -text | grep -A1 'Subject Alternative Name' | tail -1 | tr -d ' ' | sed 's/DNS:/\t/' | sed 's/\,DNS:/\r\n\t/g'`"

	echo "Friendly Name: $CERT_FRIENDLYNAME"
	echo "Common Name = $CERT_CN"
	[ "$CERT_SANS" ] && printf "Subject Alternative Names:\r\n$CERT_SANS\r\n"
	echo "Path to certificates: $CERT_PATH"
	echo "PFX is located at: `ls $CERT_PATH/$CERT_FRIENDLYNAME.pfx`"
	echo "`openssl x509 -in $CERT_PATH/$CERT_CN.cer -noout -text`" > $CERT_PATH/$CERT_FRIENDLYNAME.pfx.txt
done <<< "`grep -rl 'Le_Domain=' $CERT_HOME | grep '\.conf$'`"
