-- =============================================================
-- COMPONENTE 2: Roles y permisos
-- =============================================================

-- Eliminar roles si ya existen (para que el script sea idempotente)
DROP ROLE IF EXISTS rol_veterinario;
DROP ROLE IF EXISTS rol_recepcion;
DROP ROLE IF EXISTS rol_administrador;

-- Crear roles
CREATE ROLE rol_veterinario;
CREATE ROLE rol_recepcion;
CREATE ROLE rol_administrador;
ALTER ROLE rol_administrador BYPASSRLS; -- El admin necesita bypassear RLS y tener permisos totales

-- Revocar todos los permisos públicos por defecto para tener control explícito
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;

-- ==========================================
-- PERMISOS: ROL VETERINARIO
-- ==========================================
-- GRANT USAGE ON SCHEMA
GRANT USAGE ON SCHEMA public TO rol_veterinario;

-- SELECT, INSERT en citas
GRANT SELECT, INSERT ON citas TO rol_veterinario;
-- Necesita acceso al serial (secuencia) para poder hacer INSERT
GRANT USAGE, SELECT ON SEQUENCE citas_id_seq TO rol_veterinario;

-- SELECT, INSERT en vacunas_aplicadas
GRANT SELECT, INSERT ON vacunas_aplicadas TO rol_veterinario;
GRANT USAGE, SELECT ON SEQUENCE vacunas_aplicadas_id_seq TO rol_veterinario;

-- SELECT en mascotas, duenos, inventario_vacunas, vet_atiende_mascota, v_mascotas_vacunacion_pendiente
GRANT SELECT ON mascotas TO rol_veterinario;
GRANT SELECT ON duenos TO rol_veterinario;
GRANT SELECT ON inventario_vacunas TO rol_veterinario;
GRANT SELECT ON vet_atiende_mascota TO rol_veterinario;
GRANT SELECT ON veterinarios TO rol_veterinario;
GRANT SELECT ON v_mascotas_vacunacion_pendiente TO rol_veterinario;

-- ==========================================
-- PERMISOS: ROL RECEPCIÓN
-- ==========================================
GRANT USAGE ON SCHEMA public TO rol_recepcion;

-- SELECT en mascotas, duenos, citas
GRANT SELECT ON mascotas TO rol_recepcion;
GRANT SELECT ON duenos TO rol_recepcion;
GRANT SELECT ON citas TO rol_recepcion;
GRANT SELECT ON veterinarios TO rol_recepcion;

-- INSERT, UPDATE en citas
GRANT INSERT, UPDATE ON citas TO rol_recepcion;
GRANT USAGE, SELECT ON SEQUENCE citas_id_seq TO rol_recepcion;

-- Sin ningún permiso sobre vacunas_aplicadas
-- Sin acceso a historial_movimientos

-- ==========================================
-- PERMISOS: ROL ADMINISTRADOR
-- ==========================================
GRANT USAGE ON SCHEMA public TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_administrador;

-- El rol usado por la conexión principal desde la API debe poder hacer SET ROLE a estos
GRANT rol_veterinario TO postgres;
GRANT rol_recepcion TO postgres;
GRANT rol_administrador TO postgres;
