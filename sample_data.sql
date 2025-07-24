-- sample_data.sql
-- Sample data for testing the low-stock alerts endpoint

-- Insert sample companies
INSERT INTO companies (name) VALUES
('TechCorp Inc'),
('RetailMart LLC');

-- Insert sample warehouses
INSERT INTO warehouses (company_id, name, address) VALUES
(1, 'Main Warehouse', '123 Tech Street, Silicon Valley, CA'),
(1, 'East Coast Warehouse', '456 Innovation Ave, Boston, MA'),
(2, 'Central Distribution', '789 Retail Blvd, Chicago, IL');

-- Insert sample suppliers
INSERT INTO suppliers (name, contact_email, phone) VALUES
('Supplier Corp', 'orders@supplier.com', '+1-555-0101'),
('Tech Components Ltd', 'sales@techcomponents.com', '+1-555-0102'),
('Widget Manufacturing', 'info@widgetmfg.com', '+1-555-0103');

-- Insert sample products
INSERT INTO products (name, sku, price, description, min_threshold) VALUES
('Widget A', 'WID-001', 25.99, 'Premium widget for general use', 20),
('Tech Gadget Pro', 'TGP-001', 199.99, 'Professional grade tech gadget', 5),
('Standard Component', 'STD-001', 5.50, 'Standard replacement component', 50),
('Premium Sensor', 'PSN-001', 89.99, 'High-precision sensor device', 10),
('Basic Tool', 'BTL-001', 12.99, 'Basic utility tool', 15);

-- Insert product-supplier relationships
INSERT INTO product_suppliers (product_id, supplier_id) VALUES
(1, 1), -- Widget A from Supplier Corp
(2, 2), -- Tech Gadget Pro from Tech Components Ltd
(3, 1), -- Standard Component from Supplier Corp
(4, 2), -- Premium Sensor from Tech Components Ltd
(5, 3); -- Basic Tool from Widget Manufacturing

-- Insert inventory records (some with low stock)
INSERT INTO inventory (product_id, warehouse_id, quantity, min_threshold) VALUES
-- TechCorp Main Warehouse (low stock scenarios)
(1, 1, 5, 20),   -- Widget A: 5 units (below threshold of 20)
(2, 1, 2, 5),    -- Tech Gadget Pro: 2 units (below threshold of 5)
(3, 1, 100, 50), -- Standard Component: 100 units (above threshold)
(4, 1, 8, 10),   -- Premium Sensor: 8 units (below threshold of 10)
(5, 1, 20, 15),  -- Basic Tool: 20 units (above threshold)

-- TechCorp East Coast Warehouse
(1, 2, 25, 20),  -- Widget A: 25 units (above threshold)
(2, 2, 1, 5),    -- Tech Gadget Pro: 1 unit (below threshold)
(3, 2, 75, 50),  -- Standard Component: 75 units (above threshold)

-- RetailMart Central Distribution
(1, 3, 3, 20),   -- Widget A: 3 units (below threshold)
(5, 3, 10, 15);  -- Basic Tool: 10 units (below threshold)

-- Insert recent sales history (last 30 days)
-- This ensures products with low stock also have recent sales activity
INSERT INTO inventory_history (product_id, warehouse_id, change_type, quantity_change, new_quantity, reason, created_at) VALUES
-- Recent sales for Widget A (low stock items)
(1, 1, 'SALE', -2, 5, 'Customer order #1001', CURRENT_DATE - INTERVAL '5 days'),
(1, 1, 'SALE', -3, 7, 'Customer order #1002', CURRENT_DATE - INTERVAL '10 days'),
(1, 1, 'SALE', -1, 10, 'Customer order #1003', CURRENT_DATE - INTERVAL '15 days'),
(1, 3, 'SALE', -1, 3, 'Customer order #2001', CURRENT_DATE - INTERVAL '3 days'),
(1, 3, 'SALE', -2, 4, 'Customer order #2002', CURRENT_DATE - INTERVAL '8 days'),

-- Recent sales for Tech Gadget Pro
(2, 1, 'SALE', -1, 2, 'Corporate order #3001', CURRENT_DATE - INTERVAL '2 days'),
(2, 1, 'SALE', -2, 3, 'Corporate order #3002', CURRENT_DATE - INTERVAL '12 days'),
(2, 2, 'SALE', -1, 1, 'Online order #4001', CURRENT_DATE - INTERVAL '7 days'),

-- Recent sales for Premium Sensor
(4, 1, 'SALE', -1, 8, 'Technical order #5001', CURRENT_DATE - INTERVAL '4 days'),
(4, 1, 'SALE', -1, 9, 'Technical order #5002', CURRENT_DATE - INTERVAL '18 days'),

-- Recent sales for Basic Tool
(5, 3, 'SALE', -2, 10, 'Bulk order #6001', CURRENT_DATE - INTERVAL '6 days'),
(5, 3, 'SALE', -3, 12, 'Bulk order #6002', CURRENT_DATE - INTERVAL '20 days'),

-- Some restocking history
(1, 1, 'RESTOCK', 10, 15, 'Weekly restock', CURRENT_DATE - INTERVAL '25 days'),
(2, 1, 'RESTOCK', 5, 8, 'Monthly restock', CURRENT_DATE - INTERVAL '28 days');

-- Add some products without recent sales (these should NOT appear in alerts)
INSERT INTO products (name, sku, price, description, min_threshold) VALUES
('Obsolete Item', 'OBS-001', 15.99, 'Legacy product with no recent sales', 25);

INSERT INTO product_suppliers (product_id, supplier_id) VALUES
(6, 1); -- Obsolete Item from Supplier Corp

INSERT INTO inventory (product_id, warehouse_id, quantity, min_threshold) VALUES
(6, 1, 2, 25); -- Obsolete Item: 2 units (below threshold but no recent sales)

-- No recent sales for Obsolete Item (should not trigger alerts)
