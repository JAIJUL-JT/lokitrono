// publish-webapp.js - Orquestador principal
const { spawnSync } = require('child_process');
const path = require('path');

console.log('=== Iniciando publicación completa de Lokitrono ===');

// Detectar el binario disponible (bun o node)
const runtime = process.argv[0];

const steps = [
  { name: 'Tests', script: 'test.js' },
  { name: 'GitHub', script: 'github.js' },
  { name: 'Supabase', script: 'supabase.js' },
  { name: 'Vercel', script: 'vercel.js' },
  { name: 'Backup', script: 'backup.js' },
  { name: 'Notificación Gmail', script: 'gmail.js' }
];

for (const step of steps) {
  console.log(`\n>> Ejecutando fase: ${step.name}...`);
  const result = spawnSync(runtime, [path.join(__dirname, step.script)], { stdio: 'inherit' });
  if (result.status !== 0) {
    console.error(`Fallo en el paso: ${step.name}`);
    process.exit(result.status || 1);
  }
}

console.log('\n=== ¡Publicación finalizada con éxito total! ===');
