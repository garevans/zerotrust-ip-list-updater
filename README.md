# **ZeroTrust IP List Updater**

A lightweight Alpine‑based container that automatically monitors your public IPv4 address and updates a Cloudflare Zero Trust **Reusable IP List** whenever your WAN IP changes. Ideal for home broadband setups where your ISP assigns a dynamic IP but Cloudflare firewall or Zero Trust rules require a stable source IP.

---

## **Features**
- Detects your current public IPv4 address every 60 seconds  
- Updates a Cloudflare Zero Trust Gateway IP List only when the IP changes  
- Persists the last known IP via a dedicated data directory  
- Optional Pushover push notifications on IP change  
- Minimal footprint (Alpine + curl + bash)  
- No secrets stored in the image — all credentials supplied via environment variables  

---

## **Environment Variables**

Set these directly in your Compose file or deployment environment:

```
CF_API_TOKEN=
CF_ACCOUNT_ID=
CF_LIST_ID=
CF_LIST_NAME=
CF_LIST_DESCRIPTION=

# Optional Pushover notifications
PUSHOVER_TOKEN=
PUSHOVER_USER=
```

---

## **Persistent Data**

The container stores the last known IP in:

```
/app/data/last_ip.txt
```

Mount this directory as a volume to persist state across restarts.

---

## **Example docker‑compose.yml**

```yaml
version: "3.9"

services:
  cf-ip-updater:
    image: garevans/zerotrust-ip-list-updater:1.2
    container_name: cf-ip-updater
    restart: unless-stopped
    environment:
      CF_API_TOKEN: "your_cloudflare_api_token"
      CF_ACCOUNT_ID: "your_account_id"
      CF_LIST_ID: "your_list_id"
      CF_LIST_NAME: "your_list_name"
      CF_LIST_DESCRIPTION: "your_list_description"
      PUSHOVER_TOKEN: "your_pushover_token"        # optional
      PUSHOVER_USER: "your_pushover_user"          # optional
    volumes:
      - cf-ip-updater-data:/app/data

volumes:
  cf-ip-updater-data:
```

---

## **How It Works**

1. Retrieves your public IP from `api.ipify.org`  
2. Compares it to the stored IP in `/app/data/last_ip.txt`  
3. If unchanged → logs and waits  
4. If changed →  
   - Updates the Cloudflare IP list  
   - Saves the new IP  
   - Sends a Pushover notification (if configured)  

---

## **Security**

- No API tokens or secrets are included in the image  
- All credentials are supplied at runtime  
- The container only communicates with:  
  - Cloudflare API  
  - ipify (to detect WAN IP)  
  - Pushover (optional)  

---

## **Release 1.2**

Release 1.2 rebases the image from Alpine 3.19 onto Alpine 3.24, the current supported stable release. The runtime behaviour and environment variables are unchanged from 1.1, so an existing deployment can move to `garevans/zerotrust-ip-list-updater:1.2` without a configuration change.

Alpine 3.19's CA bundle (the published 1.1 image is Alpine 3.19.9 with `ca-certificates` 20250911) still trusts the eMudhra root **emSign ECC Root CA - G3** (`CN=emSign ECC Root CA - G3, O=eMudhra Technologies Limited, OU=emSign PKI, C=IN`). That root was removed in the October 2026 CA security update. Alpine 3.24 ships `ca-certificates-bundle` 20261020, which no longer includes it. There is no certificate in either bundle whose common name is exactly `emSign Root CA - G3`; the 1.1 root is the ECC G3 certificate above.

The 1.2 bundle still contains one other eMudhra root, **emSign Root CA - G1** (`CN=emSign Root CA - G1, O=eMudhra Technologies Limited, OU=emSign PKI, C=IN`). That certificate is still in the Mozilla trust store shipped by Alpine, so this image does not remove it. The other emSign roots present in 1.1 (emSign ECC Root CA - C3, emSign Root CA - C1, and emSign ECC Root CA - G3) are not in the 1.2 bundle.

Checked at release time against `alpine:3.24`, which resolved to Alpine 3.24.3.

---

## **Build and push**

Publishing to Docker Hub is manual. From a checkout of this repository:

```
docker build -t garevans/zerotrust-ip-list-updater:1.2 -t garevans/zerotrust-ip-list-updater:latest .
docker push garevans/zerotrust-ip-list-updater:1.2
docker push garevans/zerotrust-ip-list-updater:latest
```

---

## **Contributions**

Generated with assistance from AI.  
Designed to remain minimal, reliable, and easy to maintain.
