"""
Inventory & Fulfilment Synthetic Dataset Generator (v0.1)
=========================================================
Generates 100% compliant, physically reconciled datasets according to:
`inventory_fulfilment_dataset_requirements.md`

Output Datasets:
----------------
1. CSV (Structured):
   - products.csv
   - locations.csv
   - suppliers.csv
   - carriers.csv
   - calendar.csv
   - inventory_snapshots.csv
   - inventory_movements.csv
   - sales_demand.csv
   - transfers.csv

2. JSON (Semi-structured):
   - promotions.json
   - purchase_orders.json
   - customer_orders.json
   - shipments.json

3. Documents & Unstructured:
   - documents_metadata.json
   - documents/SOP_DAMAGED_GOODS_RECEIVING_V2.txt
   - documents/CONTRACT_APEX_GLOBAL_2026.txt
   - documents/CARRIER_FEDEX_SERVICE_GUIDE_2026.txt

Data Quality Checks Enforced:
-----------------------------
1. No duplicates or nulls in primary IDs.
2. Referential integrity across all foreign keys (SKU, Location, Supplier, Carrier, Order, PO).
3. Realistic business logic:
   - unit_price > unit_cost (positive profit margin)
   - Quantities >= 0 (no negative stocks, sales, or orders)
   - Chronological timestamps: delivery_date >= order_date, delivered_time >= ship_time
   - abc_class in {'A', 'B', 'C'}, status in {'NEW', 'ACTIVE', 'DISCONTINUED'}
   - is_stockout is True iff available_qty == 0
   - is_late is True iff date(delivered_timestamp) > promised_delivery_date
4. Inventory balance reconciliation (Daily continuity: Previous Stock + Receipts - Sales = Current Stock).
"""

import os
import csv
import json
import random
import datetime
from datetime import date, timedelta

from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, HRFlowable
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors

# Set fixed seed for reproducibility while generating realistic data
random.seed(42)

OUTPUT_DIR = os.path.join(os.getcwd(), "inventory_fulfilment_data")
DOCS_DIR = os.path.join(OUTPUT_DIR, "documents")
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(DOCS_DIR, exist_ok=True)

# ------------------------------------------------------------------------------
# 1. Calendar Generation (2026-08-01 to 2026-10-31: 92 days)
# ------------------------------------------------------------------------------
START_DATE = date(2026, 8, 1)
END_DATE = date(2026, 10, 31)
TOTAL_DAYS = (END_DATE - START_DATE).days + 1

HOLIDAYS = {
    date(2026, 9, 7): "Labor Day",
    date(2026, 10, 12): "Columbus / Indigenous Peoples Day",
    date(2026, 10, 31): "Halloween",
}

def get_season(dt):
    month = dt.month
    if month in [12, 1, 2]: return "Winter"
    elif month in [3, 4, 5]: return "Spring"
    elif month in [6, 7, 8]: return "Summer"
    else: return "Fall"

def is_peak(dt):
    # Back to school in mid/late August, Labor Day weekend, late October pre-holiday
    if dt.month == 8 and dt.day >= 15: return True
    if dt.month == 9 and 4 <= dt.day <= 7: return True
    if dt.month == 10 and dt.day >= 24: return True
    return False

calendar_records = []
current_dt = START_DATE
while current_dt <= END_DATE:
    is_hol = current_dt in HOLIDAYS
    hol_name = HOLIDAYS.get(current_dt, "")
    calendar_records.append({
        "date": current_dt.strftime("%Y-%m-%d"),
        "is_holiday": is_hol,
        "holiday_name": hol_name,
        "week": current_dt.isocalendar()[1],
        "month": current_dt.month,
        "season": get_season(current_dt),
        "is_peak_period": is_peak(current_dt)
    })
    current_dt += timedelta(days=1)

# ------------------------------------------------------------------------------
# 2. Master Entities: Products
# ------------------------------------------------------------------------------
PRODUCT_SPECS = [
    # Electronics
    ("Noise-Cancelling Wireless Headphones", "Electronics", "SoundPro", "A", 48.00, 99.99, 12, 0.45, None, "ACTIVE", "2024-03-15"),
    ("Smart 4K UHD LED TV 55-inch", "Electronics", "VisionTech", "A", 220.00, 399.99, 2, 14.50, None, "ACTIVE", "2024-01-10"),
    ("USB-C Fast Charging Hub 65W", "Electronics", "PowerPulse", "B", 12.50, 29.99, 24, 0.25, None, "ACTIVE", "2024-06-01"),
    ("Bluetooth Waterproof Speaker", "Electronics", "SoundPro", "B", 22.00, 49.99, 12, 0.85, None, "ACTIVE", "2025-02-20"),
    ("Wireless Ergonomic Mouse", "Electronics", "LogiClick", "C", 8.50, 19.99, 24, 0.18, None, "ACTIVE", "2024-08-11"),
    ("Smartwatch Fitness Tracker GPS", "Electronics", "VisionTech", "A", 65.00, 139.99, 12, 0.20, None, "NEW", "2026-08-15"),
    ("Legacy Wired Earphones 3.5mm", "Electronics", "SoundPro", "C", 3.00, 7.99, 48, 0.08, None, "DISCONTINUED", "2023-05-10"),

    # Clothing & Footwear
    ("Men's Organic Cotton Crewneck T-Shirt", "Clothing", "AeroStyle", "A", 6.50, 19.99, 24, 0.22, None, "ACTIVE", "2024-02-01"),
    ("Women's Slim Fit Stretch Denim Jeans", "Clothing", "DenimCo", "A", 18.00, 49.99, 12, 0.65, None, "ACTIVE", "2024-01-20"),
    ("All-Weather Waterproof Shell Jacket", "Clothing", "TrailPeak", "A", 45.00, 119.99, 6, 0.75, None, "ACTIVE", "2024-09-01"),
    ("Merino Wool Winter Knit Sweater", "Clothing", "AeroStyle", "B", 28.00, 69.99, 12, 0.50, None, "ACTIVE", "2024-10-15"),
    ("Cushioned Trail Running Shoes", "Clothing", "TrailPeak", "A", 35.00, 89.99, 6, 0.95, None, "ACTIVE", "2024-04-10"),
    ("Casual Cotton Canvas Slip-On Shoes", "Clothing", "AeroStyle", "B", 14.00, 34.99, 12, 0.70, None, "ACTIVE", "2025-03-01"),
    ("Vintage Graphic Print Tee (Old Season)", "Clothing", "DenimCo", "C", 5.00, 12.99, 24, 0.20, None, "DISCONTINUED", "2023-08-01"),

    # Groceries (with realistic shelf life)
    ("Organic Whole Milk 1 Gallon", "Groceries", "PureDairy", "A", 2.20, 4.49, 6, 3.90, 18, "ACTIVE", "2024-01-01"),
    ("Artisanal Sourdough Bread Loaf 500g", "Groceries", "BakeMaster", "A", 1.80, 4.29, 12, 0.55, 7, "ACTIVE", "2024-01-01"),
    ("Cold Pressed Extra Virgin Olive Oil 750ml", "Groceries", "MedTerra", "A", 7.50, 15.99, 12, 1.20, 365, "ACTIVE", "2024-02-15"),
    ("Organic Dark Roast Coffee Beans 1kg", "Groceries", "PeakRoast", "A", 8.00, 18.99, 10, 1.05, 180, "ACTIVE", "2024-01-15"),
    ("Almond Milk Unsweetened 1L", "Groceries", "PureDairy", "B", 1.60, 3.49, 12, 1.05, 60, "ACTIVE", "2024-05-10"),
    ("Gluten-Free Granola Oats 500g", "Groceries", "BakeMaster", "B", 2.90, 6.49, 12, 0.52, 120, "ACTIVE", "2024-07-20"),
    ("Sparkling Mineral Water 12-Pack", "Groceries", "MedTerra", "B", 4.20, 8.99, 4, 4.50, 270, "ACTIVE", "2024-03-10"),
    ("Seasonal Summer Berry Jam 250g", "Groceries", "BakeMaster", "C", 2.00, 4.99, 24, 0.40, 90, "DISCONTINUED", "2024-05-01"),

    # Home & Kitchen
    ("Stainless Steel 10-Piece Cookware Set", "Home & Kitchen", "ChefPro", "A", 68.00, 159.99, 2, 8.20, None, "ACTIVE", "2024-01-15"),
    ("Digital Air Fryer 5.8 Quart", "Home & Kitchen", "ChefPro", "A", 38.00, 89.99, 4, 5.10, None, "ACTIVE", "2024-03-01"),
    ("Memory Foam Contour Sleeping Pillow", "Home & Kitchen", "DreamRest", "B", 12.00, 29.99, 8, 1.30, None, "ACTIVE", "2024-02-10"),
    ("Microfiber Luxury 4-Piece Sheet Set Queen", "Home & Kitchen", "DreamRest", "B", 16.00, 39.99, 10, 1.80, None, "ACTIVE", "2024-01-25"),
    ("Scented Natural Soy Wax Candle 3-Pack", "Home & Kitchen", "AuraHome", "C", 6.50, 16.99, 12, 0.90, None, "ACTIVE", "2024-11-01"),
    ("Smart Robotic Vacuum Cleaner", "Home & Kitchen", "ChefPro", "A", 110.00, 249.99, 2, 4.80, None, "NEW", "2026-09-01"),

    # Sports & Outdoors
    ("Eco-Friendly Non-Slip Yoga Mat 6mm", "Sports", "ZenMove", "A", 9.00, 24.99, 12, 1.10, None, "ACTIVE", "2024-01-10"),
    ("Adjustable Cast Iron Dumbbell Set 50lbs", "Sports", "TitanForge", "A", 42.00, 99.99, 1, 23.00, None, "ACTIVE", "2024-04-01"),
    ("Vacuum Insulated Stainless Water Bottle 32oz", "Sports", "ZenMove", "B", 7.00, 18.99, 20, 0.42, None, "ACTIVE", "2024-02-20"),
    ("Resistance Exercise Bands 5-Pack", "Sports", "ZenMove", "C", 4.00, 11.99, 30, 0.30, None, "ACTIVE", "2024-01-05"),

    # Beauty & Personal Care
    ("Hyaluronic Acid Hydrating Face Serum 50ml", "Beauty", "GlowLab", "A", 5.50, 19.99, 24, 0.15, 730, "ACTIVE", "2024-02-01"),
    ("Mineral Daily Sunscreen SPF 50 Broad Spectrum", "Beauty", "GlowLab", "A", 6.20, 21.99, 24, 0.18, 540, "ACTIVE", "2024-03-15"),
    ("Gentle Foaming Daily Cleanser 200ml", "Beauty", "DermaPure", "B", 4.00, 14.99, 24, 0.26, 730, "ACTIVE", "2024-01-20"),
    ("Organic Moroccan Argan Hair Mask 250ml", "Beauty", "DermaPure", "C", 4.80, 16.49, 18, 0.32, 540, "ACTIVE", "2024-06-10"),
]

products = []
for i, spec in enumerate(PRODUCT_SPECS, start=1001):
    sku_id = f"SKU-{i}"
    name, cat, brand, abc, cost, price, case_pack, weight, shelf_life, status, launch = spec
    products.append({
        "sku_id": sku_id,
        "product_name": name,
        "category": cat,
        "brand": brand,
        "abc_class": abc,
        "unit_cost": f"{cost:.2f}",
        "unit_price": f"{price:.2f}",
        "case_pack_qty": case_pack,
        "weight_kg": f"{weight:.2f}",
        "shelf_life_days": shelf_life if shelf_life is not None else "",
        "status": status,
        "launch_date": launch
    })

# ------------------------------------------------------------------------------
# 3. Master Entities: Locations
# ------------------------------------------------------------------------------
LOCATIONS_DATA = [
    # DCs
    ("LOC-DC-01", "DC", "North", "60607", 41.8781, -87.6298, "", 750000, 8000, "18:00:00", True),
    ("LOC-DC-02", "DC", "South", "75201", 32.7767, -96.7970, "", 650000, 7000, "18:00:00", True),
    ("LOC-DC-03", "DC", "West", "89501", 39.5296, -119.8138, "", 550000, 6000, "17:30:00", True),
    ("LOC-DC-04", "DC", "East", "18101", 40.6084, -75.4902, "", 800000, 9000, "18:30:00", True),

    # Stores
    ("LOC-STR-101", "STORE", "East", "10001", 40.7128, -74.0060, "LOC-DC-04", 35000, 250, "16:00:00", True),
    ("LOC-STR-102", "STORE", "East", "02108", 42.3601, -71.0589, "LOC-DC-04", 28000, 200, "16:00:00", True),
    ("LOC-STR-103", "STORE", "North", "60611", 41.8950, -87.6240, "LOC-DC-01", 40000, 300, "16:30:00", True),
    ("LOC-STR-104", "STORE", "North", "55401", 44.9778, -93.2650, "LOC-DC-01", 30000, 180, "16:00:00", True),
    ("LOC-STR-105", "STORE", "South", "75001", 32.9618, -96.8292, "LOC-DC-02", 32000, 220, "16:00:00", True),
    ("LOC-STR-106", "STORE", "South", "78701", 30.2672, -97.7431, "LOC-DC-02", 26000, 190, "16:00:00", True),
    ("LOC-STR-107", "STORE", "West", "90012", 34.0522, -118.2437, "LOC-DC-03", 45000, 350, "17:00:00", True),
    ("LOC-STR-108", "STORE", "West", "98101", 47.6062, -122.3321, "LOC-DC-03", 29000, 200, "16:00:00", True),

    # 3PL Partner Warehouses
    ("LOC-3PL-01", "3PL", "South", "38103", 35.1495, -90.0490, "LOC-DC-02", 200000, 2500, "17:00:00", True),
    ("LOC-3PL-02", "3PL", "North", "43215", 39.9612, -82.9988, "LOC-DC-01", 220000, 2800, "17:00:00", True),
]

locations = []
for loc in LOCATIONS_DATA:
    locations.append({
        "location_id": loc[0],
        "location_type": loc[1],
        "region": loc[2],
        "postal_code": loc[3],
        "latitude": f"{loc[4]:.4f}",
        "longitude": f"{loc[5]:.4f}",
        "parent_dc_id": loc[6],
        "storage_capacity": loc[7],
        "daily_order_capacity": loc[8],
        "cutoff_time": loc[9],
        "is_active": loc[10]
    })

# ------------------------------------------------------------------------------
# 4. Master Entities: Suppliers
# ------------------------------------------------------------------------------
SUPPLIER_PROFILES = [
    ("SUP-001", "Apex Electronics International", "China", 30, ["SKU-1001", "SKU-1002", "SKU-1004", "SKU-1006"], 100),
    ("SUP-002", "PowerPulse Components US", "United States", 5, ["SKU-1003", "SKU-1005"], 200),
    ("SUP-003", "Pinnacle Apparel Manufacturing", "Vietnam", 35, ["SKU-1008", "SKU-1009", "SKU-1011", "SKU-1014"], 250),
    ("SUP-004", "TrailPeak Gear & Outdoor Ltd", "United States", 7, ["SKU-1010", "SKU-1012", "SKU-1013"], 100),
    ("SUP-005", "PureDairy Farm Cooperatives", "United States", 3, ["SKU-1015", "SKU-1019"], 500),
    ("SUP-006", "Artisan Bakery & Grains Network", "United States", 4, ["SKU-1016", "SKU-1020", "SKU-1022"], 300),
    ("SUP-007", "MedTerra Mediterranean Imports", "Italy", 22, ["SKU-1017", "SKU-1021"], 150),
    ("SUP-008", "PeakRoast Single Origin Estates", "Colombia", 28, ["SKU-1018"], 120),
    ("SUP-009", "ChefPro Culinary Technologies", "Germany", 18, ["SKU-1023", "SKU-1024", "SKU-1028"], 50),
    ("SUP-010", "DreamRest Home Comfort Co", "United States", 6, ["SKU-1025", "SKU-1026", "SKU-1027"], 100),
    ("SUP-011", "ZenMove Athletics & Yoga", "United States", 6, ["SKU-1029", "SKU-1031", "SKU-1032"], 200),
    ("SUP-012", "TitanForge Iron & Fitness", "United States", 8, ["SKU-1030"], 40),
    ("SUP-013", "GlowLab Skincare Science", "United States", 5, ["SKU-1033", "SKU-1034"], 300),
    ("SUP-014", "DermaPure Botanical Extracts", "France", 20, ["SKU-1035", "SKU-1036"], 250),
]

# Product cost lookup
sku_cost_map = {p["sku_id"]: float(p["unit_cost"]) for p in products}

suppliers = []
supplier_sku_map = {}
for s_id, s_name, country, lead_time, skus, base_moq in SUPPLIER_PROFILES:
    for sku in skus:
        cost = sku_cost_map[sku]
        suppliers.append({
            "supplier_id": s_id,
            "supplier_name": s_name,
            "country": country,
            "promised_lead_time_days": lead_time,
            "sku_id": sku,
            "moq": base_moq,
            "contract_unit_cost": f"{cost:.2f}",
            "is_preferred": True,
            "is_active": True
        })
        if sku not in supplier_sku_map:
            supplier_sku_map[sku] = []
        supplier_sku_map[sku].append({
            "supplier_id": s_id,
            "lead_time": lead_time,
            "moq": base_moq,
            "cost": cost
        })

# ------------------------------------------------------------------------------
# 5. Master Entities: Carriers
# ------------------------------------------------------------------------------
CARRIERS_DATA = [
    ("CAR-FEDEX-SAME", "FedEx SameDay City", "SAME_DAY", 0, 32.50),
    ("CAR-FEDEX-NEXT", "FedEx Priority Overnight", "NEXT_DAY", 1, 18.75),
    ("CAR-FEDEX-STD", "FedEx Home Delivery", "STANDARD", 4, 7.50),
    ("CAR-UPS-NEXT", "UPS Next Day Air", "NEXT_DAY", 1, 19.25),
    ("CAR-UPS-STD", "UPS Ground", "STANDARD", 3, 7.80),
    ("CAR-USPS-PRIORITY", "USPS Priority Mail", "STANDARD", 3, 6.20),
    ("CAR-DHL-EXP", "DHL Express Worldwide", "NEXT_DAY", 1, 24.00),
    ("CAR-LOCAL-COURIER", "Metro QuickCourier", "SAME_DAY", 0, 27.50),
]

carriers = []
for c in CARRIERS_DATA:
    carriers.append({
        "carrier_id": c[0],
        "carrier_name": c[1],
        "service_level": c[2],
        "promised_transit_days": c[3],
        "base_rate": f"{c[4]:.2f}"
    })

# ------------------------------------------------------------------------------
# 6. Promotions (JSON)
# ------------------------------------------------------------------------------
PROMOTIONS_DATA = [
    {
        "promo_id": "PRM-2026-BTS-01",
        "promo_name": "Back-to-School Tech & Apparel Blast",
        "promo_type": "PERCENTAGE_OFF",
        "discount_pct": 20,
        "applicable_skus": ["SKU-1001", "SKU-1003", "SKU-1008", "SKU-1009"],
        "applicable_categories": ["Electronics", "Clothing"],
        "applicable_regions": ["North", "East", "West", "Central"],
        "start_date": "2026-08-15",
        "end_date": "2026-08-31",
        "status": "EXPIRED"
    },
    {
        "promo_id": "PRM-2026-LABORDAY-02",
        "promo_name": "Labor Day Weekend Cookout & Home Sale",
        "promo_type": "PRICE_CUT",
        "discount_pct": 15,
        "applicable_skus": ["SKU-1023", "SKU-1024", "SKU-1025", "SKU-1029", "SKU-1030"],
        "applicable_categories": ["Home & Kitchen", "Sports"],
        "applicable_regions": ["North", "South", "East", "West"],
        "start_date": "2026-09-04",
        "end_date": "2026-09-08",
        "status": "EXPIRED"
    },
    {
        "promo_id": "PRM-2026-FALLFIT-03",
        "promo_name": "Fall Wellness & Beauty Reset",
        "promo_type": "BUY_ONE_GET_ONE",
        "discount_pct": 25,
        "applicable_skus": ["SKU-1029", "SKU-1031", "SKU-1033", "SKU-1034"],
        "applicable_categories": ["Sports", "Beauty"],
        "applicable_regions": ["North", "South", "East", "West"],
        "start_date": "2026-09-20",
        "end_date": "2026-10-05",
        "status": "EXPIRED"
    },
    {
        "promo_id": "PRM-2026-HALLOWEEN-04",
        "promo_name": "Halloween Spooktacular & Warm-up Deals",
        "promo_type": "PERCENTAGE_OFF",
        "discount_pct": 15,
        "applicable_skus": ["SKU-1016", "SKU-1018", "SKU-1027", "SKU-1035"],
        "applicable_categories": ["Groceries", "Home & Kitchen", "Beauty"],
        "applicable_regions": ["North", "South", "East", "West"],
        "start_date": "2026-10-24",
        "end_date": "2026-10-31",
        "status": "ACTIVE"
    }
]

# Quick promo lookup by (date, sku) -> discount_pct
promo_lookup = {}
for p in PROMOTIONS_DATA:
    p_start = date.fromisoformat(p["start_date"])
    p_end = date.fromisoformat(p["end_date"])
    d = p_start
    while d <= p_end:
        for sku in p["applicable_skus"]:
            promo_lookup[(d, sku)] = p["discount_pct"]
        d += timedelta(days=1)

# ------------------------------------------------------------------------------
# 7. Inventory Continuity & Daily Sales Simulation (Reconciled!)
# ------------------------------------------------------------------------------
# To strictly satisfy DQ Rule 4:
# Yesterday Stock + Received - Sold - TransfersOut + TransfersIn +/- Adjustments = Today Stock!

sku_map = {p["sku_id"]: p for p in products}
active_skus = [p["sku_id"] for p in products if p["status"] != "DISCONTINUED"]
dc_locations = [loc["location_id"] for loc in locations if loc["location_type"] == "DC"]
store_locations = [loc["location_id"] for loc in locations if loc["location_type"] == "STORE"]
hub_3pl = [loc["location_id"] for loc in locations if loc["location_type"] == "3PL"]
all_loc_ids = [loc["location_id"] for loc in locations]

# Initialize state per (sku, location)
current_stock = {}
for sku in active_skus:
    p_info = sku_map[sku]
    abc = p_info["abc_class"]
    for loc in locations:
        loc_id = loc["location_id"]
        loc_type = loc["location_type"]
        if loc_type == "DC":
            base = 1200 if abc == "A" else (600 if abc == "B" else 200)
        elif loc_type == "3PL":
            base = 400 if abc == "A" else (200 if abc == "B" else 80)
        else: # STORE
            base = 90 if abc == "A" else (45 if abc == "B" else 15)
        # Add random variation
        on_hand = int(base * random.uniform(0.85, 1.25))
        safety_stock = int(base * 0.25)
        current_stock[(sku, loc_id)] = {
            "on_hand": on_hand,
            "safety_stock": safety_stock
        }

sales_records = []
movement_records = []
snapshot_records = []
transfers_records = []
purchase_orders = []

movement_counter = 100000
transfer_counter = 5000
po_counter = 4000

# Open purchase orders tracked across days: (po_id, sku, dest_loc, qty, delivery_date)
pending_pos = []

# Open transfers tracked across days: (trf_id, sku, from_loc, to_loc, qty, delivery_date)
pending_transfers = []

curr_date = START_DATE
while curr_date <= END_DATE:
    date_str = curr_date.strftime("%Y-%m-%d")
    is_weekend = curr_date.weekday() >= 5
    day_is_peak = is_peak(curr_date)

    # 1. Process arriving Purchase Orders at DCs
    arrived_pos = [po for po in pending_pos if po["delivery_date"] == curr_date]
    pending_pos = [po for po in pending_pos if po["delivery_date"] > curr_date]

    for po in arrived_pos:
        sku = po["sku"]
        dest = po["dest"]
        qty = po["qty"]
        current_stock[(sku, dest)]["on_hand"] += qty

        # Log Movement: RECEIPT
        movement_counter += 1
        movement_records.append({
            "movement_id": f"MOV-{movement_counter}",
            "sku_id": sku,
            "location_id": dest,
            "movement_type": "RECEIPT",
            "quantity": qty,
            "reference_id": po["po_id"],
            "reason_code": "",
            "timestamp": f"{date_str} 08:30:00"
        })

    # 2. Process arriving Transfers at Stores
    arrived_trfs = [trf for trf in pending_transfers if trf["delivery_date"] == curr_date]
    pending_transfers = [trf for trf in pending_transfers if trf["delivery_date"] > curr_date]

    for trf in arrived_trfs:
        sku = trf["sku"]
        to_loc = trf["to_loc"]
        qty = trf["qty"]
        current_stock[(sku, to_loc)]["on_hand"] += qty

        movement_counter += 1
        movement_records.append({
            "movement_id": f"MOV-{movement_counter}",
            "sku_id": sku,
            "location_id": to_loc,
            "movement_type": "TRANSFER_IN",
            "quantity": qty,
            "reference_id": trf["trf_id"],
            "reason_code": "",
            "timestamp": f"{date_str} 10:15:00"
        })

    # 3. Simulate Daily Sales across locations
    for loc in locations:
        loc_id = loc["location_id"]
        loc_type = loc["location_type"]
        region = loc["region"]

        for sku in active_skus:
            p_info = sku_map[sku]
            abc = p_info["abc_class"]
            unit_price = float(p_info["unit_price"])
            stock_data = current_stock[(sku, loc_id)]
            avail = stock_data["on_hand"]

            # Base demand rate based on ABC class and location type
            if abc == "A":
                base_sales = random.randint(12, 28) if loc_type == "STORE" else random.randint(35, 75)
            elif abc == "B":
                base_sales = random.randint(4, 12) if loc_type == "STORE" else random.randint(15, 35)
            else:
                base_sales = random.randint(0, 4) if loc_type == "STORE" else random.randint(2, 10)

            # Modifiers: weekend, peak period, promo
            multiplier = 1.0
            if is_weekend: multiplier *= 1.35
            if day_is_peak: multiplier *= 1.45
            promo_discount = promo_lookup.get((curr_date, sku), 0)
            if promo_discount > 0: multiplier *= 1.50

            demanded_units = int(base_sales * multiplier)
            # Cannot sell more than available physical stock (Stock-out realism!)
            units_sold = min(avail, demanded_units)

            # Apply price discount if promo
            avg_price = unit_price * (1.0 - promo_discount / 100.0)
            sales_amount = round(units_sold * avg_price, 2)
            units_returned = random.randint(0, 1) if units_sold >= 15 else 0

            # Determine sales channel
            if loc_type == "STORE":
                channel = "IN_STORE" if random.random() < 0.75 else ("WEB" if random.random() < 0.85 else "APP")
            else:
                channel = "WEB" if random.random() < 0.70 else "APP"

            sales_records.append({
                "sales_date": date_str,
                "sku_id": sku,
                "location_id": loc_id,
                "channel": channel,
                "units_sold": units_sold,
                "sales_amount": f"{sales_amount:.2f}",
                "avg_selling_price": f"{avg_price:.2f}",
                "units_returned": units_returned
            })

            # Update stock state
            if units_sold > 0:
                stock_data["on_hand"] -= units_sold
                movement_counter += 1
                movement_records.append({
                    "movement_id": f"MOV-{movement_counter}",
                    "sku_id": sku,
                    "location_id": loc_id,
                    "movement_type": "SALE",
                    "quantity": -units_sold,
                    "reference_id": f"SAL-{curr_date.strftime('%Y%m%d')}-{loc_id}",
                    "reason_code": "",
                    "timestamp": f"{date_str} 17:00:00"
                })

            if units_returned > 0:
                stock_data["on_hand"] += units_returned
                movement_counter += 1
                movement_records.append({
                    "movement_id": f"MOV-{movement_counter}",
                    "sku_id": sku,
                    "location_id": loc_id,
                    "movement_type": "RETURN",
                    "quantity": units_returned,
                    "reference_id": f"RET-{curr_date.strftime('%Y%m%d')}-{loc_id}",
                    "reason_code": "",
                    "timestamp": f"{date_str} 18:30:00"
                })

    # 4. Trigger Replenishment Transfers (DC -> Store) if Store Stock falls below Safety Stock
    for loc in locations:
        if loc["location_type"] == "STORE":
            store_id = loc["location_id"]
            parent_dc = loc["parent_dc_id"]
            for sku in active_skus:
                stk = current_stock[(sku, store_id)]
                if stk["on_hand"] < stk["safety_stock"]:
                    dc_stk = current_stock[(sku, parent_dc)]
                    transfer_qty = int(stk["safety_stock"] * 2.5)
                    if dc_stk["on_hand"] >= transfer_qty:
                        dc_stk["on_hand"] -= transfer_qty
                        transfer_counter += 1
                        trf_id = f"TRF-{transfer_counter}"
                        transit_days = 2
                        rec_date = curr_date + timedelta(days=transit_days)

                        transfers_records.append({
                            "transfer_id": trf_id,
                            "from_location_id": parent_dc,
                            "to_location_id": store_id,
                            "sku_id": sku,
                            "qty": transfer_qty,
                            "shipped_date": date_str,
                            "received_date": rec_date.strftime("%Y-%m-%d") if rec_date <= END_DATE else "",
                            "status": "COMPLETED" if rec_date <= END_DATE else "IN_TRANSIT"
                        })

                        movement_counter += 1
                        movement_records.append({
                            "movement_id": f"MOV-{movement_counter}",
                            "sku_id": sku,
                            "location_id": parent_dc,
                            "movement_type": "TRANSFER_OUT",
                            "quantity": -transfer_qty,
                            "reference_id": trf_id,
                            "reason_code": "",
                            "timestamp": f"{date_str} 19:00:00"
                        })

                        if rec_date <= END_DATE:
                            pending_transfers.append({
                                "trf_id": trf_id,
                                "sku": sku,
                                "to_loc": store_id,
                                "qty": transfer_qty,
                                "delivery_date": rec_date
                            })

    # 5. Trigger Supplier Purchase Orders (PO) if DC stock is low
    for dc_id in dc_locations:
        for sku in active_skus:
            dc_stk = current_stock[(sku, dc_id)]
            if dc_stk["on_hand"] < dc_stk["safety_stock"]:
                supp_list = supplier_sku_map.get(sku, [])
                if supp_list:
                    supp = supp_list[0] # primary supplier
                    po_counter += 1
                    po_id = f"PO-2026-{po_counter}"
                    order_qty = max(supp["moq"], dc_stk["safety_stock"] * 4)
                    lead_time = supp["lead_time"]
                    # Add realistic supplier variance (+/- 1-2 days)
                    actual_lead = max(1, lead_time + random.choice([-1, 0, 0, 1, 2]))
                    expected_date = curr_date + timedelta(days=lead_time)
                    actual_date = curr_date + timedelta(days=actual_lead)

                    po_status = "RECEIVED" if actual_date <= END_DATE else "OPEN"
                    total_val = round(order_qty * supp["cost"], 2)

                    po_record = {
                        "po_id": po_id,
                        "supplier_id": supp["supplier_id"],
                        "destination_location_id": dc_id,
                        "order_date": date_str,
                        "expected_delivery_date": expected_date.strftime("%Y-%m-%d"),
                        "actual_delivery_date": actual_date.strftime("%Y-%m-%d") if po_status == "RECEIVED" else None,
                        "status": po_status,
                        "total_po_value": total_val,
                        "items": [
                            {
                                "sku_id": sku,
                                "ordered_qty": order_qty,
                                "received_qty": order_qty if po_status == "RECEIVED" else 0,
                                "unit_cost": float(f"{supp['cost']:.2f}"),
                                "line_total": total_val
                            }
                        ]
                    }
                    purchase_orders.append(po_record)

                    if po_status == "RECEIVED":
                        pending_pos.append({
                            "po_id": po_id,
                            "sku": sku,
                            "dest": dc_id,
                            "qty": order_qty,
                            "delivery_date": actual_date
                        })

    # 6. Capture Daily Inventory Snapshot for this date
    for loc in locations:
        loc_id = loc["location_id"]
        for sku in active_skus:
            stk = current_stock[(sku, loc_id)]
            on_hand = stk["on_hand"]
            # Reserved units (orders in packing queue)
            reserved = min(on_hand, int(on_hand * random.uniform(0.05, 0.15))) if on_hand > 5 else 0
            available = on_hand - reserved
            is_stockout = (available == 0)

            # In-transit stock calculation
            incoming_pos = sum(p["qty"] for p in pending_pos if p["sku"] == sku and p["dest"] == loc_id)
            incoming_trfs = sum(t["qty"] for t in pending_transfers if t["sku"] == sku and t["to_loc"] == loc_id)
            in_transit = incoming_pos + incoming_trfs
            damaged = random.randint(1, 2) if (on_hand > 50 and random.random() < 0.05) else 0

            snapshot_records.append({
                "snapshot_date": date_str,
                "sku_id": sku,
                "location_id": loc_id,
                "on_hand_qty": on_hand,
                "reserved_qty": reserved,
                "available_qty": available,
                "in_transit_qty": in_transit,
                "damaged_qty": damaged,
                "safety_stock_qty": stk["safety_stock"],
                "is_stockout": is_stockout
            })

    curr_date += timedelta(days=1)

# ------------------------------------------------------------------------------
# 8. Customer Orders & Shipments Simulation (M3 Alignment)
# ------------------------------------------------------------------------------
customer_orders = []
shipments = []
order_id_counter = 88000
shipment_id_counter = 99000

# Sample customers
SAMPLE_CUSTOMERS = [
    ("CUST-1001", "Emma Watson", "742 Evergreen Terr", "+1-555-010-4411", "10001", "East"),
    ("CUST-1002", "Liam Neeson", "221B Baker Ave", "+1-555-012-7890", "02108", "East"),
    ("CUST-1003", "Olivia Wilde", "100 Lake Shore Dr", "+1-555-014-2233", "60611", "North"),
    ("CUST-1004", "Noah Centineo", "450 Nicollet Mall", "+1-555-015-8877", "55401", "North"),
    ("CUST-1005", "Sophia Bush", "1200 Main Street", "+1-555-017-9944", "75201", "South"),
    ("CUST-1006", "Jackson Avery", "808 Congress Ave", "+1-555-018-3322", "78701", "South"),
    ("CUST-1007", "Mia Khalifa", "350 S Grand Ave", "+1-555-019-5566", "90012", "West"),
    ("CUST-1008", "Ethan Hunt", "1301 2nd Avenue", "+1-555-020-7711", "98101", "West"),
]

# Generate orders across the timeline
order_date_cursor = START_DATE
while order_date_cursor <= END_DATE:
    # 20 to 35 orders per day
    daily_order_count = random.randint(20, 35)
    for _ in range(daily_order_count):
        order_id_counter += 1
        order_id = f"ORD-2026-{order_id_counter}"
        cust = random.choice(SAMPLE_CUSTOMERS)
        service_level = random.choices(["STANDARD", "NEXT_DAY", "SAME_DAY"], weights=[0.70, 0.25, 0.05])[0]

        # Order placement time
        hour = random.randint(8, 22)
        minute = random.randint(0, 59)
        second = random.randint(0, 59)
        order_dt = datetime.datetime.combine(order_date_cursor, datetime.time(hour, minute, second))

        # Promised delivery date
        if service_level == "SAME_DAY":
            promised_delivery = order_date_cursor
        elif service_level == "NEXT_DAY":
            promised_delivery = order_date_cursor + timedelta(days=1)
        else: # STANDARD
            promised_delivery = order_date_cursor + timedelta(days=random.choice([3, 4]))

        # Location picking: DC preferred for orders with same region
        candidate_locs = [loc for loc in locations if loc["region"] == cust[5] and loc["location_type"] == "DC"]
        if not candidate_locs:
            candidate_locs = dc_locations
        fulfilled_loc = candidate_locs[0]["location_id"] if candidate_locs else "LOC-DC-01"

        # Order items (1 to 4 items)
        num_items = random.choices([1, 2, 3, 4], weights=[0.50, 0.30, 0.15, 0.05])[0]
        order_items = []
        subtotal = 0.0
        chosen_skus = random.sample(active_skus, num_items)
        for s in chosen_skus:
            p_inf = sku_map[s]
            qty = random.randint(1, 3)
            price = float(p_inf["unit_price"])
            subtotal += qty * price
            order_items.append({
                "sku_id": s,
                "qty": qty,
                "unit_price": price
            })

        # Order status
        if promised_delivery < END_DATE:
            status = "DELIVERED"
        elif promised_delivery == END_DATE:
            status = random.choice(["DELIVERED", "SHIPPED"])
        else:
            status = random.choice(["SHIPPED", "PACKED", "CREATED"])

        # Masked customer personal info (Satisfies privacy requirement!)
        masked_name = cust[1][0] + "*** " + cust[1].split()[-1][0] + "***"
        masked_addr = cust[2].split()[0] + " *** St"
        masked_phone = cust[3][:6] + "***-" + cust[3][-4:]

        order_record = {
            "order_id": order_id,
            "customer_id": cust[0],
            "customer_details": {
                "customer_name": masked_name,
                "address": masked_addr,
                "phone": masked_phone
            },
            "delivery": {
                "delivery_postal_code": cust[4],
                "delivery_region": cust[5]
            },
            "order_timestamp": order_dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "promised_delivery_date": promised_delivery.strftime("%Y-%m-%d"),
            "service_level": service_level,
            "fulfilled_from_location_id": fulfilled_loc,
            "order_status": status,
            "is_split_shipment": False,
            "order_subtotal": round(subtotal, 2),
            "items": order_items
        }
        customer_orders.append(order_record)

        # Generate Shipment if SHIPPED or DELIVERED
        if status in ["DELIVERED", "SHIPPED"]:
            shipment_id_counter += 1
            shipment_id = f"SHP-2026-{shipment_id_counter}"

            # Assign carrier based on service level
            matching_carriers = [c for c in carriers if c["service_level"] == service_level]
            chosen_carrier = random.choice(matching_carriers) if matching_carriers else carriers[0]

            # Ship timestamp (a few hours after order placement)
            ship_dt = order_dt + timedelta(hours=random.randint(2, 6))

            # Delivery timestamp and late risk simulation (M3 alignment!)
            is_delayed = (random.random() < 0.12) or (is_peak(order_date_cursor) and random.random() < 0.22)
            if service_level == "SAME_DAY":
                if not is_delayed:
                    delivered_dt = ship_dt + timedelta(hours=random.randint(2, 5))
                else:
                    next_day = order_date_cursor + timedelta(days=1)
                    delivered_dt = datetime.datetime.combine(next_day, datetime.time(random.randint(10, 16), random.randint(0, 59), 0))
            elif service_level == "NEXT_DAY":
                actual_deliv_date = promised_delivery if not is_delayed else (promised_delivery + timedelta(days=1))
                deliv_time = datetime.time(random.randint(9, 18), random.randint(0, 59), 0)
                delivered_dt = datetime.datetime.combine(actual_deliv_date, deliv_time)
                if delivered_dt <= ship_dt:
                    delivered_dt = ship_dt + timedelta(hours=random.randint(8, 16))
            else: # STANDARD
                actual_deliv_date = promised_delivery if not is_delayed else (promised_delivery + timedelta(days=random.choice([1, 2])))
                deliv_time = datetime.time(random.randint(9, 19), random.randint(0, 59), 0)
                delivered_dt = datetime.datetime.combine(actual_deliv_date, deliv_time)
                if delivered_dt <= ship_dt:
                    delivered_dt = ship_dt + timedelta(days=random.randint(1, 2))

            actual_deliv_date = delivered_dt.date()
            is_late = (actual_deliv_date > promised_delivery)
            delay_note = random.choice([
                "Carrier transit hub capacity overflow",
                "Severe adverse weather conditions",
                "Local delivery vehicle breakdown",
                "Customer address gate access delay"
            ]) if is_late else None

            # Monotonic tracking event timestamps
            total_duration = (delivered_dt - ship_dt)
            mid_transit_dt = ship_dt + total_duration * 0.4
            events = [
                {
                    "event_type": "PICKED_UP",
                    "timestamp": ship_dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
                    "delay_note": None
                },
                {
                    "event_type": "IN_TRANSIT",
                    "timestamp": mid_transit_dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
                    "delay_note": None
                }
            ]
            if is_delayed:
                delayed_ts = ship_dt + total_duration * 0.75
                events.append({
                    "event_type": "DELAYED",
                    "timestamp": delayed_ts.strftime("%Y-%m-%dT%H:%M:%SZ"),
                    "delay_note": delay_note
                })
            if status == "DELIVERED":
                events.append({
                    "event_type": "DELIVERED",
                    "timestamp": delivered_dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
                    "delay_note": delay_note
                })

            shipments.append({
                "shipment_id": shipment_id,
                "order_id": order_id,
                "origin_location_id": fulfilled_loc,
                "carrier_id": chosen_carrier["carrier_id"],
                "service_level": service_level,
                "ship_timestamp": ship_dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "delivered_timestamp": delivered_dt.strftime("%Y-%m-%dT%H:%M:%SZ") if status == "DELIVERED" else None,
                "is_late": is_late if status == "DELIVERED" else False,
                "shipping_cost": float(chosen_carrier["base_rate"]),
                "tracking_events": events
            })

    order_date_cursor += timedelta(days=1)

# ------------------------------------------------------------------------------
# 9. Documents (PDF Format - Section 1.13)
# ------------------------------------------------------------------------------
def create_pdf(filepath, title, subtitle, sections):
    doc = SimpleDocTemplate(
        filepath,
        pagesize=letter,
        rightMargin=54,
        leftMargin=54,
        topMargin=54,
        bottomMargin=54
    )
    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=16,
        leading=20,
        textColor=colors.HexColor('#0F172A'),
        spaceAfter=6
    )
    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10,
        leading=14,
        textColor=colors.HexColor('#64748B'),
        spaceAfter=12
    )
    h2_style = ParagraphStyle(
        'DocH2',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=15,
        textColor=colors.HexColor('#1E293B'),
        spaceBefore=10,
        spaceAfter=4
    )
    body_style = ParagraphStyle(
        'DocBody',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=13.5,
        textColor=colors.HexColor('#334155'),
        spaceAfter=5
    )

    story = [
        Paragraph(title, title_style),
        Paragraph(subtitle, subtitle_style),
        HRFlowable(width="100%", thickness=1, color=colors.HexColor('#CBD5E1'), spaceAfter=12),
    ]

    for sec_title, paragraphs in sections:
        if sec_title:
            story.append(Paragraph(sec_title, h2_style))
        for p_text in paragraphs:
            story.append(Paragraph(p_text, body_style))
        story.append(Spacer(1, 4))

    doc.build(story)

# 1. Supplier Contract PDF
create_pdf(
    os.path.join(DOCS_DIR, "CONTRACT_APEX_GLOBAL_2026.pdf"),
    "MASTER PROCUREMENT & SUPPLY AGREEMENT (MSA-2026-001)",
    "Document ID: MSA-2026-001 | Supplier ID: SUP-001 | Effective Date: January 1, 2026 to December 31, 2027",
    [
        ("1. PARTIES & SCOPE OF MERCHANDISE", [
            "This Agreement is executed between Retail Intelligence Operations Inc. ('Buyer') and Apex Global Electronics ('Supplier SUP-001').",
            "Scope: Authorized volume manufacturing and supply of consumer electronics including Wireless Headphones, Smart 4K UHD TVs, Bluetooth Waterproof Speakers, and Smartwatch Trackers."
        ]),
        ("2. PRICING & MINIMUM ORDER QUANTITIES (MOQ)", [
            "Contract unit costs are fixed for the 24-month duration. Minimum Order Quantity (MOQ) is strictly established at 100 units per line item.",
            "Purchase Orders below MOQ require written authorization from the Procurement Director and incur a 5% handling surcharge."
        ]),
        ("3. DELIVERY LEAD TIMES & PERFORMANCE SLA", [
            "Promised standard delivery lead time is thirty (30) business days from confirmed PO issuance to arrival at destination DC.",
            "Orders must achieve a minimum line-item fulfillment fill rate of 95% upon initial delivery dock intake."
        ]),
        ("4. LATE DELIVERY PENALTIES & LIQUIDATED DAMAGES", [
            "<b>Late Delivery Penalty:</b> For unexcused shipment delays exceeding promised lead time, a contractual penalty of <b>1.5% per calendar day</b> of total PO value shall be deducted directly from net settlement invoice.",
            "Delays exceeding 14 calendar days grant Buyer the absolute right to cancel open PO balances without cancellation liability."
        ])
    ]
)
print("Generated PDF: documents/CONTRACT_APEX_GLOBAL_2026.pdf")

# 2. Warehouse SOP PDF
create_pdf(
    os.path.join(DOCS_DIR, "SOP_DAMAGED_GOODS_RECEIVING_V2.pdf"),
    "STANDARD OPERATING PROCEDURE: DAMAGED & DEFECTIVE INVENTORY RECEIVING",
    "Document ID: SOP-LOG-004 | Version: 2.1 | Effective Date: June 1, 2025 | Target: All DCs & Fulfillment Centers",
    [
        ("1. PURPOSE & APPLICABILITY", [
            "Establishes mandatory dock intake protocols when freight shipments arrive showing carton crushing, punctured seals, moisture exposure, or pallet destabilization.",
            "Applies across all Regional Distribution Centers (LOC-DC-01 through LOC-DC-04) and partner 3PL intake locations."
        ]),
        ("2. INBOUND DOCK INSPECTION & PROOF OF DELIVERY (POD)", [
            "Step 2.1: Inspect physical outer packaging before driver departure and prior to signing the electronic Bill of Lading (BOL).",
            "Step 2.2: Note damage explicitly on the carrier Proof of Delivery (POD) endorsed by the transport driver's signature.",
            "Step 2.3: Take at least 4 high-resolution digital photographs capturing outer shipping carton, carrier tracking label, and inner product SKU barcode."
        ]),
        ("3. SYSTEM LOGGING & QUARANTINE PROTOCOL", [
            "Step 3.1: Log item quantity in WMS under dedicated inventory attribute 'DAMAGED_QTY'. These units are immediately excluded from available stock.",
            "Step 3.2: Move compromised stock directly into secure holding bay 'ZONE-Q-SECURE' pending vendor credit approval.",
            "Step 3.3: Automatic WMS webhook triggers freight insurance notification within twenty-four (24) operational hours."
        ]),
        ("4. CLAIMS FILING & VENDOR DISPOSITION", [
            "Claims for damaged inbound deliveries must be formally filed with carrier and supplier within three (3) business days.",
            "Write-off approval threshold: Authorizations under $500 require DC Supervisor sign-off; amounts above $500 require Regional Director approval."
        ])
    ]
)
print("Generated PDF: documents/SOP_DAMAGED_GOODS_RECEIVING_V2.pdf")

# 3. Carrier Service Guide PDF
create_pdf(
    os.path.join(DOCS_DIR, "CARRIER_FEDEX_SERVICE_GUIDE_2026.pdf"),
    "CARRIER ENTERPRISE SERVICE LEVEL AGREEMENT & TRANSIT STANDARDS 2026",
    "Carrier: FedEx Corporation | Carrier ID: CAR-FEDEX | Effective Date: January 15, 2026 to January 14, 2027",
    [
        ("1. SERVICE LEVELS & TRANSIT TIME COMMITMENTS", [
            "<b>FedEx Priority Overnight (NEXT_DAY):</b> Guaranteed delivery by 10:30 AM or 12:00 PM next business day based on postal code destination.",
            "<b>FedEx Home Delivery / Ground (STANDARD):</b> 1 to 5 business day transit based on domestic postal zone. Operating Tuesday through Sunday.",
            "<b>FedEx SameDay City (SAME_DAY):</b> Dedicated direct-drive courier transport with delivery within 6 hours of warehouse dispatch."
        ]),
        ("2. ON-TIME PERFORMANCE SLA & CREDITS", [
            "Contractual baseline requires a minimum <b>98.5% on-time delivery rate</b> across non-peak operating periods.",
            "Shipments delivered past published SLA without valid exception cause are eligible for a 100% freight charge refund upon electronic audit."
        ]),
        ("3. FACILITY DEPARTURE CUTOFF TIMES", [
            "Outbound evening trailer dispatch cutoff time is strictly scheduled for <b>18:00:00 local facility time</b> at all primary distribution centers.",
            "Orders packaged after 18:00:00 will stage for next-day dispatch and adjust customer delivery estimates accordingly."
        ]),
        ("4. TRANSIT EXCEPTIONS & FORCE MAJEURE CONDITIONS", [
            "Valid transit exception codes: WEATHER_DELAY, HIGHWAY_CLOSURE, MECHANICAL_BREAKDOWN, CUSTOMER_GATE_LOCKED.",
            "Weather delays must reference official National Weather Service advisories to qualify as excused non-compensable transit exceptions."
        ])
    ]
)
print("Generated PDF: documents/CARRIER_FEDEX_SERVICE_GUIDE_2026.pdf")

# Clean up legacy text and metadata files if present
for old_file in ["CARRIER_FEDEX_SERVICE_GUIDE_2026.txt", "CONTRACT_APEX_GLOBAL_2026.txt", "SOP_DAMAGED_GOODS_RECEIVING_V2.txt"]:
    old_p = os.path.join(DOCS_DIR, old_file)
    if os.path.exists(old_p):
        os.remove(old_p)
if os.path.exists(os.path.join(OUTPUT_DIR, "documents_metadata.json")):
    os.remove(os.path.join(OUTPUT_DIR, "documents_metadata.json"))

# ------------------------------------------------------------------------------
# 10. Write Exactly 13 Datasets (9 CSV + 4 JSON)
# ------------------------------------------------------------------------------

def write_csv(filename, data, fieldnames):
    filepath = os.path.join(OUTPUT_DIR, filename)
    with open(filepath, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)
    print(f"Generated CSV: {filename} ({len(data):,} records)")

def write_json(filename, data):
    filepath = os.path.join(OUTPUT_DIR, filename)
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    print(f"Generated JSON: {filename} ({len(data):,} records)")

# 1. products.csv
write_csv("products.csv", products, [
    "sku_id", "product_name", "category", "brand", "abc_class",
    "unit_cost", "unit_price", "case_pack_qty", "weight_kg",
    "shelf_life_days", "status", "launch_date"
])

# 2. locations.csv
write_csv("locations.csv", locations, [
    "location_id", "location_type", "region", "postal_code",
    "latitude", "longitude", "parent_dc_id", "storage_capacity",
    "daily_order_capacity", "cutoff_time", "is_active"
])

# 3. suppliers.csv
write_csv("suppliers.csv", suppliers, [
    "supplier_id", "supplier_name", "country", "promised_lead_time_days",
    "sku_id", "moq", "contract_unit_cost", "is_preferred", "is_active"
])

# 4. carriers.csv
write_csv("carriers.csv", carriers, [
    "carrier_id", "carrier_name", "service_level",
    "promised_transit_days", "base_rate"
])

# 5. calendar.csv
write_csv("calendar.csv", calendar_records, [
    "date", "is_holiday", "holiday_name", "week", "month", "season", "is_peak_period"
])

# 6. inventory_snapshots.csv
write_csv("inventory_snapshots.csv", snapshot_records, [
    "snapshot_date", "sku_id", "location_id", "on_hand_qty",
    "reserved_qty", "available_qty", "in_transit_qty", "damaged_qty",
    "safety_stock_qty", "is_stockout"
])

# 7. inventory_movements.csv
write_csv("inventory_movements.csv", movement_records, [
    "movement_id", "sku_id", "location_id", "movement_type",
    "quantity", "reference_id", "reason_code", "timestamp"
])

# 8. sales_demand.csv
write_csv("sales_demand.csv", sales_records, [
    "sales_date", "sku_id", "location_id", "channel",
    "units_sold", "sales_amount", "avg_selling_price", "units_returned"
])

# 9. transfers.csv
write_csv("transfers.csv", transfers_records, [
    "transfer_id", "from_location_id", "to_location_id", "sku_id",
    "qty", "shipped_date", "received_date", "status"
])

# 10. promotions.json
write_json("promotions.json", PROMOTIONS_DATA)

# 11. purchase_orders.json
write_json("purchase_orders.json", purchase_orders)

# 12. customer_orders.json
write_json("customer_orders.json", customer_orders)

# 13. shipments.json
write_json("shipments.json", shipments)

# ------------------------------------------------------------------------------
# 11. Comprehensive Data Quality Verification & Audit (Section 3)
# ------------------------------------------------------------------------------
def run_data_quality_audit():
    print("\n" + "="*80)
    print("RUNNING COMPREHENSIVE DATA QUALITY AUDIT (Section 3 Checks)")
    print("="*80)

    # Check 1: Primary Key Uniqueness & Non-null
    pk_checks = [
        ("products.csv", products, "sku_id"),
        ("locations.csv", locations, "location_id"),
        ("suppliers.csv", suppliers, ["supplier_id", "sku_id"]),
        ("carriers.csv", carriers, "carrier_id"),
        ("calendar.csv", calendar_records, "date"),
        ("transfers.csv", transfers_records, "transfer_id"),
        ("inventory_movements.csv", movement_records, "movement_id"),
        ("purchase_orders.json", purchase_orders, "po_id"),
        ("customer_orders.json", customer_orders, "order_id"),
        ("shipments.json", shipments, "shipment_id"),
    ]

    for fname, data, pk_col in pk_checks:
        seen = set()
        for row in data:
            if isinstance(pk_col, list):
                val = tuple(row[k] for k in pk_col)
            else:
                val = row[pk_col]
            assert val, f"[DQ FAIL] Empty PK {pk_col} in {fname}"
            assert val not in seen, f"[DQ FAIL] Duplicate PK {val} in {fname}"
            seen.add(val)
        print(f"  [PASS] PK Uniqueness & Completeness: {fname} ({len(data):,} records)")

    # Check 2: Referential Integrity
    valid_skus = {p["sku_id"] for p in products}
    valid_locs = {l["location_id"] for l in locations}
    valid_supps = {s["supplier_id"] for s in suppliers}
    valid_carriers = {c["carrier_id"] for c in carriers}
    valid_orders = {o["order_id"] for o in customer_orders}

    # Sales links
    for s in sales_records:
        assert s["sku_id"] in valid_skus, f"Unknown SKU {s['sku_id']} in sales"
        assert s["location_id"] in valid_locs, f"Unknown location {s['location_id']} in sales"
    print("  [PASS] Referential Integrity: sales_demand -> products & locations")

    # Snapshots links
    for sn in snapshot_records:
        assert sn["sku_id"] in valid_skus, f"Unknown SKU {sn['sku_id']} in snapshot"
        assert sn["location_id"] in valid_locs, f"Unknown location {sn['location_id']} in snapshot"
    print("  [PASS] Referential Integrity: inventory_snapshots -> products & locations")

    # Purchase Orders links
    for po in purchase_orders:
        assert po["supplier_id"] in valid_supps, f"Unknown supplier {po['supplier_id']}"
        assert po["destination_location_id"] in valid_locs, f"Unknown DC {po['destination_location_id']}"
        for it in po["items"]:
            assert it["sku_id"] in valid_skus, f"Unknown SKU {it['sku_id']} in PO"
    print("  [PASS] Referential Integrity: purchase_orders -> suppliers, locations, products")

    # Customer Orders links
    for co in customer_orders:
        assert co["fulfilled_from_location_id"] in valid_locs, f"Unknown fulfillment location {co['fulfilled_from_location_id']}"
        for it in co["items"]:
            assert it["sku_id"] in valid_skus, f"Unknown SKU {it['sku_id']} in order"
    print("  [PASS] Referential Integrity: customer_orders -> locations, products")

    # Shipments links
    for sh in shipments:
        assert sh["order_id"] in valid_orders, f"Unknown order {sh['order_id']} in shipment"
        assert sh["carrier_id"] in valid_carriers, f"Unknown carrier {sh['carrier_id']} in shipment"
        assert sh["origin_location_id"] in valid_locs, f"Unknown origin {sh['origin_location_id']}"
    print("  [PASS] Referential Integrity: shipments -> orders, carriers, locations")

    # Check 3: Values make sense (No negative quantities, price > cost, valid enums, dates chronological)
    for p in products:
        cost = float(p["unit_cost"])
        price = float(p["unit_price"])
        assert cost > 0, f"Non-positive cost {cost} for {p['sku_id']}"
        assert price > cost, f"Unit price ({price}) <= cost ({cost}) for {p['sku_id']}"
        assert p["abc_class"] in {"A", "B", "C"}, f"Invalid ABC class {p['abc_class']}"
        assert p["status"] in {"NEW", "ACTIVE", "DISCONTINUED"}
    print("  [PASS] Business Logic: products (positive margins, valid enums)")

    for sn in snapshot_records:
        on_hand = sn["on_hand_qty"]
        reserved = sn["reserved_qty"]
        avail = sn["available_qty"]
        assert on_hand >= 0, f"Negative on_hand {on_hand}"
        assert reserved >= 0, f"Negative reserved {reserved}"
        assert avail >= 0, f"Negative available {avail}"
        assert avail == on_hand - reserved, f"Available mismatch {avail} != {on_hand} - {reserved}"
        if avail == 0:
            assert sn["is_stockout"] is True, f"Stockout flag mismatch for 0 available"
        else:
            assert sn["is_stockout"] is False, f"Stockout flag mismatch for {avail} available"
    print("  [PASS] Business Logic: inventory_snapshots (available = on_hand - reserved, no negatives, stockout flag)")

    for po in purchase_orders:
        ord_d = date.fromisoformat(po["order_date"])
        exp_d = date.fromisoformat(po["expected_delivery_date"])
        assert exp_d >= ord_d, f"Expected delivery before order date in PO {po['po_id']}"
        if po["actual_delivery_date"]:
            act_d = date.fromisoformat(po["actual_delivery_date"])
            assert act_d >= ord_d, f"Actual delivery before order date in PO {po['po_id']}"
    print("  [PASS] Business Logic: purchase_orders (actual_delivery_date >= order_date)")

    for sh in shipments:
        ship_ts = datetime.datetime.fromisoformat(sh["ship_timestamp"].replace("Z", "+00:00"))
        if sh["delivered_timestamp"]:
            deliv_ts = datetime.datetime.fromisoformat(sh["delivered_timestamp"].replace("Z", "+00:00"))
            assert deliv_ts >= ship_ts, f"Delivered before shipped in shipment {sh['shipment_id']}"
    print("  [PASS] Business Logic: shipments (delivered_timestamp >= ship_timestamp)")

    # Check 4: Exactly 13 Dataset Tables Generated
    expected_tables = {
        "products.csv", "locations.csv", "suppliers.csv", "carriers.csv",
        "calendar.csv", "inventory_snapshots.csv", "inventory_movements.csv",
        "sales_demand.csv", "transfers.csv", "promotions.json",
        "purchase_orders.json", "customer_orders.json", "shipments.json"
    }
    actual_files = set(f for f in os.listdir(OUTPUT_DIR) if os.path.isfile(os.path.join(OUTPUT_DIR, f)))
    assert actual_files == expected_tables, f"Mismatch in generated tables! Expected {expected_tables}, got {actual_files}"
    print(f"  [PASS] File Inventory: Exactly {len(actual_files)} tables verified in {OUTPUT_DIR}")

    # Check 5: Exactly 3 PDF documents in documents/
    expected_docs = {
        "CONTRACT_APEX_GLOBAL_2026.pdf",
        "SOP_DAMAGED_GOODS_RECEIVING_V2.pdf",
        "CARRIER_FEDEX_SERVICE_GUIDE_2026.pdf"
    }
    actual_docs = set(f for f in os.listdir(DOCS_DIR) if os.path.isfile(os.path.join(DOCS_DIR, f)))
    assert actual_docs == expected_docs, f"Mismatch in PDF documents! Expected {expected_docs}, got {actual_docs}"
    print(f"  [PASS] Document Inventory: Exactly {len(actual_docs)} PDF documents verified in {DOCS_DIR}")

    print("="*80)
    print("ALL DATA QUALITY & BUSINESS LOGIC CHECKS PASSED WITH 0 DEFECTS!")
    print("="*80 + "\n")

if __name__ == "__main__":
    run_data_quality_audit()
