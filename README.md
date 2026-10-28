# Proyecto **Lokitrono** – Publicación automática

Esta guía está escrita en **español (España)** y detalla el sistema de despliegue y pruebas automatizadas configurado para el proyecto usando exclusivamente herramientas gratuitas (Supabase, GitHub, Vercel, Gmail, Google Drive, OneDrive) junto a la skill `webapp-publish-all`.

---

## 📁 Estructura del proyecto
```
C:\Users\usuario\proyectos\lokitrono
│   README.md                # Guía y estado de checklist
│   publish-config.json      # Configuración de entornos y proyectos
│   Makefile                 # Comandos unificados (test, publish, ci)
│   .gitignore               # Protección contra filtración de claves (.env)
│   .env.example             # Plantilla de variables de entorno
│   .env                     # Credenciales locales (protegido, no commiteado)
│
├─ .github
│   └─ workflows
│       └─ publish.yml       # Pipeline CI/CD en GitHub Actions con tests
│
└─ .gemini
    └─ plugins
        └─ webapp-publish-all
            ├─ test.js               # Suite de tests automatizados
            ├─ publish-webapp.js     # Orquestador del despliegue
            ├─ github.js             # Sincronización Git / GitHub
            ├─ supabase.js           # Migraciones y Backend Supabase
            ├─ vercel.js             # Despliegue Frontend Vercel
            ├─ gmail.js              # Notificaciones por correo
            ├─ backup.js             # Copias de seguridad (Drive / OneDrive)
            ├─ utils.js              # Utilidades de entorno y argumentos
            ├─ package.json          # Configuración y script de test
            ├─ Makefile              # Comandos internos de la skill
            └─ n8n_publish_workflow.json  # Workflow listo para importar en n8n
```

---

## 🧪 Tests Automatizados

Se ha integrado un ejecutor de pruebas en [test.js](file:///C:/Users/usuario/proyectos/lokitrono/.gemini/plugins/webapp-publish-all/test.js) que valida:
1. **Presencia de módulos críticos:** Valida que todos los componentes (`github.js`, `supabase.js`, `vercel.js`, `gmail.js`, `backup.js`, `publish-webapp.js`) existan.
2. **Integridad del Workflow n8n:** Verifica que el archivo JSON de n8n sea válido y cuente con los nodos esenciales (GitHub Trigger, Ejecución Make y Gmail).
3. **Consistencia de Configuración:** Comprueba que `publish-config.json` posea las propiedades requeridas para los servicios gratuitos.

Para correr los tests en local:
```powershell
cd C:\Users\usuario\proyectos\lokitrono
make test
```

---

## 🚀 Flujo de Publicación (Make & CI)

El comando `make publish` ejecuta primero la suite de tests y, si es satisfactoria, procede con la orquestación secuencial:

```powershell
cd C:\Users\usuario\proyectos\lokitrono
make publish
```

---

## ✅ Checklist Final

Todas las fases de preparación, tests e infraestructura han quedado ejecutadas y validadas:

- [x] **Skill copiada e instalada** en `C:\Users\usuario\proyectos\lokitrono\.gemini\plugins\webapp-publish-all`.
- [x] **Tests automatizados creados y validados** (`test.js` pasa con éxito todos los checks de componentes, n8n y configuración).
- [x] **Ficheros de entorno creados**: `.env` configurado localmente y `.env.example` añadido como plantilla segura.
- [x] **Seguridad configurada**: `.gitignore` añadido para proteger `.env` y credenciales privadas.
- [x] **Integración Continua (CI) preparada**: `.github/workflows/publish.yml` configurado para ejecutar tests y desplegar en GitHub Actions.
- [x] **Workflow n8n generado**: `n8n_publish_workflow.json` listo para automatizaciones por webhook o triggers.
- [x] **Repositorio Git inicializado**: Primer commit generado localmente con todos los componentes, tests y configuraciones.
- [x] **Prueba integral de publicación ejecutada con éxito**: Flujo verificado de principio a fin (Tests → GitHub → Supabase → Vercel → Backup → Gmail).
