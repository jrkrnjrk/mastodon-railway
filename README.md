# Mastodon on Railway (v4.7.2)

Self-host [Mastodon](https://github.com/mastodon/mastodon) on Railway using
the official images, not a from-source Rails build.

This repo is a deploy wrapper:

| Service | Image | Role |
|---|---|---|
| **Web** | `ghcr.io/mastodon/mastodon:v4.7.2` | Puma + first-boot migrate / admin / secrets |
| **Sidekiq** | `ghcr.io/mastodon/mastodon:v4.7.2` | background jobs + scheduler |
| **Streaming** | `ghcr.io/mastodon/mastodon-streaming:v4.7.2` | WebSocket / streaming API |
| **Postgres** | Railway plugin | data |
| **Redis** | Railway plugin | cache + queues + pub/sub |

You add Postgres and Redis from the Railway canvas. This repo builds the
three app services.

Hobby plan or higher. Free/trial does not have enough RAM, volume, or
custom/public domain headroom.

You said you will use the Railway domain (`*.up.railway.app`). That works.
Pin `LOCAL_DOMAIN` to the **Web** hostname and do not change it after you
federate. A later custom domain needs a new instance.

## 1. Push this repo to GitHub

```bash
unzip mastodon-railway.zip
cd mastodon-railway
git init
git add .
git commit -m "Mastodon Railway v4.7.2"
git branch -M main
git remote add origin git@github.com:YOU/mastodon-railway.git
git push -u origin main
```

Connect GitHub to Railway if you have not already.

## 2. Create the Railway project

1. New Project → Empty project.
2. **+ Create** → Database → **PostgreSQL**. Rename the service `Postgres`.
3. **+ Create** → Database → **Redis**. Rename the service `Redis`.
4. **+ Create** → GitHub Repo → this repository.
   - Rename the service `Web`.
   - Root directory: `/` (default).
   - Config file path (Settings → Config-as-code): `railway.toml`.
5. **+ Create** → GitHub Repo → same repository again.
   - Rename the service `Sidekiq`.
   - Settings → Build → Dockerfile path: `Dockerfile.sidekiq`
     (or Config file path: `railway.sidekiq.toml`).
6. **+ Create** → GitHub Repo → same repository again.
   - Rename the service `Streaming`.
   - Settings → Build → Dockerfile path: `Dockerfile.streaming`
     (or Config file path: `railway.streaming.toml`).

Do not deploy yet if you can add variables first. If a deploy already
started, let Web crash, add vars, redeploy.

## 3. Volumes

On **Web** and **Sidekiq** attach a volume:

- Mount path: `/opt/mastodon/public/system`
- Use **one volume shared is not supported across services** on Railway.
  Attach a volume to Web. Sidekiq needs the same files for media
  processing.

Railway volumes are per-service. For a small Railway-domain instance:

- Attach the volume to **Web** (`/opt/mastodon/public/system`).
- Attach a **second** volume to **Sidekiq** at the same path if you process
  uploads on Sidekiq. They will **not** see each other's files.

Practical setup for a personal instance on Railway domains:

1. Attach the media volume to **Web** only.
2. Keep Sidekiq running for federation/jobs (it does not need local files
   if you later enable S3).
3. When you outgrow the 5 GB Hobby volume, enable S3/R2 (see
   `docs/VARIABLES.md`) so both Web and Sidekiq talk to object storage.

Set `RAILWAY_RUN_UID=0` on Web (and Sidekiq if it has a volume) so the
`mastodon` user can write the mount.

Hobby volume cap is 5 GB.

## 4. Public networking

On **Web**: generate a Railway domain. Copy the hostname
(`something.up.railway.app`).

On **Streaming**: generate a Railway domain. Copy that hostname too.

Web listens on Railway `PORT` (Puma). Streaming listens on Railway `PORT`
(Node, default 4000). Do not hard-code ports.

Healthchecks (already in the toml files):

- Web: `/health`
- Streaming: `/api/v1/streaming/health`

Leave Postgres and Redis **private**.

## 5. Variables

Full sheet: [`docs/VARIABLES.md`](docs/VARIABLES.md).

Minimum that must exist before Web can boot:

```
LOCAL_DOMAIN=${{Web.RAILWAY_PUBLIC_DOMAIN}}
WEB_DOMAIN=${{Web.RAILWAY_PUBLIC_DOMAIN}}
STREAMING_PUBLIC_DOMAIN=${{Streaming.RAILWAY_PUBLIC_DOMAIN}}
STREAMING_API_BASE_URL=wss://${{Streaming.RAILWAY_PUBLIC_DOMAIN}}
DATABASE_URL=${{Postgres.DATABASE_URL}}
REDIS_URL=${{Redis.REDIS_URL}}
ADMIN_USERNAME=admin
ADMIN_EMAIL=you@example.com
ADMIN_PASSWORD=long-password-here
RAILS_ENV=production
LOCAL_HTTPS=true
ES_ENABLED=false
RAILS_SERVE_STATIC_FILES=true
RAILWAY_RUN_UID=0
```

Put the same identity / DB / Redis / secrets on Web, Sidekiq, and
Streaming.

`LOCAL_DOMAIN` is permanent. It will become
`@admin@web-production-xxxx.up.railway.app`.

## 6. Deploy order

1. Postgres and Redis healthy.
2. Deploy **Web**. First boot generates secrets, runs `db:migrate`, creates
   the admin. Give it 3–5 minutes. Watch logs for the secrets block.
3. Copy the printed secrets into shared Variables.
4. Deploy **Streaming**, then **Sidekiq**.
5. Open `https://<web-railway-domain>` and log in with `ADMIN_EMAIL` /
   `ADMIN_PASSWORD`.

If Web loops on migrate, the database URL is wrong or Postgres is not
reachable on the private network.

## 7. What the entrypoint does

Web:

1. Derives `LOCAL_DOMAIN` from `RAILWAY_PUBLIC_DOMAIN` if unset.
2. Loads or generates secrets onto
   `/opt/mastodon/public/system/.railway/secrets.env`.
3. Waits for Postgres + Redis.
4. `rails db:migrate`.
5. Creates / updates the Owner account from `ADMIN_*`.
6. Starts Puma.

Sidekiq waits until those secrets exist (or are set as Variables), then
starts `bundle exec sidekiq`.

Streaming starts `node ./streaming/index.js` on `$PORT`.

## 8. After login

Preferences → Administration:

- instance name / description
- registrations **closed** until SMTP works
- federation on if you want the public timeline to fill

SMTP variables are in `docs/VARIABLES.md`. Without SMTP, extra signups and
password resets will not work. The first admin is already confirmed.

Useful shell commands on the Web service:

```bash
bin/tootctl accounts modify admin --confirm --approve
bin/tootctl cache clear
bin/tootctl media remove --days 30
bin/tootctl self-destruct    # destroys the instance. never run casually.
```

## 9. Resources

Quiet personal instance:

| Service | RAM |
|---|---|
| Web | 1–1.5 GB |
| Sidekiq | 1 GB |
| Streaming | 256–512 MB |
| Postgres | 1 GB |
| Redis | 256 MB |

Do not enable app sleeping. Sidekiq and streaming must stay up.

## 10. Upgrade

1. Snapshot / `pg_dump` Postgres.
2. Bump the image tags in `Dockerfile`, `Dockerfile.sidekiq`, and
   `Dockerfile.streaming` to the same new version.
3. Deploy Web first (migrations), then Sidekiq and Streaming.

Read https://github.com/mastodon/mastodon/releases before jumping versions.

## 11. Limits of a Railway-domain instance

- The handle is `@user@something.up.railway.app`.
- Changing that hostname later breaks federation.
- Hobby media volume is 5 GB.
- Railway Buckets are private and are a poor fit for Mastodon media.
- This is for you + a few accounts, not a public signup server.

Mastodon itself is AGPL-3.0. This wrapper is MIT. See `LICENSE`.
