"""
Lightweight mock server for FurSpeak AI.
Responds to health checks and detection endpoints so the Flutter app
can run against a local backend during development.

Usage:  python backend/mock_server.py
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json, uuid, time, os

PORT = 8000


class MockHandler(BaseHTTPRequestHandler):
    """Handles the minimum set of endpoints the Flutter app hits."""

    def _json(self, data: dict, status: int = 200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    # ── OPTIONS (CORS preflight) ────────────────────────────────────────
    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "*")
        self.end_headers()

    # ── GET routes ──────────────────────────────────────────────────────
    def do_GET(self):
        path = self.path.split("?")[0]

        if path in ("/", "/health"):
            self._json({
                "database": "ok",
                "model_loaded": True,
                "queue_depth": 0,
                "temp_storage_ok": True,
                "firebase_initialized": True,
            })
        elif path == "/ping":
            self._json({"status": "ok"})
        elif path.startswith("/api/v1/detect/status/"):
            request_id = path.rsplit("/", 1)[-1]
            self._json({
                "status": "success",
                "request_id": request_id,
                "results": {
                    "emotion": "happy",
                    "confidence": 0.92,
                    "breed": "Golden Retriever",
                    "summary": "Your dog appears happy and relaxed! The tail is wagging and the posture is open and playful.",
                    "recommendations": [
                        "Keep up the great interaction!",
                        "This is a good time for training exercises.",
                        "Consider a play session or walk."
                    ]
                }
            })
        else:
            self._json({"error": "Not found"}, 404)

    # ── POST routes (image / video upload) ──────────────────────────────
    def do_POST(self):
        path = self.path.split("?")[0]
        
        # Read the body to avoid early connection closure issues
        content_length = int(self.headers.get('Content-Length', 0))
        if content_length > 0:
            # We don't actually need the data, but we must read it
            _ = self.rfile.read(content_length)
            print(f"[MOCK] Received {content_length} bytes of data")

        if path == "/api/v1/detect/image":
            # Simulate image analysis
            request_id = str(uuid.uuid4())
            self._json({
                "status": "success",
                "request_id": request_id,
                "results": {
                    "emotion": "happy",
                    "confidence": 0.89,
                    "breed": "Golden Retriever",
                    "summary": "Your dog looks happy! Their body language shows a relaxed posture with a wagging tail.",
                    "recommendations": [
                        "Your dog is in a great mood!",
                        "This is an ideal time for bonding activities.",
                        "Consider rewarding with a treat."
                    ]
                }
            })
        elif path == "/api/v1/detect/video":
            request_id = str(uuid.uuid4())
            self._json({
                "status": "processing",
                "request_id": request_id,
                "message": "Video processing started."
            })
        elif path == "/api/v1/auth/guest":
            self._json({
                "token": "mock_guest_token_" + str(uuid.uuid4()),
                "user_id": "guest_" + str(uuid.uuid4())[:8],
            })
        else:
            self._json({"error": "Not found"}, 404)

    def log_message(self, fmt, *args):
        print(f"[MOCK] {self.client_address[0]} - {fmt % args}")


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), MockHandler)
    print(f"🐾 FurSpeak Mock Server running on http://0.0.0.0:{PORT}")
    print(f"   Emulator should connect via http://10.0.2.2:{PORT}")
    print(f"   Press Ctrl+C to stop.\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped.")
        server.server_close()
