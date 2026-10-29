-- =============================================================================
-- Super Store Retail Intelligence & Profitability Audit (2014–2017)
-- SQLite Analytical Warehouse Schema, Performance Indexes & Executive Views
-- Database: Super_Store.db
-- Scope: 9,994 Line Items | 5,009 Unique Orders | 793 Customers | $2.30M Sales
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. CORE RELATIONAL & FEATURE-ENGINEERED TABLES
-- -----------------------------------------------------------------------------

-- Base Operational Orders Table (9,994 rows)
CREATE TABLE IF NOT EXISTS "orders" (
    "Row ID" INTEGER PRIMARY KEY,
    "Order ID" TEXT NOT NULL,
    "Order Date" TEXT NOT NULL,
    "Ship Date" TEXT NOT NULL,
    "Ship Mode" TEXT NOT NULL,
    "Customer ID" TEXT NOT NULL,
    "Customer Name" TEXT NOT NULL,
    "Segment" TEXT NOT NULL,
    "Country" TEXT NOT NULL,
    "City" TEXT NOT NULL,
    "State" TEXT NOT NULL,
    "Postal Code" INTEGER,
    "Region" TEXT NOT NULL,
    "Product ID" TEXT NOT NULL,
    "Category" TEXT NOT NULL,
    "Sub-Category" TEXT NOT NULL,
    "Product Name" TEXT NOT NULL,
    "Sales" REAL NOT NULL,
    "Quantity" INTEGER NOT NULL,
    "Discount" REAL NOT NULL,
    "Profit" REAL NOT NULL
);

-- Enriched Analytical Orders Fact Table (9,994 rows x 40 columns)
CREATE TABLE IF NOT EXISTS "clean_orders" (
    "Row ID" INTEGER PRIMARY KEY,
    "Order ID" TEXT NOT NULL,
    "Order Date" TEXT NOT NULL,
    "Ship Date" TEXT NOT NULL,
    "Ship Mode" TEXT NOT NULL,
    "Customer ID" TEXT NOT NULL,
    "Customer Name" TEXT NOT NULL,
    "Segment" TEXT NOT NULL,
    "Country" TEXT NOT NULL,
    "City" TEXT NOT NULL,
    "State" TEXT NOT NULL,
    "Postal Code" INTEGER,
    "Region" TEXT NOT NULL,
    "Product ID" TEXT NOT NULL,
    "Category" TEXT NOT NULL,
    "Sub-Category" TEXT NOT NULL,
    "Product Name" TEXT NOT NULL,
    "Sales" REAL NOT NULL,
    "Quantity" INTEGER NOT NULL,
    "Discount" REAL NOT NULL,
    "Profit" REAL NOT NULL,
    "Order Year" INTEGER NOT NULL,
    "Order Month" INTEGER NOT NULL,
    "Shipping Duration" INTEGER NOT NULL,
    "Order Quarter" TEXT NOT NULL,
    "Order Month Name" TEXT NOT NULL,
    "Order Year-Month" TEXT NOT NULL,
    "Day of Week" TEXT NOT NULL,
    "Unit Selling Price" REAL NOT NULL,
    "Gross Sales" REAL NOT NULL,
    "Discount Amount" REAL NOT NULL,
    "Estimated Cost" REAL NOT NULL,
    "Profit Margin %" REAL NOT NULL,
    "Profit Status" TEXT NOT NULL,
    "Loss Amount" REAL NOT NULL,
    "Wasted Sales" REAL NOT NULL,
    "Discount Tier" TEXT NOT NULL,
    "Target SLA Days" INTEGER NOT NULL,
    "SLA Status" TEXT NOT NULL,
    "Customer RFM Tier" TEXT NOT NULL
);

-- Customer RFM & Profitability Dimension Table (793 rows x 16 columns)
CREATE TABLE IF NOT EXISTS "customer_rfm" (
    "Customer ID" TEXT PRIMARY KEY,
    "Customer_Name" TEXT NOT NULL,
    "Segment" TEXT NOT NULL,
    "Region" TEXT NOT NULL,
    "Recency_Days" INTEGER NOT NULL,
    "Frequency_Orders" INTEGER NOT NULL,
    "Total_Items" INTEGER NOT NULL,
    "Monetary_Sales" REAL NOT NULL,
    "Total_Profit" REAL NOT NULL,
    "Avg_Discount" REAL NOT NULL,
    "Profit_Margin_Pct" REAL NOT NULL,
    "R_Score" INTEGER NOT NULL,
    "F_Score" INTEGER NOT NULL,
    "M_Score" INTEGER NOT NULL,
    "RFM_Score" INTEGER NOT NULL,
    "Customer_Tier" TEXT NOT NULL
);

-- -----------------------------------------------------------------------------
-- 2. HIGH-PERFORMANCE ANALYTICAL INDEXES
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_clean_orders_order_date ON clean_orders("Order Date");
CREATE INDEX IF NOT EXISTS idx_clean_orders_year ON clean_orders("Order Year");
CREATE INDEX IF NOT EXISTS idx_clean_orders_region ON clean_orders("Region");
CREATE INDEX IF NOT EXISTS idx_clean_orders_state ON clean_orders("State");
CREATE INDEX IF NOT EXISTS idx_clean_orders_category ON clean_orders("Category", "Sub-Category");
CREATE INDEX IF NOT EXISTS idx_clean_orders_customer ON clean_orders("Customer ID");
CREATE INDEX IF NOT EXISTS idx_clean_orders_discount ON clean_orders("Discount");
CREATE INDEX IF NOT EXISTS idx_clean_orders_sla ON clean_orders("SLA Status");
CREATE INDEX IF NOT EXISTS idx_rfm_tier ON customer_rfm("Customer_Tier");

-- -----------------------------------------------------------------------------
-- 3. EXECUTIVE BI & ANALYTICAL DATA WAREHOUSE VIEWS
-- -----------------------------------------------------------------------------

-- View 1: Annual Financial Trajectory, Top-Line Sales & Erosion Tracking
DROP VIEW IF EXISTS vw_executive_yearly_kpis;
CREATE VIEW vw_executive_yearly_kpis AS
SELECT 
    "Order Year" AS order_year,
    COUNT(DISTINCT "Order ID") AS total_orders,
    COUNT(DISTINCT "Customer ID") AS active_customers,
    ROUND(SUM("Sales"), 2) AS total_sales,
    ROUND(SUM("Profit"), 2) AS total_profit,
    ROUND(SUM("Profit") * 100.0 / SUM("Sales"), 2) AS profit_margin_pct,
    ROUND(AVG("Discount") * 100.0, 2) AS avg_discount_pct,
    ROUND(SUM("Loss Amount"), 2) AS gross_loss,
    ROUND(SUM("Wasted Sales"), 2) AS wasted_sales
FROM clean_orders
GROUP BY "Order Year"
ORDER BY "Order Year";

-- View 2: Sub-Category Unit Economics & Margin Bleeding Center Diagnosis
DROP VIEW IF EXISTS vw_subcategory_bleeding_analysis;
CREATE VIEW vw_subcategory_bleeding_analysis AS
SELECT 
    "Category",
    "Sub-Category",
    COUNT(DISTINCT "Order ID") AS total_orders,
    SUM("Quantity") AS units_sold,
    ROUND(SUM("Sales"), 2) AS total_sales,
    ROUND(SUM("Profit"), 2) AS net_profit,
    ROUND(SUM("Profit") * 100.0 / SUM("Sales"), 2) AS profit_margin_pct,
    ROUND(AVG("Discount") * 100.0, 2) AS avg_discount_pct,
    SUM(CASE WHEN "Profit" < 0 THEN 1 ELSE 0 END) AS loss_item_count,
    ROUND(SUM("Loss Amount"), 2) AS total_loss_amount,
    ROUND(SUM("Wasted Sales"), 2) AS wasted_sales
FROM clean_orders
GROUP BY "Category", "Sub-Category"
ORDER BY net_profit ASC;

-- View 3: The 20% Discount Cliff Impact & Elasticity Breakdown
DROP VIEW IF EXISTS vw_discount_cliff_impact;
CREATE VIEW vw_discount_cliff_impact AS
SELECT 
    "Discount Tier",
    ROUND("Discount" * 100.0, 0) AS discount_pct,
    COUNT(*) AS line_items,
    ROUND(SUM("Sales"), 2) AS total_sales,
    ROUND(SUM("Profit"), 2) AS net_profit,
    ROUND(AVG("Profit"), 2) AS avg_profit_per_item,
    ROUND(SUM("Profit") * 100.0 / SUM("Sales"), 2) AS profit_margin_pct
FROM clean_orders
GROUP BY "Discount Tier", "Discount"
ORDER BY "Discount" ASC;

-- View 4: State Profitability Ranking & Geographic Erosion Hotspots
DROP VIEW IF EXISTS vw_state_profitability_ranking;
CREATE VIEW vw_state_profitability_ranking AS
SELECT 
    "State",
    "Region",
    COUNT(DISTINCT "Order ID") AS total_orders,
    ROUND(SUM("Sales"), 2) AS total_sales,
    ROUND(SUM("Profit"), 2) AS net_profit,
    ROUND(SUM("Profit") * 100.0 / SUM("Sales"), 2) AS profit_margin_pct,
    ROUND(AVG("Discount") * 100.0, 2) AS avg_discount_pct,
    ROUND(SUM("Loss Amount"), 2) AS gross_loss
FROM clean_orders
GROUP BY "State", "Region"
ORDER BY net_profit ASC;

-- View 5: Logistics Shipping Mode SLA Compliance & Regional Delivery Speed
DROP VIEW IF EXISTS vw_logistics_sla_performance;
CREATE VIEW vw_logistics_sla_performance AS
SELECT 
    "Ship Mode",
    "Region",
    COUNT(DISTINCT "Order ID") AS total_orders,
    ROUND(AVG("Shipping Duration"), 2) AS avg_shipping_days,
    SUM(CASE WHEN "SLA Status" = 'On-Time' THEN 1 ELSE 0 END) AS on_time_items,
    ROUND(SUM(CASE WHEN "SLA Status" = 'On-Time' THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(*), 2) AS sla_compliance_pct,
    ROUND(SUM("Sales"), 2) AS total_sales,
    ROUND(SUM("Profit"), 2) AS total_profit
FROM clean_orders
GROUP BY "Ship Mode", "Region"
ORDER BY "Ship Mode", "Region";

-- -----------------------------------------------------------------------------
-- 4. EXECUTIVE AD-HOC DIAGNOSTIC QUERIES
-- -----------------------------------------------------------------------------

-- Diagnostic 1: Identify the Top 10 Loss-Driving Orders & Root Causes
SELECT 
    "Order ID",
    "Customer Name",
    "State",
    "Category",
    "Sub-Category",
    "Sales",
    "Discount",
    "Profit",
    "Loss Amount"
FROM clean_orders
WHERE "Profit" < 0
ORDER BY "Loss Amount" DESC
LIMIT 10;

-- Diagnostic 2: RFM Customer Cohort Financial Contribution Summary
SELECT 
    Customer_Tier,
    COUNT(*) AS total_customers,
    ROUND(SUM(Monetary_Sales), 2) AS total_sales,
    ROUND(SUM(Total_Profit), 2) AS net_profit,
    ROUND(AVG(Profit_Margin_Pct), 2) AS avg_margin_pct,
    ROUND(AVG(Avg_Discount) * 100.0, 2) AS avg_cohort_discount_pct
FROM customer_rfm
GROUP BY Customer_Tier
ORDER BY net_profit DESC;

-- Diagnostic 3: Late Shipments SLA Risk Exposure by Shipping Mode
SELECT 
    "Ship Mode",
    "Target SLA Days",
    COUNT(*) AS total_shipments,
    SUM(CASE WHEN "SLA Status" = 'Delayed' THEN 1 ELSE 0 END) AS delayed_shipments,
    ROUND(SUM(CASE WHEN "SLA Status" = 'Delayed' THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(*), 2) AS delay_rate_pct,
    ROUND(AVG("Shipping Duration"), 2) AS actual_avg_days
FROM clean_orders
GROUP BY "Ship Mode", "Target SLA Days"
ORDER BY delay_rate_pct DESC;
