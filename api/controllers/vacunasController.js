const pool = require('../config/db');
const redisClient = require('../config/redis');

// GET /vacunas/pendientes
const getVacunasPendientes = async (req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('Access-Control-Expose-Headers', 'X-Cache');
    const rol = req.headers['x-rol'];
    const vetId = req.headers['x-vet-id'];
    const key = 'api:vacunas:pendientes';

    const rolesPermitidos = ['rol_admin', 'rol_veterinario', 'rol_recepcion'];
    if (!rolesPermitidos.includes(rol)) return res.status(403).json({ error: 'Acceso denegado: Rol inválido' });

    try {
        // Consulta rapida para saber si esta cacheado la key
        const cached = await redisClient.get(key);
        if (cached) {
            console.log(`[CACHE HIT] ${key}`);
            res.setHeader('X-Cache', 'HIT');
            return res.json(JSON.parse(cached)); // Al devolver un texto gigante, lo parseamos a un arreglo
        }

        // Si arroja cache miss vamos de nuevo a Postgre
        console.log(`[CACHE MISS] ${key} — consultando a la BD...`);
        const inicio = Date.now(); // tiempo para saber cuanto tardo en consultar la bd

        // Consulta a la vista con el ciclo seguro
        const client = await pool.connect();
        let rows = []; // variable para guardar el arreglo de respuestas
        try {
            await client.query('BEGIN');
            if (rol === 'rol_veterinario') {
                if (!vetId) return res.status(400).json({ error: 'Falta id del veterinario' });
                await client.query('SELECT set_config($1, $2, true)', ['app.current_vet_id', vetId.toString()]);
            }
            await client.query(`SET LOCAL ROLE ${rol}`);
            
            // Consultamos la vista
            const result = await client.query('SELECT * FROM v_mascotas_vacunacion_pendiente');
            rows = result.rows;

            await client.query('COMMIT');
        } catch (dbError) {
            await client.query('ROLLBACK');
            throw dbError; // Mandamos el error al catch principal
        } finally {
            client.release();
        }

        // Saber cuantos milisegundos tardo Postgre en responder
        const latencia = Date.now() - inicio;
        console.log(`[CACHE MISS] Latencia BD: ${latencia}ms`);

        // Teniendo los datos lo guardamos en la cache 
        //stringify(rows) comprime los datos para guardalo en redis 
        await redisClient.set(key, JSON.stringify(rows), 'EX', 300); 

        res.setHeader('X-Cache', 'MISS');
        
        res.json(rows);

    } catch (error) {
        console.error('Error en vacunas pendientes:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
};

// POST /vacunas/aplicar
const aplicarVacuna = async (req, res) => {
    const rol = req.headers['x-rol'];
    const vetId = req.headers['x-vet-id'];
    const {mascota_id, vacuna_id, costo} = req.body;
    const key = 'api:vacunas:pendientes';

    const rolesPermitidos = ['rol_admin', 'rol_veterinario'];
    if(!rolesPermitidos.includes(rol)) return res.status(403).json({error: 'Rol inválido o sin permisos'});

    const client = await pool.connect();

    try{
        await client.query('BEGIN');

        if (rol === 'rol_veterinario'){
            if (!vetId) return res.status(400).json({error: 'Falta el id del veterinario'});
            await client.query('SELECT set_config($1, $2, true)', ['app.current_vet_id', vetId.toString()]);
        }
        
        await client.query(`SET LOCAL ROLE ${rol}`);   
        
        // Verificamos que la mascota pertenezca al veterinario
        const verificacion = await client.query ('SELECT 1 FROM mascotas WHERE id = $1', [mascota_id]);

        // Si la verificación regresa 0 es porque no es el veterinario asignado
        if (verificacion.rows.length === 0){
            await client.query('ROLLBACK');
            return res.status(403).json({error: 'No tienes permiso para aplicar vacuna a esta mascota'});
        }
        
        // Insertamos la nueva vacuna aplicada }
        // Returning * devuelve la fila recien creada 
        const query = 'INSERT INTO vacunas_aplicadas (mascota_id, vacuna_id, veterinario_id, costo_cobrado) VALUES ($1, $2, $3, $4) RETURNING *';
        
        // Mandamos la query y los parametros al mismo tiempo
        const result = await client.query(query, [mascota_id, vacuna_id, vetId, costo]);

        await client.query('COMMIT');
    
        // Invalidación de la cache
        await redisClient.del(key); // Borramos la cache para obligar al siguiente usuario a volver ir a Postgre
        console.log(`[CACHE INVALIDADO] ${key}`);
        // rows[0] para regresar los datos aplicados en el INSERT
        res.json ({message: 'Vacuna aplicada correctamente', data: result.rows[0]}); 

    } catch (error){
        await client.query('ROLLBACK');
        console.log('Error al aplicar la vacuna', error);
        res.status(500).json({error: 'Error al aplicar la vacuna'});
    } finally{
        client.release();
    }

}

module.exports = { getVacunasPendientes, aplicarVacuna };