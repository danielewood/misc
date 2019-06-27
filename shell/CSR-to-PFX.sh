#!/bin/bash
COMPANY_NAME="CompanyName, LLC"
COMMON_NAME="test.ttl.one"

# Remove non-alphanumeric character from Company Name
COMPANY_NAME=$(echo "$COMPANY_NAME" | tr -cd '[[:space:]][:alnum:]-' | sed -e 's/[[:space:]]*$//')

ALIAS_NAME="$(echo "$COMMON_NAME" | sed 's/\*/wildcard/' | sed 's/\./_/g' | tr -cd '[[:space:]][:alnum:]-_')-$(date +%Y%m%d)"

if [ ! -f "$ALIAS_NAME-password.txt" ]; then
  KEYSTORE_PASS=$(sha256sum /dev/stdin <<<$(dd if=/dev/urandom bs=512 count=100 2>/dev/null) | awk '{print $1}')
  echo "$KEYSTORE_PASS" > "$ALIAS_NAME-password.txt"
else
  KEYSTORE_PASS=$(cat "$ALIAS_NAME-password.txt")
fi

CSR_FILE="$ALIAS_NAME.csr"
P12_FILE="$ALIAS_NAME.p12"
PEM_FILE="$ALIAS_NAME.pem"
CER_FILE="$ALIAS_NAME.cer"
KEY_FILE="$ALIAS_NAME.key"
BUNDLE_PEM_FILE="$ALIAS_NAME-bundle.pem"
FULLCHAIN_CER_FILE="$ALIAS_NAME-fullchain.cer"
TEXT_FILE="$ALIAS_NAME-text.txt"

if [ ! -f "$P12_FILE" ]; then
  keytool -genkey -keyalg RSA -keysize 2048 \
    -alias "$ALIAS_NAME" \
    -dname "CN=$COMMON_NAME,OU=Information Technology, O=$COMPANY_NAME, L=San Diego, ST=California, C=US" \
    -storepass "$KEYSTORE_PASS" \
    -keypass "$KEYSTORE_PASS" \
    -destkeystore "$P12_FILE" \
    -deststoretype pkcs12
fi

if [ ! -f "$CSR_FILE" ]; then
  keytool -certreq \
    -alias "$ALIAS_NAME" \
    -keystore "$P12_FILE" \
    -storepass "$KEYSTORE_PASS" \
    -keypass "$KEYSTORE_PASS" \
    -file "$CSR_FILE"
  # Remove NEW keyword since it causes LE to error: https://community.letsencrypt.org/t/error-parsing-certificate-request-resolved/40039/2
  sed -i 's/NEW CERTIFICATE/CERTIFICATE/' "$CSR_FILE"
fi

if [ ! -f "$CER_FILE" ]; then
  echo "### Send CSR ($CSR_FILE) to the signing authority ###"
  openssl req -in "$CSR_FILE" -noout -subject
  cat "$CSR_FILE"
  echo "Waiting for CER from Signing Authority, exiting..."
  echo "### Send CSR ($CSR_FILE) to the signing authority ###"
  exit 1
else
  count=0
  URL=$(openssl x509 -in "$CER_FILE" -noout -text | grep 'CA Issuers - URI:' | awk -F'URI:' '{print $2}' | head -1)

  while true;
  do
    CA_COUNT="/tmp/temp-ca-chain.$count"
    curl -L $URL 2>/dev/null |openssl pkcs7 -inform der > $CA_COUNT 2>/dev/null || \
    curl -L $URL 2>/dev/null | openssl x509 -inform der > $CA_COUNT 2>/dev/null

    let "count++"
    echo $URL
    URL=$(openssl x509 -in $CA_COUNT -noout -text | grep 'CA Issuers - URI:' | awk -F'URI:' '{print $2}' | head -1)
    [ -z $URL ] && break
  done

  cat "$CER_FILE" | openssl x509 -subject > "$FULLCHAIN_CER_FILE"

  for TEMP_CER_FILE in $(find /tmp/ -name 'temp-ca-chain.*' -type f | sort -rV)
  do
    cat "$TEMP_CER_FILE" | openssl x509 -subject >> "$FULLCHAIN_CER_FILE"
    rm "$TEMP_CER_FILE"
  done
fi

[ ! -f "$FULLCHAIN_CER_FILE" ] && exit 1

if [ ! -f "$PEM_FILE" ]; then
  ## Import Signed CER from signing authority
  keytool -importcert \
    -alias "$ALIAS_NAME" \
    -keystore "$P12_FILE" \
    -storepass "$KEYSTORE_PASS" \
    -keypass "$KEYSTORE_PASS" \
    -noprompt \
    -file "$FULLCHAIN_CER_FILE"

  #Export certificate using openssl:
  openssl pkcs12 \
    -in "$P12_FILE" \
    -out "$PEM_FILE" \
    -password "pass:$KEYSTORE_PASS" \
    -nokeys

  #Export unencrypted private key:
  openssl pkcs12 \
    -in "$P12_FILE" \
    -out "$KEY_FILE" \
    -password "pass:$KEYSTORE_PASS" \
    -nodes \
    -nocerts

  # Export cert + unencrypted private key
  openssl pkcs12 \
    -in "$P12_FILE" \
    -out "$BUNDLE_PEM_FILE" \
    -password "pass:$KEYSTORE_PASS" \
    -nodes
fi
