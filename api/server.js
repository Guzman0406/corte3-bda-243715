require("dotenv").config()
// Exportar las dependencias necesarias
const express = require("express")
const pool = require("./config/db")
const redisClient = require("./config/redis")
const path = require('path'); 

// Variables para inicializar el servidor
const app = express()   
const PORT = process.env.PORT || 3000

app.use(express.json())

app.use(express.static(path.join(__dirname, '../frontend')));

const cors = require('cors');
app.use(cors());

// Cuando se consulte /mascotas mandamos a llamar mascotasRoutes la cual 
// usa mascotasController
const mascotasRoutes = require ('./routes/mascotasRoutes')
app.use ('/mascotas', mascotasRoutes)

const vacunasRoutes = require ('./routes/vacunasRoutes');
app.use('/vacunas', vacunasRoutes);

app.get('/health', async (req, res) => {
    try{
        // Prueba de conexión a la base de datos
        await pool.query('SELECT 1')

        // Prueba de conexión a Redis
        await redisClient.ping();

        res.status(200).json ({db: 'ok', redis: 'ok'}); // Si todo sale bien devuelve un 200 y los mensajes
    } catch(error){
        console.error('Error con el estado de la salud', error); // Si falla mandamos el error y el mensaje 
        res.status(500).json({status: 'error', message: 'falló en las conexiones'})
    }
});

app.listen(PORT, () => {
    console.log(`Servidor corriendo en el puerto: ${PORT}`);
})



module.exports = app