# VPN Protocol Comparison, WireGuard vs OpenVPN

Codebase size: WireGuard is roughly 4000 lines, OpenVPN is roughly 100000 lines.
Crypto: WireGuard uses a modern fixed suite, ChaCha20, Curve25519, BLAKE2s. OpenVPN is TLS-based and configurable, which can be misconfigured.
Performance: WireGuard runs in kernel space and is very fast. OpenVPN runs in userspace and is slower.
Config complexity: WireGuard uses simple keypairs. OpenVPN requires a full PKI with certificates.
NAT traversal: Both handle NAT traversal well over UDP.
Maturity: WireGuard is newer with a formally verified handshake. OpenVPN has a long track record.

Choice for this worklet: WireGuard, for simplicity and strong default crypto.
