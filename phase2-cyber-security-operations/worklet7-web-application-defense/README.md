# Worklet 7: Web Application Defense, WAF

Objective: Defend against OWASP Top 10 threats using Nginx and ModSecurity.

## Lab Topology

  Kali attacker, HTTP on TCP 80
    connects to nginx with ModSecurity and the OWASP Core Rule Set, on the target web server VM
      passes clean requests to the web application behind it, which listens on 127.0.0.1 only
      returns 403 for blocked requests and writes them to the ModSecurity audit log, forwarded to Wazuh, see Worklet 4

## Build Steps

1. On the target web server VM, install nginx and the ModSecurity connector for nginx.
2. Enable the OWASP Core Rule Set by cloning coreruleset into the nginx modsec directory.
3. Apply the settings in config/modsecurity-rules.conf, then restart nginx.
4. From Kali, attempt a SQL injection payload against a login endpoint, confirm the request is blocked with a 403.
5. Attempt a reflected XSS payload against a search endpoint, confirm it is also blocked.
6. Check the ModSecurity audit log for the blocked requests and note the rule ID that triggered.

## Evidence to capture

- 403 response for both the SQL injection and XSS payloads
- ModSecurity audit log excerpt showing the triggered rule ID
- A legitimate request still succeeding, to prove the WAF is not blocking everything

## Lessons Learned / Limitations

Fill in after testing.
