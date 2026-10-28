# AUDIT_PLATFORM.md: Auditoría Técnica y Operativa de LokiTrono

**Fecha de ejecución:** 2026-10-28  
**Objetivo:** Identificar el estado real del sistema, activos en uso, elementos huérfanos, deuda técnica y dependencias para orientar la plataforma hacia un modelo SaaS comercializable con clientes reales.

---

## 1. Tablas Utilizadas vs. Tablas Sin Uso

A partir de la inspección OpenAPI de Supabase (44 tablas activas):

### 1.1 Tablas en Uso Activo (Core y Plataforma - 32 tablas):
- **Competición y Rankings:** `votos`, `votos_evento`, `clasificacion_barrios`, `orden_sorteo_barrios`.
- **Territorio y Cobertura:** `barrios`, `distritos`, `ciudades`, `provincias`, `comunidades`, `codigos_postales`, `codigo_postal_ciudad`.
- **Autenticación y Seguridad:** `authorized_users`, `sesiones_lokitrono`, `intentos_acceso`, `maestres`.
- **Juego y Recompensas Base:** `juegos`, `estado_juego`, `piezas_puzzle`, `configuracion_reino`, `config_gala_final`, `codigos_diarios`, `locales_promocion`, `eventos`.
- **Plataforma Multicampaña (Fases 1 a 6):** `templates`, `campaigns`, `campaign_theme`, `campaign_settings`, `campaign_entities`, `campaign_rewards`, `hub_events`, `event_missions`, `user_mission_progress`, `tourist_routes`, `route_stops`, `marketplace_packages`.

### 1.2 Tablas Sin Uso / Candidatas a Deprecación o Consolidación (12 tablas):
- `juicios`: Tabla heredada de versiones preliminares del juego medieval de barrios sin flujo activo en la webapp actual.
- `casas`: Modelo estático con funciones RPC duplicadas (`crear_casa_superadmin`, `editar_casa_superadmin`). Puede consolidarse dentro de `campaign_entities` con tipo `casa`.
- `lokibot_consultas`: Registro de un bot experimental no conectado al flujo comercial actual.
- `event_affiliations`: Tabla creada pero sin tráfico real ni enlaces de conversión configurados.
- `event_sync_logs`: Sin jobs recurrentes activos de ingesta de datos.
- `external_event_sources`: Creada pero sin conectores activos contra APIs de terceros.
- `mission_checkins`: Creada para gamificación presencial, pendiente de integrar con el lector de cámara del móvil.
- `user_route_completions`: Pendiente de consumo por el frontend.
- `campaign_installations`: Sin registros de instalaciones de plantillas aún.

---

## 2. Endpoints y RPCs Sin Uso / Sobredimensionados

De las **63 funciones RPC** inspeccionadas:
- **En uso directo:** `emitir_voto`, `emitir_voto_lokitrono`, `calcular_ranking`, `validar_login_lokitrono`, `cerrar_sesion_lokitrono`, `juego_oficial_activo`.
- **Duplicadas o redundantes:**
  - `admin_crear_usuario` vs `crear_usuario_superadmin`
  - `admin_editar_usuario` vs `editar_usuario_superadmin`
  - `admin_borrar_usuario` vs `eliminar_usuario_superadmin`
  - `admin_crear_juego` vs `admin_guardar_juego_activo`
- **Sin uso activo:** Funciones de galas y sorteos específicos (`sortear_piezas_puzzle_superadmin`, `guardar_orden_sorteo_barrios_superadmin`, `gala_final_config_actual`).

---

## 3. Componentes y Código Frontend Sin Uso

- **Frontend actual:** [`public/index.html`](file:///C:/Users/usuario/proyectos/lokitrono/public/index.html) agrupa toda la interfaz en un único archivo monolítico accesible.
- **Componentes huérfanos:** No hay componentes React/Next.js activos en el árbol del proyecto; el frontend se compila como HTML plano servido por Vercel.
- **Scripts residuales locales:** Se han eliminado scripts de diagnóstico temporales para mantener la raíz limpia.

---

## 4. Deuda Técnica y Consultas Lentas

1. **Monolito en Frontend:** La lógica de rutas, eventos, misiones y marketplace reside en un único fichero HTML/JS. Para escalar hacia multicliente necesitará un router ligero o framework moderno (ej. Next.js / Astro / Vite).
2. **Caché de Esquema Supabase:** Al aplicar migraciones DDL manuales, el PostgREST cachea el schema y puede tardar hasta 30 segundos en reflejar nuevas tablas en `/rest/v1/`.
3. **Consultas a optimizar:** La vista `clasificacion_barrios` calcula agrupaciones sobre la tabla completa de `votos`. Si el volumen de votos crece en campañas grandes, requerirá una tabla agregada o vista materializada con refresco periódico.

---

## 5. Auditoría de Dependencias

- **Node.js:** v20.18.0 LTS (Actualizado y seguro).
- **Herramientas locales:** Bun v1.3.14, Vercel CLI 65.4.0, Supabase CLI 2.122.0.
- **Paquetes npm en la skill:** Sin vulnerabilidades críticas detectadas (`npm audit` limpio).
- **CDNs externas en frontend:** Tailwind CSS CDN y FontAwesome 6.4.0. Se recomienda empaquetar localmente para producción comercial para evitar latencias de red externas.
