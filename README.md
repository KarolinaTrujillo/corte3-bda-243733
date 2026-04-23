# Decisiones de Diseño - Corte 3 BDA

1. **Política RLS en mascotas:**
   ```sql
   CREATE POLICY pol_vet_mascotas ON mascotas
       FOR SELECT
       TO rol_veterinario
       USING (
           id IN (
               SELECT mascota_id FROM vet_atiende_mascota
               WHERE vet_id = current_setting('app.vet_id')::INT
           )
       );
   ```
   Esta regla le dice a PostgreSQL que cuando un veterinario hace una consulta, solo le muestre las mascotas que aparecen en la tabla de asignaciones con su número de identificación.

2. **Vector de ataque del mecanismo de sesión:**
    Si alguien tuviera acceso directo a la conexión de base de datos podría cambiar el `app.vet_id` manualmente y ver mascotas de otro veterinario. La primera línea de defensa es el uso de `SET ROLE`, que cambia el rol de la base de datos realmente a nivel de transacción para aplicar los permisos correctamente. La segunda capa es `SET LOCAL app.vet_id`, que limita el alcance del identificador del veterinario a la transacción actual, asegurando que las políticas RLS funcionen. El backend establece esto al inicio de cada petición y el frontend nunca toca la base de datos directamente. Un vector adicional: si el veterinario tiene acceso directo a vet_atiende_mascota con SELECT, podría enumerar qué vet_id existen — pero no puede cambiar el app.vet_id de su propia sesión sin acceso a la conexión de base de datos.


3. **SECURITY DEFINER:**
   No lo usé porque los procedures del sistema no necesitan ejecutarse con permisos elevados — cada usuario se conecta con su propio rol y los permisos ya están definidos con GRANT. Usar SECURITY DEFINER habría añadido un riesgo innecesario (un procedimiento con más permisos de los necesarios puede ser explotado si el search_path no está fijo).

4. **TTL del caché:**
   Elegí 5 minutos porque la consulta de vacunación pendiente tarda entre 100 y 300ms y en una clínica pequeña se consulta varias veces por hora pero cambia poco. Si el TTL fuera muy bajo (5 segundos), el caché no serviría de nada porque se invalida solo antes de que alguien lo use. Si fuera muy alto (1 hora), un veterinario podría ver datos desactualizados justo después de vacunar a una mascota — por eso también invalido el caché manualmente cuando se aplica una vacuna.

5. **Línea exacta de defensa contra SQL injection:**
   La defensa está en `api/index.js` en las líneas 58 y 60:
   ```javascript
   const query = 'SELECT * FROM mascotas WHERE nombre ILIKE $1';
   const result = await queryWithRLS(req, query, [`%${nombre || ''}%`]);
   ```
   Ambas líneas trabajan juntas. La línea 58 define la consulta SQL con un placeholder `$1`. La línea 60 envía el valor separado de la consulta al driver `pg`. Así, aunque alguien escriba `' OR '1'='1`, el driver lo trata como un literal y no como código SQL.

   **Nota sobre Vistas:** La vista `v_mascotas_vacunacion_pendiente` utiliza `security_invoker = true`. Esto garantiza que cuando un veterinario o recepcionista consulte la vista, PostgreSQL aplique las políticas RLS y los permisos del rol invocador y no del creador de la vista.

6. **Qué se rompe si revocan todo excepto SELECT en mascotas:**
   (1) El veterinario no puede registrar nuevas citas porque necesita INSERT en `citas`, (2) no puede aplicar vacunas porque necesita INSERT en `vacunas_aplicadas`, y (3) no puede consultar el historial de vacunas de sus mascotas porque necesita SELECT en `vacunas_aplicadas`.

## Cómo ejecutar

Para levantar el sistema completo ejecuta el siguiente comando en la raíz del proyecto:
```bash
docker-compose up --build
```
Luego, abre el archivo `frontend/index.html` en tu navegador.
