const pool = require ('../config/db')

const buscarMascotas = async (req, res) => {
    // Recibimos los datos del request
    const nombre = req.query.nombre || ''; // Si el veterinario no pone nada devolvemos todas sus mascotas
    const rol = req.headers['x-rol']; 
    const vetId = req.headers['x-vet-id']; 

    // Seguridad de roles
    // Si el rol no se encuentra en los roles permitidos se manda error
    const rolesPermitidos = ['rol_admin', 'rol_veterinario', 'rol_recepcion'];
    if (!rolesPermitidos.includes(rol))
        return res.status(403).json ({error: 'Acceso denegado: Rol inválido'});

    // Obtenemos la conexión
    const client = await pool.connect();

    try{
        await client.query ('BEGIN');

    /*SET LOCAL parametrizado para cuando sea veterinario
     Si el rol es veterinario y si su id no coincide con ser veterinario
     se manda el error, caso exitoso se manda la petición con el id*/
    if (rol === 'rol_veterinario'){ 
        if (!vetId) return res.status(400).json ({error: 'Falta el id del veterinario'});
        // En PostgreSQL no puedes pasar parámetros ($1) directamente en un comando SET
        // Por eso usamos la función set_config que es la alternativa segura:
        await client.query ('SELECT set_config($1, $2, true)', ['app.current_vet_id', vetId.toString()]); // True es la conexión local 
        // Significa que la variable app.current_vet_id solo existe en esta conexión 
    }

    // SET LOCAL ROLE 
    // Solo cuando ya paso la validación (Corregido: comillas invertidas)
    await client.query(`SET LOCAL ROLE ${rol}`); 

    // Petición de la consulta
    // Se parametriza la consulta para evitar inyección SQL
    const query = 'SELECT id, nombre, especie FROM mascotas WHERE nombre ILIKE $1';
    // Corregido: comillas invertidas y el porcentaje final
    const result = await client.query(query, [`%${nombre}%`]);
bhgggn 
    await client.query ('COMMIT');

    // Regresar la consulta
    res.json(result.rows);

    // En caso de que falle la consulta se manda el error
    }catch(error){
        await client.query('ROLLBACK');
        console.error('ERROR EN LA BUSQUEDA', error);
        res.status(500).json({error: 'Error interno del servidor'});
    }finally{
        // liberamos la conexión para que el siguiente usuario no herede permisos
        client.release();
    }
}

module.exports = {buscarMascotas};