# Spicebush Shop (Flask)

<img src="app/static/logo-light.svg" width="650" alt="Spicebush Shop Logo">

A simple, generic e-commerce web app built with Python (Flask). It includes:

- Product catalog and product details
- Session-based shopping cart
- Checkout flow that creates orders in SQLite
- Order confirmation page
- Demo data seeding via route or script
- Homepage with logo and theme toggle (light/dark)

## Quickstart (Windows PowerShell)

```pwsh
# 1) Create and activate a virtual environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# 2) Install dependencies
pip install -r requirements.txt

# 3) Initialize the database (uses instance/shop.sqlite)
$env:FLASK_APP = "main:app"
$env:FLASK_ENV = "development"
python - <<'PY'
from app import create_app, db
app = create_app()
with app.app_context():
    db.create_all()
print('Database initialized')
PY

# 4) Seed demo products (optional)
python .\seed.py

# 5) Run the dev server
python .\main.py
```

Open http://127.0.0.1:5000/ in your browser.

You can also visit `/admin/seed` once the server is running to seed demo products via a route.

## Configuration

- SECRET_KEY: set via environment variable `SECRET_KEY` (default is a dev key)
- DATABASE_URL: set to use a different DB (default: SQLite file in `instance/shop.sqlite`)
- LOGO_URL: optional URL for the logo shown on the homepage. If not set, the app uses `static/logo.svg`.

## Theming

- Click the moon/sun button in the header to toggle between light and dark themes.
- Your preference is saved in `localStorage` and applied automatically. If no preference is set, the app follows the system color scheme.

## Project structure

```
Spicebush/
  app/
    __init__.py       # Flask app factory and extensions
    models.py         # SQLAlchemy models: Product, Order, OrderItem
    routes.py         # Blueprint with homepage, catalog, cart, checkout routes
    templates/        # Jinja2 templates (base, home, products, etc.)
    static/           # CSS, JS, and logo assets
  main.py             # Entry point to run the server
  seed.py             # Seed demo products
  requirements.txt
  README.md
```

## Tests (optional)

Run basic tests with pytest:

```pwsh
pytest -q
```

## Notes

- Payments are not processed; checkout simply records an order.
- Inventory is not decremented in this demo, but you can extend `checkout` to adjust product inventory.
- For production, configure a real database and a proper SECRET_KEY.
