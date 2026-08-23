# Log Ingestion Plan

Source pfSense, Method syslog forward on UDP 514, Log Types firewall blocks and Snort alerts
Source Ubuntu web server, Method Wazuh agent, Log Types auth log, nginx access and error logs, ModSecurity audit log
Source Windows client, Method Wazuh agent for Windows, Log Types Security Event Log, event 4625 failed logon, event 4672 privilege use
Source Metasploitable target, Method Wazuh agent, Log Types auth log and syslog
