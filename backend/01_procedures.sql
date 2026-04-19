CREATE OR REPLACE PROCEDURE sp_agendar_cita(
    p_mascota_id INT, 
    p_veterinario_id INT,
    p_fecha_hora TIMESTAMP,
    p_motivo TEXT,
    OUT p_cita_id INT
) LANGUAGE plpgsql AS $$
BEGIN

-- VALIDAR QUE LA MASCOTA EXISTA
IF NOT EXISTS (SELECT 1 FROM mascotas WHERE id = p_mascota_id)
THEN 
    RAISE EXCEPTION 'La mascota que intenta agendar no existe.';
END IF;

-- VALIDAR QUE EL VETERINARIO EXISTA Y ESTE ACTIVO
IF NOT EXISTS(SELECT 1 FROM veterinarios WHERE id = p_veterinario_id)
THEN   
    RAISE EXCEPTION 'El veterinario no existe';
END IF;

IF NOT EXISTS (SELECT 1 FROM veterinarios WHERE id = p_veterinario_id AND activo = TRUE)
THEN
    RAISE EXCEPTION 'El veterinario no se encuentra activo';
END IF;

-- REVISAR QUE NO HAYA COALISION HORARIA
-- si ya existe una fila en citas donde coincidan los parametros entonces hay conflicto
IF EXISTS (SELECT 1 FROM citas 
    WHERE veterinario_id = p_veterinario_id 
    AND fecha_hora = p_fecha_hora 
    AND estado != 'CANCELADA')
THEN 
    RAISE EXCEPTION 'Ya existe una cita agendada para esa hora';
END IF;

-- INSERTAR Y RETORNAR EL ID
INSERT INTO citas(mascota_id, veterinario_id, fecha_hora, motivo, estado)
VALUES (p_mascota_id, p_veterinario_id, p_fecha_hora, p_motivo, 'AGENDADA')
RETURNING id INTO p_cita_id; -- Insertamos el id en la tabla citas para crearla con los datos

END;
$$

/* 
CASOS DE PRUEBA 

1- CASO EXITOSO:
Agendamos una cita para firulais (id:1) con el doctor LOPEZ (id:1)
        CALL sp_agendar_cita(1, 1, '2026-05-01 10:00:00', 'Revisión general', NULL);

2- CASO FALLIDO POR HORARIO
agendamos a Misifú (id:2) con el doctor LOPEZ (id:1)
        CALL sp_agendar_cita(2, 1, '2026-05-01 10:00:00', 'Consulta de rutina', NULL);
ERROR: "Ya existe una cita agendada para esa hora"

