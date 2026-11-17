#!/usr/bin/env bash
# Step 2: Create the Signing (intermediate) CA, signed by the Root CA
# (tutorial section 2).
source "$(dirname "$0")/common.sh"

step "2.1 Create Signing CA directories"
mkdir -p ca/signing-ca/private ca/signing-ca/db crl certs
chmod 700 ca/signing-ca/private

step "2.2 Create Signing CA database"
cp /dev/null ca/signing-ca/db/signing-ca.db
cp /dev/null ca/signing-ca/db/signing-ca.db.attr
echo 01 > ca/signing-ca/db/signing-ca.crt.srl
echo 01 > ca/signing-ca/db/signing-ca.crl.srl

step "2.3 Create Signing CA request (new 3072-bit key + CSR)"
# shellcheck disable=SC2046
$OPENSSL req -new \
  -config etc/signing-ca.conf \
  -out ca/signing-ca.csr \
  -keyout ca/signing-ca/private/signing-ca.key \
  $(pass_args out SIGNING_CA_PASS)
chmod 600 ca/signing-ca/private/signing-ca.key

step "2.4 Root CA signs the Signing CA certificate"
# shellcheck disable=SC2046
$OPENSSL ca -batch \
  -config etc/root-ca.conf \
  -in ca/signing-ca.csr \
  -out ca/signing-ca.crt \
  -extensions signing_ca_ext \
  $(pass_args in ROOT_CA_PASS)

$OPENSSL x509 -in ca/signing-ca.crt -noout -subject -issuer -dates -ext basicConstraints,keyUsage
