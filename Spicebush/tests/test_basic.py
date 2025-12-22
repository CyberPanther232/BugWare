from app import create_app, db
from app.models import Product


def setup_app():
    app = create_app({
        "TESTING": True,
        "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:",
        "SECRET_KEY": "test",
    })
    with app.app_context():
        db.create_all()
        db.session.add(Product(name="Test", description="", price_cents=1234, inventory=5))
        db.session.commit()
    return app


def test_products_lists_products():
    app = setup_app()
    client = app.test_client()
    res = client.get("/products")
    assert res.status_code == 200
    assert b"Test" in res.data


def test_cart_flow():
    app = setup_app()
    client = app.test_client()
    # Add to cart
    with app.app_context():
        p = Product.query.first()
    res = client.post(f"/cart/add/{p.id}", data={"quantity": 2}, follow_redirects=True)
    assert res.status_code == 200
    assert b"Cart Total" in res.data

    # Go to checkout
    res = client.get("/checkout")
    assert res.status_code == 200

    # Submit checkout
    res = client.post(
        "/checkout",
        data={
            "name": "Alice",
            "email": "alice@example.com",
            "address": "1 Main St",
            "city": "Townsville",
            "country": "US",
            "postal_code": "12345",
        },
        follow_redirects=True,
    )
    assert res.status_code == 200
    assert b"Thank you for your order!" in res.data

    # Verify receipt page is accessible
    with app.app_context():
        from app.models import Order
        order = Order.query.order_by(Order.id.desc()).first()
        order_id = order.id
    rec = client.get(f"/order/{order_id}/receipt")
    assert rec.status_code == 200
    assert b"Receipt" in rec.data or b"Print Receipt" in rec.data
