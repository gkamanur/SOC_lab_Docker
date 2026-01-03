#!/bin/bash

# Suricata Rule Update Script
# Downloads and updates Emerging Threats Open ruleset

set -e

RULES_DIR="/var/lib/suricata/rules"
TEMP_DIR="/tmp/suricata-rules"
ET_URL="https://rules.emergingthreats.net/open/suricata-6.0/emerging.rules.tar.gz"

echo "[*] Suricata Rule Update Script"
echo "[*] Downloading Emerging Threats Open ruleset..."

# Create directories
mkdir -p "$RULES_DIR"
mkdir -p "$TEMP_DIR"

# Download rules
if command -v wget &> /dev/null; then
    wget -q -O "$TEMP_DIR/emerging.rules.tar.gz" "$ET_URL"
elif command -v curl &> /dev/null; then
    curl -s -o "$TEMP_DIR/emerging.rules.tar.gz" "$ET_URL"
else
    echo "[!] Error: Neither wget nor curl found. Cannot download rules."
    exit 1
fi

echo "[*] Extracting rules..."
tar -xzf "$TEMP_DIR/emerging.rules.tar.gz" -C "$TEMP_DIR"

echo "[*] Installing rules..."
# Combine all rules into a single file
cat "$TEMP_DIR/rules/"*.rules > "$RULES_DIR/suricata.rules"

# Add custom rules if they exist
if [ -f "/etc/suricata/rules/custom.rules" ]; then
    echo "[*] Appending custom rules..."
    cat /etc/suricata/rules/custom.rules >> "$RULES_DIR/suricata.rules"
fi

echo "[*] Cleaning up..."
rm -rf "$TEMP_DIR"

echo "[*] Rules updated successfully!"
echo "[*] Total rules: $(grep -c "^alert\|^drop\|^pass\|^reject" "$RULES_DIR/suricata.rules" || echo 0)"

# Reload Suricata if running
if command -v suricatasc &> /dev/null; then
    echo "[*] Reloading Suricata..."
    suricatasc -c reload-rules || echo "[!] Could not reload rules. Restart Suricata manually."
else
    echo "[!] Suricatasc not found. Please restart Suricata to apply new rules."
fi

echo "[*] Done!"
