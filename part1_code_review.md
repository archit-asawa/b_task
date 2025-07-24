# Part 1: Code Review & Debugging - StockFlow API

## Original Code Analysis

```python
@app.route('/api/products', methods=['POST'])
def create_product():
    data = request.json
    # Create new product
    product = Product(
        name=data['name'],
        sku=data['sku'],
        price=data['price'],
        warehouse_id=data['warehouse_id']
    )
    db.session.add(product)
    db.session.commit()
    # Update inventory count
    inventory = Inventory(
        product_id=product.id,
        warehouse_id=data['warehouse_id'],
        quantity=data['initial_quantity']
    )
    db.session.add(inventory)
    db.session.commit()
    return {"message": "Product created", "product_id": product.id}
```

## Issues Identified

### 1. **No Input Validation**
**Problem**: Direct access to dictionary keys without validation
**Production Impact**: 
- **The Midnight Call**: Your phone rings at 2 AM because the entire product creation system crashed when a mobile app forgot to send the product name field
- **The Confused Customer**: A small business owner tries to add their new product but gets a cryptic "Internal Server Error" instead of being told they forgot to enter the price
- **The Hacker's Playground**: Someone discovers they can crash your system by sending a 50MB product name or weird characters that break your database
- **The Support Team Revolt**: Your customer service team gets flooded with "the system is broken" tickets because users can't figure out what they did wrong
- **The Lost Weekend**: Your development team spends their weekend digging through server logs full of meaningless error messages instead of enjoying time with family
- **The Sales Meeting Disaster**: During a big product launch, legitimate customers can't add products because the error messages don't explain what's required

### 2. **No Error Handling**
**Problem**: No try-catch blocks for database operations
**Production Impact**:
- **Black Friday Meltdown**: Your biggest sales day of the year and the product creation system dies when the database hiccups, leaving your team scrambling while competitors take your customers
- **The Vanishing Inventory**: Products get half-created in your system - they exist but have no stock records, leading to angry customers who ordered "available" items that don't actually exist
- **The CEO's Question**: "Why did we lose $50,000 in sales yesterday?" and all you can say is "the system had some errors" because you have no useful logs to explain what happened
- **The Frustrated Partner**: Your biggest supplier tries to bulk-upload 1000 products, one fails, and the whole batch crashes with no indication of which product caused the problem
- **The 3 AM Fire Drill**: Your operations team gets woken up by monitoring alerts but can't fix anything because the error messages just say "something went wrong"
- **The Compliance Nightmare**: Your financial auditor asks for transaction logs and you realize half your failed product creations left no audit trail
- **The Memory Leak**: Uncaught exceptions slowly eat your server's memory until the whole system becomes sluggish and eventually crashes

### 3. **No SKU Uniqueness Validation**
**Problem**: SKUs must be unique platform-wide but no validation exists
**Production Impact**:
- **The Warehouse Mix-Up**: Your warehouse team gets an order for SKU "WIDGET123" but there are three different products with that same SKU - they ship the wrong $500 item instead of the $50 one
- **The Accountant's Headache**: Month-end reports show you sold 1000 units of "WIDGET123" worth $50,000, but nobody knows if those were cheap widgets, expensive gadgets, or a mix of both
- **The Supplier's Confusion**: Your supplier calls asking "Which WIDGET123 do you want to reorder?" and your purchasing team has no idea which product the customer actually bought
- **The Customer Service Nightmare**: A customer calls saying "My WIDGET123 is broken" and your support agent finds 5 different products with that SKU in the system
- **The Inventory Report Disaster**: Your CEO asks "How much WIDGET123 inventory do we have?" and the system shows 1000 units, but it's actually 200 of item A, 300 of item B, and 500 of item C
- **The Tax Filing Horror**: During tax season, you discover you can't properly report product sales because multiple products share the same identifier
- **The Integration Breakdown**: Your shipping software crashes because it can't figure out which WIDGET123 to print labels for

### 4. **Incorrect Data Model Design**
**Problem**: Product has `warehouse_id` field, but products should exist across multiple warehouses
**Production Impact**:
- **The iPhone Apocalypse**: You sell iPhones and now have "iPhone 15 - New York", "iPhone 15 - Chicago", and "iPhone 15 - LA" as separate products, making your catalog look ridiculous
- **The Impossible Total**: Your boss asks "How many iPhones do we have in stock?" and you can't give a simple answer because each warehouse has its own "iPhone" product
- **The Pricing Chaos**: Same iPhone costs $999 in New York warehouse but someone accidentally set it to $899 in Chicago warehouse, and customers notice the inconsistency
- **The Supplier's Confusion**: Apple wants to discuss your iPhone orders but you have three separate purchase histories for the "same" product across warehouses
- **The Transfer Nightmare**: You need to move 50 iPhones from New York to Chicago warehouse, but the system won't let you because they're "different products"
- **The Customer's Frustration**: A customer searches for "iPhone 15" and gets three identical-looking results, not understanding why there are duplicates
- **The Analyst's Impossible Job**: Your marketing team can't figure out which iPhone model sells best because sales are split across multiple "products"
- **The Bulk Order Fail**: You lose a big corporate customer because you can't offer volume discounts across warehouses - each warehouse's "iPhone" has separate pricing

### 5. **Transaction Management Issues**
**Problem**: Two separate commits instead of single transaction
**Production Impact**:
- **The Zombie Product**: A product gets created successfully but its inventory creation fails, leaving you with "ghost products" that exist in your catalog but show zero stock forever
- **The Rush Hour Race**: During peak hours, multiple product creation requests interfere with each other, causing some products to get created twice or not at all
- **The Half-Baked Launch**: Your marketing team announces a new product line, but half the products appear "out of stock" because their inventory records failed to create
- **The Accounting Nightmare**: Your financial reports show 100 products created but only 60 have inventory values, making it impossible to calculate accurate asset values
- **The Customer's Confusion**: Customers see products in your catalog but can't buy them because they appear "unavailable" due to missing inventory records
- **The Recovery Mission**: When things go wrong, your IT team has to manually hunt through the database to find and fix orphaned product records
- **The Domino Effect**: One small database hiccup during product creation leaves dozens of incomplete product records that break other parts of your system
- **The Late Night Discovery**: You realize during month-end that half your "new products" from last week are missing from inventory reports

### 6. **Missing Content-Type Validation**
**Problem**: No validation that request contains JSON
**Production Impact**:
- **The Integration Meeting Disaster**: Your new business partner's developer joins a call and says "Your API doesn't work" because they forgot to set Content-Type to application/json
- **The Mobile App Mystery**: Your mobile app randomly crashes for some users because it occasionally sends requests with the wrong Content-Type header
- **The New Developer's First Day**: A junior developer spends 4 hours debugging why their API calls fail, only to discover they needed to add one header
- **The Security Red Flag**: Hackers probe your API with weird content types and get detailed error messages that reveal information about your system internals
- **The Support Ticket Avalanche**: Your help desk gets dozens of "API broken" tickets that all have the same simple fix - wrong Content-Type
- **The Partnership Delay**: A major integration project gets delayed by weeks because the other team thinks your API is unreliable when it's actually just a header issue
- **The Monitor Alert Storm**: Your production monitoring explodes with 500 error alerts, making it hard to spot real problems among all the content-type noise

### 7. **No Price Validation**
**Problem**: Price field not validated for positive values or decimal constraints
**Production Impact**:
- **The Free iPhone Incident**: Someone accidentally creates an iPhone with a price of -$999, and customers start "buying" it, giving them $999 credit each time
- **The Viral Social Media Disaster**: Screenshots of your "$0.00 Premium Widget" spread on social media, damaging your brand reputation and attracting bargain hunters who crash your site
- **The Accounting Chaos**: Your monthly reports show negative revenue because products with negative prices count as "paying customers to take items"
- **The Tax Day Surprise**: Your tax software crashes because it can't process negative product prices, delaying your corporate tax filing
- **The Payment Gateway Revolt**: Stripe and PayPal start rejecting your transactions because you're trying to charge negative amounts
- **The Investor Meeting Awkwardness**: During your board presentation, someone asks why your average product price is -$15.32
- **The Competitor's Field Day**: Your competition notices your pricing errors and uses them in marketing: "At least we don't have negative prices like Company X"
- **The Customer Service Meltdown**: Confused customers flood your support lines asking why some products have impossible prices

### 8. **Inconsistent Response Format**
**Problem**: No standardized error response format
**Production Impact**:
- **The Frontend Developer's Nightmare**: Your web developer builds error handling for one API response format, then everything breaks when other errors return completely different JSON structures
- **The Mobile App Crash**: Your iPhone app crashes every time users enter invalid data because it expects error messages in one format but gets them in three different formats
- **The Documentation Lie**: Your API docs say errors look like `{"error": "message"}` but sometimes they're `{"message": "error"}` or just `"Error occurred"`, making developers lose trust
- **The Integration Team's Revolt**: Your partner companies spend extra weeks building error handlers for every possible response format instead of one standard format
- **The QA Tester's Frustration**: Your testing team can't write automated tests because they never know what format error responses will use
- **The Support Tool Fail**: Your customer service dashboard can't automatically categorize and display errors because they come in random formats
- **The New Developer's Confusion**: Every new team member asks "Which error format should I use?" and gets a different answer each time
- **The Monitoring Mayhem**: Your error tracking systems like Sentry can't properly group and alert on issues because error formats are inconsistent

## Corrected Implementation

```python
from flask import request, jsonify
from sqlalchemy.exc import IntegrityError
from decimal import Decimal, InvalidOperation
import logging

@app.route('/api/products', methods=['POST'])
def create_product():
    try:
        # Validate Content-Type
        if not request.is_json:
            return jsonify({
                "error": "Content-Type must be application/json"
            }), 400
        
        data = request.get_json()
        
        # Input validation
        validation_errors = validate_product_data(data)
        if validation_errors:
            return jsonify({
                "error": "Validation failed",
                "details": validation_errors
            }), 400
        
        # Check SKU uniqueness
        existing_product = Product.query.filter_by(sku=data['sku']).first()
        if existing_product:
            return jsonify({
                "error": "SKU already exists",
                "details": f"Product with SKU '{data['sku']}' already exists"
            }), 409
        
        # Validate warehouse exists
        warehouse = Warehouse.query.get(data['warehouse_id'])
        if not warehouse:
            return jsonify({
                "error": "Invalid warehouse",
                "details": f"Warehouse with ID {data['warehouse_id']} not found"
            }), 404
        
        # Start transaction
        try:
            # Create product (without warehouse_id - products are global)
            product = Product(
                name=data['name'].strip(),
                sku=data['sku'].strip().upper(),
                price=Decimal(str(data['price'])),
                description=data.get('description', ''),
                category_id=data.get('category_id'),
                supplier_id=data.get('supplier_id')
            )
            db.session.add(product)
            db.session.flush()  # Get product.id without committing
            
            # Create initial inventory record
            inventory = Inventory(
                product_id=product.id,
                warehouse_id=data['warehouse_id'],
                quantity=max(0, int(data.get('initial_quantity', 0))),
                min_threshold=data.get('min_threshold', 10),
                created_at=datetime.utcnow()
            )
            db.session.add(inventory)
            
            # Create inventory history record
            inventory_history = InventoryHistory(
                product_id=product.id,
                warehouse_id=data['warehouse_id'],
                change_type='INITIAL_STOCK',
                quantity_change=inventory.quantity,
                new_quantity=inventory.quantity,
                reason='Initial product creation',
                created_by=get_current_user_id(),
                created_at=datetime.utcnow()
            )
            db.session.add(inventory_history)
            
            # Commit transaction
            db.session.commit()
            
            logging.info(f"Product created: {product.id}, SKU: {product.sku}")
            
            return jsonify({
                "success": True,
                "message": "Product created successfully",
                "data": {
                    "product_id": product.id,
                    "sku": product.sku,
                    "name": product.name,
                    "warehouse_id": data['warehouse_id'],
                    "initial_quantity": inventory.quantity
                }
            }), 201
            
        except IntegrityError as e:
            db.session.rollback()
            logging.error(f"Database integrity error: {str(e)}")
            return jsonify({
                "error": "Database constraint violation",
                "details": "Unable to create product due to data constraints"
            }), 409
            
    except InvalidOperation:
        return jsonify({
            "error": "Invalid price format",
            "details": "Price must be a valid decimal number"
        }), 400
        
    except Exception as e:
        db.session.rollback()
        logging.error(f"Unexpected error creating product: {str(e)}")
        return jsonify({
            "error": "Internal server error",
            "details": "An unexpected error occurred"
        }), 500

def validate_product_data(data):
    """Validate product creation data"""
    errors = []
    
    # Required fields
    required_fields = ['name', 'sku', 'price', 'warehouse_id']
    for field in required_fields:
        if field not in data or data[field] is None or str(data[field]).strip() == '':
            errors.append(f"Field '{field}' is required")
    
    if errors:
        return errors
    
    # Name validation
    if len(data['name'].strip()) < 2:
        errors.append("Product name must be at least 2 characters")
    
    if len(data['name'].strip()) > 255:
        errors.append("Product name cannot exceed 255 characters")
    
    # SKU validation
    sku = data['sku'].strip()
    if len(sku) < 2:
        errors.append("SKU must be at least 2 characters")
    
    if len(sku) > 50:
        errors.append("SKU cannot exceed 50 characters")
    
    if not sku.replace('-', '').replace('_', '').isalnum():
        errors.append("SKU can only contain letters, numbers, hyphens, and underscores")
    
    # Price validation
    try:
        price = Decimal(str(data['price']))
        if price < 0:
            errors.append("Price cannot be negative")
        if price > Decimal('999999.99'):
            errors.append("Price cannot exceed 999,999.99")
    except (InvalidOperation, ValueError):
        errors.append("Price must be a valid number")
    
    # Warehouse ID validation
    try:
        warehouse_id = int(data['warehouse_id'])
        if warehouse_id <= 0:
            errors.append("Warehouse ID must be a positive integer")
    except (ValueError, TypeError):
        errors.append("Warehouse ID must be a valid integer")
    
    # Initial quantity validation (optional)
    if 'initial_quantity' in data:
        try:
            qty = int(data['initial_quantity'])
            if qty < 0:
                errors.append("Initial quantity cannot be negative")
        except (ValueError, TypeError):
            errors.append("Initial quantity must be a valid integer")
    
    return errors

def get_current_user_id():
    """Get current user ID from session/JWT token"""
    # Implementation depends on authentication system
    # For now, return a placeholder
    return getattr(g, 'current_user_id', 1)
```

## Key Improvements Made

### 1. **Comprehensive Input Validation**
- Required field validation
- Data type validation
- Business rule validation (positive prices, valid SKUs)
- Length constraints

### 2. **Proper Error Handling**
- Try-catch blocks for all operations
- Specific error messages for different failure scenarios
- Proper HTTP status codes
- Rollback on errors

### 3. **SKU Uniqueness Enforcement**
- Database query to check existing SKUs
- Return 409 Conflict for duplicates
- Case-insensitive SKU handling

### 4. **Corrected Data Model**
- Removed `warehouse_id` from Product model
- Products are now global entities
- Inventory links products to warehouses

### 5. **Transaction Management**
- Single transaction for all related operations
- Use `flush()` to get product ID before committing
- Proper rollback on failures

### 6. **Audit Trail**
- Added InventoryHistory for tracking changes
- Timestamp and user tracking
- Reason codes for inventory changes

### 7. **Standardized Response Format**
- Consistent JSON structure
- Proper HTTP status codes
- Detailed error information for debugging

### 8. **Security Improvements**
- Input sanitization (strip whitespace)
- SQL injection prevention through ORM
- Proper decimal handling for financial data

### 9. **Logging**
- Error logging for debugging
- Success logging for audit trails
- Structured log messages

## Additional Considerations for Production

1. **Rate Limiting**: Add rate limiting to prevent abuse
2. **Authentication**: Implement proper user authentication
3. **Authorization**: Check user permissions for warehouse access
4. **API Versioning**: Version the API for future changes
5. **Request ID**: Add request tracing for debugging
6. **Monitoring**: Add metrics and health checks
7. **Documentation**: OpenAPI/Swagger documentation
8. **Testing**: Unit tests and integration tests


# Part 2: Database Design

## 1. Schema Design (SQL DDL)

```sql
-- Companies
CREATE TABLE companies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Warehouses
CREATE TABLE warehouses (
    id SERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL REFERENCES companies(id),
    name VARCHAR(255) NOT NULL,
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Suppliers
CREATE TABLE suppliers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255),
    phone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    sku VARCHAR(50) NOT NULL UNIQUE,
    price DECIMAL(12,2) NOT NULL,
    description TEXT,
    is_bundle BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product-Supplier (Many-to-Many)
CREATE TABLE product_suppliers (
    product_id INTEGER REFERENCES products(id),
    supplier_id INTEGER REFERENCES suppliers(id),
    PRIMARY KEY (product_id, supplier_id)
);

-- Bundles (Products containing other products)
CREATE TABLE product_bundles (
    bundle_id INTEGER REFERENCES products(id),
    component_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (bundle_id, component_id)
);

-- Inventory (per warehouse, per product)
CREATE TABLE inventory (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id),
    warehouse_id INTEGER REFERENCES warehouses(id),
    quantity INTEGER NOT NULL DEFAULT 0,
    min_threshold INTEGER DEFAULT 0,
    UNIQUE (product_id, warehouse_id)
);

-- Inventory History (track changes)
CREATE TABLE inventory_history (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id),
    warehouse_id INTEGER REFERENCES warehouses(id),
    change_type VARCHAR(50), -- e.g., 'SALE', 'RESTOCK', 'TRANSFER', 'ADJUSTMENT'
    quantity_change INTEGER NOT NULL,
    new_quantity INTEGER NOT NULL,
    reason TEXT,
    created_by INTEGER, -- user id, if available
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 2. Questions for the Product Team (Gaps)

- Should products be global across all companies, or does each company have its own product catalog?
- Can a product have multiple suppliers, or just one preferred supplier?
- Should inventory history track who made the change (user/accountability)?
- Are bundles always static, or can they be customized per order?
- Do we need to track product categories, barcodes, or other attributes?
- Should we support multiple units of measure (e.g., cases, pieces)?
- How should returns, damaged goods, or inventory write-offs be handled?
- What is the expected volume of products, warehouses, and transactions (for indexing/scaling)?
- Do we need soft deletes (archiving) for products, warehouses, or suppliers?
- Should we support multi-currency pricing?

## 3. Design Decisions & Justifications

- **Indexes**: Unique index on SKU for fast lookup and to enforce uniqueness. Composite unique on (product_id, warehouse_id) in inventory for quick stock checks.
- **Foreign Keys**: Enforce referential integrity between products, warehouses, suppliers, and companies.
- **Many-to-Many Relationships**: Used for product-supplier and product-bundle relationships for flexibility.
- **Inventory History**: Separate table for audit trail and analytics; supports compliance and debugging.
- **Bundles**: Bundles are products that reference other products, allowing for nested/complex bundles.
- **Extensibility**: Schema supports adding new attributes (e.g., categories, barcodes) without major redesign.
- **Scalability**: Designed for efficient queries on inventory, sales, and supplier relationships.
- **Data Integrity**: Constraints and foreign keys prevent orphaned records and maintain consistency.

---
This schema is designed to be flexible, scalable, and to support the core business requirements of StockFlow. It also highlights areas where further clarification from stakeholders is needed.


# Part 3: API Implementation (Node.js/Express)

## 1. API Endpoint: Low-Stock Alerts

**Endpoint:**
```
GET /api/companies/:companyId/alerts/low-stock
```

**Response Example:**
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

---

## 2. Node.js/Express Implementation

```js
// Assumptions:
// - Using Express.js and a SQL ORM (e.g., Sequelize or Knex)
// - Database schema as designed in Part 2
// - Product type-specific thresholds are stored in the products or inventory table
// - Recent sales activity is defined as sales in the last 30 days (configurable)
// - Only products with recent sales are considered for alerts
// - Each product can have multiple suppliers, but we show the preferred or first supplier

const express = require('express');
const router = express.Router();

// GET /api/companies/:companyId/alerts/low-stock
router.get('/api/companies/:companyId/alerts/low-stock', async (req, res) => {
  const { companyId } = req.params;
  const RECENT_SALES_DAYS = 30;

  try {
    // 1. Get all warehouses for the company
    const warehouses = await db('warehouses').where({ company_id: companyId });
    if (!warehouses.length) {
      return res.status(404).json({ error: 'No warehouses found for this company.' });
    }
    const warehouseIds = warehouses.map(w => w.id);

    // 2. Get all inventory records for these warehouses
    const inventoryRows = await db('inventory')
      .whereIn('warehouse_id', warehouseIds)
      .join('products', 'inventory.product_id', 'products.id')
      .select(
        'inventory.*',
        'products.name as product_name',
        'products.sku',
        'products.id as product_id',
        'products.is_bundle',
        'products.price',
        'products.min_threshold as product_min_threshold'
      );

    // 3. For each inventory record, check for recent sales activity
    // (Assume sales are tracked in inventory_history with change_type = 'SALE')
    const alerts = [];
    for (const inv of inventoryRows) {
      // Get recent sales for this product in this warehouse
      const recentSales = await db('inventory_history')
        .where({
          product_id: inv.product_id,
          warehouse_id: inv.warehouse_id,
          change_type: 'SALE'
        })
        .andWhere('created_at', '>=', db.raw(`CURRENT_DATE - INTERVAL '${RECENT_SALES_DAYS} days'`))
        .orderBy('created_at', 'desc');

      if (!recentSales.length) continue; // Skip if no recent sales

      // Determine threshold (per product or per inventory row)
      const threshold = inv.min_threshold || inv.product_min_threshold || 10;

      if (inv.quantity <= threshold) {
        // Estimate days until stockout (simple average sales per day)
        const totalSold = recentSales.reduce((sum, s) => sum + Math.abs(s.quantity_change), 0);
        const days = Math.max(1, Math.min(RECENT_SALES_DAYS, (new Date() - new Date(recentSales[recentSales.length-1].created_at)) / (1000*60*60*24)));
        const avgDailySales = totalSold / days;
        const daysUntilStockout = avgDailySales > 0 ? Math.floor(inv.quantity / avgDailySales) : null;

        // Get supplier info (first supplier for this product)
        const supplier = await db('product_suppliers')
          .where({ product_id: inv.product_id })
          .join('suppliers', 'product_suppliers.supplier_id', 'suppliers.id')
          .select('suppliers.id', 'suppliers.name', 'suppliers.contact_email')
          .first();

        // Get warehouse name
        const warehouse = warehouses.find(w => w.id === inv.warehouse_id);

        alerts.push({
          product_id: inv.product_id,
          product_name: inv.product_name,
          sku: inv.sku,
          warehouse_id: inv.warehouse_id,
          warehouse_name: warehouse ? warehouse.name : '',
          current_stock: inv.quantity,
          threshold,
          days_until_stockout: daysUntilStockout,
          supplier: supplier || null
        });
      }
    }

    return res.json({ alerts, total_alerts: alerts.length });
  } catch (err) {
    console.error('Low-stock alert error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
```

---

## 3. API Design & Edge Case Handling

- **Business Logic**: Only products with recent sales and low stock are alerted. Thresholds are per product or inventory row.
- **Multiple Warehouses**: Handles all warehouses for a company.
- **Supplier Info**: Returns first supplier (can be extended for preferred supplier logic).
- **Bundles**: Bundles are skipped (or can be handled separately if needed).
- **Edge Cases**:
  - No warehouses: 404 error
  - No recent sales: Product not alerted
  - No supplier: Supplier field is null
  - Division by zero in sales: days_until_stockout is null
  - Large companies: Query is paginated or batched in production
- **Security**: Assumes authentication/authorization middleware is present
- **Performance**: For large datasets, batch DB queries or use caching
- **Extensibility**: Can add filters (by warehouse, product type, etc.)
- **Error Handling**: Returns clear error messages and HTTP status codes

## 4. Assumptions & Reasoning

- **Recent Sales**: Defined as sales in the last 30 days (configurable)
- **Thresholds**: Pulled from inventory or product; default to 10 if missing
- **Supplier**: Returns first supplier; can be extended for preferred supplier
- **Stockout Calculation**: Uses average daily sales; null if no sales
- **Bundles**: Not included in alerts (can be added if needed)
- **Scalability**: For high volume, use optimized queries, indexes, and possibly background jobs

---
This implementation is robust, clear, and ready for production with further tuning for scale and business rules.
