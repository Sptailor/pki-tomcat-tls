#!/usr/bin/env bash
# Step 3: Issue the TLS server certificate from the Signing CA
# (tutorial section 3.3/3.4), then build the chain, CRLs and a PKCS#12
# keystore for Tomcat (tutorial section 4 "Output Formats").
source "$(dirname "$0")/common.sh"

NAME="${SERVER_NAME:-www.cmpe272.test}"
export SAN="${SAN:-DNS:${NAME},DNS:localhost,IP:127.0.0.1}"
KEYSTORE_ALIAS="${KEYSTORE_ALIAS:-tomcat}"

mkdir -p certs crl

step "3.1 Create TLS server request (new 2048-bit key + CSR, SAN=${SAN})"
$OPENSSL req -new \
  -config etc/server.conf \
  -out "certs/${NAME}.csr" \
  -keyout "certs/${NAME}.key"
chmod 600 "certs/${NAME}.key"

step "3.2 Signing CA issues the TLS server certificate"
# shellcheck disable=SC2046
$OPENSSL ca -batch \
  -config etc/signing-ca.conf \
  -in "certs/${NAME}.csr" \
  -out "certs/${NAME}.crt" \
  -extensions server_ext \
  $(pass_args in SIGNING_CA_PASS)

step "3.3 Create CA chain file (Signing CA + Root CA)"
cat ca/signing-ca.crt ca/root-ca.crt > ca/signing-ca-chain.pem

step "3.4 Create initial CRLs (tutorial sections 1.5, 2.5)"
# shellcheck disable=SC2046
$OPENSSL ca -gencrl -config etc/root-ca.conf    -out crl/root-ca.crl    $(pass_args in ROOT_CA_PASS)
# shellcheck disable=SC2046
$OPENSSL ca -gencrl -config etc/signing-ca.conf -out crl/signing-ca.crl $(pass_args in SIGNING_CA_PASS)

step "3.5 Create DER versions of the certificates and CRLs (tutorial section 4)"
$OPENSSL x509 -in ca/root-ca.crt    -out ca/root-ca.cer    -outform der
$OPENSSL x509 -in ca/signing-ca.crt -out ca/signing-ca.cer -outform der
$OPENSSL crl  -in crl/root-ca.crl    -out crl/root-ca.der.crl    -outform der
$OPENSSL crl  -in crl/signing-ca.crl -out crl/signing-ca.der.crl -outform der

step "3.6 Bundle key + certificate + chain into a PKCS#12 keystore for Tomcat"
# shellcheck disable=SC2046
$OPENSSL pkcs12 -export \
  -name "$KEYSTORE_ALIAS" \
  -inkey "certs/${NAME}.key" \
  -in "certs/${NAME}.crt" \
  -certfile ca/signing-ca-chain.pem \
  -caname "CMPE272 Lab Signing CA" -caname "CMPE272 Lab Root CA" \
  -out "certs/${NAME}.p12" \
  $(pass_args out KEYSTORE_PASS)

step "3.7 Verify the certificate chain"
$OPENSSL verify -CAfile ca/root-ca.crt -untrusted ca/signing-ca.crt "certs/${NAME}.crt"
$OPENSSL x509 -in "certs/${NAME}.crt" -noout -subject -issuer -dates \
  -ext subjectAltName,keyUsage,extendedKeyUsage,basicConstraints
