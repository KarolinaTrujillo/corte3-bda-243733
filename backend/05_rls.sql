-- =============================================================
-- COMPONENTE 3: Row-Level Security (RLS)
-- =============================================================

-- ==========================================
-- TABLA: mascotas
-- ==========================================
ALTER TABLE mascotas ENABLE ROW LEVEL SECURITY;

-- Los veterinarios solo ven sus mascotas asignadas
CREATE POLICY pol_vet_mascotas ON mascotas
    FOR SELECT
    TO rol_veterinario
    USING (
        id IN (
            SELECT mascota_id FROM vet_atiende_mascota
            WHERE vet_id = current_setting('app.vet_id')::INT
        )
    );

-- Recepción ve todas
CREATE POLICY pol_recepcion_mascotas ON mascotas
    FOR SELECT
    TO rol_recepcion
    USING (true);

-- Admin ve todas (aunque ya bypassea RLS por ser superuser, lo definimos para ser explícitos si no fuera superuser)
CREATE POLICY pol_admin_mascotas ON mascotas
    FOR ALL
    TO rol_administrador
    USING (true);

-- ==========================================
-- TABLA: vacunas_aplicadas
-- ==========================================
ALTER TABLE vacunas_aplicadas ENABLE ROW LEVEL SECURITY;

-- Los veterinarios solo ven vacunas de sus mascotas
CREATE POLICY pol_vet_vacunas_select ON vacunas_aplicadas
    FOR SELECT
    TO rol_veterinario
    USING (
        mascota_id IN (
            SELECT mascota_id FROM vet_atiende_mascota
            WHERE vet_id = current_setting('app.vet_id')::INT
        )
    );

-- Los veterinarios pueden insertar vacunas para sus mascotas
CREATE POLICY pol_vet_vacunas_insert ON vacunas_aplicadas
    FOR INSERT
    TO rol_veterinario
    WITH CHECK (
        mascota_id IN (
            SELECT mascota_id FROM vet_atiende_mascota
            WHERE vet_id = current_setting('app.vet_id')::INT
        )
    );

-- Admin ve todas
CREATE POLICY pol_admin_vacunas ON vacunas_aplicadas
    FOR ALL
    TO rol_administrador
    USING (true);

-- Recepción no tiene SELECT, no se le da política.

-- ==========================================
-- TABLA: citas
-- ==========================================
ALTER TABLE citas ENABLE ROW LEVEL SECURITY;

-- Los veterinarios solo ven citas donde veterinario_id coincide con su id de sesión
CREATE POLICY pol_vet_citas_select ON citas
    FOR SELECT
    TO rol_veterinario
    USING (
        veterinario_id = current_setting('app.vet_id')::INT
    );

-- Los veterinarios pueden insertar citas donde ellos son el veterinario
CREATE POLICY pol_vet_citas_insert ON citas
    FOR INSERT
    TO rol_veterinario
    WITH CHECK (
        veterinario_id = current_setting('app.vet_id')::INT
    );

-- Recepción ve todas
CREATE POLICY pol_recepcion_citas_select ON citas
    FOR SELECT
    TO rol_recepcion
    USING (true);

-- Recepción puede insertar/actualizar cualquiera
CREATE POLICY pol_recepcion_citas_insert ON citas
    FOR INSERT
    TO rol_recepcion
    WITH CHECK (true);

CREATE POLICY pol_recepcion_citas_update ON citas
    FOR UPDATE
    TO rol_recepcion
    USING (true)
    WITH CHECK (true);

-- Admin ve y hace todo
CREATE POLICY pol_admin_citas ON citas
    FOR ALL
    TO rol_administrador
    USING (true);
