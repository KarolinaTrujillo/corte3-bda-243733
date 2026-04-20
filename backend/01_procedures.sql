-- =============================================================
-- COMPONENTE 1: Stored Procedure sp_agendar_cita y fn_total_facturado
-- =============================================================

CREATE OR REPLACE PROCEDURE sp_agendar_cita(
    p_mascota_id     INT,
    p_veterinario_id INT,
    p_fecha_hora     TIMESTAMP,
    p_motivo         TEXT,
    OUT p_cita_id    INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_nombre_mascota   VARCHAR(50);
    v_activo           BOOLEAN;
    v_dias_descanso    VARCHAR(50);
    v_dia_semana       TEXT;
    v_colision         INT;
BEGIN
    SELECT nombre
      INTO v_nombre_mascota
      FROM mascotas
     WHERE id = p_mascota_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La mascota con id % no existe.', p_mascota_id;
    END IF;

    SELECT activo, dias_descanso
      INTO v_activo, v_dias_descanso
      FROM veterinarios
     WHERE id = p_veterinario_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El veterinario con id % no existe.', p_veterinario_id;
    END IF;

    IF v_activo IS NOT TRUE THEN
        RAISE EXCEPTION 'El veterinario con id % no está activo.', p_veterinario_id;
    END IF;

    v_dia_semana := CASE EXTRACT(DOW FROM p_fecha_hora)
        WHEN 0 THEN 'domingo'
        WHEN 1 THEN 'lunes'
        WHEN 2 THEN 'martes'
        WHEN 3 THEN 'miercoles'
        WHEN 4 THEN 'jueves'
        WHEN 5 THEN 'viernes'
        WHEN 6 THEN 'sabado'
    END;

    IF v_dias_descanso IS NOT NULL
       AND v_dias_descanso <> ''
       AND v_dia_semana = ANY(string_to_array(v_dias_descanso, ','))
    THEN
        RAISE EXCEPTION
            'El veterinario con id % descansa los %. No se puede agendar en ese día.',
            p_veterinario_id, v_dia_semana;
    END IF;

    PERFORM id
       FROM veterinarios
      WHERE id = p_veterinario_id
      FOR UPDATE;

    SELECT id
      INTO v_colision
      FROM citas
     WHERE veterinario_id = p_veterinario_id
       AND fecha_hora     = p_fecha_hora
     LIMIT 1;

    IF FOUND THEN
        RAISE EXCEPTION
            'El veterinario con id % ya tiene una cita agendada el % a las %.',
            p_veterinario_id,
            TO_CHAR(p_fecha_hora, 'DD/MM/YYYY'),
            TO_CHAR(p_fecha_hora, 'HH24:MI');
    END IF;

    INSERT INTO citas (mascota_id, veterinario_id, fecha_hora, motivo, estado)
    VALUES (p_mascota_id, p_veterinario_id, p_fecha_hora, p_motivo, 'AGENDADA')
    RETURNING id INTO p_cita_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$;


CREATE OR REPLACE FUNCTION fn_total_facturado(
    p_mascota_id INT,
    p_anio       INT
) RETURNS NUMERIC
LANGUAGE plpgsql AS $$
DECLARE
    v_total_citas   NUMERIC;
    v_total_vacunas NUMERIC;
BEGIN
    SELECT COALESCE(SUM(costo), 0)
      INTO v_total_citas
      FROM citas
     WHERE mascota_id = p_mascota_id
       AND estado     = 'COMPLETADA'
       AND EXTRACT(YEAR FROM fecha_hora) = p_anio;

    SELECT COALESCE(SUM(costo_cobrado), 0)
      INTO v_total_vacunas
      FROM vacunas_aplicadas
     WHERE mascota_id = p_mascota_id
       AND EXTRACT(YEAR FROM fecha_aplicacion) = p_anio;

    RETURN COALESCE(v_total_citas + v_total_vacunas, 0);
END;
$$;
