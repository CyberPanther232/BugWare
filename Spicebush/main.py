# -------------------------------------------------------------------------
# SECURITY RESEARCH & EDUCATIONAL PURPOSES ONLY
# This script is part of the BugWare repository, a collection of security tools
# and PoCs for learning about attack vectors.
# DO NOT USE THIS FOR ILLEGAL PURPOSES.
# -------------------------------------------------------------------------

"""
Program: Spicebush Main
Description: Entry point for the Spicebush e-commerce simulation application.
Author: CyberPanther232
Suite: BugWare
Version: 1.0
"""

from app import create_app


app = create_app()


if __name__ == "__main__":
	# Debug server for local development
	app.run(host="127.0.0.1", port=5000, debug=True)

