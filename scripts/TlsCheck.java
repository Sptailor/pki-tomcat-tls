import java.net.URI;
import java.security.cert.Certificate;
import java.security.cert.X509Certificate;
import javax.net.ssl.HttpsURLConnection;

/**
 * Minimal Java TLS client. Run with -Djavax.net.ssl.trustStore pointing at a
 * truststore that contains only the CMPE272 Lab Root CA; the connection
 * succeeds only if Tomcat presents a chain that builds up to that root.
 *
 *   java TlsCheck.java https://localhost:8443/pki-demo/
 */
public class TlsCheck {
    public static void main(String[] args) throws Exception {
        HttpsURLConnection c = (HttpsURLConnection) URI.create(args[0]).toURL().openConnection();
        c.connect();
        System.out.println("HTTP " + c.getResponseCode() + " via " + c.getCipherSuite());
        Certificate[] chain = c.getServerCertificates();
        for (int i = 0; i < chain.length; i++) {
            X509Certificate x = (X509Certificate) chain[i];
            System.out.println("  [" + i + "] subject: " + x.getSubjectX500Principal().getName());
            System.out.println("      issuer:  " + x.getIssuerX500Principal().getName());
        }
        c.disconnect();
    }
}
