#!/usr/bin/env bash
# Step 5: Verify that Tomcat serves the PKI-issued certificate and that clients
# that trust only the Root CA accept the connection.
source "$(dirname "$0")/common.sh"

HOST="${HOST:-localhost}"
PORT="${PORT:-8443}"
URL="https://${HOST}:${PORT}/pki-demo/"

step "5.1 Certificate chain presented by Tomcat (openssl s_client)"
echo | $OPENSSL s_client -connect "${HOST}:${PORT}" -servername "$HOST" \
  -CAfile ca/root-ca.crt -verify_hostname "$HOST" -showcerts 2>/dev/null \
  | grep -E '^ *[0-9] s:|^ +i:|^Protocol|^Cipher|Verify return code|^Peer signature|^Server Temp Key' \
  || true

step "5.2 Client that trusts the Root CA: curl --cacert ca/root-ca.crt"
curl -sS --cacert ca/root-ca.crt -o /dev/null \
  -w 'HTTP %{http_code}, ssl_verify_result=%{ssl_verify_result} (0 = OK)\n' "$URL"

step "5.3 Client with only the default OS trust store (should be rejected)"
if curl -sS -o /dev/null "$URL" 2>&1; then
  echo "UNEXPECTED: connection accepted without our Root CA"
else
  echo "Rejected as expected: our private Root CA is not in the public trust store."
fi

step "5.4 Name check: request via SAN www.cmpe272.test (resolved to 127.0.0.1)"
curl -sS --cacert ca/root-ca.crt --resolve "www.cmpe272.test:${PORT}:127.0.0.1" \
  -o /dev/null -w 'HTTP %{http_code} for https://www.cmpe272.test:'"${PORT}"'/pki-demo/\n' \
  "https://www.cmpe272.test:${PORT}/pki-demo/"

step "5.5 Java client using a truststore that contains only the Root CA"
TS="$(mktemp -d)/root-truststore.p12"
keytool -importcert -noprompt -alias cmpe272-root -file ca/root-ca.crt \
  -keystore "$TS" -storetype PKCS12 -storepass changeit >/dev/null
java -Djavax.net.ssl.trustStore="$TS" -Djavax.net.ssl.trustStorePassword=changeit \
  "$ROOT_DIR/scripts/TlsCheck.java" "$URL"

step "5.6 Page content"
curl -sS --cacert ca/root-ca.crt "$URL" | tr -d '\n' | sed 's|</tr>|\n|g' \
  | grep "<td>" | sed "s|.*<tr>||" | sed -e 's|</td>[^<]*<td[^>]*>| : |' -e 's/<[^>]*>//g' -e 's/^ *//'
