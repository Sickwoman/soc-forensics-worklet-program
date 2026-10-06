# WAF Rule Definition Document

Rule set OWASP CRS 942xx, covers SQL Injection, action Block and log.
Rule set OWASP CRS 941xx, covers Cross Site Scripting, action Block and log.
Rule set OWASP CRS 930xx, covers Path Traversal and Local File Inclusion, action Block and log.
Rule set Custom, covers rate limiting on the login endpoint, action Throttle after 10 requests per minute per IP.

## Threat Model, STRIDE-lite

Tampering and Information Disclosure: SQL injection against the login endpoint, to bypass authentication or dump the database. Blocked by CRS 942xx.
Spoofing: Reflected XSS against the search endpoint, to steal another user's session cookie. Blocked by CRS 941xx.
Information Disclosure: Path traversal and file inclusion, to read files such as /etc/passwd. Blocked by CRS 930xx.
Spoofing and Denial of Service: Brute force or credential stuffing against /login. Throttled by the custom rate limit rule.
WAF bypass: Encoded or obfuscated payloads that slip past signatures. CRS decodes and normalizes input before matching, and raising the CRS paranoia level catches more variants at the cost of more false positives.
WAF bypass: Reaching the application directly on its own port, skipping nginx. The application listens on 127.0.0.1 only, and the host firewall allows only TCP 80 and 443 inbound.
Denial of Service, self-inflicted: False positives block real users. Run new rules with SecRuleEngine DetectionOnly first, review the audit log, and add rule exclusions before switching to On.
Information Disclosure: The audit log records full request bodies, including passwords posted to /login. Restrict the log file to root and the Wazuh agent, and rotate it.
Residual risk: Business logic flaws, broken access control, and zero-days with no matching signature are not stopped by a WAF, the application itself still has to be fixed.
