# GlitchTip deployment (ADR-0009)

Self-hosted crash-report backend. The app talks to it through the standard
`sentry_flutter` SDK — the backend is just a DSN passed at build time.

## Provision (once)

1. A VPS with Docker + Docker Compose, ≥1 GB RAM (GlitchTip's stated minimum
   is far lower; 1 GB is comfortable headroom for the whole stack). An
   Iranian provider keeps billing in rial and guarantees in-country
   reachability — the entire point of self-hosting (ADR-0009).
2. A DNS A record for the chosen subdomain (e.g. `crash.<domain>.ir`)
   pointing at the VPS. Ports 80/443 open (Caddy provisions Let's Encrypt
   automatically).

## Install

### Option A — dedicated VPS (Caddy terminates TLS)

```sh
# on the VPS
git clone <this repo> && cd miras/deploy/glitchtip
cp .env.example .env && $EDITOR .env                  # SECRET_KEY, domain, email
docker compose -f compose.yml up -d                   # Caddy binds :80/:443
```

### Option B — shared VPS with existing Nginx (e.g. tebtejarat.com)

Do **not** use `compose.yml` (Caddy would fight Nginx for ports 80/443).

```sh
# on the VPS — separate directory from other apps
mkdir -p /var/www/miras && rsync -a deploy/glitchtip/ /var/www/miras/glitchtip/
cd /var/www/miras/glitchtip
cp .env.example .env && $EDITOR .env
# GLITCHTIP_HOST=miras.tebtejarat.com
# GLITCHTIP_DOMAIN=https://miras.tebtejarat.com

docker compose -p miras-glitchtip -f compose.nginx.yml --env-file .env up -d

sudo cp nginx-miras.conf /etc/nginx/sites-available/miras.tebtejarat.com
sudo ln -sf /etc/nginx/sites-available/miras.tebtejarat.com /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d miras.tebtejarat.com
```

GlitchTip listens on `127.0.0.1:8001` (Teb Tejarat GlitchTip uses `:8000`).

Then in the web UI (`https://miras.tebtejarat.com` or `https://crash.<domain>.ir`):
register the first account (becomes superuser), create organization `miras` →
project (platform: Flutter) → copy the **DSN**.

## Wire the app

Release builds pass the DSN out-of-band (never committed — ADR-0007):

```sh
flutter build apk --release --dart-define=SENTRY_DSN=<dsn>
```

An empty/absent define disables crash reporting entirely (dev builds).

## Verify (per ADR-0007/0009, before the first beta with crash reporting)

1. Force a test crash on a device **without VPN** (Iranian IP) — the event
   must appear in the dashboard.
2. Inspect that first event end-to-end and confirm zero PII: no names, no
   contacts, no identifiers beyond app version + device model/OS.

## Operate

- **Upgrade:** `docker compose pull && docker compose stop && docker compose up -d`
- **Backup (cron, daily):**
  `docker compose exec -T postgres pg_dump -U postgres postgres | gzip > glitchtip-$(date +%F).sql.gz`
  Keep copies off the VPS.
- **Event retention:** GlitchTip prunes by default; disk budget ~30 GB per
  million events/month (far beyond beta scale).
