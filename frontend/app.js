const API_URL = 'http://localhost:3000/api';

let currentSession = {
    rol: null,
    vetId: null
};

async function login() {
    const val = document.getElementById('roleSelect').value;
    const [rol, vetIdStr] = val.split(',');
    const vetId = vetIdStr !== 'null' ? vetIdStr : null;

    try {
        const response = await fetch(`${API_URL}/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ rol, vetId })
        });
        const data = await response.json();

        currentSession.rol = data.token.rol;
        currentSession.vetId = data.token.vetId;

        document.getElementById('userInfo').innerText = `Rol activo: ${currentSession.rol} | Vet ID: ${currentSession.vetId || 'N/A'}`;
        document.getElementById('pantalla-login').classList.add('hidden');
        document.getElementById('main-app').classList.remove('hidden');
    } catch (err) {
        console.error('Error al hacer login:', err);
    }
}

function logout() {
    currentSession = { rol: null, vetId: null };
    document.getElementById('pantalla-login').classList.remove('hidden');
    document.getElementById('main-app').classList.add('hidden');
    document.getElementById('userInfo').innerText = '';

    document.getElementById('mascotasTbody').innerHTML = '';
    document.getElementById('vacunasTbody').innerHTML = '';
    document.getElementById('cacheIndicator').className = 'cache-badge hidden';
}

function getHeaders() {
    const headers = { 'Content-Type': 'application/json' };
    if (currentSession.rol) headers['X-Rol'] = currentSession.rol;
    if (currentSession.vetId) headers['X-Vet-Id'] = currentSession.vetId;
    return headers;
}

async function buscarMascotas() {
    const nombre = document.getElementById('searchInput').value;
    try {
        const response = await fetch(`${API_URL}/mascotas?nombre=${encodeURIComponent(nombre)}`, {
            headers: getHeaders()
        });
        const data = await response.json();

        const tbody = document.getElementById('mascotasTbody');
        tbody.innerHTML = '';

        if (data.error) {
            tbody.innerHTML = `<tr><td colspan="3" style="color:red">Error: ${data.error}</td></tr>`;
            return;
        }

        data.forEach(m => {
            tbody.innerHTML += `<tr>
                <td>${m.id}</td>
                <td>${m.nombre}</td>
                <td>${m.especie}</td>
            </tr>`;
        });
    } catch (err) {
        console.error('Error al buscar mascotas:', err);
    }
}

async function consultarVacunacion() {
    try {
        const response = await fetch(`${API_URL}/vacunacion-pendiente`, {
            headers: getHeaders()
        });
        const data = await response.json();

        const tbody = document.getElementById('vacunasTbody');
        tbody.innerHTML = '';
        const indicator = document.getElementById('cacheIndicator');

        if (data.error) {
            tbody.innerHTML = `<tr><td colspan="4" style="color:red">Error: ${data.error}</td></tr>`;
            indicator.className = 'cache-badge hidden';
            return;
        }

        indicator.innerText = data.source;
        indicator.className = `cache-badge ${data.source === 'CACHE HIT' ? 'cache-hit' : 'cache-miss'}`;

        data.data.forEach(v => {
            const fecha = v.fecha_ultima_vacuna ? new Date(v.fecha_ultima_vacuna).toLocaleDateString() : 'N/A';
            tbody.innerHTML += `<tr>
                <td>${v.nombre_mascota} (${v.especie})</td>
                <td>${v.nombre_dueno}</td>
                <td>${fecha}</td>
                <td>${v.prioridad}</td>
            </tr>`;
        });
    } catch (err) {
        console.error('Error al consultar vacunación:', err);
    }
}

async function aplicarVacuna() {
    const mascota_id = document.getElementById('vacMascotaId').value;
    const vacuna_id = document.getElementById('vacVacunaId').value;

    if (!mascota_id || !vacuna_id) {
        alert("Llena los IDs para aplicar vacuna");
        return;
    }

    try {
        const response = await fetch(`${API_URL}/vacunas`, {
            method: 'POST',
            headers: getHeaders(),
            body: JSON.stringify({
                mascota_id: parseInt(mascota_id, 10),
                vacuna_id: parseInt(vacuna_id, 10),
                costo_cobrado: 500.00
            })
        });

        const data = await response.json();
        if (data.error) {
            alert(`Error: ${data.error}`);
        } else {
            alert(`Vacuna aplicada! ID: ${data.id}`);
            consultarVacunacion();
        }
    } catch (err) {
        console.error('Error al aplicar vacuna:', err);
    }
}
