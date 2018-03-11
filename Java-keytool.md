


#### ## Common Variables
```
# Alias is the same thing as Friendly Name
ALIAS_NAME="Contoso-Code-Sign-`date +%Y%m%d`"

KEYSTORE_PASS='P@ssW0rd!'

DISTINGUISHED_NAME='CN=Contoso Corporation,O=Contoso Corporation,L=San Francisco,ST=California,C=US'

PATH_TO_JARS='/data/jarfiles/'

JARFILES=`find $PATH_TO_JARS -name *.jar`
```

#### ## File Names (where ALIAS_NAME='Contoso-Code-Sign-YYYYMMDD')
```
Microsoft Authenticode PFX Storage Format:
Contoso-Code-Sign-YYYYMMDD-keystore.pks

Oracle/Sun Java Keystore Format:
Contoso-Code-Sign-YYYYMMDD-keystore.jks

Certificate Signing Request:
Contoso-Code-Sign-YYYYMMDD-keystore.csr
```

#### ## Generate keystore
```
keytool -genkey -alias "$ALIAS_NAME" -keystore "$ALIAS_NAME"-keystore.jks \
    -keypass "$KEYSTORE_PASS" -keyalg RSA -keysize 2048 \
    -storepass "$KEYSTORE_PASS" -dname "$DISTINGUISHED_NAME"
```

#### ## Generate CSR
```
keytool -certreq -alias "$ALIAS_NAME" -file "$ALIAS_NAME"-keystore.csr \
    -keystore "$ALIAS_NAME"-keystore.jks -storepass "$KEYSTORE_PASS"
```

#### ## Import Public CA provided PKCS7 Chain (P7B/CER) from above CSR
```
keytool -import -alias "$ALIAS_NAME" -file "$ALIAS_NAME"-keystore.cer \
    -keystore "$ALIAS_NAME"-keystore.jks -storepass "$KEYSTORE_PASS" \
    -trustcacerts 
```

#### ## Create Empty Keystore
```
#create keystore:
keytool -genkey -alias "$ALIAS_NAME" -keystore "$ALIAS_NAME"-keystore.jks \
    -keypass "$KEYSTORE_PASS" -storepass "$KEYSTORE_PASS" -dname "$DISTINGUISHED_NAME"
  
#remove the privatekey:
keytool -delete -alias "$ALIAS_NAME" -keystore "$ALIAS_NAME"-keystore.jks \
    -keypass "$KEYSTORE_PASS" -storepass "$KEYSTORE_PASS" -dname "$DISTINGUISHED_NAME"
```

#### ## Convert PKCS12 PFX/P12 to JKS (without source CSR, uses private key in PFX)
```
# get alias from PFX
SRCALIAS=`keytool -list -v -keystore "$ALIAS_NAME"-keystore.pfx \
    -keypass "$KEYSTORE_PASS" -storepass "$KEYSTORE_PASS" -storetype PKCS12 |
    grep 'Alias name: ' | awk -F'Alias name: ' '{print $2}'`
	
# Import private key and chain from PFX into (new or existing) keystore
keytool -v -importkeystore -srcalias $SRCALIAS -destalias $ALIAS_NAME \
    -srckeystore "$ALIAS_NAME"-keystore.pfx -srcstoretype PKCS12 \
    -destkeystore "$ALIAS_NAME"-keystore.jks -deststoretype JKS \
    -srcstorepass "$KEYSTORE_PASS" -deststorepass "$KEYSTORE_PASS"
```

#### ## Show keys in keystore
```
keytool -list -v -alias "$ALIAS_NAME" -keystore "$ALIAS_NAME"-keystore.jks \
    -keypass "$KEYSTORE_PASS" -storepass "$KEYSTORE_PASS"
```

#### ## Convert JKS to P12/PFX (Same file format)
```
keytool -importkeystore -srcalias $ALIAS_NAME -srckeystore "$ALIAS_NAME"-keystore.jks \
    -destkeystore "$ALIAS_NAME"-keystore.p12 -deststoretype PKCS12 \
    -srcstorepass "$KEYSTORE_PASS" -deststorepass "$KEYSTORE_PASS" -destkeypass "$KEYSTORE_PASS"
```

#### ## Verify JAR Files
```
for JARFILE in $JARFILES; do
  echo $JARFILE
  echo "====="
  jarsigner -verify -verbose "$JARFILE"
  echo "-----"
done
```

#### ## Sign JAR Files
```
for JARFILE in $JARFILES; do
  echo $JARFILE
  echo "====="
  jarsigner -tsa 'http://timestamp.digicert.com' -verbose \
    -keystore "$ALIAS_NAME"-keystore.jks \
    -keypass "$KEYSTORE_PASS" -storepass "$KEYSTORE_PASS" \
    "$JARFILE" "$ALIAS_NAME"
  echo "-----"
done
```
