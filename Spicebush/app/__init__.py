import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate


db = SQLAlchemy()
migrate = Migrate()


def create_app(test_config: dict | None = None) -> Flask:
	"""Application factory for the e-commerce app.

	Args:
		test_config: Optional configuration overrides for testing.

	Returns:
		Configured Flask app instance.
	"""
	app = Flask(
		__name__,
		instance_relative_config=True,
		static_folder="static",
		template_folder="templates",
	)

	# Default configuration
	instance_db = os.path.join(app.instance_path, "shop.sqlite")
	app.config.from_mapping(
		SECRET_KEY=os.environ.get("SECRET_KEY", "dev-secret-key-change-me"),
		SQLALCHEMY_DATABASE_URI=os.environ.get("DATABASE_URL", f"sqlite:///{instance_db}"),
		SQLALCHEMY_TRACK_MODIFICATIONS=False,
		# Optional branding
		LOGO_URL=os.environ.get("LOGO_URL"),
	)

	# Ensure instance folder exists
	try:
		os.makedirs(app.instance_path, exist_ok=True)
	except OSError:
		pass

	# Override for testing
	if test_config is not None:
		app.config.update(test_config)

	# Init extensions
	db.init_app(app)
	migrate.init_app(app, db)

	# Import models so migrations can detect them
	from . import models  # noqa: F401

	# Register blueprints/routes
	from .routes import bp as shop_bp
	app.register_blueprint(shop_bp)

	@app.shell_context_processor
	def _shell_ctx():  # pragma: no cover - convenience for dev
		from .models import Product, Order, OrderItem

		return {"db": db, "Product": Product, "Order": Order, "OrderItem": OrderItem}

	return app
