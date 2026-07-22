#!/usr/bin/env python3
import json
import os
import re
import signal
import time
from collections import deque
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlparse


LOG_FILE = Path(os.environ.get("LOG_FILE", "/opt/traccar/logs/tracker-server.log"))
API_TOKEN = os.environ.get("API_TOKEN", "")
HOST = os.environ.get("API_HOST", "0.0.0.0")
PORT = int(os.environ.get("API_PORT", "8080"))
MAX_LINES = int(os.environ.get("MAX_LINES", "2000"))
STREAM_SLEEP_SECONDS = float(os.environ.get("STREAM_SLEEP_SECONDS", "1"))
ALLOW_NO_AUTH = os.environ.get("ALLOW_NO_AUTH", "").lower() in {"1", "true", "yes"}

IMEI_RE = re.compile(r"^[0-9]{8,20}$")


def validate_imei(imei):
    return bool(IMEI_RE.fullmatch(imei or ""))


def parse_limit(query):
    raw = query.get("limit", ["300"])[0]
    try:
        limit = int(raw)
    except ValueError:
        limit = 300
    return max(1, min(limit, MAX_LINES))


def read_matching_lines(imei, limit):
    matches = deque(maxlen=limit)
    with LOG_FILE.open("r", encoding="utf-8", errors="replace") as log_file:
        for line in log_file:
            if imei in line:
                matches.append(line.rstrip("\n"))
    return list(matches)


class Handler(BaseHTTPRequestHandler):
    server_version = "traccar-log-tools-api/1.0"

    def log_message(self, fmt, *args):
        print("%s - - [%s] %s" % (self.address_string(), self.log_date_time_string(), fmt % args), flush=True)

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")
        query = parse_qs(parsed.query)

        if path == "/health":
            self.send_json({"status": "ok", "log_file": str(LOG_FILE), "api_mode": True})
            return

        if not self.is_authorized():
            self.send_error_json(HTTPStatus.UNAUTHORIZED, "unauthorized")
            return

        if path.startswith("/device/"):
            imei = unquote(path.split("/", 2)[2])
            self.handle_device(imei, query)
            return

        if path.startswith("/stream/"):
            imei = unquote(path.split("/", 2)[2])
            self.handle_stream(imei)
            return

        self.send_error_json(HTTPStatus.NOT_FOUND, "not found")

    def is_authorized(self):
        if ALLOW_NO_AUTH:
            return True
        if not API_TOKEN:
            return False
        expected = f"Bearer {API_TOKEN}"
        return self.headers.get("Authorization", "") == expected

    def handle_device(self, imei, query):
        if not validate_imei(imei):
            self.send_error_json(HTTPStatus.BAD_REQUEST, "invalid imei")
            return
        if not LOG_FILE.is_file():
            self.send_error_json(HTTPStatus.NOT_FOUND, "log file not found")
            return

        limit = parse_limit(query)
        lines = read_matching_lines(imei, limit)
        self.send_json(
            {
                "imei": imei,
                "log_file": str(LOG_FILE),
                "limit": limit,
                "count": len(lines),
                "lines": lines,
            }
        )

    def handle_stream(self, imei):
        if not validate_imei(imei):
            self.send_error_json(HTTPStatus.BAD_REQUEST, "invalid imei")
            return
        if not LOG_FILE.is_file():
            self.send_error_json(HTTPStatus.NOT_FOUND, "log file not found")
            return

        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "text/event-stream; charset=utf-8")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "keep-alive")
        self.end_headers()

        log_file = LOG_FILE.open("r", encoding="utf-8", errors="replace")
        try:
            log_file.seek(0, os.SEEK_END)
            current_inode = os.fstat(log_file.fileno()).st_ino
            while True:
                line = log_file.readline()
                if not line:
                    time.sleep(STREAM_SLEEP_SECONDS)
                    try:
                        stat = LOG_FILE.stat()
                        position = log_file.tell()
                        if stat.st_ino != current_inode or stat.st_size < position:
                            log_file.close()
                            log_file = LOG_FILE.open("r", encoding="utf-8", errors="replace")
                            current_inode = os.fstat(log_file.fileno()).st_ino
                    except FileNotFoundError:
                        pass
                    continue
                if imei in line:
                    payload = json.dumps({"imei": imei, "line": line.rstrip("\n")}, ensure_ascii=False)
                    try:
                        self.wfile.write(f"data: {payload}\n\n".encode("utf-8"))
                        self.wfile.flush()
                    except BrokenPipeError:
                        return
                    except ConnectionResetError:
                        return
        finally:
            log_file.close()

    def send_json(self, payload, status=HTTPStatus.OK):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_error_json(self, status, message):
        self.send_json({"error": message}, status)


def main():
    if not API_TOKEN and not ALLOW_NO_AUTH:
        raise SystemExit("API_TOKEN is required in api mode. Set ALLOW_NO_AUTH=true only for local testing.")

    httpd = ThreadingHTTPServer((HOST, PORT), Handler)

    def shutdown(_signum, _frame):
        httpd.shutdown()

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    print("[INFO] Traccar Log Tools API started", flush=True)
    print(f"[INFO] Listening on {HOST}:{PORT}", flush=True)
    print(f"[INFO] LOG_FILE={LOG_FILE}", flush=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
