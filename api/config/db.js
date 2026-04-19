// POOL DE CONEXIONES PG

require('dotenv').config(); // Dotenv para leer las variables de entorno
const { Pool } = require('pg'); // Pool para manejar las conexiones a la base de datos

// Conexión mediante el pool
const pool = new Pool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT
});

module.exports = pool;