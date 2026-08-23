# Worklet 3: Secure Remote Connectivity, WireGuard VPN

Objective: Encrypted remote access into the internal network via WireGuard.

## Lab Topology

  Remote Kali client, WireGuard tunnel over UDP 51820
    connects to WireGuard Server VM, WAN-facing
      connects to Internal web server at 10.10.10.20

## Build Steps

1. Install wireguard on both the server and client VMs using apt.
2. Generate a keypair on each side: private key piped into wg genkey, saved to privatekey, then wg pubkey reading from privatekey to produce publickey.
3. Configure the server using config/wg0-server.conf.template and the client using config/wg0-client.conf.template.
4. Bring up the tunnel with wg-quick up wg0 on both sides.
5. From the client, reach the internal web server over the tunnel and confirm it responds.
6. Confirm the internal web server is not reachable from the client when wg0 is down.

## Evidence to capture

- Output of wg show on both ends confirming handshake established
- Successful request over the tunnel interface
- Failed request when wg0 is down, proving there is no other path

## Lessons Learned / Limitations

Fill in after testing.
