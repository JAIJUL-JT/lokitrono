# Makefile for webapp-publish-all skill

# Variables (can be overridden via environment or command line)
REPO_URL ?= $(shell git config --get remote.origin.url)
SUPABASE_PROJECT ?= my-webapp-db
VERCEL_PROJECT ?= my-webapp-frontend
NOTIFY_EMAIL ?= user@example.com
BACKUP_SERVICE ?= drive

.PHONY: all publish supabase vercel backup github ci

all: publish

# Full publish pipeline
publish: github supabase vercel backup notify

# GitHub repo setup/push
github:
	@cd $(PWD)/../.. && node ./github.js --repo-url $(REPO_URL)

# Supabase backend deployment
supabase:
	@node ./supabase.js --project $(SUPABASE_PROJECT)

# Vercel frontend deployment
vercel:
	@node ./vercel.js --project $(VERCEL_PROJECT)

# Backup assets to Drive or OneDrive
backup:
	@node ./backup.js --service $(BACKUP_SERVICE)

# Send notification email via Gmail
notify:
	@node ./gmail.js --email $(NOTIFY_EMAIL)

# CI helper (used by GitHub Actions)
ci:
	npm ci

# Clean temporary files (if any)
clean:
	rm -rf node_modules/.cache
