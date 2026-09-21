# Click path

1. Unzip, push to GitHub.
2. Railway → New Empty Project.
3. Add PostgreSQL. Name it `Postgres`.
4. Add Redis. Name it `Redis`.
5. Add GitHub repo as service `Web`. Config file: `railway.toml`.
6. Add same repo as service `Sidekiq`. Dockerfile path: `Dockerfile.sidekiq`.
7. Add same repo as service `Streaming`. Dockerfile path: `Dockerfile.streaming`.
8. Web + Sidekiq: volume mount `/opt/mastodon/public/system` (see README note).
9. Web + Streaming: Generate Railway domain.
10. Paste variables from `VARIABLES.md` onto Web, Sidekiq, Streaming.
11. Set `RAILWAY_RUN_UID=0` on Web.
12. Deploy Web → copy secrets from logs → deploy Streaming → deploy Sidekiq.
13. Log in at the Web Railway URL with `ADMIN_EMAIL` / `ADMIN_PASSWORD`.
