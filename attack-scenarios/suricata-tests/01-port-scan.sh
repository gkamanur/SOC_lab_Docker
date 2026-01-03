#!/bin/bash

# Port Scan Attack Scenario
# Triggers Suricata port scan detection rules

TARGET="${1:-172.20.0.50}"

echo "[*] Port Scan Attack Scenario"
echo "[*] Target: $TARGET"
echo ""

echo "[1] Running Nmap SYN Scan..."
nmap -sS -p 1-1000 $TARGET

echo ""
echo "[2] Running Nmap NULL Scan..."
nmap -sN -p 80,443,22 $TARGET

echo ""
echo "[3] Running Nmap FIN Scan..."
nmap -sF -p 80,443,22 $TARGET

echo ""
echo "[4] Running Nmap XMAS Scan..."
nmap -sX -p 80,443,22 $TARGET

echo ""
echo "[5] Running comprehensive port sweep..."
nmap -p- --max-rate 1000 $TARGET

echo ""
echo "[*] Port scan scenario complete!"
echo "[*] Check Suricata alerts for detection"
