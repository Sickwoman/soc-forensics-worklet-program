# Optional: the Wazuh Web Dashboard

The verified lab in this worklet runs the Wazuh manager only, because the full
stack does not fit on 8 GB. This note is how to add the web dashboard when you
have the RAM, for example on a bigger machine or by giving WSL more memory.

## What it adds, and the cost

The dashboard needs two more services: the indexer (OpenSearch, a Java database,
the real RAM user) and the dashboard web app. Budget roughly 4 to 6 GB for the
three together. On an 8 GB machine that is also running Windows, this will be slow
and may not start the indexer at all.

## If you run it under WSL on Windows

1. Raise the WSL memory cap. Create C:\Users\<you>\.wslconfig with:

   [wsl2]
   memory=6GB
   processors=4

   On a 7.7 GB machine this leaves Windows about 1.7 GB, so close your browser and
   other apps first; Windows will be sluggish while the stack runs.
2. Apply it: run `wsl --shutdown` in PowerShell, then start the distro again. This
   stops all running containers, so bring them back up afterwards.
3. Start the dashboard stack as root in the distro:

   bash scripts/wazuh-dashboard.sh up

   The first run clones the official wazuh-docker deployment and pulls ~2-3 GB of
   images, then generates certificates and starts the services.
4. Wait a few minutes for the indexer to become ready, then open https://localhost
   and sign in as admin. Change the default password in the deployment's
   docker-compose.yml before any real use.
5. Tear it down with: bash scripts/wazuh-dashboard.sh down

## How this relates to the manager-only lab

The dashboard is a viewer on top of the same manager, decoders, and rules that
wazuh-lab.sh already runs. Everything proven with wazuh-logtest, the SSH brute
force and the Zero Trust bridge alerts, would appear in the dashboard's alert view
once an agent or log source feeds the manager. The dashboard does not change the
detection, it visualises it.

## Status

Not run on the 8 GB development machine, which cannot spare the RAM without
starving Windows. The manager-only lab is the verified path; this is the
documented extension for a host with more memory.
