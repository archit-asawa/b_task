
// lowStockAlerts.js
// Clean Node.js/Express route for low-stock alerts (PostgreSQL/Knex)

const express = require('express');
const router = express.Router();

// IMPORTANT: You must provide your own Knex instance as 'db'.
// Example: const db = require('./db');
// Attach db to req.app.locals.db or use global.db for simplicity in small projects.

// GET /api/companies/:companyId/alerts/low-stock
router.get('/api/companies/:companyId/alerts/low-stock', async (req, res) => {
  const { companyId } = req.params;
  const db = req.app.locals.db; // Database instance from app.js
  const RECENT_SALES_DAYS = 30;

  try {
    // 1. Fetch all warehouses for the company
    const warehouses = await db('warehouses').where({ company_id: companyId });
    if (!warehouses.length) {
      return res.status(404).json({ error: 'No warehouses found for this company.' });
    }
    const warehouseIds = warehouses.map(w => w.id);

    // 2. Fetch inventory for all warehouses, join with products
    const inventoryRows = await db('inventory')
      .whereIn('warehouse_id', warehouseIds)
      .join('products', 'inventory.product_id', 'products.id')
      .select(
        'inventory.*',
        'products.name as product_name',
        'products.sku',
        'products.id as product_id',
        'products.is_bundle',
        'products.min_threshold as product_min_threshold'
      );

    const alerts = [];
    for (const inv of inventoryRows) {
      // 3. Check for recent sales activity (last 30 days)
      const recentSales = await db('inventory_history')
        .where({
          product_id: inv.product_id,
          warehouse_id: inv.warehouse_id,
          change_type: 'SALE'
        })
        .andWhere('created_at', '>=', db.raw(`CURRENT_DATE - INTERVAL '${RECENT_SALES_DAYS} days'`));

      if (!recentSales.length) continue; // Only alert for products with recent sales

      // 4. Determine threshold (per inventory or product, fallback to 10)
      const threshold = inv.min_threshold || inv.product_min_threshold || 10;

      if (inv.quantity <= threshold) {
        // 5. Estimate days until stockout (average daily sales)
        const totalSold = recentSales.reduce((sum, s) => sum + Math.abs(s.quantity_change), 0);
        const days = Math.max(1, Math.min(RECENT_SALES_DAYS, (new Date() - new Date(recentSales[recentSales.length-1].created_at)) / (1000*60*60*24)));
        const avgDailySales = totalSold / days;
        const daysUntilStockout = avgDailySales > 0 ? Math.floor(inv.quantity / avgDailySales) : null;

        // 6. Get supplier info (first supplier for this product)
        const supplier = await db('product_suppliers')
          .where({ product_id: inv.product_id })
          .join('suppliers', 'product_suppliers.supplier_id', 'suppliers.id')
          .select('suppliers.id', 'suppliers.name', 'suppliers.contact_email')
          .first();

        // 7. Get warehouse name
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
