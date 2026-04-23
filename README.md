
# Clínica Veterinaria

**Guzmán López Ángel Eduardo - 243715** 


### 1. ¿Qué política RLS aplicaste a la tabla `mascotas`? Pega la cláusula exacta y explica con tus palabras qué hace.

**Cláusula SQL:**

```sql
CREATE POLICY policy_mascotas_veterinario ON mascotas
  FOR SELECT TO rol_veterinario
  USING(
    EXISTS(
      SELECT 1 FROM vet_atiende_mascota
      WHERE mascota_id = mascotas.id
      AND vet_id = current_setting('app.current_vet_id', true)::INT
    )
  );

```

Lo que hace esta política es actuar como un filtro: cuando un usuario tiene el rol de veterinario e intenta leer la tabla de mascotas, la base de datos no le dará la tabla completa, sino que evalúa fila por fila con el uso de `EXISTS`. Por cada mascota, busca en la tabla `vet_atiende_mascota` y verifica que el `id` de la mascota esté relacionado con el `id` del veterinario. En caso de que sí coincida, mostrará los resultados; caso contrario, los oculta.

----------

### 2. Cualquiera que sea la estrategia que elegiste para identificar al veterinario actual en RLS, tiene un vector de ataque posible. ¿Cuál es? ¿Tu sistema lo previene? ¿Cómo?

El ataque posible sería en cuanto a la sesión de la base de datos: si se inserta la variable `app.current_vet_id = 1` y no se borra, es posible que la siguiente solicitud que use esa conexión continúe leyendo los datos del veterinario 1, aunque el que haya iniciado sesión sea el veterinario 2.

Mi sistema sí lo previene usando transacciones locales con `set_config($1, $2, true)`. El parámetro `true` indica que estamos en una transacción local y, cuando la operación termine o falle, la base lo destruye, lo que hace que ninguna otra sesión herede los permisos de la conexión anterior.

----------

### 3. Si usas `SECURITY DEFINER` en algún procedure, ¿qué medida específica tomaste para prevenir la escalada de privilegios que ese modo habilita? Si no lo usas, justifica por qué no era necesario.

No fue necesario usarlo. En lugar de crear funciones que puedan elevar privilegios, se construyó una arquitectura de seguridad con privilegios mínimos. El backend hace la autorización con el comando `SET LOCAL` por cada operación. Cada rol ya tiene permisos predeterminados únicamente sobre las tablas que necesita trabajar.

----------

### 4. ¿Qué TTL le pusiste al caché Redis y por qué ese valor específico? ¿Qué pasaría si fuera demasiado bajo? ¿Demasiado alto?

Se eligió un tiempo de **5 minutos (300 segundos)**.

-   **Si fuera más bajo:** las consultas caducarían más rápido, el backend estaría mandando peticiones constantemente y no habría ahorro de recursos por parte del servidor.
-   **Si fuera más alto:** habría demasiado tiempo sin actualizar; otro veterinario no podría ver lo que se aplicó hace unas horas.

----------

### 5. Tu frontend manda input del usuario al backend. Elige un endpoint crítico y pega la línea exacta donde el backend maneja ese input antes de enviarlo a la base de datos. Explica qué protege esa línea y de qué. Indica archivo y número de línea.

**Archivo:** `api/controllers/mascotasController.js`

```javascript
const result = await client.query(
    'SELECT id, nombre, especie FROM mascotas WHERE nombre ILIKE $1',
    [`%${nombre}%`]
);

```

Este bloque realiza la parametrización del input y protege de inyección SQL al usar `$1` y pasar el dato por separado. La parametrización le pasa el input de forma independiente a la query para que `pg` no lo interprete como código SQL, haciendo así inofensiva cualquier entrada maliciosa.

----------

### 6. Si revocas todos los permisos del rol de veterinario excepto `SELECT` en `mascotas`, ¿qué deja de funcionar en tu sistema? Lista tres operaciones que se romperían.

1.  **`POST /vacunas/aplicar`** — el veterinario perdería el permiso de `INSERT` sobre la tabla `vacunas_aplicadas`, lo que generaría un error de permisos al intentar registrar una aplicación de vacuna.
    
2.  **Consulta de vacunas pendientes** — sin el permiso de `SELECT` sobre la vista `v_mascotas_vacunacion_pendiente`, la operación no podría ejecutarse.
    
3.  **El propio RLS** — la política necesita revisar filas en `vet_atiende_mascota`. Sin permisos sobre esta tabla, PostgreSQL lanzaría un error de permisos y el veterinario no podría ver sus mascotas asignadas.