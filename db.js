// db.js
// PostgreSQL database connection using Knex.js

const knex = require('knex');

const db = knex({
  client: 'pg',
  connection: {
    host: 'localhost',          // ✅ Correct from pgAdmin
    port: 5432,                 // ✅ Correct from pgAdmin  
    user: 'postgres',           // ✅ Correct from pgAdmin
    password: 'architiiitn',  // Replace with your actual password
    database: 'stockflow_db'    // We'll create this database
  },
  pool: {
    min: 2,
    max: 10
  },
  migrations: {
    tableName: 'knex_migrations'
  }
});

module.exports = db;
