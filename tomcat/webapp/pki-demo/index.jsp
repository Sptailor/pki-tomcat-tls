<%@ page contentType="text/html; charset=UTF-8" import="java.security.cert.X509Certificate" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>CMPE272 PKI Lab - Tomcat over TLS</title>
  <style>
    body { font-family: -apple-system, Segoe UI, Helvetica, Arial, sans-serif; margin: 40px; color: #1d2433; }
    h1 { font-size: 24px; } table { border-collapse: collapse; }
    td { border: 1px solid #c9d1de; padding: 6px 12px; } td:first-child { font-weight: 600; background: #f2f5fa; }
    .ok { color: #137333; font-weight: 700; } .bad { color: #b3261e; font-weight: 700; }
  </style>
</head>
<body>
  <h1>CMPE272 PKI Lab &mdash; Apache Tomcat over HTTPS</h1>
  <p>This page is served by Tomcat using a TLS certificate issued by the
     <em>CMPE272 Lab Signing CA</em>, which is signed by the <em>CMPE272 Lab Root CA</em>.</p>
  <table>
    <tr><td>Secure connection</td>
        <td class="<%= request.isSecure() ? "ok" : "bad" %>"><%= request.isSecure() ? "YES (HTTPS)" : "NO (HTTP)" %></td></tr>
    <tr><td>Scheme / port</td><td><%= request.getScheme() %> / <%= request.getLocalPort() %></td></tr>
    <tr><td>TLS protocol</td><td><%= request.getAttribute("jakarta.servlet.request.secure_protocol") %></td></tr>
    <tr><td>Cipher suite</td><td><%= request.getAttribute("jakarta.servlet.request.cipher_suite") %></td></tr>
    <tr><td>Key size (bits)</td><td><%= request.getAttribute("jakarta.servlet.request.key_size") %></td></tr>
    <tr><td>Server</td><td><%= application.getServerInfo() %></td></tr>
    <tr><td>Java</td><td><%= System.getProperty("java.version") %></td></tr>
  </table>
</body>
</html>
