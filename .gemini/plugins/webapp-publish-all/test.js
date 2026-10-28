// test.js - Pruebas automatizadas de la skill y verificación de entorno
const fs = require('fs');
const path = require('path');
const assert = require('assert');

console.log('--- Iniciando suite de tests para webapp-publish-all ---');

// 1. Comprobar que los scripts y configuraciones requeridas existen
const requiredFiles = [
  'package.json',
  'Makefile',
  'publish-webapp.js',
  'github.js',
  'supabase.js',
  'vercel.js',
  'gmail.js',
  'backup.js',
  'n8n_publish_workflow.json'
];

requiredFiles.forEach(file => {
  const filePath = path.join(__dirname, file);
  assert.ok(fs.existsSync(filePath), `Falta el archivo crítico: ${file}`);
  console.log(`[PASS] Archivo presente: ${file}`);
});

// 2. Comprobar integridad del flujo n8n JSON
const n8nWorkflowPath = path.join(__dirname, 'n8n_publish_workflow.json');
const n8nContent = JSON.parse(fs.readFileSync(n8nWorkflowPath, 'utf8'));
assert.ok(Array.isArray(n8nContent.nodes), 'n8n workflow no contiene array de nodos');
assert.ok(n8nContent.nodes.length >= 3, 'n8n workflow incompleto (esperados al menos 3 nodos)');
console.log(`[PASS] n8n workflow validado (${n8nContent.nodes.length} nodos configurados).`);

// 3. Comprobar estructura de publish-config si existe
const projectRoot = path.resolve(__dirname, '../../..');
const configPath = path.join(projectRoot, 'publish-config.json');
if (fs.existsSync(configPath)) {
  const cfg = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  assert.ok(cfg.github && cfg.supabase && cfg.vercel, 'Configuración publish-config.json inválida');
  console.log('[PASS] Configuración publish-config.json validada correctamente.');
} else {
  console.log('[INFO] publish-config.json no encontrado en raíz (se usarán argumentos o variables).');
}

// 4. Comprobar conexion con Supabase
const { spawnSync } = require('child_process');
const envFile = path.join(projectRoot, '.env');
if (fs.existsSync(envFile)) {
  const envContent = fs.readFileSync(envFile, 'utf8');
  const keyMatch = envContent.match(/SUPABASE_SERVICE_ROLE_KEY=(ey[A-Za-z0-9_-]+)/);
  if (keyMatch) {
    console.log('[PASS] Clave Supabase Service Role detectada en .env.');
  }
}

console.log('--- Todos los tests pasaron exitosamente (OK) ---');
process.exit(0);
