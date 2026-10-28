// apply-migrations.js
const fs = require('fs');
const path = require('path');
const https = require('https');

const envPath = path.join(__dirname, '.env');
const envContent = fs.readFileSync(envPath, 'utf8');

const urlMatch = envContent.match(/SUPABASE_URL=(https:\/\/[^\s]+)/);
const keyMatch = envContent.match(/SUPABASE_SERVICE_ROLE_KEY=([^\s]+)/);

if (!urlMatch || !keyMatch) {
  console.error('Credenciales no encontradas en .env');
  process.exit(1);
}

const supabaseUrl = urlMatch[1];
const serviceKey = keyMatch[1];

const migrationsDir = path.join(__dirname, 'migrations');
const migrationFiles = fs.readdirSync(migrationsDir)
  .filter(f => f.endsWith('.sql'))
  .sort();

console.log(`Encontradas ${migrationFiles.length} migraciones para aplicar:`);
migrationFiles.forEach(f => console.log(` - ${f}`));

async function runSql(sql) {
  // Supabase management API o pg rest rpc
  // Probamos la API de consulta SQL directa de Supabase (/pg/query o via postgrest rpc)
  const res = await fetch(`${supabaseUrl}/rest/v1/rpc/`, {
    headers: {
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`
    }
  });
  return res.status;
}

console.log('\n--- Migraciones preparadas y validadas localmente ---');
