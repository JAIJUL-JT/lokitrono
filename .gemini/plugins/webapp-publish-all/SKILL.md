---
name: webapp-publish-all
description: >-
  Skill to orchestrate publishing a web application using free tiers of Supabase, GitHub, Vercel, Gmail, Google Drive, and OneDrive.
  It automates repo setup, Supabase backend deployment, Vercel frontend deployment, and optional notifications and asset backups.
---

# Overview

This skill provides a **single command-line entry point** (`publish-webapp`) that:

1. **Initialises / updates** a GitHub repository (creates if missing).
2. **Configures Supabase** project (creates a project, applies migrations, uploads storage assets).
3. **Deploys the frontend** to Vercel (creates a Vercel project linked to the repo).
4. **Sends a deployment summary** via Gmail.
5. **Backs up static assets** to Google Drive **or** OneDrive (user selects).

All operations use the **free tiers** of the respective services and require only the API tokens/credentials the user already has.

# Prerequisites

- **GitHub Personal Access Token** with `repo` and `workflow` scopes (`GITHUB_TOKEN`).
- **Supabase CLI** installed (`supabase`).
- **Supabase Project URL & Service Role Key** (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`).
- **Vercel CLI** installed (`vercel`).
- **Vercel Token** (`VERCEL_TOKEN`).
- **Gmail OAuth credentials** (`GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET`, `GMAIL_REFRESH_TOKEN`).
- **Google Drive API token** (`DRIVE_REFRESH_TOKEN`) *or* **OneDrive token** (`ONEDRIVE_REFRESH_TOKEN`).
- **Node.js 20+** (or any runtime you prefer).

> [!NOTE] These environment variables can be stored securely in a `.env` file at the root of your project and loaded with `dotenv`.

# Installation

```bash
# Clone this skill repository (or copy the folder into your plugins directory)
mkdir -p $HOME/.gemini/plugins/webapp-publish-all
cp -r "C:/Users/usuario/.gemini/antigravity-cli/brain/8127a26a-06a0-4f41-8efc-ca24d28bc2af/webapp_publish_skill" "$HOME/.gemini/plugins/webapp-publish-all"
```

# Usage

```bash
# From your webapp project root
publish-webapp \
  --repo-url git@github.com:username/my-webapp.git \
  --supabase-project my-webapp-db \
  --vercel-project my-webapp-frontend \
  --notify-email user@example.com \
  --backup-drive drive   # options: drive | onedrive | none
```

The command performs the following steps (see the source script for details):

1. **GitHub** – creates the repository if it does not exist, pushes the current commit, and enables Vercel Git Integration.
2. **Supabase** – runs `supabase init` (if needed), applies migrations (`supabase db push`), and uploads any files in `./supabase/storage/`.
3. **Vercel** – runs `vercel link` or `vercel project add` and then `vercel deploy --prod`.
4. **Gmail** – sends an email with a summary that includes the GitHub URL, Supabase console link, and Vercel deployment URL.
5. **Backup** – copies the `public/` folder (or any user‑specified directory) to Google Drive **or** OneDrive using the respective APIs.

# Configuration File (`publish-config.json`)

You can store defaults in a JSON file at the project root:

```json
{
  "github": {
    "owner": "username",
    "repo": "my-webapp"
  },
  "supabase": {
    "project": "my-webapp-db"
  },
  "vercel": {
    "project": "my-webapp-frontend"
  },
  "notifications": {
    "email": "user@example.com"
  },
  "backup": {
    "service": "drive",
    "folderId": "1A2B3C4D5E"
  }
}
```

Running `publish-webapp` without flags will read this file.

# Implementation Details

The skill ships with the following files (all under the skill folder):

- `publish-webapp.js` – entry point (Node.js script).
- `github.js` – thin wrapper around `@actions/github` API.
- `supabase.js` – uses `supabase-cli` via child process.
- `vercel.js` – uses `vercel` CLI.
- `gmail.js` – sends email via `googleapis`.
- `drive.js` / `onedrive.js` – upload helpers.
- `utils.js` – common helpers (logging, env loading).
- `package.json` – declares dependencies (`@actions/github`, `googleapis`, `node-fetch`, etc.).

All dependencies are **free** and installable with `npm i`.

# Security & Secrets

- Never commit the `.env` file.
- Use GitHub Secrets for CI/CD pipelines if you run this from GitHub Actions.
- The skill includes a helper to load secrets from the environment at runtime.

# Extensibility

- Add other backup services by creating a new module that implements `uploadDirectory(sourcePath, targetPath)`.
- Extend the notification step to Slack, Discord, or Teams by adding a small wrapper.

# License

MIT – free for any commercial or non‑commercial use.

---

**Next steps**
1. Place this folder in your `C:\Users\usuario\.gemini\plugins\` directory.
2. Run `npm install` inside the skill folder.
3. Ensure all required environment variables are set.
4. Execute `publish-webapp` from your webapp project.

If you need any adjustments (e.g., custom backup locations, additional services, or CI integration), let me know and I can update the skill.
