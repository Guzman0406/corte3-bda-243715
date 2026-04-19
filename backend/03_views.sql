CREATE OR REPLACE VIEW v_mascotas_vacunacion_pendiente AS
SELECT 
m.id            AS mascota_id,
m.nombre        AS mascota,
m.especie, 
d.nombre        AS dueno, 
d.telefono, 
iv.nombre       AS vacuna_pendiente,
iv.stock_actual,    
iv.stock_minimo


FROM mascotas m 
/* Unimos las mascotas con sus dueños y cruzamos cada una de las mascotas con 
el inventario completo de las vacunas*/
JOIN duenos d on m.dueno_id = d.id
JOIN inventario_vacunas iv ON 1=1  -- 1=1 sirve para unir todo con todo (cross join)

/* Buscamos en el historial si la mascota ya recibió esa vacuna especifica
dentro del último año para verificar*/
LEFT JOIN vacunas_aplicadas va ON
va.mascota_id = m.id  -- vinculamos el historial con las mascotas
AND va.vacuna_id = iv.id -- verificamos que coincida con la vacuna
AND va.fecha_aplicacion > NOW() - INTERVAL '1 year' -- solo filtramos a los que sean recientes

 /*Solo las vacunas que estan en alerta y nos quedamos 
 con las que no tengan registro de vacuna aplicada (sea null)*/
WHERE iv.stock_actual < iv.stock_minimo -- solo las vacunas en alerta
AND va.id IS NULL;

/*
LÓGICA:
    1. Cruzamos cada mascota con cada vacuna en el inventario esto para tener una lista de todas las "teoricas vacunas"
    2. Descartamos las vacunas con stock suficiente (iv.stock_actual > iv.stock_minimo) que son las que necesitamos circular
    3. Usamos LEFT JOIN para emparejar cada fila con la tabla "vacunas_aplicadas" buscando aquellos que sean recientes
        si la mascota ya tiene la vacuna: se llenan los datos
        si la mascota no tiene la vacuna: se marcan como null
    4. Con WHERE va.id IS NULL dejamos a los que tienen un registro de vacunación pendiente.  
*/