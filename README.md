# traccar-log-tools

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

- following `tracker-server.log` with `tail -F`;
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

The `:ro` flag is recommended because this container only needs to read log files.

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
| `logs` | Follow the current log with `tail -f` |
| `follow` | Follow the current log with `tail -F`, useful for rotated logs |
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
grep -iE "error|exception|failed|timeout|warn" "$LOG_FILE" | tail -100
```

Search by IMEI:

```bash
grep "000000000000000" "$LOG_FILE" | tail -50
```

Search by IP address:

```bash
grep "0.0.0.0" "$LOG_FILE" | tail -50
```

Search by protocol:

```bash
grep -i "gt06" "$LOG_FILE" | tail -100
```

Search compressed rotated logs:

```bash
zgrep -i "000000000000000" "$LOG_DIR"/*.gz | tail -100
```

Follow live logs:

```bash
tail -F "$LOG_FILE"
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

---

## Security notes

This container is intended to be read-only and isolated:

```yaml
volumes:
  - traccar_data:/opt/traccar:ro

network_mode: "none"

security_opt:
  - no-new-privileges:true
```

Recommended behavior:

- mount the Traccar volume as read-only;
- do not expose ports;
- do not connect this container to public networks;
- do not mount the Docker socket;
- limit Docker JSON logs with `max-size` and `max-file`.

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
