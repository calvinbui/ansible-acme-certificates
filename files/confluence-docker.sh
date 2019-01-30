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
KEYSTOREPASSWORD=changeit
DOCKERCERTFILE=/tmp/CERTFILE
DOCKERKEYFILE=/tmp/KEYFILE
DOCKERCACERTFILE=/tmp/CACERTFILE
DOCKERSCRIPT=/tmp/confluence-docker.sh

docker cp $CERTFILE confluence:"$DOCKERCERTFILE"
docker cp $KEYFILE confluence:"$DOCKERKEYFILE"
docker cp $CACERTFILE confluence:"$DOCKERCACERTFILE"

cat > "$DOCKERSCRIPT" << EOT
#!/usr/bin/env bash

# Create default keystore if missing
if [ ! -f $KEYSTORE ]; then
  keytool \
  -genkeypair \
  -alias $KEYSTORENAME \
  -keyalg RSA \
  -keysize 4096 \
  -keystore $KEYSTORE \
  -dname "CN=$SITE" \
  -storepass $KEYSTOREPASSWORD \
  -keypass $KEYSTOREPASSWORD
fi

# Combine the private key and the certificate into a PKCS12 keystore
openssl pkcs12 -export \
-in $DOCKERCERTFILE \
-inkey $DOCKERKEYFILE \
-out $PKCS12KEYSTORE \
-name $KEYSTORENAME \
-CAfile $DOCKERCACERTFILE \
-caname root \
-password pass:$KEYSTOREPASSWORD

# Merge PKCS12 keystore with default keystore
keytool \
-importkeystore \
-noprompt \
-deststorepass $KEYSTOREPASSWORD \
-destkeypass $KEYSTOREPASSWORD \
-destkeystore $KEYSTORE \
-srckeystore $PKCS12KEYSTORE \
-srcstoretype PKCS12 \
-srcstorepass $KEYSTOREPASSWORD \
-alias $KEYSTORENAME

# Edit server.xml
if grep "$KEYSTOREPASSWORD" /opt/atlassian/confluence/conf/server.xml; then
  echo "nothing needs to be done"
else
  # remove comment line before match
  tac server.xml | sed '/<Connector port="8443"/{n;d}' | tac > tmp && mv tmp server.xml
  # remove comment line after match
  sed -i '/keystorePass/{n;d}' server.xml
  # replace password
  sed -i 's/<MY_CERTIFICATE_PASSWORD>/$KEYSTOREPASSWORD/' server.xml
fi

EOT

docker cp "$DOCKERSCRIPT" confluence:"$DOCKERSCRIPT"
docker exec -it confluence chmod +x "$DOCKERSCRIPT"
docker exec -it confluence "$DOCKERSCRIPT"

# restarting confluence to apply changes
docker restart confluence
