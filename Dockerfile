# SendDock wrapper for Railway. The official image serves a first-run setup endpoint (POST /api/v1/setup) that is open to the first
# visitor until a user exists, and it needs DATABASE_URL and REDIS_URL assembled by hand. This image builds both URLs from the
# Railway variables, binds to Railway's injected PORT, and creates the administrator from SENDDOCK_ADMIN_* as soon as the server
# answers, so no stranger can claim the instance and no one has to open the setup page.
# upstream: SendDock/senddock
FROM ghcr.io/senddock/senddock:0.8.3@sha256:1110e33b09244ae4af034099b965b1cc88ba0f6f39929e34e1dd0ee837a1af43

USER root
RUN apk add --no-cache curl jq

COPY --chmod=0755 boot.sh /railway-boot.sh

ENV SENDDOCK_ADMIN_NAME=Admin

EXPOSE 8080
ENTRYPOINT ["/railway-boot.sh"]
CMD ["./entrypoint.sh"]
