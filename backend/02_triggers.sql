CREATE OR REPLACE FUNCTION fn_registrar_historial_citas()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN

INSERT INTO historial_movimientos (tipo, referencia_id, descripcion)
VALUES ('CITA_AGENDADA', NEW.id, 'Cita agendada para la mascota #' || NEW.mascota_id || ' con el veterinario #' || NEW.veterinario_id );
RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_historial_cita
AFTER INSERT ON citas
FOR EACH ROW EXECUTE FUNCTION fn_registrar_historial_citas();

/*
PRUEBA
        CALL sp_agendar_cita(3, 2, '2026-06-10 12:00:00', 'Vacunación', NULL);

REVISAR QUE SE HAYA GUARDADO
        SELECT * FROM historial_movimientos ORDER BY fecha DESC LIMIT 3;

usamos AFTER INSERT ya que si se ejecuta antes de que se modifique la tabla la cita todavia no existiria
por lo tanto podria fallas por alguna u otra cosa y quedaria como registro falso
*/