from app import create_app, db
from app.models import Product


def run():
    app = create_app()
    with app.app_context():
        if Product.query.count() > 0:
            print("Products already exist; skipping seeding.")
            return
        demo_products = [
            (
                "Vintage Coffee Mug",
                "A classic ceramic mug with a retro design.",
                1599,
                "https://images.unsplash.com/photo-1498804103079-a6351b050096?w=800&q=80",
                100,
            ),
            (
                "Leather Notebook",
                "Handmade leather-bound notebook for your ideas.",
                2499,
                "https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=800&q=80",
                50,
            ),
            (
                "Desk Plant",
                "Low-maintenance succulent to brighten your workspace.",
                1299,
                "https://images.unsplash.com/photo-1463320726281-696a485928c7?w=800&q=80",
                200,
            ),
        ]
        for name, desc, price, img, inv in demo_products:
            db.session.add(
                Product(name=name, description=desc, price_cents=price, image_url=img, inventory=inv)
            )
        db.session.commit()
        print("Seeded demo products.")


if __name__ == "__main__":
    run()
