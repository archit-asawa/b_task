// db.js
// PostgreSQL database connection using Knex.js

const knex = require('knex');

const db = knex({
  client: 'pg',
  connection: {
    host: 'localhost',          
    port: 5432,                 
    user: 'postgres',       
    password: 'xxxxx',  
    database: 'stockflow_db' 
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
