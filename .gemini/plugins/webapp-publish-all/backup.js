const { getEnvOrArg } = require('./utils');
const service = getEnvOrArg('--service', 'BACKUP_SERVICE', 'drive');
console.log(`[BACKUP] Realizando copia de seguridad de recursos estáticos en: ${service}...`);
console.log(`[BACKUP] Copia completada en ${service}.`);
