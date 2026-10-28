# Proyecto **Lokitrono** – Publicación automática

Esta guía está escrita en **español (España)** y detalla paso a paso cómo configurar y publicar la webapp usando únicamente los servicios gratuitos que ya tienes (Supabase, GitHub, Vercel, Gmail, Google Drive, OneDrive) y la **skill** `webapp-publish-all` que hemos creado.

---

## 📁 Estructura del proyecto
```
C:\Users\usuario\proyectos\lokitrono
│   README.md                # ← este archivo
│   publish-config.json      # configuración por defecto
│   Makefile                 # comandos rápidos
│
├─ .github
│   └─ workflows
│       └─ publish.yml       # CI de GitHub Actions
│
└─ .gemini
    └─ plugins
        └─ webapp-publish-all   # la skill (copiada desde el brain)
```

> **Nota**: La carpeta `.gemini/plugins/webapp-publish-all` contiene todos los scripts (`publish-webapp.js`, `github.js`, `supabase.js`, …) necesarios para el despliegue.

---

## 1️⃣ Preparación inicial

1. **Clona o crea el repositorio** en GitHub (si aún no lo tienes).  
   ```powershell
   git init
   git remote add origin git@github.com:TU_USUARIO/lokitrono.git
   ```
2. **Copia la skill** dentro del proyecto:
   ```powershell
   md .gemini\plugins
   xcopy "C:\Users\usuario\.gemini\antigravity-cli\brain\8127a26a-06a0-4f41-8efc-ca24d28bc2af\webapp_publish_skill" "C:\Users\usuario\proyectos\lokitrono\.gemini\plugins\webapp-publish-all" /E /I /Y
   ```
3. **Instala las dependencias** (Node 20+ debe estar instalado):
   ```powershell
   cd C:\Users\usuario\proyectos\lokitrono\.gemini\plugins\webapp-publish-all
   npm ci
   ```
4. **Crea el fichero `.env`** en la raíz del proyecto (no se versiona).  Usa tus tokens y claves de cada servicio:
   ```dotenv
   GITHUB_TOKEN=xxxxxxxxxxxxxxxxxxxx
   SUPABASE_URL=https://xxxx.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=xxxxxxxxxxxxxxxxxxxx
   VERCEL_TOKEN=xxxxxxxxxxxxxxxxxxxx
   GMAIL_CLIENT_ID=xxxxxxxxxxxxxxxxxxxx
   GMAIL_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxx
   GMAIL_REFRESH_TOKEN=xxxxxxxxxxxxxxxxxxxx
   DRIVE_REFRESH_TOKEN=xxxxxxxxxxxxxxxxxxxx   # si usas Google Drive
   ONEDRIVE_REFRESH_TOKEN=xxxxxxxxxxxxxxxxxxxx   # si usas OneDrive
   ```

---

## 2️⃣ Configuración por defecto (`publish-config.json`)

Puedes editar este archivo para evitar pasar parámetros en la línea de comandos.  Un ejemplo ya está incluido:

```json
{
  "github": {
    "owner": "TU_USUARIO",
    "repo": "lokitrono"
  },
  "supabase": {
    "project": "lokitrono-db"
  },
  "vercel": {
    "project": "lokitrono-frontend"
  },
  "notifications": {
    "email": "tu@email.com"
  },
  "backup": {
    "service": "drive",
    "folderId": "1A2B3C4D5E"
  }
}
```

---

## 3️⃣ Uso local con **Make**

El `Makefile` del proyecto delega en la skill:

```make
# Makefile – proyecto lokitrono

.PHONY: publish ci

# Ruta absoluta a la skill (no cambiar a menos que la muevas)
SKILL_PATH := $(CURDIR)\.gemini\plugins\webapp-publish-all

publish:
	@cd $(SKILL_PATH) && \
		make publish REPO_URL=git@github.com:TU_USUARIO/lokitrono.git \
		SUPABASE_PROJECT=lokitrono-db \
		VERCEL_PROJECT=lokitrono-frontend \
		NOTIFY_EMAIL=tu@email.com \
		BACKUP_SERVICE=drive

ci:
	@cd $(SKILL_PATH) && npm ci
```

### Ejecutar
```powershell
cd C:\Users\usuario\proyectos\lokitrono
make publish      # despliega todo de una vez
``` 

---

## 4️⃣ CI con **GitHub Actions**

Añade este archivo (`.github/workflows/publish.yml`) al repositorio:

```yaml
name: Publicar webapp

on:
  push:
    branches: [ main ]

jobs:
  publicar:
    runs-on: ubuntu-latest
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
      SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
      VERCEL_TOKEN: ${{ secrets.VERCEL_TOKEN }}
      GMAIL_CLIENT_ID: ${{ secrets.GMAIL_CLIENT_ID }}
      GMAIL_CLIENT_SECRET: ${{ secrets.GMAIL_CLIENT_SECRET }}
      GMAIL_REFRESH_TOKEN: ${{ secrets.GMAIL_REFRESH_TOKEN }}
      DRIVE_REFRESH_TOKEN: ${{ secrets.DRIVE_REFRESH_TOKEN }}   # opcional
      ONEDRIVE_REFRESH_TOKEN: ${{ secrets.ONEDRIVE_REFRESH_TOKEN }}   # opcional
    steps:
      - uses: actions/checkout@v4

      - name: Instalar Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Instalar dependencias de la skill
        run: |
          cd .gemini/plugins/webapp-publish-all
          npm ci

      - name: Publicar webapp
        run: |
          cd .gemini/plugins/webapp-publish-all
          make publish REPO_URL=${{ github.repositoryUrl }}
```

> **Importante**: Añade todos los *secrets* citados en la sección **Settings → Secrets and variables → Actions** del repositorio.

---

## 5️⃣ Automatización con **n8n** (opcional)

Si dispones de una instancia gratuita de n8n, importa el archivo `n8n_publish_workflow.json` que hemos creado (se encuentra en la carpeta de la skill).  Configura las siguientes variables de entorno en n8n:

| Variable | Valor de ejemplo |
|----------|-------------------|
| `GITHUB_REPO` | `TU_USUARIO/lokitrono` |
| `WEBAPP_ROOT` | `C:/Users/usuario/proyectos/lokitrono` |
| `GMAIL_USER` | `tu@email.com` |
| `NOTIFY_EMAIL` | `destinatario@email.com` |

El workflow se disparará cada vez que haya un **push** a GitHub y ejecutará `make publish`.

---

## 6️⃣ Resumen rápido de comandos
| Acción | Comando |
|--------|---------|
| **Instalar dependencias** | `cd .gemini/plugins/webapp-publish-all && npm ci` |
| **Publicar manualmente** | `make publish` (desde la raíz del proyecto) |
| **Ejecutar CI** | `git push origin main` – GitHub Actions lo hará automáticamente |
| **Desplegar con n8n** | *Push → n8n → make publish* |

---

## 🛠️ ¿Problemas?
- **Credenciales faltantes** → revisa el fichero `.env` y los *secrets* de GitHub.
- **Error en Supabase** → asegúrate de que el proyecto exista y que la clave `SERVICE_ROLE` tenga permisos de *admin*.
- **Vercel no detecta el repo** → en el dashboard de Vercel enlaza manualmente el proyecto con el repositorio y vuelve a ejecutar `make publish`.
- **Backup fallido** → verifica que el `folderId` de Drive o el token de OneDrive sean correctos.

¡Listo! Con estos pasos podrás desarrollar en **c:\users\usuario\proyectos\lokitrono** y publicar tu aplicación de forma totalmente automática y sin costes adicionales.
