#!/usr/bin/env bash
# Step 4: Download Apache Tomcat, install the PKCS#12 keystore built in step 3,
# add an HTTPS connector on port 8443 and deploy a small demo page.
# Follows https://tomcat.apache.org/tomcat-7.0-doc/ssl-howto.html, using the
# Tomcat 8.5+ <SSLHostConfig> syntax (Tomcat 7 is end-of-life).
source "$(dirname "$0")/common.sh"

TOMCAT_VERSION="${TOMCAT_VERSION:-11.0.29}"
TOMCAT_MAJOR="${TOMCAT_VERSION%%.*}"
NAME="${SERVER_NAME:-www.cmpe272.test}"
KEYSTORE_ALIAS="${KEYSTORE_ALIAS:-tomcat}"
: "${KEYSTORE_PASS:?Set KEYSTORE_PASS to the password used for certs/${NAME}.p12}"

BASE_URL="https://dlcdn.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin"
ARCHIVE="apache-tomcat-${TOMCAT_VERSION}.tar.gz"
CATALINA_HOME="$ROOT_DIR/tomcat/apache-tomcat-${TOMCAT_VERSION}"

mkdir -p tomcat/downloads
if [[ ! -d "$CATALINA_HOME" ]]; then
  step "4.1 Download Tomcat ${TOMCAT_VERSION} and verify SHA-512"
  curl -fsSL -o "tomcat/downloads/${ARCHIVE}"        "${BASE_URL}/${ARCHIVE}"
  curl -fsSL -o "tomcat/downloads/${ARCHIVE}.sha512" "${BASE_URL}/${ARCHIVE}.sha512"
  expected="$(awk '{print $1}' "tomcat/downloads/${ARCHIVE}.sha512")"
  actual="$(shasum -a 512 "tomcat/downloads/${ARCHIVE}" | awk '{print $1}')"
  [[ "$expected" == "$actual" ]] || { echo "SHA-512 mismatch for ${ARCHIVE}" >&2; exit 1; }
  echo "SHA-512 OK"
  tar -xzf "tomcat/downloads/${ARCHIVE}" -C tomcat
else
  step "4.1 Tomcat already present at ${CATALINA_HOME}"
fi

step "4.2 Install keystore into \$CATALINA_HOME/conf"
cp "certs/${NAME}.p12" "$CATALINA_HOME/conf/${NAME}.p12"
chmod 600 "$CATALINA_HOME/conf/${NAME}.p12"
keytool -list -storetype PKCS12 -keystore "$CATALINA_HOME/conf/${NAME}.p12" \
  -storepass "$KEYSTORE_PASS" | sed -n '1,8p'

step "4.3 Add HTTPS connector (port 8443) to conf/server.xml"
SERVER_XML="$CATALINA_HOME/conf/server.xml"
[[ -f "${SERVER_XML}.orig" ]] || cp "$SERVER_XML" "${SERVER_XML}.orig"
python3 - "$SERVER_XML.orig" "$SERVER_XML" tomcat/ssl-connector.xml \
  "${NAME}.p12" "$KEYSTORE_PASS" "$KEYSTORE_ALIAS" <<'PY'
import sys
src, dst, snippet_path, ks_file, ks_pass, alias = sys.argv[1:]
xml = open(src).read()
snippet = (open(snippet_path).read()
           .replace("@KEYSTORE_FILE@", ks_file)
           .replace("@KEYSTORE_PASS@", ks_pass)
           .replace("@KEYSTORE_ALIAS@", alias))
anchor = "  </Service>"
assert xml.count(anchor) == 1, "unexpected server.xml layout"
open(dst, "w").write(xml.replace(anchor, snippet + anchor))
PY
chmod 600 "$SERVER_XML"
grep -n 'port="8443"' "$SERVER_XML" | grep -v '<!--' || true

step "4.4 Deploy demo web app (/pki-demo)"
rm -rf "$CATALINA_HOME/webapps/pki-demo"
cp -R tomcat/webapp/pki-demo "$CATALINA_HOME/webapps/pki-demo"

echo
echo "CATALINA_HOME=$CATALINA_HOME"
echo "Start:  $CATALINA_HOME/bin/startup.sh"
echo "Stop:   $CATALINA_HOME/bin/shutdown.sh"
echo "Browse: https://localhost:8443/pki-demo/"
