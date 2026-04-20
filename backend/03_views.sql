-- =============================================================
-- COMPONENTE 4: Vista v_mascotas_vacunacion_pendiente
-- =============================================================

CREATE OR REPLACE VIEW v_mascotas_vacunacion_pendiente WITH (security_invoker = true) AS
WITH ultima_vacuna_por_mascota AS (
    SELECT
        mascota_id,
        MAX(fecha_aplicacion) AS fecha_ultima_vacuna
      FROM vacunas_aplicadas
     GROUP BY mascota_id
)
SELECT
    m.nombre                                            AS nombre_mascota,
    m.especie,
    d.nombre                                            AS nombre_dueno,
    d.telefono                                          AS telefono_dueno,
    uv.fecha_ultima_vacuna,
    (CURRENT_DATE - uv.fecha_ultima_vacuna)::INT        AS dias_desde_ultima_vacuna,
    CASE
        WHEN uv.fecha_ultima_vacuna IS NULL THEN 'NUNCA_VACUNADA'
        ELSE 'VENCIDA'
    END                                                 AS prioridad
  FROM mascotas m
  JOIN duenos d ON d.id = m.dueno_id
  LEFT JOIN ultima_vacuna_por_mascota uv ON uv.mascota_id = m.id
 WHERE uv.fecha_ultima_vacuna IS NULL                       -- nunca vacunada
    OR (CURRENT_DATE - uv.fecha_ultima_vacuna) > 365;       -- vacuna vencida
