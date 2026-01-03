#!/bin/bash

# DNS Tunneling Simulation
# Triggers DNS anomaly detection

DNS_SERVER="${1:-8.8.8.8}"

echo "[*] DNS Tunneling Attack Scenario"
echo "[*] DNS Server: $DNS_SERVER"
echo ""

echo "[1] Long DNS query (potential tunneling)..."
LONG_QUERY="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.example.com"
dig @$DNS_SERVER $LONG_QUERY >/dev/null 2>&1 || true
sleep 1

echo "[2] Multiple TXT record queries..."
for i in {1..5}; do
    dig @$DNS_SERVER TXT "data$i.tunnel.example.com" >/dev/null 2>&1 || true
    sleep 0.5
done

echo "[3] Suspicious subdomain queries..."
for i in {1..10}; do
    RANDOM_SUB=$(head /dev/urandom | tr -dc a-z0-9 | head -c 20)
    dig @$DNS_SERVER "$RANDOM_SUB.tunnel.example.com" >/dev/null 2>&1 || true
    sleep 0.3
done

echo ""
echo "[*] DNS tunneling scenario complete!"
echo "[*] Check Suricata alerts for DNS anomalies"
