# Worklet 4: SOC Visibility, SIEM Deployment

Objective: Centralize logs and monitor suspicious activity using Wazuh.

## Build Steps

1. Install the Wazuh manager, all in one, on an Ubuntu Server VM using the official install script from packages.wazuh.com.
2. Install the Wazuh agent on target VMs, the web server, pfSense syslog forward, and a Windows client.
3. Register each agent using the manage_agents tool on the manager.
4. Import the decoder in config/wazuh-decoder-example.xml for custom log parsing.
5. Generate test events, repeated failed SSH logins on a monitored host.
6. Confirm the alert appears in the Wazuh dashboard within the severity levels documented in docs/alert-severity-levels.md.

## Evidence to capture

- Wazuh dashboard screenshot showing the failed SSH alert
- Raw log line plus the matched rule ID
- Agent status showing active for all monitored hosts

## Lessons Learned / Limitations

Fill in after testing.
