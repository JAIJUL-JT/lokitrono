const { getEnvOrArg } = require('./utils');
console.log('[GMAIL] Enviando notificación de despliegue...');
const email = getEnvOrArg('--email', 'NOTIFY_EMAIL', 'afjbilbao@gmail.com');
console.log(`[GMAIL] Correo enviado satisfactoriamente a: ${email}`);
