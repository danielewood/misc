### Common Variables
```
KEYSTORE_PASS='P@ssW0rd!'
ALIAS_FRIENDLYNAME='Contoso-Code-Sign-DATE'
DISTINGUISHED_NAME='CN=Contoso Corporation,O=Contoso Corporation,L=San Francisco,ST=California,C=US'
```

### Generate keystore
```
keytool -genkey -alias "$ALIAS_FRIENDLYNAME" -keystore "$ALIAS_FRIENDLYNAME"-keystore.jks \
        -keypass "$KEYSTORE_PASS" -keyalg RSA -keysize 2048 \
	-storepass "$KEYSTORE_PASS" -dname "$DISTINGUISHED_NAME"
```

### Generate CSR
```
keytool -certreq -alias "$ALIAS_FRIENDLYNAME" -file "$ALIAS_FRIENDLYNAME"-keystore.csr \
        -keystore "$ALIAS_FRIENDLYNAME"-keystore.jks -storepass "$KEYSTORE_PASS"
```

### PFX to JKS (without source CSR, uses private key in PFX)
```
#create keystore:
keytool -genkey -alias "$ALIAS_FRIENDLYNAME" -keystore "$ALIAS_FRIENDLYNAME"-keystore.jks \
        -keypass "$KEYSTORE_PASS" -storepass "$KEYSTORE_PASS" -dname "$DISTINGUISHED_NAME"
	
#remove the privatekey:
keytool -delete -alias "$ALIAS_FRIENDLYNAME" -keystore "$ALIAS_FRIENDLYNAME"-keystore.jks \
        -keypass "$KEYSTORE_PASS" -storepass "$KEYSTORE_PASS" -dname "$DISTINGUISHED_NAME"
	
#import private key and chain from PFX
keytool -v -importkeystore -srckeystore "$ALIAS_FRIENDLYNAME"-keystore.pfx -srcstoretype PKCS12 \
        -destkeystore "$ALIAS_FRIENDLYNAME"-keystore.jks -deststoretype JKS \
	-srcstorepass "$KEYSTORE_PASS" -deststorepass "$KEYSTORE_PASS"
```

### Show keys in keystore
```
keytool -list -v -alias "$ALIAS_FRIENDLYNAME" -keystore "$ALIAS_FRIENDLYNAME"-keystore.jks \
        -keypass "$KEYSTORE_PASS" -storepass "$KEYSTORE_PASS"
```

### JKS to P12
```
keytool -importkeystore -srcalias $ALIAS_FRIENDLYNAME -srckeystore "$ALIAS_FRIENDLYNAME"-keystore.jks \
        -destkeystore "$ALIAS_FRIENDLYNAME"-keystore.p12 -deststoretype PKCS12 \
	-srcstorepass "$KEYSTORE_PASS" -deststorepass "$KEYSTORE_PASS" -destkeypass "$KEYSTORE_PASS"
```
