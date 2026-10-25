#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo " Setting up Stremio Scraper Stack on VM   "
echo " (Jackett + FlareSolverr + Comet)        "
echo "=========================================="

# 1. Install Docker & Docker Compose if missing
if ! command -v docker &>/dev/null; then
  echo "[-] Docker not found. Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo usermod -aG docker "$USER" || true
  rm get-docker.sh
  echo "[+] Docker installed."
fi

# Detect docker compose syntax
DOCKER_COMPOSE="docker compose"
if ! docker compose version &>/dev/null; then
  if command -v docker-compose &>/dev/null; then
    DOCKER_COMPOSE="docker-compose"
  else
    echo "[-] Installing Docker Compose plugin..."
    sudo apt-get update && sudo apt-get install -y docker-compose-plugin
  fi
fi

# 2. Start Jackett & FlareSolverr first
echo "[+] Starting FlareSolverr and Jackett..."
$DOCKER_COMPOSE up -d flaresolverr jackett

# 3. Wait for Jackett to generate its ServerConfig.json
CONFIG_FILE="./data/jackett/config/Jackett/ServerConfig.json"
echo "[+] Waiting for Jackett to initialize configuration..."

for i in {1..30}; do
  if [[ -f "$CONFIG_FILE" ]] && grep -q '"APIKey"' "$CONFIG_FILE" 2>/dev/null; then
    break
  fi
  sleep 2
done

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "[!] Jackett configuration taking longer than usual. Waiting another 10s..."
  sleep 10
fi

# Extract API Key from Jackett config
JACKETT_API_KEY=""
if [[ -f "$CONFIG_FILE" ]]; then
  JACKETT_API_KEY=$(grep -o '"APIKey": *"[^"]*"' "$CONFIG_FILE" | head -n1 | cut -d'"' -f4 || true)
fi

if [[ -z "$JACKETT_API_KEY" ]]; then
  echo "[!] Could not automatically read Jackett API key."
  echo "    Please visit http://<VM_IP>:9117, copy the API key, and add JACKETT_API_KEY=... in .env"
else
  echo "[+] Found Jackett API Key: $JACKETT_API_KEY"
  echo "JACKETT_API_KEY=$JACKETT_API_KEY" > .env
  
  # Set FlareSolverr URL in Jackett config if not already configured
  if grep -q '"FlareSolverrUrl": *""' "$CONFIG_FILE" 2>/dev/null; then
    sed -i 's|"FlareSolverrUrl": *""|"FlareSolverrUrl": "http://flaresolverr:8191"|g' "$CONFIG_FILE" || true
    echo "[+] Linked FlareSolverr to Jackett."
    $DOCKER_COMPOSE restart jackett
  fi
fi

# 4. Start Comet
echo "[+] Starting Comet..."
$DOCKER_COMPOSE up -d comet

# 5. Get IP info
PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "150.136.77.174")
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")

echo ""
echo "=========================================="
echo " Stack is up and running!                "
echo "=========================================="
echo "Jackett Dashboard: http://$PUBLIC_IP:9117"
if [[ -n "$TAILSCALE_IP" ]]; then
  echo "  (or Tailscale): http://$TAILSCALE_IP:9117"
fi
echo ""
echo "Comet Configurator: http://$PUBLIC_IP:8000/configure"
if [[ -n "$TAILSCALE_IP" ]]; then
  echo "  (or Tailscale):   http://$TAILSCALE_IP:8000/configure"
fi
echo "=========================================="
echo "Next Steps:"
echo "1. Open Jackett (port 9117) and add your trackers (enable 'Adult' for 18+ content)."
echo "2. Open Comet (port 8000/configure), paste your TorBox API key, and click 'Install Add-on'."
echo "=========================================="
