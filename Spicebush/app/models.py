from __future__ import annotations

from datetime import datetime
from typing import Optional

from . import db


class Product(db.Model):
    __tablename__ = "products"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False, unique=True)
    description = db.Column(db.Text, nullable=True)
    price_cents = db.Column(db.Integer, nullable=False)  # store price in cents to avoid float issues
    image_url = db.Column(db.String(500), nullable=True)
    inventory = db.Column(db.Integer, nullable=False, default=0)

    def price_display(self) -> str:
        return f"${self.price_cents / 100:.2f}"

    def __repr__(self) -> str:  # pragma: no cover - for debugging
        return f"<Product {self.id} {self.name}>"


class Order(db.Model):
    __tablename__ = "orders"

    id = db.Column(db.Integer, primary_key=True)
    customer_name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(200), nullable=False)
    address = db.Column(db.String(200), nullable=False)
    city = db.Column(db.String(120), nullable=False)
    country = db.Column(db.String(120), nullable=False)
    postal_code = db.Column(db.String(40), nullable=False)
    total_cents = db.Column(db.Integer, nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    items = db.relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")

    def total_display(self) -> str:
        return f"${self.total_cents / 100:.2f}"

    def __repr__(self) -> str:  # pragma: no cover
        return f"<Order {self.id} {self.customer_name} ${self.total_cents / 100:.2f}>"


class OrderItem(db.Model):
    __tablename__ = "order_items"

    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey("orders.id"), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey("products.id"), nullable=False)
    quantity = db.Column(db.Integer, nullable=False, default=1)
    unit_price_cents = db.Column(db.Integer, nullable=False)

    order = db.relationship("Order", back_populates="items")
    product = db.relationship("Product")

    def line_total_cents(self) -> int:
        return self.quantity * self.unit_price_cents

    def line_total_display(self) -> str:
        return f"${self.line_total_cents() / 100:.2f}"

    def __repr__(self) -> str:  # pragma: no cover
        return f"<OrderItem o={self.order_id} p={self.product_id} qty={self.quantity}>"
