import json
import pandas as pd

# Read local JSON
with open("../data/customer_orders.json", "r") as file:
    data = json.load(file)

# Customer table data
customer_rows = []

# Orders table data
order_rows = []

for customer in data:
    customer_rows.append({
        "customer_id": customer["customer_id"],
        "customer_name": customer["customer_name"],
        "email": customer["email"],
        "phone": customer["phone"],
        "city": customer["city"],
        "registration_date": customer["registration_date"]
    })

    for order in customer["orders"]:
        order_rows.append({
            "order_id": order["order_id"],
            "customer_id": customer["customer_id"],
            "order_date": order["order_date"],
            "product_name": order["product_name"],
            "quantity": order["quantity"],
            "price": order["price"]
        })

customer_df = pd.DataFrame(customer_rows)
orders_df = pd.DataFrame(order_rows)

print("Customer Info Table")
print(customer_df)

print("\nOrders Table")
print(orders_df)