# Mastodon web (Puma) for Railway
# Official image: https://github.com/mastodon/mastodon/pkgs/container/mastodon
FROM ghcr.io/mastodon/mastodon:v4.7.2

USER root
RUN mkdir -p /railway
COPY scripts/common.sh scripts/generate-secrets.sh scripts/web-entrypoint.sh scripts/bootstrap-admin.rb /railway/
RUN chmod 0755 /railway/common.sh /railway/generate-secrets.sh /railway/web-entrypoint.sh \
    && chown -R mastodon:mastodon /railway

USER mastodon
WORKDIR /opt/mastodon
EXPOSE 3000
CMD ["/railway/web-entrypoint.sh"]
