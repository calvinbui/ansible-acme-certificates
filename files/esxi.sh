#!/usr/bin/env bash

ESXIHOST=$1
ESXIUSER=$2
ESXIPASSWORD=$3
CERTFILE=$4
FULLCHAIN=$5
KEYFILE=$6

# Backup existing SSL components on ESXi target
echo "Backing up certificates"
time=$(date +%Y.%m.%d_%H:%M:%S)
sshpass -p "$ESXIPASSWORD" ssh -o StrictHostKeyChecking=no "$ESXIUSER"@"$ESXIHOST" "cp /etc/vmware/ssl/castore.pem /etc/vmware/ssl/castore.pem.back.$time"
sshpass -p "$ESXIPASSWORD" ssh -o StrictHostKeyChecking=no "$ESXIUSER"@"$ESXIHOST" "cp /etc/vmware/ssl/rui.crt /etc/vmware/ssl/rui.crt.back.$time"
sshpass -p "$ESXIPASSWORD" ssh -o StrictHostKeyChecking=no "$ESXIUSER"@"$ESXIHOST" "cp /etc/vmware/ssl/rui.key /etc/vmware/ssl/rui.key.back.$time"

# Copy letsencrypt cert to ESXi target
echo "Copying new certificates"
sshpass -p "$ESXIPASSWORD" scp -o StrictHostKeyChecking=no "$FULLCHAIN" "$ESXIUSER"@"$ESXIHOST":/etc/vmware/ssl/castore.pem
sshpass -p "$ESXIPASSWORD" scp -o StrictHostKeyChecking=no "$CERTFILE" "$ESXIUSER"@"$ESXIHOST":/etc/vmware/ssl/rui.crt
sshpass -p "$ESXIPASSWORD" scp -o StrictHostKeyChecking=no "$KEYFILE" "$ESXIUSER"@"$ESXIHOST":/etc/vmware/ssl/rui.key

# Restart services on ESXi target
echo "Restarting ESXi hostd"
sshpass -p "$ESXIPASSWORD" ssh -o StrictHostKeyChecking=no $ESXIUSER@$ESXIHOST "/etc/init.d/hostd restart"
