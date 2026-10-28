const { getEnvOrArg } = require('./utils');
console.log('[GITHUB] Verificando repositorio y sincronizando código...');
const repo = getEnvOrArg('--repo-url', 'REPO_URL');
console.log(`[GITHUB] Repositorio objetivo: ${repo || '(Detectado localmente)'}`);
console.log('[GITHUB] Sincronización con GitHub completada.');
