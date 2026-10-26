# traccar-log-tools

[![CI](https://github.com/Natan-M64/traccar-log-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/Natan-M64/traccar-log-tools/actions/workflows/ci.yml)
[![Docker Publish](https://github.com/Natan-M64/traccar-log-tools/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Natan-M64/traccar-log-tools/actions/workflows/docker-publish.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Lightweight Docker sidecar for viewing and searching Traccar logs from Docker, Portainer, SSH, or mobile devices.

`traccar-log-tools` makes the Traccar `tracker-server.log` available through `docker logs` while also providing an interactive shell with useful commands and aliases such as `errors`, `warnings`, `today`, `zgrep`, `grep`, `tail`, and `less`.

It is designed for Traccar deployments running with Docker Compose.

---

## Why this exists

Traccar commonly writes its main application log to a file inside the Traccar data directory:

```text
/opt/traccar/logs/tracker-server.log
```

In many Docker deployments, `docker logs` only shows startup messages, database migration output, or very limited stdout/stderr content. The useful runtime logs are inside the Traccar data volume.

This sidecar solves that by:

- following `tracker-server.log` with `tail -n "$TAIL_LINES" -F`;
- making Traccar logs visible through Docker and Portainer logs;
- providing quick shell tools for searching logs;
- supporting compressed rotated logs with `zgrep`;
- running with the Traccar volume mounted as read-only;
- requiring no network access.

---

## Features

- Lightweight Alpine-based image.
- Works as a Docker Compose sidecar.
- Shows Traccar logs through `docker logs`.
- Useful from Portainer, including mobile access.
- Includes `grep`, `zgrep`, `awk`, `sed`, `less`, `tail`, `find`, and common shell utilities.
- Interactive shell help menu with examples.
- Optional HTTP API mode for read-only IMEI log queries.
- Read-only access to the Traccar data volume.
- No network required.
- Safe default Docker logging limits.

---

## How it works

The container must run in the same Docker Compose stack as your Traccar container, or at least mount the same Traccar data volume.

Example:

```yaml
services:
  traccar:
    volumes:
      - traccar_data:/opt/traccar

  traccar_logs:
    image: ghcr.io/natan-m64/traccar-log-tools:latest
    volumes:
      - traccar_data:/opt/traccar:ro
```

The `:ro` flag is recommended for read-only log viewing. To enable optional rotation cleanup in the same container, use the maintenance override instead:

```sh
docker compose -f docker-compose.example.yml -f docker-compose.janitor.example.yml config
docker compose -f docker-compose.example.yml -f docker-compose.janitor.example.yml up -d
```

The default Compose file only reads logs. The maintenance override enables `LOG_JANITOR=true` and mounts only the `logs` subpath with write access while keeping the rest of `/opt/traccar` read-only. Initialize a new Traccar volume using the base stack first; the logs directory must already exist inside `traccar_data` before enabling maintenance, to preserve volume initialization; Docker Engine 26+ and a Compose release supporting volume `subpath` are required. Confirm these versions and the volume name on the deployment host before applying the override. Use the files together as a single stack, not as two independent stacks. The optional API service remains read-only.

---

## Docker Compose example

```yaml
services:
  # Example Traccar service.
  # In your own stack, keep your existing Traccar configuration.
  traccar:
    image: traccar/traccar:latest
    restart: unless-stopped
    ports:
      - "8082:8082"
    volumes:
      - traccar_data:/opt/traccar

  # Add this sidecar service to the same Compose stack as Traccar.
  traccar_logs:
    image: ghcr.io/natan-m64/traccar-log-tools:latest
    restart: unless-stopped
    depends_on:
      - traccar
    logging:
      driver: "json-file"
      options:
        max-size: "25m"
        max-file: "2"
    environment:
      LOG_FILE: /opt/traccar/logs/tracker-server.log
      LOG_DIR: /opt/traccar/logs
    volumes:
      # Must be the same volume used by the Traccar container.
      # Mounted read-only for safety.
      - traccar_data:/opt/traccar:ro
    network_mode: "none"
    security_opt:
      - no-new-privileges:true

volumes:
  traccar_data:
```

---

## Using with an existing Traccar stack

If you already have a Traccar Compose stack, add only this service:

```yaml
traccar_logs:
  image: ghcr.io/natan-m64/traccar-log-tools:latest
  restart: unless-stopped
  depends_on:
    - traccar
  logging:
    driver: "json-file"
    options:
      max-size: "25m"
      max-file: "2"
  environment:
    LOG_FILE: /opt/traccar/logs/tracker-server.log
    LOG_DIR: /opt/traccar/logs
  volumes:
    - traccar_data:/opt/traccar:ro
  network_mode: "none"
  security_opt:
    - no-new-privileges:true
```

Make sure `traccar_data` is the same volume used by your Traccar container.

---

## Viewing logs

```bash
docker logs -f traccar_logs
```

Depending on your Compose project name, the container name may be different. You can also use:

```bash
docker compose logs -f traccar_logs
```

In Portainer, open the `traccar_logs` container and use the Logs tab.

---

## Optional HTTP API mode

The default container mode is still local and safe: it follows the log with `tail -n "$TAIL_LINES" -F` and does not need network access.

If you need an external tool, automation, or AI assistant to inspect logs without SSH, run a separate API container with `LOG_MODE=api`.

Available endpoints:

| Endpoint | Description |
|---|---|
| `GET /health` | Health check |
| `GET /device/{imei}?limit=300` | Returns the latest matching lines for an IMEI as JSON |
| `GET /stream/{imei}` | Streams new matching lines for an IMEI using Server-Sent Events |

Example:

```yaml
traccar_logs_api:
  image: ghcr.io/natan-m64/traccar-log-tools:latest
  restart: unless-stopped
  environment:
    LOG_MODE: api
    LOG_FILE: /opt/traccar/logs/tracker-server.log
    LOG_DIR: /opt/traccar/logs
    API_TOKEN: "change-this-token"
    API_PORT: "8080"
    MAX_LINES: "2000"
  volumes:
    - traccar_data:/opt/traccar:ro
  ports:
    - "8080:8080"
  security_opt:
    - no-new-privileges:true
```

Query an IMEI:

```bash
curl -H "Authorization: Bearer change-this-token" \
  "http://localhost:8080/device/000000000000000?limit=50"
```

Follow an IMEI live:

```bash
curl -N -H "Authorization: Bearer change-this-token" \
  "http://localhost:8080/stream/000000000000000"
```

For public access, put this service behind HTTPS using Traefik, Cloudflare Tunnel, Nginx, or another reverse proxy. Keep the Traccar volume mounted as read-only.

Traefik example:

```yaml
traccar_logs_api:
  image: ghcr.io/natan-m64/traccar-log-tools:latest
  restart: unless-stopped
  environment:
    LOG_MODE: api
    LOG_FILE: /opt/traccar/logs/tracker-server.log
    API_TOKEN: "change-this-token"
  volumes:
    - traccar_data:/opt/traccar:ro
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.traccar-logs-api.rule=Host(`logs.example.com`)"
    - "traefik.http.routers.traccar-logs-api.entrypoints=websecure"
    - "traefik.http.routers.traccar-logs-api.tls.certresolver=letsencrypt"
    - "traefik.http.services.traccar-logs-api.loadbalancer.server.port=8080"
  security_opt:
    - no-new-privileges:true
```

### API environment variables

| Variable | Default | Description |
|---|---|---|
| `LOG_MODE` | `tail` | Use `api` to start the HTTP API instead of `tail -F` |
| `API_TOKEN` | empty | Required in API mode. Use as `Authorization: Bearer <token>` |
| `API_HOST` | `0.0.0.0` | API bind host |
| `API_PORT` | `8080` | API bind port |
| `MAX_LINES` | `2000` | Maximum accepted `limit` for `/device/{imei}` |
| `TAIL_LINES` | `200` | Number of recent lines shown when starting `tail`/`follow` mode |
| `ALLOW_NO_AUTH` | `false` | Allows API without token only for local testing |

Security recommendations:

- use a long random `API_TOKEN`;
- publish only through HTTPS;
- do not expose the API publicly without a token;
- keep the volume mounted with `:ro`;
- do not mount the Docker socket;
- limit access further with reverse proxy rules if possible.

---

## Interactive shell

Open a shell inside the container:

```bash
docker exec -it traccar_logs sh
```

Or use the Portainer console.

When the shell opens, a help menu is displayed with aliases and examples.

---

## Available aliases

| Alias | Description |
|---|---|
| `logs` | Follow the current log with `tail -n "$TAIL_LINES" -f` |
| `follow` | Follow the current log with `tail -n "$TAIL_LINES" -F`, useful for rotated logs |
| `errors` | Show recent errors, exceptions, warnings, failures, and timeouts |
| `warnings` | Show recent warnings |
| `today` | Show recent log lines from today |
| `gzerrors` | Search common errors inside compressed `.gz` logs |
| `listlogs` | List files in the log directory |
| `ll` | Shortcut for `ls -lah` |

---

## Useful commands

Search common problems:

```bash
grep -iE "error|exception|failed|timeout|warn" "$LOG_FILE" | tail -n 100
```

Search by IMEI:

```bash
grep "000000000000000" "$LOG_FILE" | tail -n 50
```

Search by IP address:

```bash
grep "0.0.0.0" "$LOG_FILE" | tail -n 50
```

Search by protocol:

```bash
grep -i "gt06" "$LOG_FILE" | tail -n 100
```

Search compressed rotated logs:

```bash
zgrep -i "000000000000000" "$LOG_DIR"/*.gz | tail -n 100
```

Follow live logs:

```bash
tail -n "$TAIL_LINES" -F "$LOG_FILE"
```

List log files:

```bash
ls -lah "$LOG_DIR"
```

---

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `LOG_FILE` | `/opt/traccar/logs/tracker-server.log` | Main Traccar log file to follow |
| `LOG_DIR` | `/opt/traccar/logs` | Traccar log directory |
| `TAIL_LINES` | `200` | Number of recent lines shown when starting `tail`/`follow` mode |
| `LOG_MODE` | `tail` | Use `api` to start the optional HTTP API |
| `LOG_JANITOR` | `false` | Set to `true` to run log rotation and retention cleanup in the background |
| `LOG_RETENTION_DAYS` | `15` | Days to keep rotated log files before deletion |
| `LOG_CLEAN_INTERVAL` | `86400` | Interval in seconds between log cleanup passes |
| `LOG_GZIP_LEVEL` | `9` | Compression level for gzip (1-9) |

---

## Security notes

In default `tail` mode, this container is intended to be read-only and isolated:

```yaml
volumes:
  - traccar_data:/opt/traccar:ro

network_mode: "none"

security_opt:
  - no-new-privileges:true
```

Recommended behavior:

- mount the Traccar volume as read-only;
- do not expose ports for the default `tail` container;
- do not connect the default `tail` container to public networks;
- if using API mode, expose it only behind HTTPS and Bearer token authentication;
- do not mount the Docker socket;
- limit Docker JSON logs with `max-size` and `max-file`.

---

## Testing

The HTTP API's input validation, query-limit handling, and bounded log matching are covered with Python standard-library unit tests:

```bash
python -m unittest -v
```

GitHub Actions runs the tests, compiles the Python sources, and builds the Docker image for every pull request and push to `main`.

---

## Building locally

```bash
git clone https://github.com/Natan-M64/traccar-log-tools.git
cd traccar-log-tools
docker build -t traccar-log-tools:latest .
```

Then use:

```yaml
image: traccar-log-tools:latest
```

---

## GitHub Container Registry

Official image:

```text
ghcr.io/natan-m64/traccar-log-tools:latest
```

Pull manually:

```bash
docker pull ghcr.io/natan-m64/traccar-log-tools:latest
```

---

## Project scope

This project is intentionally small. It is not a replacement for Loki, ELK, OpenSearch, Promtail, Fluent Bit, or a full observability stack.

It is meant to be a practical, lightweight helper for quick Traccar log inspection.

---

## License

MIT License.
