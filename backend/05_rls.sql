-- ENABLE activa las politicas mientras que FORCE es para 
-- que ABSOLUTAMENTE TODOS tengan reglas definidas (nadie pueda escalar)
ALTER TABLE mascotas ENABLE ROW LEVEL SECURITY;
ALTER TABLE mascotas FORCE ROW LEVEL SECURITY;

-- FOR ALL aplica para el CRUD
-- USING(true) hace que la condición siempre sea verdadera y pueda realizarla sin 
-- necesidad de pasos extras
CREATE POLICY policy_mascotas_admin ON mascotas
    FOR ALL TO rol_admin USING(TRUE);


CREATE POLICY policy_mascotas_veterinario ON mascotas
    FOR SELECT TO rol_veterinario
    USING(
        -- Regresa los registros de las mascotas asignadas a un veterinario especifico
        EXISTS(
            SELECT 1 FROM vet_atiende_mascota
            WHERE mascota_id = mascotas.id
            -- current_settings() es la identidad del veterinario que se manda en el pool de node.js
            AND vet_id = current_setting('app.current_vet_id', true)::INT
        )
    );

CREATE POLICY policy_mascotas_recepcion ON mascotas
    FOR ALL TO rol_recepcion USING(true);


ALTER TABLE citas ENABLE ROW LEVEL SECURITY;
ALTER TABLE citas FORCE ROW LEVEL SECURITY;

-- Permiso total al administrador y a recepción para ver todas las citas
CREATE POLICY policy_citas_admin ON citas FOR ALL TO rol_admin USING (true);
CREATE POLICY policy_citas_recepcion ON citas FOR ALL TO rol_recepcion USING (true);

-- Muestra unicamente las filas donde la columna veterinario_id coincida con el de la conexión 
-- El veterinario no puede hacer ninguna acción sobre citas que no se le hayan asignado
CREATE POLICY policy_citas_veterinario ON citas 
    FOR ALL TO rol_veterinario
    USING (veterinario_id = current_setting('app.current_vet_id', true)::INT);


ALTER TABLE vacunas_aplicadas ENABLE ROW LEVEL SECURITY;
ALTER TABLE vacunas_aplicadas FORCE ROW LEVEL SECURITY;

CREATE POLICY policy_vacunas_admin ON vacunas_aplicadas FOR ALL TO rol_admin USING (true);

-- No aparece que veterinario puso una vacuna solo a que mascota
-- asi que se valida que la mascota sea atendido por el veterinario en curso
CREATE POLICY policy_vacunas_veterinario ON vacunas_aplicadas
    FOR ALL TO rol_veterinario
    USING(
        EXISTS(
            -- Buscamos las mascotas que esten asignados a un veterinario y que esten vacunados
            SELECT 1 FROM vet_atiende_mascota
            WHERE mascota_id = vacunas_aplicadas.mascota_id
            AND vet_id = current_setting('app.current_vet_id', true)::INT
        )
    );


/* El admin puede ver todo 
la Recepción puede ver todas las mascotas y las citas para agendar pero no las vacunas aplicadas
el Veterinario solo puede ver a sus pacientes, las citas y las vacunas de las mascotas que atiende
*/