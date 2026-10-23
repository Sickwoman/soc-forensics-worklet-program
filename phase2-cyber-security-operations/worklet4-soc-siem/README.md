# Worklet 4: SOC Visibility, SIEM Deployment

Objective: Centralize logs and monitor suspicious activity using Wazuh.

## Lab Topology

  pfSense gateway, syslog forward over UDP 514, see Worklet 1
  Ubuntu web server with nginx and ModSecurity, Wazuh agent, see Worklet 7
  Windows 10 client, Wazuh agent
  Metasploitable target, Wazuh agent
      all send events to the Wazuh manager on Ubuntu Server, agents over TCP 1514, enrollment over TCP 1515
        Wazuh indexer and dashboard on the same VM, all in one, dashboard over HTTPS 443 from the Admin VLAN only

## Build Steps

1. Install the Wazuh manager, all in one, on an Ubuntu Server VM using the official install script from packages.wazuh.com.
2. Install the Wazuh agent on target VMs, the web server, pfSense syslog forward, and a Windows client.
3. Register each agent using the manage_agents tool on the manager.
4. Import the decoder in config/wazuh-decoder-example.xml for custom log parsing.
5. Generate test events, repeated failed SSH logins on a monitored host.
6. Confirm the alert appears in the Wazuh dashboard within the severity levels documented in docs/alert-severity-levels.md.
7. Load config/wazuh-local-rules.xml on the manager so the Worklet 3 Zero Trust wg-monitor alerts become SIEM alerts, the Worklet 3 to Worklet 4 bridge. See docs/log-ingestion-plan.md and the W3 doc monitoring-and-detection.md.

## Running it on 8 GB, verified method

The full all-in-one stack, manager plus indexer plus dashboard, wants roughly 4 to
6 GB, which does not fit on an 8 GB host beside anything else. The manager alone,
which is the detection engine the rubric is about, runs in about 350 MiB. So the
verified lab here runs the manager only, in Docker, and demonstrates detection
with Wazuh's own wazuh-logtest instead of the dashboard:

  bash scripts/wazuh-lab.sh up      # start the manager, ~350 MiB
  bash scripts/wazuh-lab.sh rules   # load the custom decoder and the bridge rules
  bash scripts/wazuh-lab.sh test    # prove SSH brute force and the ZT bridge fire
  bash scripts/wazuh-lab.sh down

This was run on WSL2 on an 8 GB Windows machine; see evidence/. The dashboard and
the full multi-agent topology above are the "more RAM" extension, not required to
show detection.

## Evidence to capture

- The matched rule ID and level for the failed SSH alert (evidence/10 shows
  rule 5710 per attempt escalating to rule 5712, level 10, brute force)
- The Zero Trust bridge alerts firing on wg-monitor events (evidence/11, rule
  100101 and 100102 at level 12)
- With the dashboard, a screenshot of the alert and agent status showing active

## Lessons Learned / Limitations

Verified on 2026-10-23: the Wazuh manager detects an SSH brute force (built-in
rule 5712, level 10) and, via config/wazuh-local-rules.xml, raises the Worklet 3
Zero Trust events to level 12 SIEM alerts. Wazuh decoded the wg-monitor JSON with
its built-in json decoder, so no custom decoder was needed for the bridge.

Limitations: on 8 GB the indexer and dashboard are not run, so detection is shown
through wazuh-logtest and the manager's alerts.json rather than the web UI; a real
agent pipeline and the four-source topology are the next step on more RAM. The
logtest method proves the decoders and rules, but not agent enrolment or the
dashboard, which remain untested here.
