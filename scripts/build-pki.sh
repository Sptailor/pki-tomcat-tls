#!/usr/bin/env bash
# Build the whole PKI from scratch: Root CA -> Signing CA -> TLS certificate.
# Set ROOT_CA_PASS, SIGNING_CA_PASS and KEYSTORE_PASS to run unattended,
# otherwise OpenSSL prompts for each passphrase.
source "$(dirname "$0")/common.sh"

if [[ -e ca || -e certs || -e crl ]]; then
  echo "ca/, certs/ or crl/ already exists. Run scripts/clean.sh first." >&2
  exit 1
fi

"$ROOT_DIR/scripts/01-root-ca.sh"
"$ROOT_DIR/scripts/02-signing-ca.sh"
"$ROOT_DIR/scripts/03-tls-cert.sh"

step "Done. Artifacts:"
find ca certs crl -type f | sort
