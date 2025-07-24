# StockFlow API Setup Instructions

## Prerequisites
- Node.js (v14+)
- PostgreSQL (v12+)

## Setup Steps

### 1. Install Dependencies
```bash
npm install
```

### 2. Database Setup

1. **Create PostgreSQL Database:**
   ```sql
   CREATE DATABASE stockflow_db;
   ```

2. **Update Database Connection:**
   Edit `db.js` and replace these values:
   ```javascript
   user: 'your_username',      // Your PostgreSQL username
   password: 'your_password',  // Your PostgreSQL password
   database: 'stockflow_db'    // Your database name
   ```

3. **Run Schema:**
   ```bash
   psql -U your_username -d stockflow_db -f schema.sql
   ```

4. **Insert Sample Data:**
   ```bash
   psql -U your_username -d stockflow_db -f sample_data.sql
   ```

### 3. Start the Server
```bash
npm start
# or for development:
npm run dev
```

### 4. Test the API

**Health Check:**
```bash
curl http://localhost:3000/health
```

**Low Stock Alerts for Company 1:**
```bash
curl http://localhost:3000/api/companies/1/alerts/low-stock
```

**Low Stock Alerts for Company 2:**
```bash
curl http://localhost:3000/api/companies/2/alerts/low-stock
```

## Expected Response Format

```json
{
  "alerts": [
    {
      "product_id": 123,
      "product_name": "Widget A",
      "sku": "WID-001",
      "warehouse_id": 456,
      "warehouse_name": "Main Warehouse",
      "current_stock": 5,
      "threshold": 20,
      "days_until_stockout": 12,
      "supplier": {
        "id": 789,
        "name": "Supplier Corp",
        "contact_email": "orders@supplier.com"
      }
    }
  ],
  "total_alerts": 1
}
```

## Business Rules Implemented

✅ **Low stock threshold varies by product type** - Each product/inventory can have custom thresholds
✅ **Only alert for products with recent sales activity** - Only products sold in last 30 days are considered
✅ **Must handle multiple warehouses per company** - Alerts across all company warehouses
✅ **Include supplier information for reordering** - First supplier info included in response

## Sample Data Includes

- **Company 1 (TechCorp):** 2 warehouses with 4 low-stock alerts
- **Company 2 (RetailMart):** 1 warehouse with 2 low-stock alerts
- **Products with no recent sales:** Won't trigger alerts (business rule)

## Files Structure

```
d:\bynry_assesment\
├── app.js              # Main Express application
├── db.js               # PostgreSQL connection
├── lowStockAlerts.js   # Low-stock alerts endpoint
├── schema.sql          # Database schema
├── sample_data.sql     # Test data
├── package.json        # Dependencies
└── README.md           # This file
```
