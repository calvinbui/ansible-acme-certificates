#!/usr/bin/env bash

FULLCHAIN=$1
KEYFILE=$2
WORKDIR=$3

# Backup previous keystore
cp /var/lib/unifi/keystore /var/lib/unifi/keystore.backup."$(date +%F_%R)"

# Convert cert to PKCS12 format
# Ignore warnings
openssl pkcs12 -export -inkey "$KEYFILE" -in "$FULLCHAIN" -out "$WORKDIR"/fullchain.p12 -name unifi -password pass:unifi

# Install certificate
# Ignore warnings
keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /var/lib/unifi/keystore -srckeystore "$WORKDIR"/fullchain.p12 -srcstoretype PKCS12 -srcstorepass unifi -alias unifi -noprompt

#Restart UniFi controller
service unifi restart
