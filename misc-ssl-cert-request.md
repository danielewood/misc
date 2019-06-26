# Certificate Request/Generation Script

### Define Variables

```bash
ALIAS_NAME="star_companyname_com-`date +%Y%m%d`"
KEYSTORE_PASS='RANDOMdjnslbklksgbvsligbil4eubgvlksregbgvklih'
```

### Generate Keystore + CSR

```bash
keytool -genkey -keyalg RSA -keysize 2048 \
  -dname "CN=*.companyname.com,OU=Information Technology, O=CompanyName LLC, L=San Diego, ST=California, C=US" \
  -alias "$ALIAS_NAME" -file "$ALIAS_NAME".csr \
  -keystore "$ALIAS_NAME"-keystore.jks -storepass "$KEYSTORE_PASS"

keytool -certreq -alias "$ALIAS_NAME" -file "$ALIAS_NAME".csr \
  -keystore "$ALIAS_NAME"-keystore.jks -storepass "$KEYSTORE_PASS"

cat "$ALIAS_NAME"-keystore.csr
-----BEGIN NEW CERTIFICATE REQUEST-----
### Send CSR to the signing authority ###
-----END NEW CERTIFICATE REQUEST-----
```

### Import Signed CER from signing authority

Note: Name the signed CER as `"$ALIAS_NAME".cer`

```bash
keytool -importcert -file "$ALIAS_NAME".cer -keystore "$ALIAS_NAME"\
  -keystore.jks -alias "$ALIAS_NAME" -storepass "$KEYSTORE_PASS"
```

### Generate P12/PFX and PEM Formats

```bash
openssl pkcs12 -in "$ALIAS_NAME"-keystore.p12 -out "$ALIAS_NAME".pem -passin "$KEYSTORE_PASS"

keytool -list -v -alias "$ALIAS_NAME" -keystore "$ALIAS_NAME"-keystore.jks \
  -keypass "$KEYSTORE_PASS" -storepass "$KEYSTORE_PASS" > "$ALIAS_NAME"-text.txt

openssl rsa -in "$ALIAS_NAME".pem -out "$ALIAS_NAME".key
```
