# Live Demo Runbook

The demo is one command and runs about five minutes. This runbook is what to say,
what should happen, and what to do if it breaks.

## Before the review

- Build and smoke-test on the actual review laptop, not just your own:
  bash scripts/lab-up.sh up, then bash scripts/demo.sh --auto, then
  bash scripts/lab-up.sh down. A cold Docker image pull must not happen live.
- Record a clean run as the fallback: bash scripts/demo.sh --auto --reset while
  capturing with asciinema or screen capture. Keep it in evidence/.
- Leave the lab built but down. Bring it up once, a few minutes before, so key
  generation and the tunnels are settled.

## Running it

  bash scripts/demo.sh            # paced, pauses between scenes
  bash scripts/demo.sh --auto     # no pauses, for the recording
  bash scripts/demo.sh --reset    # re-provision mallory, start clean

## The three scenes, and the line to land

Scene 1, least privilege. alice reaches the web app, is blocked from the
database; bob is the reverse. Line: "Same tunnel, same crypto, different reach.
Access follows identity, so a stolen key is worth one service, not the network."

Scene 2, attack and detection. A port scan of the VPN endpoint gets no response,
WireGuard does not announce itself. Then mallory's compromised laptop tries to
pivot to the database and is dropped, and the monitor raises a denied_traffic
alert. Line: "The VPN is invisible to a scanner, and when a trusted-but-compromised
device reaches past its entitlement, we see it."

Scene 3, respond and recover. The operator revokes mallory; her tunnel drops
within a keepalive interval while alice stays connected. Line: "Containment is one
command and takes seconds, with no outage for anyone else. That is the recovery
step a flat VPN cannot do."

## If something breaks

- A scene shows FAILED or LEAK: stop, run bash scripts/lab-up.sh down then up,
  and re-run. If it persists, switch to the recording.
- Tunnels not up: docker exec zt-wg-server wg show should list peers; if empty,
  bash scripts/lab-up.sh down then up to regenerate keys.
- Docker not available on the day: play the recording and walk through this
  runbook and the architecture diagram instead.
- Keep docs/zero-trust-architecture.md open in a second window to point at while
  the scenes run.

## Questions he may ask, and the honest answer

- "Why not OpenVPN or IPsec?" See the scored matrix in vpn-protocol-comparison.md.
  Short answer: keep WireGuard's small attack surface and add the identity and
  logging it lacks, rather than adopt a larger one to get them.
- "Where is the SIEM?" The monitor is the live feed here because the full Wazuh
  stack does not fit beside the lab on 8 GB; the decoder and rule to forward these
  alerts to Worklet 4 are written in monitoring-and-detection.md.
- "Is the posture check real?" It is a lab-grade stub, and the doc says exactly
  which real probe replaces each stub on a production endpoint.
- "Would this run on the real firewall?" Yes, see the pfSense section in
  zero-trust-architecture.md; the lab uses a container so it fits on 8 GB.
