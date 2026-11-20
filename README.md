# senddock-railway

Wrapper image for [SendDock](https://github.com/SendDock/senddock) (open source email marketing and transactional email platform, AGPL-3.0) on Railway.

It runs the official `ghcr.io/senddock/senddock` image, pinned by digest. It builds `DATABASE_URL` and `REDIS_URL` from the Railway
variables, binds to the injected `PORT`, and creates the administrator from `SENDDOCK_ADMIN_EMAIL` and `SENDDOCK_ADMIN_PASSWORD` as
soon as the server answers. SendDock's first-run setup endpoint is open to whoever reaches it first, so doing it at boot means no
stranger can claim the instance. It only acts while `setup_required` is true, so a redeploy never touches existing data.

Needs Postgres 17 and Redis alongside it; the Railway template wires both. Licence of this wrapper: MIT. SendDock itself is AGPL-3.0.
