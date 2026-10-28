// inspect-db.js
const fs = require('fs');
const path = require('path');

const envPath = path.join(__dirname, '.env');
const envContent = fs.readFileSync(envPath, 'utf8');

const urlMatch = envContent.match(/SUPABASE_URL=(https:\/\/[^\s]+)/);
const keyMatch = envContent.match(/SUPABASE_SERVICE_ROLE_KEY=([^\s]+)/);

if (!urlMatch || !keyMatch) {
  console.error('No se encontraron credenciales de Supabase en .env');
  process.exit(1);
}

const supabaseUrl = urlMatch[1];
const serviceKey = keyMatch[1];

async function inspect() {
  console.log('--- Conectando a Supabase REST OpenAPI ---');
  try {
    const res = await fetch(`${supabaseUrl}/rest/v1/`, {
      headers: {
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`
      }
    });

    const data = await res.json();
    console.log('Swagger API version:', data.swagger);
    console.log('API Info:', data.info ? data.info.title : 'N/A');

    const tables = Object.keys(data.definitions || {});
    console.log(`\nTablas y vistas detectadas en la base de datos (${tables.length}):`);
    tables.forEach(t => console.log(` - ${t}`));

    const paths = Object.keys(data.paths || {}).filter(p => p !== '/');
    console.log(`\nRutas REST disponibles (${paths.length}):`);
    paths.forEach(p => console.log(` - ${p}`));

  } catch (err) {
    console.error('Error al inspeccionar base de datos:', err);
  }
}

inspect();
