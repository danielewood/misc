## Fix:
```
$ ldapsearch -Y GSSAPI -b "cn=users,cn=accounts,dc=contoso,dc=com" -h ipa1
ldap_initialize( ldap://ipa1.contoso.com )
ldap_sasl_interactive_bind_s: Unknown authentication method (-6)
        additional info: SASL(-4): no mechanism available: No worthy mechs found

$ sudo yum -y install cyrus-sasl cyrus-sasl-gssapi
```
