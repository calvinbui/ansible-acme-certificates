#!/usr/bin/env bash
#
# https://confluence.atlassian.com/doc/running-confluence-over-ssl-or-https-161203.html

SITE=$1
CERTFILE=$2
KEYFILE=$3
CACERTFILE=$4

KEYSTORE=/root/.keystore
KEYSTORENAME=tomcat
PKCS12KEYSTORE=/root/pkcs12
KEYSTORE_PASSWORD=changeit

cat > /tmp/confluence-cert.sh << EOT
#!/usr/bin/env bash

# Combine the private key and the certificate into a PKCS12 keystore
openssl pkcs12 -export \
-in $CERTFILE \
-inkey $KEYFILE \
-out $PKCS12KEYSTORE \
-name $KEYSTORENAME \
-CAfile $CACERTFILE \
-caname root \
-password pass:$KEYSTORE_PASSWORD

# Create default keystore
keytool \
-genkeypair \
-alias $KEYSTORENAME \
-keyalg RSA \
-keysize 4096 \
-keystore $KEYSTORE \
-dname "CN=$SITE" \
-storepass $KEYSTORE_PASSWORD

# Merge PKCS12 keystore with default keystore
keytool \
-importkeystore \
-deststorepass $KEYSTORE_PASSWORD \
-destkeypass $KEYSTORE_PASSWORD \
-destkeystore $KEYSTORE \
-srckeystore $PKCS12KEYSTORE \
-srcstoretype PKCS12 \
-srcstorepass $KEYSTORE_PASSWORD \
-alias $KEYSTORENAME

# Remove PKCS12 keystore after merge
rm $PKCS12KEYSTORE

# Edit server.xml
if grep "$KEYSTORE_PASSWORD" /opt/atlassian/confluence/conf/server.xml; then
  echo "nothing needs to be done"
else
  # remove comment line before match
  tac server.xml | sed '/<Connector port="8443"/{n;d}' | tac > tmp && mv tmp server.xml
  # remove comment line after match
  sed -i '/keystorePass/{n;d}' server.xml
  # replace password
  sed -i 's/<MY_CERTIFICATE_PASSWORD>/$KEYSTORE_PASSWORD/' server.xml
fi
EOT

# restarting confluence to apply changes
docker restart confluence
