import csv, random, time
from datetime import datetime,timedelta
from faker import Faker

fake = Faker()

def generate_sales_data(num_rows):
    header = ["Product", "Price", "Quantity", "Total", "Discount", "Tax", "Shipping", "Profit", "Customer", "Date"]
    data = [header]

    for _ in range(num_rows):
        product = generate_random_product()
        price = generate_random_price()
        quantity = generate_random_quantity()
        total = price * quantity
        discount = generate_random_discount()
        tax = generate_random_tax()
        shipping = generate_random_shipping()
        profit = total - discount - tax - shipping
        customer = generate_random_customer()
        date = generate_random_date()

        row = [
            product,
            "{:.2f}".format(price),
            str(quantity),
            "{:.2f}".format(total),
            "{:.2f}".format(discount),
            "{:.2f}".format(tax),
            "{:.2f}".format(shipping),
            "{:.2f}".format(profit),
            customer,
            date.strftime("%Y-%m-%d")
        ]

        data.append(row)

    return data

def generate_random_product():
    return fake.word()

def generate_random_price():
    return round(random.uniform(1.0, 999.9), 2)

def generate_random_quantity():
    return random.randint(1, 100)

def generate_random_discount():
    return round(random.uniform(0.0, 85.0), 2)

def generate_random_tax():
    return round(random.uniform(0.0, 3.0), 2)

def generate_random_shipping():
    return round(random.uniform(0.0, 5.0), 2)

def generate_random_customer():
    return fake.name()

def generate_random_date():
    start_date = datetime.strptime("2010-01-01", "%Y-%m-%d")
    end_date = datetime.now()

    time_between_dates = end_date - start_date
    days_between_dates = time_between_dates.days
    random_number_of_days = random.randrange(days_between_dates)
    return start_date + timedelta(days=random_number_of_days)


def save_to_csv(data, filename):
    with open(filename, "w", newline="") as file:
        writer = csv.writer(file)
        writer.writerows(data)

def main():
    start = time.time()

    # Generate random sales data
    data = generate_sales_data(1000000)

    # Save data to CSV file
    save_to_csv(data, "sales_data.csv")

    elapsed = time.time() - start
    print(f"Sales data generated and saved to sales_data.csv in {elapsed} seconds")

if __name__ == "__main__":
    main()
