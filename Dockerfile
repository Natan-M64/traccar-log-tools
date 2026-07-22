FROM alpine:3.20

LABEL org.opencontainers.image.title="traccar-log-tools"
LABEL org.opencontainers.image.description="Lightweight Docker sidecar for viewing and searching Traccar logs"
LABEL org.opencontainers.image.source="https://github.com/Natan-M64/traccar-log-tools"
LABEL org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache \
    bash \
    python3 \
    grep \
    coreutils \
    less \
    gzip \
    sed \
    gawk \
    findutils

COPY entrypoint.sh /entrypoint.sh
COPY api_server.py /api_server.py
COPY profile.sh /etc/profile
COPY profile.sh /root/.profile
COPY profile.sh /root/.ashrc
COPY profile.sh /root/.bashrc
COPY log-help /usr/local/bin/log-help

RUN chmod +x /entrypoint.sh /api_server.py /usr/local/bin/log-help

ENV LOG_FILE=/opt/traccar/logs/tracker-server.log
ENV LOG_DIR=/opt/traccar/logs
ENV LOG_MODE=tail
ENV API_HOST=0.0.0.0
ENV API_PORT=8080
ENV MAX_LINES=2000
ENV TAIL_LINES=200
ENV ENV=/root/.ashrc

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
