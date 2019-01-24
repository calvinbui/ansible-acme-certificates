#!/usr/bin/env bash

CERTFILE=$1
FULLCHAIN=$2
KEYFILE=$3
UNIFICERTFOLDER=$4

sudo cp "$FULLCHAIN" "$UNIFICERTFOLDER"/chain.pem
sudo cp "$CERTFILE" "$UNIFICERTFOLDER"/cert.pem
sudo cp "$KEYFILE" "$UNIFICERTFOLDER"/privkey.pem
