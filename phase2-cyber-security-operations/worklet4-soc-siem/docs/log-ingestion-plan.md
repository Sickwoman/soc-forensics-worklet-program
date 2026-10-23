# Log Ingestion Plan

Source pfSense, Method syslog forward on UDP 514, Log Types firewall blocks and Snort alerts
Source Ubuntu web server, Method Wazuh agent, Log Types auth log, nginx access and error logs, ModSecurity audit log
Source Windows client, Method Wazuh agent for Windows, Log Types Security Event Log, event 4625 failed logon, event 4672 privilege use
Source Metasploitable target, Method Wazuh agent, Log Types auth log and syslog

## Threat Model, STRIDE-lite

Tampering: An attacker on a monitored host deletes or edits local logs to hide their tracks. Agents forward events within seconds, so the copy on the manager survives, and file integrity monitoring on /var/log alerts on the change.
Spoofing: Syslog over UDP 514 is unauthenticated plain text, so anyone on the network can inject fake pfSense events. Accept syslog only from the pfSense IP using allowed-ips in the manager's remote block, and prefer TCP where supported.
Spoofing: A rogue host enrolls as an agent to flood the manager or poison the data. Require an enrollment password for agent registration on TCP 1515.
Information Disclosure: The SIEM holds auth logs and web request bodies from every host. Change the default dashboard admin password, allow dashboard access from the Admin VLAN only, and require MFA per Worklet 6.
Denial of Service: An attacker generates a huge log volume to bury real alerts or fill the disk. Cap each agent with events_per_second in its client_buffer settings, and alert on disk usage on the manager.
Repudiation: Events from hosts with drifting clocks cannot be put in order. All VMs sync to the same NTP source.
Residual risk: Hosts without an agent are blind spots, and the content of encrypted traffic is invisible to the SIEM.
