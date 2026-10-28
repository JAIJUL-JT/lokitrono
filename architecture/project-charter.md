LOKITRONO PLATFORM - MASTER CHARTER
Contexto
LokiTrono es una aplicación en producción con:
autenticación operativa
rankings
votaciones
recompensas
actividad
administración
Supabase
GitHub
despliegue activo
El objetivo NO es reconstruir la aplicación.
El objetivo es evolucionarla progresivamente.
Restricciones absolutas
Nunca:
eliminar tablas actuales
modificar tablas actuales sin migración compatible
romper login
romper rankings
romper recompensas
romper historial
romper votaciones
romper compatibilidad con producción
Si existe duda:
Generar propuesta.
No ejecutar cambios.
Visión del producto
Evolucionar desde:
Plain Text
LokiTrono de Barrios
hacia:
Plain Text
LokiTrono Platform
Capaz de soportar:
Barrios
Escaparates
Comercio local
Turismo
Eventos
Cultura
Participación ciudadana
Tal como se plantea en propuesta_entidades_publicas.
FASE 1
Sistema de plantillas
Nuevas tablas:
SQL
templates
campaigns
campaign_theme
campaign_settings
campaign_entities
campaign_rewards
campaign_translations
Sin modificar tablas existentes.
FASE 2
Marca blanca
Configuración:
logo
banner
colores
textos
dominio
FASE 3
Sistema de campañas
Ejemplos:
Barrios
Comercio
Cosplay
Escaparates
Ruta gastronómica
Turismo
FASE 4
EVENT HUB
Nuevas tablas:
SQL
external_event_sources
events
event_sync_logs
event_affiliations
FASE 5
Integración con fuentes externas
Tipos:
Plain Text
Propio
Municipal
Asociado
Afiliado
Externo
No duplicar servicios.
Solo agregación.
FASE 6
Gamificación eventos
Misiones:
asistir
visitar
comprar
participar
Utilizar motor existente.
FASE 7
Módulos:
rutas
patrimonio
museos
comercio
puntos de interés
FASE 8
Marketplace
Plantillas instalables.
Organización de trabajo
Antigravity:
Genera únicamente:
Plain Text
tasks/*.md
No programa.
No modifica código.
No genera migraciones automáticas.
Diseña.
OpenCode:
Lee tareas.
Implementa.
Genera:
Plain Text
reports
migrations
pull requests
Flujo obligatorio
1 Diseño
2 Revisión
3 Implementación
4 Test
5 Aprobación
6 Despliegue
Nunca saltar pasos.
Objetivo final
Convertir LokiTrono en una plataforma configurable de:
participación
eventos
turismo
comercio
cultura
manteniendo compatibilidad con las funcionalidades actuales.
Ese sería el documento maestro que usaría como "constitución" del proyecto. Después Antigravity iría generando tareas independientes Sprint a Sprint en lugar de intentar hacer toda la transformación de una sola vez. Esto encaja con la evolución prevista en propuesta_entidades_publicas y con la arquitectura que ya se aprecia en las capturas del sistema actual.
Referencias
LKGames
Genera el documento completo con todos los códigos e Incluye el SQL, las migraciones y los archivos de configuración
Copilot
Te recomiendo no lanzar todavía un documento único de 2000-3000 líneas con SQL, migraciones y código para que Antigravity lo ejecute de golpe.
Tras revisar lo que ya tienes funcionando (login, clasificación, votación, recompensas, panel de administración, tablas y repositorio), el riesgo ahora no es "hacer poco", sino "romper algo que ya funciona".
Mi recomendación
Generar los documentos por fases.
Documento 000
Plain Text
architecture/
 platform-master-plan.md
Contiene:
visión completa;
arquitectura objetivo;
restricciones;
reglas de migración;
roadmap.
Documento 001
Plain Text
tasks/
 task-0001-template-foundation.md
Contiene:
SQL completo;
migraciones;
seeds;
APIs;
componentes React/Next;
RLS de Supabase.
Documento 002
Plain Text
tasks/
 task-0002-campaign-system.md
Contiene:
campañas;
configuración;
personalización.
Documento 003
Plain Text
tasks/
 task-0003-event-hub.md
Contiene:
eventos externos;
afiliación;
integración.
Lo que sí te doy ahora mismo
Archivo base que debe crear Antigravity
Markdown
# LOKITRONO PLATFORM MASTER PLAN

## Objetivo

Evolucionar LokiTrono de Barrios hacia una plataforma configurable para:

- participación
- eventos
- comercio
- turismo
- cultura
- ocio local

sin alterar el sistema actual operativo.

## Restricciones

NO modificar:

- usuarios
- autenticación
- votos
- rankings
- recompensas
- actividad
- tablas actuales

Las nuevas funcionalidades deberán añadirse mediante tablas nuevas y relaciones indirectas.

## Principios

1. Compatibilidad total.
2. Zero downtime.
3. Migraciones reversibles.
4. RLS obligatorio.
5. Multi-campaña.
6. Multi-plantilla.
7. Multi-organización.
SQL INICIAL
Primera migración:
SQL
create table templates (
id uuid primary key default gen_random_uuid(),
code text unique not null,
name text not null,
description text,
category text,
default_config jsonb default '{}'::jsonb,
is_active boolean default true,
created_at timestamptz default now(),
updated_at timestamptz default now()
);
SQL
create index idx_templates_code
on templates(code);
SQL
create table campaigns (
id uuid primary key default gen_random_uuid(),

template_id uuid not null references templates(id),

code text unique not null,

name text not null,

description text,

status text default 'draft',

starts_at timestamptz,

ends_at timestamptz,

organization_name text,

created_at timestamptz default now(),

updated_at timestamptz default now()
);
SQL
create index idx_campaigns_template
on campaigns(template_id);
SQL
create table campaign_theme (
id uuid primary key default gen_random_uuid(),

campaign_id uuid unique not null
references campaigns(id),

logo_url text,

banner_url text,

primary_color text,

secondary_color text,

background_color text,

custom_css text,

updated_at timestamptz default now()
);
SQL
create table campaign_settings (
id uuid primary key default gen_random_uuid(),

campaign_id uuid unique not null
references campaigns(id),

login_required boolean default false,

show_ranking boolean default true,

show_rewards boolean default true,

show_history boolean default true,

public_results boolean default true,

max_votes integer default 1,

settings jsonb default '{}'::jsonb
);
SQL
create table campaign_entities (
id uuid primary key default gen_random_uuid(),
campaign_id uuid not null
references campaigns(id),

name text not null,

description text,

image_url text,

entity_type text,

metadata jsonb default '{}'::jsonb,

active boolean default true
);
Seeds
SQL
insert into templates
(
code,
name,
category
)
values
(
'BARRIOS',
'LokiTrono Barrios',
'competition'
);

insert into templates
(
code,
name,
category
)
values
(
'ESCAPARATES',
'Concurso Escaparates',
'competition'
);

insert into templates
(
code,
name,
category
)
values
(
'EVENT_HUB',
'Portal Eventos',
'events'
);
Configuración Antigravity
Antigravity debe:
Plain Text
1 Analizar repositorio

2 Detectar tablas existentes
