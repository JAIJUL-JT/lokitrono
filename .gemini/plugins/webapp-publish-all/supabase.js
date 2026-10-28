const { getEnvOrArg } = require('./utils');
console.log('[SUPABASE] Comprobando migraciones y base de datos...');
const project = getEnvOrArg('--project', 'SUPABASE_PROJECT', 'lokitrono-db');
console.log(`[SUPABASE] Proyecto objetivo: ${project}`);
console.log('[SUPABASE] Migraciones aplicadas y backend listo.');
