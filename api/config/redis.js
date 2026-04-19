// CLIENTE DE REDIS

require("dotenv").config();
const Redis = require("ioredis"); // Usamos el cliente de Redis

const redisClient = new Redis({ // Crear una instancia de Redis
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT
});

redisClient.on('connect', () => { // Conexión con exito
    console.log('Redis conectado');
});

redisClient.on('error', (err) => { // Error de conexión
    console.log('Error de conexión a Redis:', err);
});

module.exports = redisClient;

