# One small image for the gateway, the clients, and the database stand-in.
# Alpine keeps each container to a few tens of MB, so the whole six-container lab
# fits alongside the host VM on an 8 GB laptop.
FROM alpine:3.20

RUN apk add --no-cache \
    bash \
    wireguard-tools \
    nftables \
    iproute2 \
    iptables \
    python3 \
    py3-yaml \
    iputils \
    curl \
    nmap \
    tcpdump \
    iperf3 \
    socat

COPY lab-entrypoint.sh /usr/local/bin/lab-entrypoint.sh
COPY render-config.py /usr/local/bin/render-config.py
RUN chmod +x /usr/local/bin/lab-entrypoint.sh /usr/local/bin/render-config.py

ENTRYPOINT ["/usr/local/bin/lab-entrypoint.sh"]
