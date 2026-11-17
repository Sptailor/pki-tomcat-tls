#!/usr/bin/env bash
# Step 1: Create the Root CA (tutorial section 1).
source "$(dirname "$0")/common.sh"

step "1.1 Create Root CA directories"
mkdir -p ca/root-ca/private ca/root-ca/db crl certs
chmod 700 ca/root-ca/private

step "1.2 Create Root CA database"
cp /dev/null ca/root-ca/db/root-ca.db
cp /dev/null ca/root-ca/db/root-ca.db.attr
echo 01 > ca/root-ca/db/root-ca.crt.srl
echo 01 > ca/root-ca/db/root-ca.crl.srl

step "1.3 Create Root CA request (new 4096-bit key + CSR)"
# shellcheck disable=SC2046
$OPENSSL req -new \
  -config etc/root-ca.conf \
  -out ca/root-ca.csr \
  -keyout ca/root-ca/private/root-ca.key \
  $(pass_args out ROOT_CA_PASS)
chmod 600 ca/root-ca/private/root-ca.key

step "1.4 Self-sign the Root CA certificate"
# shellcheck disable=SC2046
$OPENSSL ca -selfsign -batch \
  -config etc/root-ca.conf \
  -in ca/root-ca.csr \
  -out ca/root-ca.crt \
  -extensions root_ca_ext \
  $(pass_args in ROOT_CA_PASS)

$OPENSSL x509 -in ca/root-ca.crt -noout -subject -issuer -dates -ext basicConstraints,keyUsage
