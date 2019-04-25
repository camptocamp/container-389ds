#!/bin/bash

# LDAP_CA_CERTIFICATE_DIR
# LDAP_LOCAL_KEY_FILE
# LDAP_LOCAL_CERT_FILE

if [ "$LDAP_CA_CERTIFICATE_DIR"x != "x" ] && [ -d "$LDAP_CA_CERTIFICATE_DIR" ]; then
  for each in $(find $LDAP_CA_CERTIFICATE_DIR -type f); do
    echo "processing '$each' CA certificate"
    certutil -A -n $(basename $each) -t c -i $each -d /etc/dirsrv/slapd-*/
  done
fi

if [ "$LDAP_LOCAL_KEY_FILE"x != "x" ] && [ -f "$LDAP_LOCAL_KEY_FILE" ] && [ "$LDAP_LOCAL_CERT_FILE"x != "x" ] && [ -f "$LDAP_LOCAL_CERT_FILE" ]; then
  echo "Enabling LDAPS with $LDAP_LOCAL_KEY_FILE key and $LDAP_LOCAL_CERT_FILE certificate"
  openssl pkcs12 -export -out /tmp/cert.p12 -inkey "$LDAP_LOCAL_KEY_FILE" -in "$LDAP_LOCAL_CERT_FILE" -certfile "$LDAP_LOCAL_CERT_FILE" -name 'LDAPS' -passout pass:
  pk12util -i /tmp/cert.p12 -d /etc/dirsrv/slapd-*/ -W "" -K ""

  cat > /tmp/ldif << EOF
dn: cn=config
changetype: modify
replace: nsslapd-securePort
nsslapd-securePort: 6636
-
replace: nsslapd-security
nsslapd-security: on

dn: cn=RSA,cn=encryption,cn=config
changetype: add
cn: RSA
objectClass: nsEncryptionModule
nsSSLToken: internal (software)
nsSSLPersonalitySSL: LDAPS
nsSSLActivation: on
EOF

  echo "${ldapmodify[@]}" -f "/tmp/ldif"
  "${ldapmodify[@]}" -f "/tmp/ldif"
fi
