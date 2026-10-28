# Makefile – Proyecto Lokitrono

SKILL_PATH := $(CURDIR)/.gemini/plugins/webapp-publish-all

.PHONY: all test publish ci

all: test publish

# Ejecuta suite de tests de validación y estructura
test:
	@cd $(SKILL_PATH) && (bun test.js 2>nul || node test.js)

# Orquesta el pipeline completo de publicación
publish: test
	@cd $(SKILL_PATH) && (bun publish-webapp.js 2>nul || node publish-webapp.js)

# Instalación / preparación de dependencias
ci:
	@cd $(SKILL_PATH) && (bun install 2>nul || npm ci)
