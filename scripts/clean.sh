#!/usr/bin/env bash
# Remove all generated PKI material (keys, certs, CRLs, databases).
source "$(dirname "$0")/common.sh"
rm -rf ca certs crl
echo "Removed ca/, certs/, crl/"
