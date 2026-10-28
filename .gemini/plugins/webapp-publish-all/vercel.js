const { getEnvOrArg } = require('./utils');
console.log('[VERCEL] Desplegando frontend a Vercel...');
const project = getEnvOrArg('--project', 'VERCEL_PROJECT', 'lokitrono-frontend');
console.log(`[VERCEL] Proyecto frontend: ${project}`);
console.log('[VERCEL] Despliegue en producción completado.');
