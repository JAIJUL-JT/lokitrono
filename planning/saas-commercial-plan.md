# PLAN MAESTRO: LOKITRONO SAAS MULTICLIENTE (TRANSICIÓN COMERCIAL)

**Misión de Antigravity:**  
> **"No desarrollar más funcionalidades. Diseñar el plan para convertir LokiTrono en un SaaS multicliente comercializable. Objetivo: conseguir el primer cliente real (piloto)."**

---

## 1. FASE B: Demos Comerciales (Verticales de Venta)

Para presentar la plataforma a ayuntamientos y asociaciones sin desarrollar código nuevo, se configuran 5 perfiles temáticos usando las tablas `templates`, `campaigns` y `campaign_theme`:

| Vertical | Nombre de Demo | Propuesta de Valor para el Cliente | Elementos Clave |
| :--- | :--- | :--- | :--- |
| **Comercio Local** | `DEMO_COMERCIO_LOCAL` | Dinamización del comercio de barrio con compras gamificadas. | Sellos QR en tiendas, bonos descuento, ranking de comercios más votados. |
| **Escaparates** | `DEMO_ESCAPARATES` | Concurso popular de escaparates navideños o de temporada. | Galería fotográfica, votación pública (1 voto/usuario), resultados en gala final. |
| **Turismo** | `DEMO_TURISMO` | Circuitos y senderos inteligentes para visitantes. | Rutas geolocalizadas, paradas con audioguías, misiones de visita patrimonial. |
| **Festivales** | `DEMO_FESTIVALES` | Agenda y participación en eventos culturales masivos. | Conciertos, mapas de escenarios, check-ins de asistencia, notificaciones. |
| **Cultura** | `DEMO_CULTURA` | Gymkanas interactivas en museos y cascos históricos. | Preguntas de historia local, pistas en estatuas/plazas, diploma virtual. |

---

## 2. FASE C: Arquitectura Multicliente (Aislamiento de Organizaciones)

Diseño conceptual para operar clientes aislados bajo una misma infraestructura de Supabase:

```
[Organización: Ayuntamiento Bilbao]   ---> Campaña: "Aste Nagusia 2026"  (Dominio: bilbao.lokitrono.com)
[Organización: Ayuntamiento Barakaldo]---> Campaña: "Ruta del Pintxo"     (Dominio: barakaldo.lokitrono.com)
[Organización: Asociación Comercios]  ---> Campaña: "Black Friday Local"  (Dominio: comercios.lokitrono.com)
[Organización: Promotor Privado]      ---> Campaña: "Festival Rock Local" (Dominio: festival.lokitrono.com)
```

- **Aislamiento de Datos:** Cada tabla (`campaigns`, `campaign_entities`, `hub_events`, `votos`) incluye `organization_id` con políticas RLS que impiden la lectura cruzada de datos administrativos.
- **Marca Blanca Completa:** Cada cliente define su logo, colores primarios/secundarios y dominio personalizado a través de `campaign_theme`.

---

## 3. FASE D: Especificación de Integración de Event Hub (Sin Programar)

Diseño de ingestores para fuentes externas:

| Fuente | Qué Datos Importar | Qué Datos Mostrar | Qué Datos Almacenar en `hub_events` |
| :--- | :--- | :--- | :--- |
| **Fever** | ID evento, título, sinopsis, fecha/hora, precio, link de afiliado, cartel. | Título, imagen, fecha, botón directo "Comprar entradas". | `title`, `description`, `start_date`, `external_url` con tag de afiliado, `category`. |
| **Eventbrite** | Eventos públicos por geolocalización (lat/long), organizador, aforo. | Título, organizador, ubicación en mapa, enlace oficial. | `title`, `location_name`, `latitude`, `longitude`, `external_url`. |
| **Entradium** | Entradas de teatro, ferias y música local. | Fechas de sesiones, cartel, precio orientativo. | `title`, `start_date`, `end_date`, `image_url`, `metadata->price`. |
| **Ayuntamientos (Open Data / RSS)** | Agenda municipal oficial, plazos de inscripción, lugares públicos. | Categoría institucional, fecha, dirección pública, gratuidad. | `title`, `address`, `category = 'municipal'`, `source_id`. |
| **Asociaciones Locales** | Actividades de barrio, talleres, festejos patronales. | Punto de encuentro, programa en PDF, organizador. | `title`, `description`, `metadata->organizer`. |

---

## 4. FASE E: Generadores con IA (Antigravity Blueprints)

Para permitir que un comercial o técnico municipal cree una campaña en 5 minutos sin tocar código:

1. **`CAMPAIGN_GENERATOR.md`**: Prompt maestro para generar un JSON completo de campaña (tema, reglas de voto, fechas y categorías) a partir de una descripción en lenguaje natural.
2. **`EVENT_GENERATOR.md`**: Normalizador automático de agendas culturales en PDF o notas de prensa hacia el esquema estructurado de `hub_events`.
3. **`TOURISM_GENERATOR.md`**: Conversor de folletos turísticos a rutas secuenciales con paradas, textos descriptivos y coordenadas aproximadas.

---

## 5. FASE F: Observabilidad y Métricas para Clientes

Los ayuntamientos y patrocinadores no compran tecnología; compran **datos de impacto ciudadano**:

- **Métricas de Participación:** Total de votos emitidos, participantes únicos, picos horarios de votación.
- **Métricas de Comercio:** Clics en establecimientos, check-ins presenciales completados, volumen de códigos PIN canjeados.
- **Métricas de Turismo:** Rutas iniciadas vs. rutas completadas, paradas más visitadas, tiempo medio de permanencia.
- **Logs y Errores:** Registro de caídas de servicio, intentos fallidos de autenticación y latencia de respuestas de la API.

---

## 6. Lo Mínimo Imprescindible para Vender el Primer Piloto (MVP Comercial)

Para cerrar el primer contrato piloto con un cliente real (ej. un ayuntamiento o asociación comercial):

1. **Un dossier de 1 página (One-Pager):** Presentando la solución como "Plataforma de Participación y Dinamización Local Llave en Mano".
2. **Una demo en vivo funcional:** [https://lokitrono.vercel.app](https://lokitrono.vercel.app) personalizada con el logo y colores del cliente potencial.
3. **Panel de control básico:** Para que el concejal o presidente de la asociación pueda ver cuántas personas han votado o participado.
4. **Cero fricción para el ciudadano:** Votación o participación directa desde el móvil sin obligar a descargar ninguna app de la tienda (WebApp directa).
