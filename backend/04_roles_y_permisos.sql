-- Limpiar roles solo en caso de existencia
DROP ROLE IF EXISTS rol_veterinario;
DROP ROLE IF EXISTS rol_recepcion;
DROP ROLE IF EXISTS rol_admin;

-- Crear los roles
CREATE ROLE rol_veterinario;
CREATE ROLE rol_recepcion;
CREATE ROLE rol_admin;

-- Dar permisos al SCHEMA de la base
GRANT USAGE ON SCHEMA public TO rol_veterinario, rol_recepcion, rol_admin;

-- Dar permisos para los que realizan INSERT 
-- SEQUENCES para los id´s
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_veterinario;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_recepcion;

-- Permisos especificos al rol de veterinario
GRANT SELECT, INSERT ON citas TO rol_veterinario;
GRANT SELECT ON mascotas TO rol_veterinario;
GRANT SELECT ON duenos TO rol_veterinario;
GRANT SELECT, INSERT ON vacunas_aplicadas TO rol_veterinario;
GRANT SELECT ON inventario_vacunas TO rol_veterinario;
GRANT SELECT ON vet_atiende_mascota TO rol_veterinario;

-- Permisos especificos al rol de recepción
GRANT SELECT, INSERT, UPDATE ON mascotas TO rol_recepcion;
GRANT SELECT, INSERT ON duenos TO rol_recepcion;
GRANT SELECT, INSERT ON citas TO rol_recepcion;

-- Permisos para el rol de administrador
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_admin;