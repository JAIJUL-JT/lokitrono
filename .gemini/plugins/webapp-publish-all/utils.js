// utils.js - Helpers comunes y carga de configuración
const fs = require('fs');
const path = require('path');

function getEnvOrArg(flagName, envName, defaultValue = '') {
  const args = process.argv.slice(2);
  const flagIndex = args.indexOf(flagName);
  if (flagIndex !== -1 && args[flagIndex + 1]) {
    return args[flagIndex + 1];
  }
  return process.env[envName] || defaultValue;
}

module.exports = {
  getEnvOrArg
};
