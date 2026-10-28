# =============================================================================
# RETAIL CUSTOMER PROMOTION — REAL-TIME SYNTHETIC DATA GENERATOR
# =============================================================================
# Generates realistic, enterprise-grade semi-structured JSON payloads mirroring
# production source systems (Salesforce CRM, Shopify POS, Zendesk, Segment).
#
# ARCHITECTURAL SEPARATION OF CONCERNS:
# 1. RAW INGESTION (Bronze): Contains full authentic operational payloads including
#    PII (names, emails, phones), operational IDs (stores, products, sessions),
#    audit metadata, and resolution details.
# 2. SNOWFLAKE GOVERNANCE & SILVER: Applies Dynamic Data Masking (MP_STRING_PII_MASK),
#    unnests items via LATERAL FLATTEN, and enforces CDC streams.
# 3. FEATURE STORE & ML: Filters out PII and high-cardinality noise, deriving high-signal
#    features (RFM, velocity drop, friction, CSAT) for model training and online serving.
# =============================================================================

import json
import random
import uuid
import os
from datetime import datetime, timedelta

random.seed(42)

BASE_DIR = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else os.getcwd()
OUTPUT_DIR = os.path.join(BASE_DIR, "cooked_json_data")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Configuration record counts
NUM_CUSTOMERS = 200
NUM_TRANSACTIONS = 1500
NUM_CAMPAIGNS = 50
NUM_CAMPAIGN_INTERACTIONS = 2500
NUM_CHANNEL_ACTIVITIES = 3000
NUM_SUPPORT_TICKETS = 300

FIRST_NAMES = [
    "James", "Mary", "Robert", "Patricia", "John", "Jennifer", "Michael", "Linda",
    "David", "Elizabeth", "William", "Barbara", "Richard", "Susan", "Joseph", "Jessica",
    "Thomas", "Sarah", "Christopher", "Karen", "Charles", "Lisa", "Daniel", "Nancy",
    "Matthew", "Betty", "Anthony", "Margaret", "Mark", "Sandra", "Donald", "Ashley",
    "Steven", "Kimberly", "Paul", "Emily", "Andrew", "Donna", "Joshua", "Michelle"
]

LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
    "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
    "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson", "White"
]

EMAIL_DOMAINS = ["gmail.com", "yahoo.com", "outlook.com", "icloud.com", "retailmail.com"]
LOYALTY_TIERS = ["BRONZE", "SILVER", "GOLD", "PLATINUM"]
LOYALTY_WEIGHTS = [0.40, 0.30, 0.20, 0.10]
SIGNUP_CHANNELS = ["WEB", "MOBILE_APP", "IN_STORE", "REFERRAL", "SOCIAL_MEDIA"]

STATES = [
    "CA", "NY", "TX", "FL", "IL", "PA", "OH", "GA", "NC", "MI",
    "NJ", "VA", "WA", "AZ", "MA", "TN", "IN", "MO", "MD", "WI",
    "CO", "MN", "SC", "AL", "LA", "KY", "OR", "OK", "CT", "UT"
]

PAYMENT_METHODS = ["CREDIT_CARD", "DEBIT_CARD", "APPLE_PAY", "GOOGLE_PAY", "PAYPAL", "CASH"]

PRODUCT_CATALOG = {
    "ELECTRONICS": [
        ("PROD_1001", "Wireless Earbuds Pro", 79.99),
        ("PROD_1002", "Bluetooth Speaker Mini", 49.99),
        ("PROD_1003", "Smart Fitness Tracker", 89.99),
        ("PROD_1004", "Noise Cancelling Headphones", 149.99),
        ("PROD_1005", "USB-C Fast Charging Hub", 34.99),
    ],
    "CLOTHING": [
        ("PROD_2001", "Classic Cotton Crewneck", 19.99),
        ("PROD_2002", "Slim Stretch Denim Jeans", 49.99),
        ("PROD_2003", "Full-Zip Athletic Hoodie", 44.99),
        ("PROD_2004", "Breathable Running Shorts", 24.99),
    ],
    "HOME_KITCHEN": [
        ("PROD_3001", "Stainless Insulated Bottle", 22.99),
        ("PROD_3002", "Ceramic Pour-Over Mug Set", 18.99),
        ("PROD_3003", "Non-Stick 10in Skillet", 29.99),
    ],
    "BEAUTY": [
        ("PROD_4001", "Hydrating Vitamin C Serum", 24.99),
        ("PROD_4002", "Mineral Sunscreen SPF 50", 19.99),
        ("PROD_4003", "Nourishing Night Cream", 27.99),
    ],
    "SPORTS": [
        ("PROD_5001", "High-Density Yoga Mat", 34.99),
        ("PROD_5002", "Resistance Bands 5-Pack", 19.99),
        ("PROD_5003", "Adjustable Speed Jump Rope", 12.99),
    ],
    "FOOTWEAR": [
        ("PROD_6001", "Road Runner Cushion Sneaker", 89.99),
        ("PROD_6002", "Waterproof Trail Hiking Boot", 119.99),
        ("PROD_6003", "Everyday Canvas Slip-On", 49.99),
    ]
}

PRODUCT_CATEGORIES = list(PRODUCT_CATALOG.keys())

OFFER_TYPES = ["PERCENTAGE_DISCOUNT", "FIXED_AMOUNT_OFF", "BUY_ONE_GET_ONE",
               "FREE_SHIPPING", "LOYALTY_POINTS_MULTIPLIER"]

CAMPAIGN_CHANNELS = ["EMAIL", "PUSH_NOTIFICATION", "SMS", "IN_APP_BANNER"]

CAMPAIGN_SEGMENTS = ["ALL_CUSTOMERS", "BRONZE_AND_ABOVE", "SILVER_AND_ABOVE",
                     "GOLD_AND_ABOVE", "PLATINUM_ONLY", "INACTIVE_90D",
                     "NEW_SIGNUPS_30D", "HIGH_SPENDERS"]

DIGITAL_CHANNELS = ["WEB", "MOBILE_APP", "EMAIL", "IN_STORE"]
DIGITAL_EVENTS = ["PAGE_VIEW", "PRODUCT_DETAIL_VIEW", "CART_ADD", "CHECKOUT_START", "CHECKOUT_COMPLETE", "SEARCH"]
DEVICE_TYPES = ["IOS_APP", "ANDROID_APP", "DESKTOP_MAC", "DESKTOP_WINDOWS", "MOBILE_SAFARI"]

TICKET_CATEGORIES = ["SHIPPING_DELAY", "BILLING_DISPUTE", "PRODUCT_DEFECT",
                     "RETURN_REQUEST", "ACCOUNT_ACCESS", "PROMO_CODE_ISSUE"]
SEVERITIES = ["LOW", "MEDIUM", "HIGH", "CRITICAL"]

def random_timestamp(start_date, end_date):
    delta = end_date - start_date
    random_seconds = random.randint(0, max(1, int(delta.total_seconds())))
    return (start_date + timedelta(seconds=random_seconds)).strftime("%Y-%m-%dT%H:%M:%S")

def generate_promo_code():
    prefix = random.choice(["SAVE", "DEAL", "VIP", "FLASH", "FALL", "SPRING"])
    num = random.choice([10, 15, 20, 25, 30])
    suffix = "".join(random.choices("ABCDEFGHIJKLMNOPQRSTUVWXYZ", k=2))
    return f"{prefix}{num}-{suffix}"

# =============================================================================
# 1. RAW CUSTOMER PROFILES (CRM Source: Salesforce / HubSpot)
# =============================================================================
def generate_customer_profiles(num_customers):
    print(f"Generating {num_customers} raw customer profiles (with PII & CRM metadata)...")
    customers = []
    customer_ids = []

    for i in range(num_customers):
        cust_id = f"CUST_{i+1:05d}"
        customer_ids.append(cust_id)

        first_name = random.choice(FIRST_NAMES)
        last_name = random.choice(LAST_NAMES)
        email = f"{first_name.lower()}.{last_name.lower()}{random.randint(10, 999)}@{random.choice(EMAIL_DOMAINS)}"
        phone = f"+1-{random.randint(200, 999)}-{random.randint(100, 999)}-{random.randint(1000, 9999)}"

        tier = random.choices(LOYALTY_TIERS, weights=LOYALTY_WEIGHTS, k=1)[0]
        pts_range = {"BRONZE": (0, 500), "SILVER": (500, 2000), "GOLD": (2000, 8000), "PLATINUM": (8000, 25000)}
        pts_min, pts_max = pts_range[tier]

        age = min(72, max(18, int(random.gauss(36, 11))))
        is_active = random.random() < {"BRONZE": 0.70, "SILVER": 0.82, "GOLD": 0.94, "PLATINUM": 0.98}[tier]

        consent_email = random.random() < (0.90 if is_active else 0.35)
        consent_sms = random.random() < (0.60 if consent_email else 0.15)
        consent_push = random.random() < (0.70 if is_active else 0.20)

        preferred_channel = random.choices(["EMAIL", "MOBILE_APP", "SMS", "IN_STORE"], weights=[0.45, 0.30, 0.15, 0.10], k=1)[0]
        max_weekly_touchpoints = random.choice([1, 2, 3])

        created_at = random_timestamp(datetime(2022, 1, 1), datetime(2026, 6, 30))
        updated_at = random_timestamp(datetime.strptime(created_at, "%Y-%m-%dT%H:%M:%S"), datetime(2026, 10, 27))

        customer = {
            "customer_id": cust_id,
            "profile": {
                "first_name": first_name,
                "last_name": last_name,
                "age": age,
                "gender": random.choice(["M", "F", "NON_BINARY", "PREFER_NOT_TO_SAY"])
            },
            "contact": {
                "email": email,
                "phone": phone,
                "address": {
                    "state": random.choice(STATES),
                    "zip_code": f"{random.randint(10000, 99999)}"
                }
            },
            "loyalty": {
                "tier": tier,
                "points_balance": random.randint(pts_min, pts_max),
                "signup_channel": random.choice(SIGNUP_CHANNELS)
            },
            "preferences": {
                "preferred_channel": preferred_channel,
                "max_weekly_touchpoints": max_weekly_touchpoints
            },
            "consent": {
                "email": consent_email,
                "sms": consent_sms,
                "push": consent_push
            },
            "status": {
                "is_active": is_active,
                "created_at": created_at,
                "updated_at": updated_at
            }
        }
        customers.append(customer)

    print(f"  [OK] {len(customers)} raw customer profiles generated")
    return customers, customer_ids

# =============================================================================
# 2. RAW TRANSACTIONS (POS & Order Management Source: Shopify / Store POS)
# =============================================================================
def generate_transactions(num_transactions, customer_ids, customer_profiles):
    print(f"Generating {num_transactions} raw transactions (with stores, products & line items)...")
    transactions = []
    cust_map = {c["customer_id"]: c for c in customer_profiles}
    active_customers = [c["customer_id"] for c in customer_profiles if c["status"]["is_active"]]

    # 15% at-risk cohort (velocity collapse)
    at_risk_cohort = set(random.sample(active_customers, k=int(len(active_customers) * 0.15)))
    store_ids = [f"STORE_{i:03d}" for i in range(1, 51)]

    for i in range(num_transactions):
        cust_id = random.choice(active_customers)
        cust = cust_map[cust_id]
        tier = cust["loyalty"]["tier"]
        is_at_risk = cust_id in at_risk_cohort

        num_items = max(1, min(5, int(random.gauss({"BRONZE": 1.5, "SILVER": 2.0, "GOLD": 2.8, "PLATINUM": 3.5}[tier], 0.8))))

        items = []
        gross_total = 0.0
        discount_total = 0.0

        for _ in range(num_items):
            category = random.choice(PRODUCT_CATEGORIES)
            prod_id, prod_name, base_price = random.choice(PRODUCT_CATALOG[category])
            quantity = random.choices([1, 2, 3], weights=[0.75, 0.20, 0.05], k=1)[0]

            if random.random() < {"BRONZE": 0.15, "SILVER": 0.25, "GOLD": 0.40, "PLATINUM": 0.55}[tier]:
                discount_pct = random.choice([10, 15, 20, 25, 30])
                discount_amount = round(base_price * quantity * discount_pct / 100, 2)
            else:
                discount_amount = 0.00

            item_gross = round(base_price * quantity, 2)
            gross_total += item_gross
            discount_total += discount_amount

            items.append({
                "product_id": prod_id,
                "product_name": prod_name,
                "category": category,
                "quantity": quantity,
                "unit_price": base_price,
                "discount_amount": discount_amount
            })

        net_total = round(gross_total - discount_total, 2)

        # GOVERNED EVIDENCE: At-risk customers bought previously, but 0 purchases in last 75+ days
        if is_at_risk:
            ts = random_timestamp(datetime(2025, 6, 1), datetime(2026, 7, 10))
        else:
            ts = random_timestamp(datetime(2024, 1, 1), datetime(2026, 10, 27))

        promo_applied = generate_promo_code() if (discount_total > 0 and random.random() < 0.70) else None

        transaction = {
            "transaction_id": f"TXN_{i+1:06d}",
            "customer_id": cust_id,
            "store_id": random.choice(store_ids),
            "channel": random.choice(["IN_STORE", "WEB", "MOBILE_APP"]),
            "payment": {
                "method": random.choice(PAYMENT_METHODS),
                "promo_code_applied": promo_applied
            },
            "items": items,
            "totals": {
                "gross_total": round(gross_total, 2),
                "discount_total": round(discount_total, 2),
                "net_total": net_total
            },
            "timestamp": ts
        }
        transactions.append(transaction)

    print(f"  [OK] {len(transactions)} raw transactions generated")
    return transactions, at_risk_cohort

# =============================================================================
# 3. RAW CAMPAIGNS (Marketing Source: Braze / Marketo)
# =============================================================================
def generate_campaigns(num_campaigns):
    print(f"Generating {num_campaigns} raw campaigns (with rules & audit metadata)...")
    campaigns = []
    campaign_ids = []

    adj_list = ["Mega", "Exclusive", "VIP", "Early Access", "Flash", "Holiday", "Member"]
    noun_list = ["Rewards", "Savings", "Deal", "Cashback", "Points Boost", "Sale"]

    for i in range(num_campaigns):
        cmp_id = f"CMP_{i+1:03d}"
        campaign_ids.append(cmp_id)
        name = f"{random.choice(adj_list)} {random.choice(noun_list)} 2026"
        offer_type = random.choice(OFFER_TYPES)
        target_seg = random.choice(CAMPAIGN_SEGMENTS)
        channel = random.choice(CAMPAIGN_CHANNELS)

        start_dt = datetime(2026, 1, 1) + timedelta(days=random.randint(0, 300))
        end_dt = start_dt + timedelta(days=random.choice([7, 14, 21, 30]))
        today = datetime(2026, 10, 28)

        status = "COMPLETED" if end_dt < today else ("SCHEDULED" if start_dt > today else "ACTIVE")
        discount_pct = random.choice([10, 15, 20, 25, 30, 40]) if offer_type == "PERCENTAGE_DISCOUNT" else None
        min_spend = random.choice([0, 25, 50, 75, 100])
        budget = round(random.uniform(2000, 35000), 2)
        exclude_open_support = random.choice([True, True, True, False])
        max_freq_7d = random.choice([1, 2])

        campaign = {
            "campaign_id": cmp_id,
            "campaign_name": name,
            "channel": channel,
            "offer": {
                "type": offer_type,
                "discount_percentage": discount_pct,
                "min_spend_threshold": min_spend,
                "budget_allocated": budget
            },
            "rules": {
                "target_segment": target_seg,
                "exclude_open_support_cases": exclude_open_support,
                "max_contact_frequency_7d": max_freq_7d
            },
            "schedule": {
                "start_date": start_dt.strftime("%Y-%m-%d"),
                "end_date": end_dt.strftime("%Y-%m-%d"),
                "status": status
            },
            "metadata": {
                "created_by": random.choice(["marketing_ops", "campaign_manager", "growth_lead"]),
                "created_at": random_timestamp(datetime(2025, 11, 1), start_dt)
            }
        }
        campaigns.append(campaign)

    print(f"  [OK] {len(campaigns)} raw campaigns generated")
    return campaigns, campaign_ids

# =============================================================================
# 4. RAW CAMPAIGN INTERACTIONS (Delivery & Tracking Logs)
# =============================================================================
def generate_campaign_interactions(num_interactions, customer_ids, campaign_ids, customer_profiles, campaigns):
    print(f"Generating {num_interactions} raw campaign interaction events (with tracking URLs)...")
    interactions = []
    cust_lookup = {c["customer_id"]: c for c in customer_profiles}
    cmp_lookup = {c["campaign_id"]: c for c in campaigns}
    active_cust_ids = [c["customer_id"] for c in customer_profiles if c["status"]["is_active"]]

    tier_redemption_rate = {"BRONZE": 0.12, "SILVER": 0.24, "GOLD": 0.40, "PLATINUM": 0.58}

    for i in range(num_interactions):
        cust_id = random.choice(active_cust_ids)
        cust = cust_lookup[cust_id]
        cmp_id = random.choice(campaign_ids)
        cmp = cmp_lookup[cmp_id]
        tier = cust["loyalty"]["tier"]

        channel = cmp["channel"]
        base_rate = tier_redemption_rate[tier]

        roll = random.random()
        if roll < base_rate:
            action = "REDEEMED"
        elif roll < base_rate + 0.18:
            action = "CLICK"
        elif roll < base_rate + 0.32:
            action = "IMPRESSION"
        else:
            action = "IGNORED"

        response_details = {}
        if action == "REDEEMED":
            response_details["promo_code_used"] = generate_promo_code()
            response_details["redemption_value"] = round(random.uniform(5.0, 65.0), 2)
        elif action == "CLICK":
            response_details["click_url"] = f"https://shop.retail.com/promo/{cmp_id.lower()}?src={channel.lower()}"
            response_details["time_on_page_seconds"] = random.randint(5, 180)

        interaction = {
            "interaction_id": f"INT_{i+1:06d}",
            "customer_id": cust_id,
            "campaign_id": cmp_id,
            "channel": channel,
            "response": {
                "action": action,
                "details": response_details
            },
            "timestamp": random_timestamp(datetime(2026, 1, 1), datetime(2026, 10, 27))
        }
        interactions.append(interaction)

    print(f"  [OK] {len(interactions)} raw campaign interactions generated")
    return interactions

# =============================================================================
# 5. RAW CHANNEL ACTIVITIES (Web / App Clickstream Source: Segment / Snowplow)
# =============================================================================
def generate_channel_activities(num_activities, customer_ids, customer_profiles):
    print(f"Generating {num_activities} raw clickstream activities (with session IDs & devices)...")
    activities = []
    active_cust_ids = [c["customer_id"] for c in customer_profiles if c["status"]["is_active"]]

    for i in range(num_activities):
        cust_id = random.choice(active_cust_ids)
        channel = random.choice(DIGITAL_CHANNELS)
        event = random.choice(DIGITAL_EVENTS)

        session_info = {
            "session_id": str(uuid.uuid4())[:8],
            "device_type": random.choice(DEVICE_TYPES) if channel in ["WEB", "MOBILE_APP"] else "POS_TERMINAL"
        }

        activity = {
            "activity_id": f"ACT_{i+1:06d}",
            "customer_id": cust_id,
            "channel": channel,
            "session": session_info,
            "activity": {
                "event_type_detail": event,
                "page_category": random.choice(PRODUCT_CATEGORIES + ["HOME", "DEALS", "CHECKOUT"]),
                "duration_seconds": random.randint(5, 180)
            },
            "timestamp": random_timestamp(datetime(2026, 1, 1), datetime(2026, 10, 27))
        }
        activities.append(activity)

    print(f"  [OK] {len(activities)} raw channel activities generated")
    return activities

# =============================================================================
# 6. RAW SUPPORT TICKETS (Helpdesk Source: Zendesk / ServiceNow)
# =============================================================================
def generate_support_tickets(num_tickets, customer_ids, customer_profiles, at_risk_cohort):
    print(f"Generating {num_tickets} raw support tickets (with resolution hours & contact channels)...")
    tickets = []
    at_risk_list = list(at_risk_cohort)

    for i in range(num_tickets):
        if random.random() < 0.45 and at_risk_list:
            cust_id = random.choice(at_risk_list)
            is_at_risk = True
        else:
            cust_id = random.choice(customer_ids)
            is_at_risk = False

        severity = random.choices(["HIGH", "CRITICAL"], weights=[0.6, 0.4], k=1)[0] if is_at_risk else random.choices(SEVERITIES, weights=[0.35, 0.35, 0.20, 0.10], k=1)[0]

        if is_at_risk:
            ticket_status = random.choices(["OPEN", "IN_PROGRESS", "RESOLVED"], weights=[0.60, 0.25, 0.15], k=1)[0]
            is_escalated = random.random() < 0.60
            sat_score = random.choices([1, 2, 3], weights=[0.50, 0.35, 0.15], k=1)[0]
            category = random.choice(["SHIPPING_DELAY", "PRODUCT_DEFECT", "BILLING_DISPUTE"])
        else:
            ticket_status = random.choices(["RESOLVED", "CLOSED", "OPEN"], weights=[0.75, 0.15, 0.10], k=1)[0]
            is_escalated = random.random() < 0.08
            sat_score = random.choices([3, 4, 5], weights=[0.25, 0.45, 0.30], k=1)[0]
            category = random.choice(TICKET_CATEGORIES)

        base_hours = {"LOW": 48, "MEDIUM": 24, "HIGH": 8, "CRITICAL": 2}
        res_hours = max(0.5, round(base_hours[severity] * random.uniform(0.5, 2.0), 1))

        ticket = {
            "ticket_id": f"TKT_{i+1:05d}",
            "customer_id": cust_id,
            "ticket_details": {
                "category": category,
                "severity": severity,
                "contact_channel": random.choice(["PHONE", "CHAT", "EMAIL", "IN_STORE"])
            },
            "resolution": {
                "ticket_status": ticket_status,
                "is_escalated": is_escalated,
                "resolution_time_hours": res_hours,
                "satisfaction_score": sat_score
            },
            "timestamp": random_timestamp(datetime(2026, 6, 1) if is_at_risk else datetime(2025, 6, 1), datetime(2026, 10, 27))
        }
        tickets.append(ticket)

    print(f"  [OK] {len(tickets)} raw support tickets generated")
    return tickets

# =============================================================================
# FILE WRITER
# =============================================================================
def write_json_file(data, filename):
    filepath = os.path.join(OUTPUT_DIR, filename)
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    size_mb = os.path.getsize(filepath) / (1024 * 1024)
    print(f"  --> Written: {filename} ({len(data):,} records, {size_mb:.2f} MB)")
    return filepath

def main():
    print("=" * 70)
    print("RETAIL OPERATIONAL RAW DATA GENERATOR (BRONZE INGESTION)")
    print("=" * 70)
    print(f"Target Directory: {OUTPUT_DIR}\n")

    customers, customer_ids = generate_customer_profiles(NUM_CUSTOMERS)
    write_json_file(customers, "customer_profiles.json")

    transactions, at_risk_cohort = generate_transactions(NUM_TRANSACTIONS, customer_ids, customers)
    write_json_file(transactions, "transactions.json")

    campaigns, campaign_ids = generate_campaigns(NUM_CAMPAIGNS)
    write_json_file(campaigns, "campaigns.json")

    interactions = generate_campaign_interactions(
        NUM_CAMPAIGN_INTERACTIONS, customer_ids, campaign_ids, customers, campaigns
    )
    write_json_file(interactions, "campaign_interactions.json")

    activities = generate_channel_activities(NUM_CHANNEL_ACTIVITIES, customer_ids, customers)
    write_json_file(activities, "channel_activities.json")

    tickets = generate_support_tickets(NUM_SUPPORT_TICKETS, customer_ids, customers, at_risk_cohort)
    write_json_file(tickets, "support_tickets.json")

    print("\n" + "=" * 70)
    print("ALL 6 RAW OPERATIONAL DATASETS GENERATED SUCCESSFULLY")
    print("All ML features (RFM, CSAT, velocity drop) are derived in Snowflake Feature Store.")
    print("=" * 70)

if __name__ == "__main__":
    main()
