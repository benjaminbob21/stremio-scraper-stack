# Stremio Scraper Stack (Jackett + FlareSolverr + Comet)

A self-hosted, uncensored scraping and debrid resolution stack for Stremio, featuring:
- **Jackett:** Multi-tracker indexer proxy with full support for mature/18+, cult, foreign, and niche cinema.
- **FlareSolverr:** Automatically solves Cloudflare challenges (Turnstile / DDoS protection) for public trackers like 1337x.
- **Comet:** High-speed FastAPI Stremio stream provider with native TorBox support.

---

## 🚀 Quick Start (On your Linux VM)

Run this one-liner on your VM to clone and launch everything:

```bash
git clone https://github.com/benjaminbob21/stremio-scraper-stack.git
cd stremio-scraper-stack
./setup.sh
```

The script will automatically:
1. Verify / install Docker & Docker Compose.
2. Spin up FlareSolverr, Jackett, and Comet.
3. Automatically grab your Jackett API key and link it to Comet.
4. Wire FlareSolverr to Jackett so Cloudflare challenges are solved automatically.

---

## ⚙️ Configuration & Stremio Setup

### 1. Jackett Setup (Port 9117)
Open `http://<VM_IP>:9117` (or `http://<TAILSCALE_IP>:9117`) in your browser:
* Click **+ Add indexer**.
* In the left filter, select **Adult** and **Movies**.
* Add your favorite trackers (e.g., 1337x, ThePirateBay, RuTracker, and niche/adult trackers).
* Test them to ensure they return green status checks.

### 2. Comet Setup (Port 8000)
Open `http://<VM_IP>:8000/configure` (or `http://<TAILSCALE_IP>:8000/configure`):
* Select **TorBox** as your debrid service.
* Paste your **TorBox API Key** ([find it here](https://torbox.app/settings)).
* Ensure **"Don't show download to debrid"** is **UNCHECKED** (allows you to see uncached streams).
* Click **Install Add-on** (or copy the generated manifest link and paste it into Stremio's search bar).

---

## 🔒 Oracle Cloud Firewall Note (If using Public IP)
If you access the web interfaces via public IP (`150.136.77.174`) rather than Tailscale, make sure ports `8000` and `9117` are open in:
1. **Oracle Cloud Ingress Rules:** Virtual Cloud Network (VCN) -> Security Lists -> Ingress Rules -> Add Ingress for TCP 8000, 9117.
2. **Ubuntu iptables / ufw:**
   ```bash
   sudo ufw allow 8000/tcp
   sudo ufw allow 9117/tcp
   ```
*(If you use your VM's Tailscale IP, no public ports need to be opened!)*
