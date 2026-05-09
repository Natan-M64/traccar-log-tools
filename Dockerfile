FROM alpine:3.20

LABEL org.opencontainers.image.title="traccar-log-tools"
LABEL org.opencontainers.image.description="Lightweight Docker sidecar for viewing and searching Traccar logs"
LABEL org.opencontainers.image.source="https://github.com/Natan-M64/traccar-log-tools"
LABEL org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache \
    bash \
    grep \
    coreutils \
    less \
    gzip \
    sed \
    gawk \
    findutils

COPY entrypoint.sh /entrypoint.sh
COPY profile.sh /etc/profile

RUN chmod +x /entrypoint.sh

ENV LOG_FILE=/opt/traccar/logs/tracker-server.log
ENV LOG_DIR=/opt/traccar/logs
ENV ENV=/etc/profile

ENTRYPOINT ["/entrypoint.sh"]
