const express = require('express');
const cors = require('cors');
const pool = require('./db');
const redisClient = require('./redis');

const app = express();
app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
    req.user = {
        rol: req.headers['x-rol'] || 'rol_recepcion',
        vetId: req.headers['x-vet-id'] ? parseInt(req.headers['x-vet-id'], 10) : null
    };
    next();
});


async function queryWithRLS(req, queryText, params = []) {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        const validRoles = (process.env.VALID_ROLES || 'rol_veterinario,rol_recepcion,rol_administrador').split(',');
        const defaultRole = process.env.DEFAULT_ROLE || 'rol_recepcion';
        const roleToSet = validRoles.includes(req.user.rol) ? req.user.rol : defaultRole;

        await client.query(`SET ROLE ${roleToSet}`);

        if (roleToSet === 'rol_veterinario' && req.user.vetId) {
            await client.query('SELECT set_config(\'app.vet_id\', $1::text, true)', [req.user.vetId]);
        }

        const result = await client.query(queryText, params);
        await client.query('COMMIT');
        return result;
    } catch (err) {
        await client.query('ROLLBACK');
        throw err;
    } finally {
        await client.query('RESET ROLE');
        client.release();
    }
}


app.post('/api/login', (req, res) => {
    const { rol, vetId } = req.body;
    res.json({ token: { rol, vetId } });
});


app.get('/api/veterinarios', async (req, res) => {
    try {
        const query = 'SELECT id, nombre FROM veterinarios ORDER BY id';
        const result = await pool.query(query);
        res.json(result.rows);
    } catch (err) {
        console.error('[ERROR INTERNO]', err.message);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});


app.get('/api/mascotas', async (req, res) => {
    const { nombre } = req.query;
    try {
        const query = 'SELECT * FROM mascotas WHERE nombre ILIKE $1';

        const result = await queryWithRLS(req, query, [`%${nombre || ''}%`]);
        res.json(result.rows);
    } catch (err) {
        console.error('[ERROR INTERNO]', err.message);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});


app.get('/api/vacunacion-pendiente', async (req, res) => {
    const roleKey = req.user.rol === 'rol_veterinario' ? `_vet_${req.user.vetId}` : `_${req.user.rol}`;
    const KEY = `vacunacion_pendiente${roleKey}`;
    const TTL = process.env.CACHE_TTL || 300;

    try {
        const start = Date.now();
        const cached = await redisClient.get(KEY);
        if (cached) {
            console.log(`[CACHE HIT] ${KEY} (${Date.now() - start}ms)`);
            return res.json({ source: 'CACHE HIT', data: JSON.parse(cached) });
        }

        const result = await queryWithRLS(req, 'SELECT * FROM v_mascotas_vacunacion_pendiente');

        await redisClient.setEx(KEY, TTL, JSON.stringify(result.rows));
        console.log(`[CACHE MISS] ${KEY} — consultando BD (${Date.now() - start}ms)`);
        res.json({ source: 'CACHE MISS', data: result.rows });
    } catch (err) {
        console.error('[ERROR INTERNO]', err.message);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});


app.post('/api/vacunas', async (req, res) => {
    const { mascota_id, vacuna_id, costo_cobrado } = req.body;
    if (!Number.isInteger(Number(mascota_id)) || !Number.isInteger(Number(vacuna_id))) {
        return res.status(400).json({ error: 'mascota_id y vacuna_id deben ser enteros' });
    }
    try {
        const query = `
            INSERT INTO vacunas_aplicadas (mascota_id, vacuna_id, veterinario_id, costo_cobrado)
            VALUES ($1, $2, $3, $4) RETURNING id
        `;

        const vetId = req.user.vetId || null;
        const defaultCost = parseFloat(process.env.VACCINE_COST || '500.00');
        const finalCost = costo_cobrado || defaultCost;

        const result = await queryWithRLS(req, query, [mascota_id, vacuna_id, vetId, finalCost]);


        const keys = await redisClient.keys('vacunacion_pendiente*');
        if (keys.length > 0) {
            await redisClient.del(keys);
        }
        console.log(`[CACHE INVALIDADO] vacunacion_pendiente* — nueva vacuna aplicada`);

        res.json({ message: 'Vacuna aplicada', id: result.rows[0].id });
    } catch (err) {
        console.error('[ERROR INTERNO]', err.message);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});


app.post('/api/citas', async (req, res) => {
    const { mascota_id, veterinario_id, fecha_hora, motivo } = req.body;
    if (isNaN(Date.parse(fecha_hora))) {
        return res.status(400).json({ error: 'fecha_hora no tiene formato válido' });
    }
    try {
        const query = 'CALL sp_agendar_cita($1, $2, $3, $4, null)';
        const result = await queryWithRLS(req, query, [mascota_id, veterinario_id, fecha_hora, motivo]);

        res.json({ message: 'Cita agendada', cita_id: result.rows[0]?.p_cita_id });
    } catch (err) {
        if (err.code === 'P0001') {
            res.status(400).json({ error: err.message });
        } else {
            console.error('[ERROR INTERNO]', err.message);
            res.status(500).json({ error: 'Error interno del servidor' });
        }
    }
});

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || 'localhost';
app.listen(PORT, HOST, () => {
    console.log(`API corriendo en ${HOST}:${PORT}`);
    console.log(`FRONT en: http://localhost:${process.env.FRONTEND_PORT || 8080}`);
});
