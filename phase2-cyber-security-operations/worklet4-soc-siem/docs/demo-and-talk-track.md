# Worklet 4 Demo and Talk Track

How to show Worklet 4 in about five minutes, and what to say. Verified on an 8 GB
machine with the manager-only method, see the README.

## Running it

From a root shell on the Docker host (WSL2 Ubuntu on Windows works):

  cd .../worklet4-soc-siem/scripts
  bash wazuh-lab.sh up      # start the Wazuh manager, ~350 MiB
  bash wazuh-lab.sh rules   # load the custom decoder and the Zero Trust bridge rules
  bash wazuh-lab.sh test    # feed attack logs, show the alerts fire

When up says "still initialising", that is normal on a low-RAM host, wait and run
the next step.

## The five-minute script

1. Problem, 45s. On a real network, the traces of an attack sit in local logs on
   many hosts, where they can be wiped. A SOC centralises those logs and turns
   them into prioritised alerts. This worklet is that SIEM, built with Wazuh.

2. What is running, 45s. The Wazuh manager, which holds the decoders and rules and
   does the detection. On 8 GB we run the manager, the part the grade is about,
   and demonstrate detection with Wazuh's own wazuh-logtest, which runs the exact
   same decoders and rules the live pipeline uses. The indexer and web dashboard
   are the more-RAM extension.

3. Detection, 60s. Feed in failed SSH logins. Wazuh decodes each one, pulling out
   the user and source IP, and on the eighth attempt it escalates from rule 5710,
   a failed login at level 5, to rule 5712, brute force at level 10, mapped to
   MITRE T1110. Raw log lines have become one prioritised alert.

4. The bridge, 60s. Worklet 3's Zero Trust monitor emits JSON alerts. The rules in
   config/wazuh-local-rules.xml make Wazuh ingest them, so a denied_traffic event
   from the VPN becomes a level 12 SIEM alert, rule 100101, in the same console as
   the SSH brute force. The remote-access defence and the SOC are now one system,
   which is the program's through-line, Worklet 3 feeding Worklet 4.

5. Limits, 30s. On this host we do not run the web dashboard or a live agent, so
   agent enrolment and the GUI are untested here; logtest proves the decoders and
   rules, which is the detection logic itself. The dashboard and a multi-agent
   fleet are the next step on more RAM.

## Questions and honest answers

- Why logtest and not the dashboard? The dashboard needs roughly 4 to 6 GB and is
  a viewer; the manager is the detection engine, and logtest runs the identical
  decoders and rules. The logic is what we are demonstrating.
- Would a real agent give the same alerts? Yes. An agent forwards the same log
  lines to the manager, which applies these same rules. logtest is the manager's
  own test harness for exactly that.
- How does the Worklet 3 bridge work? wg-monitor emits flat JSON; Wazuh's built-in
  json decoder parses it into fields; the local rules match the source and type
  fields and set the alert level. No custom decoder is needed for these.
- Could an attacker just delete the logs? They can delete the local copy, but the
  agent forwards events within seconds and the manager keeps its own copy, which
  is the reason to centralise.
- What do the levels mean? Wazuh severity levels, summarised in
  docs/alert-severity-levels.md; brute force is level 10, the Zero Trust denied
  and unknown-peer events are level 12.

## Evidence

See evidence/: the SSH brute-force logtest (rule 5712), the Zero Trust bridge
logtest (rule 100101 and 100102), and a captured wazuh-lab.sh test run.
