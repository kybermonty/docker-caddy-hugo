FROM debian:stretch

ARG plugins=http.cache,http.expires,http.git,http.hugo,http.realip
ARG telemetry=on

ENV HUGO_VERSION 0.52

ENV HUGO_BINARY hugo_${HUGO_VERSION}_Linux-64bit.deb

RUN apt-get -qq update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends git curl tar ca-certificates libcap2-bin \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -sL -o /tmp/hugo.deb \
    https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY} && \
    dpkg -i /tmp/hugo.deb && \
    rm /tmp/hugo.deb && \
    hugo version

RUN curl --silent --show-error --fail --location --header "Accept: application/tar+gzip, application/x-gzip, application/octet-stream" -o - \
      "https://caddyserver.com/download/linux/amd64?plugins=${plugins}&license=personal&telemetry=${telemetry}" \
    | tar --no-same-owner -C /usr/bin/ -xz caddy && \
    chmod 0755 /usr/bin/caddy && \
    addgroup --system caddy && \
    adduser --system --shell /usr/sbin/nologin --ingroup caddy caddy && \
    setcap cap_net_bind_service=+ep `readlink -f /usr/bin/caddy` && \
    /usr/bin/caddy -version && \
    /usr/bin/caddy -plugins

EXPOSE 80 443 2015

USER caddy

RUN mkdir /home/caddy/www
VOLUME /home/caddy/www
WORKDIR /home/caddy/www

ADD files/Caddyfile /etc/Caddyfile
ADD files/index.html /home/caddy/www/index.html

ENTRYPOINT ["/usr/bin/caddy"]
CMD ["--conf", "/etc/Caddyfile"]
