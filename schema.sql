-- schema.sql
-- PostgreSQL schema for StockFlow inventory management system

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS inventory_history CASCADE;
DROP TABLE IF EXISTS product_bundles CASCADE;
DROP TABLE IF EXISTS product_suppliers CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS warehouses CASCADE;
DROP TABLE IF EXISTS companies CASCADE;

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
    min_threshold INTEGER DEFAULT 10,
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
    min_threshold INTEGER DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (product_id, warehouse_id)
);

-- Inventory History (track changes)
CREATE TABLE inventory_history (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id),
    warehouse_id INTEGER REFERENCES warehouses(id),
    change_type VARCHAR(50) NOT NULL, -- 'SALE', 'RESTOCK', 'TRANSFER', 'ADJUSTMENT'
    quantity_change INTEGER NOT NULL,
    new_quantity INTEGER NOT NULL,
    reason TEXT,
    created_by INTEGER, -- user id, if available
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_warehouses_company_id ON warehouses(company_id);
CREATE INDEX idx_inventory_warehouse_id ON inventory(warehouse_id);
CREATE INDEX idx_inventory_product_id ON inventory(product_id);
CREATE INDEX idx_inventory_history_product_warehouse ON inventory_history(product_id, warehouse_id);
CREATE INDEX idx_inventory_history_created_at ON inventory_history(created_at);
CREATE INDEX idx_inventory_history_change_type ON inventory_history(change_type);

-- Comments
COMMENT ON TABLE companies IS 'Companies using the inventory system';
COMMENT ON TABLE warehouses IS 'Warehouses belonging to companies';
COMMENT ON TABLE products IS 'Products available in the system';
COMMENT ON TABLE inventory IS 'Current inventory levels per warehouse';
COMMENT ON TABLE inventory_history IS 'Audit trail of all inventory changes';
