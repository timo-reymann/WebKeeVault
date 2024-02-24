FROM ubuntu as keeweb_sources
WORKDIR /build
RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        unzip

# renovate: datasource=github-releases depName=keeweb/keeweb
ARG keeweb_version=v1.18.7
RUN curl -Ls https://github.com/keeweb/keeweb/releases/download/${keeweb_version}/KeeWeb-$(echo $keeweb_version | cut -c 2-).html.zip --output keeweb.zip \
    && ls -la \
    && unzip keeweb.zip \
    && rm keeweb.zip

RUN sed -i 's/(no-config)/config.json/g' index.html

FROM caddy:2.7.6 as caddy_base

FROM scratch as files
COPY --from=keeweb_sources /build /opt/keeweb
COPY Caddyfile /etc/caddy/Caddyfile

FROM gcr.io/distroless/static-debian12

LABEL org.opencontainers.image.title="WebKeeVault"
LABEL org.opencontainers.image.description="Access your keepass files hosted on WebDAV through the browser"
LABEL org.opencontainers.image.ref.name="main"
LABEL org.opencontainers.image.licenses='MIT'
LABEL org.opencontainers.image.vendor="Timo Reymann <mail@timo-reymann.de>"
LABEL org.opencontainers.image.authors="Timo Reymann <mail@timo-reymann.de>"
LABEL org.opencontainers.image.url="https://github.com/timo-reymann/WebKeeVault"
LABEL org.opencontainers.image.documentation="https://github.com/timo-reymann/WebKeeVault"
LABEL org.opencontainers.image.source="https://github.com/timo-reymann/WebKeeVault.git"

ENV KW_WEBDAV_PROTOCOL=https
ENV KW_WEBDAV_AUTH_TYPE=Basic
ENV KW_FILE_DISPLAY_NAME="My Passwords"

COPY --from=caddy_base --chown=nonroot:nonroot /usr/bin/caddy /usr/bin/caddy
COPY --from=files --chown=nonroot:nonroot / /

EXPOSE 8080
ENTRYPOINT ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
