# Railway variable sheet

Name your services exactly:

- `Web`
- `Sidekiq`
- `Streaming`
- `Postgres`
- `Redis`

Then you can paste the references below.

Put secrets and identity variables on **all three** app services, or use Railway shared variables.

## Required on Web, Sidekiq, Streaming

```
RAILS_ENV=production
NODE_ENV=production
LOCAL_HTTPS=true
ES_ENABLED=false
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
BIND=0.0.0.0
RAILWAY_RUN_UID=0

LOCAL_DOMAIN=${{Web.RAILWAY_PUBLIC_DOMAIN}}
WEB_DOMAIN=${{Web.RAILWAY_PUBLIC_DOMAIN}}
STREAMING_PUBLIC_DOMAIN=${{Streaming.RAILWAY_PUBLIC_DOMAIN}}
STREAMING_API_BASE_URL=wss://${{Streaming.RAILWAY_PUBLIC_DOMAIN}}

DATABASE_URL=${{Postgres.DATABASE_URL}}
REDIS_URL=${{Redis.REDIS_URL}}
```

`LOCAL_DOMAIN` must be the hostname only, no `https://`. Railway's
`${{Web.RAILWAY_PUBLIC_DOMAIN}}` is already a hostname like
`web-production-xxxx.up.railway.app`.

If your Postgres or Redis service uses a different name, change the
reference. Railway Redis usually exposes `REDIS_URL`. Railway Postgres
usually exposes `DATABASE_URL`.

## Required on Web only (first boot)

```
ADMIN_USERNAME=admin
ADMIN_EMAIL=you@example.com
ADMIN_PASSWORD=use-a-long-password
```

The admin is auto-confirmed so you can log in before SMTP works.

## Secrets

First Web boot writes these to the media volume and prints them in logs:

- `SECRET_KEY_BASE`
- `OTP_SECRET`
- `VAPID_PRIVATE_KEY`
- `VAPID_PUBLIC_KEY`
- `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`
- `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`
- `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`

Copy that block into shared Railway Variables after the first successful
deploy. Do not rotate them later.

## SMTP (strongly recommended)

```
SMTP_SERVER=smtp.resend.com
SMTP_PORT=587
SMTP_LOGIN=resend
SMTP_PASSWORD=
SMTP_FROM_ADDRESS=noreply@example.com
SMTP_AUTH_METHOD=plain
SMTP_ENABLE_STARTTLS=auto
SMTP_OPENSSL_VERIFY_MODE=peer
```

Mastodon also accepts `SMTP_USERNAME` as an alias in some versions; this
image uses `SMTP_LOGIN`.

## Optional S3

Railway volumes are capped on Hobby (5 GB). For anything that federates
media, switch to R2/S3/Wasabi and set:

```
S3_ENABLED=true
S3_PROTOCOL=https
S3_REGION=auto
S3_ENDPOINT=
S3_BUCKET=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
S3_ALIAS_HOST=
```

Do not use Railway Buckets for Mastodon media. They are private-only.

## Tuning

```
WEB_CONCURRENCY=2
MAX_THREADS=5
SIDEKIQ_CONCURRENCY=5
```

Give Web ~1–1.5 GB RAM, Sidekiq ~1 GB, Streaming ~256–512 MB, Postgres ~1 GB.
