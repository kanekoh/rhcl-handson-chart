"""HTTP echo server for RHCL hands-on workshop."""
import json
import signal
import sys
from datetime import datetime, timezone
from http.server import HTTPServer, BaseHTTPRequestHandler


class EchoHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        if self.path == "/health":
            self._send_json(200, {"status": "ok"})
            return
        if self.path == "/ready":
            self._send_json(200, {"status": "ready"})
            return

        body = self._build_echo()

        if self.path.startswith("/admin"):
            body["area"] = "admin"

        self._send_json(200, body)

    def do_POST(self):
        self._handle_any()

    def do_PUT(self):
        self._handle_any()

    def do_PATCH(self):
        self._handle_any()

    def do_DELETE(self):
        self._handle_any()

    def _handle_any(self):
        self._send_json(200, self._build_echo())

    def _build_echo(self):
        headers = {k: v for k, v in self.headers.items()}
        auth = headers.get("Authorization") or headers.get("authorization")
        if auth and len(auth) > 20:
            headers["Authorization"] = auth[:20] + "..."
        return {
            "method": self.command,
            "path": self.path,
            "headers": headers,
            "client_ip": self.client_address[0],
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }

    def _send_json(self, code, body):
        payload = json.dumps(body, indent=2).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format, *args):
        print(f"{datetime.now(timezone.utc).isoformat()} {self.client_address[0]} {format % args}",
              flush=True)


def main():
    server = HTTPServer(("0.0.0.0", 8080), EchoHandler)

    def shutdown(signum, frame):
        print("Shutting down...", flush=True)
        server.shutdown()
        sys.exit(0)

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    print("Echo server listening on :8080", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
