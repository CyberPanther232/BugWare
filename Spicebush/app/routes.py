# -------------------------------------------------------------------------
# SECURITY RESEARCH & EDUCATIONAL PURPOSES ONLY
# This script is part of the BugWare repository, a collection of security tools
# and PoCs for learning about attack vectors.
# DO NOT USE THIS FOR ILLEGAL PURPOSES.
# -------------------------------------------------------------------------

"""
Program: Spicebush Routes
Description: Defines the routes and logic for the e-commerce simulation application.
Author: CyberPanther232
Suite: BugWare
Version: 1.0
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Tuple

from flask import (
	Blueprint,
	current_app,
	redirect,
	render_template,
	request,
	session,
	url_for,
	flash,
)

from . import db
from .models import Product, Order, OrderItem
from flask import send_file


bp = Blueprint("shop", __name__)


# ---- Cart helpers (session-based) ----

Cart = Dict[int, int]  # product_id -> quantity


def _get_cart() -> Cart:
	cart: Cart = session.get("cart", {})
	# ensure keys are ints
	return {int(pid): int(qty) for pid, qty in cart.items()}


def _save_cart(cart: Cart) -> None:
	session["cart"] = cart


def _cart_summary(cart: Cart) -> Tuple[list[dict], int]:
	product_ids = list(cart.keys())
	items: list[dict] = []
	total_cents = 0
	if product_ids:
		products = Product.query.filter(Product.id.in_(product_ids)).all()
		by_id = {p.id: p for p in products}
		for pid, qty in cart.items():
			product = by_id.get(pid)
			if not product:
				continue
			line_cents = product.price_cents * qty
			total_cents += line_cents
			items.append(
				{
					"product": product,
					"quantity": qty,
					"line_cents": line_cents,
				}
			)
	return items, total_cents


# ---- Routes ----


@bp.route("/")
def home():
	return render_template("home.html")


@bp.route("/products", endpoint="index")
def products():
	products = Product.query.order_by(Product.id.desc()).all()
	return render_template("products.html", products=products)


@bp.route("/product/<int:product_id>")
def product_detail(product_id: int):
	product = Product.query.get_or_404(product_id)
	return render_template("product_detail.html", product=product)


@bp.route("/cart")
def view_cart():
	cart = _get_cart()
	items, total_cents = _cart_summary(cart)
	return render_template("cart.html", items=items, total_cents=total_cents)


@bp.route("/cart/add/<int:product_id>", methods=["POST"])
def add_to_cart(product_id: int):
	product = Product.query.get_or_404(product_id)
	qty = int(request.form.get("quantity", 1))
	if qty < 1:
		qty = 1
	cart = _get_cart()
	cart[product.id] = cart.get(product.id, 0) + qty
	_save_cart(cart)
	flash(f"Added {qty} × {product.name} to cart.", "success")
	return redirect(url_for("shop.view_cart"))


@bp.route("/cart/update/<int:product_id>", methods=["POST"])
def update_cart(product_id: int):
	qty = int(request.form.get("quantity", 1))
	cart = _get_cart()
	if qty <= 0:
		cart.pop(product_id, None)
	else:
		cart[product_id] = qty
	_save_cart(cart)
	return redirect(url_for("shop.view_cart"))


@bp.route("/cart/remove/<int:product_id>", methods=["POST"])
def remove_from_cart(product_id: int):
	cart = _get_cart()
	cart.pop(product_id, None)
	_save_cart(cart)
	return redirect(url_for("shop.view_cart"))


@bp.route("/checkout", methods=["GET", "POST"])
def checkout():
	cart = _get_cart()
	items, total_cents = _cart_summary(cart)
	if request.method == "POST":
		if not items:
			flash("Your cart is empty.", "error")
			return redirect(url_for("shop.index"))
		# Collect form data
		name = request.form.get("name", "").strip()
		email = request.form.get("email", "").strip()
		address = request.form.get("address", "").strip()
		city = request.form.get("city", "").strip()
		country = request.form.get("country", "").strip()
		postal_code = request.form.get("postal_code", "").strip()

		if not all([name, email, address, city, country, postal_code]):
			flash("Please fill out all fields.", "error")
			return render_template("checkout.html", items=items, total_cents=total_cents)

		# Create order
		order = Order(
			customer_name=name,
			email=email,
			address=address,
			city=city,
			country=country,
			postal_code=postal_code,
			total_cents=total_cents,
		)
		db.session.add(order)
		db.session.flush()  # get order.id

		# Add items
		for it in items:
			product = it["product"]
			quantity = it["quantity"]
			db.session.add(
				OrderItem(
					order_id=order.id,
					product_id=product.id,
					quantity=quantity,
					unit_price_cents=product.price_cents,
				)
			)

		db.session.commit()
		# Clear cart
		session.pop("cart", None)
		return redirect(url_for("shop.order_confirmation", order_id=order.id))

	return render_template("checkout.html", items=items, total_cents=total_cents)


@bp.route("/order/<int:order_id>/confirmation")
def order_confirmation(order_id: int):
	order = Order.query.get_or_404(order_id)
	return render_template("order_confirm.html", order=order)

@bp.route("/order/<int:order_id>/receipt")
def order_receipt(order_id: int):
	"""Printable receipt view for an order."""
	return send_file('payloads/receipt.docx')  # Placeholder implementation


@bp.route("/admin/seed")
def seed_products():  # Simple seed route for demo purposes
	if Product.query.count() > 0:
		flash("Products already seeded.", "info")
		return redirect(url_for("shop.index"))

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
	flash("Seeded demo products.", "success")
	return redirect(url_for("shop.index"))
