# PADMA AI Plugins

Plugins y skills para que los usuarios de [PADMA](https://derose.app/) puedan
trabajar con sus datos desde Codex y Claude Code.

Este repositorio publica catálogos específicos para cada cliente. Ambos
instalan los mismos plugins, skills y conexiones MCP con las aplicaciones de
PADMA.

Incluye tres integraciones MCP independientes:

- [`crm`](#crm), para contactos, actividad, métricas y operaciones comerciales
  en PADMA CRM.
- [`money`](#money), para cuentas, planes, presupuestos y movimientos
  financieros en PADMA Money.
- [`learn`](#learn), para administrar publicaciones, alumnos, accesos,
  suscripciones, cursos y asistencia de una escuela en Learn.

Instalá CRM y Money si necesitás trabajar entre ambos productos; instalá sólo el
plugin correspondiente cuando tu consulta pertenezca a un único producto.
Learn se instala de forma independiente; el coordinador `padma` conserva su
alcance de CRM y Money.

Cada directorio bajo `plugins/` también publica el contrato portable de
[Agent Plugins 1.0](https://agent-plugins.org/) mediante un `plugin.json`, sus
skills y, para los plugins de producto, un `mcp.json`. Esta superficie convive
con los manifiestos y marketplaces específicos de Codex y Claude Code.

## Instalar el marketplace en Codex

Necesitás una versión reciente de Codex con soporte para plugins.

```bash
codex plugin marketplace add dwaynemac/padma-ai-plugins
```

Después:

1. Abrí el catálogo con `/plugins` en Codex CLI o desde **Plugins** en la app de ChatGPT/Codex.
2. Elegí **PADMA AI Plugins**.
3. Instalá el plugin que quieras usar.
4. Iniciá una tarea nueva para que el agente cargue sus skills y herramientas.

Para actualizar el catálogo y los plugins instalados:

```bash
codex plugin marketplace upgrade padma-ai-plugins
```

## Instalar el marketplace en Claude Code

Necesitás una versión reciente de Claude Code con soporte para plugins.

```bash
claude plugin marketplace add dwaynemac/padma-ai-plugins
claude plugin install crm@padma-ai-plugins
claude plugin install money@padma-ai-plugins
claude plugin install learn@padma-ai-plugins
claude plugin install padma@padma-ai-plugins
```

El plugin `padma` sólo coordina los otros dos: no declara servidores MCP. Para
usar un solo producto, instalá únicamente su plugin:

```bash
claude plugin install money@padma-ai-plugins
# o
claude plugin install crm@padma-ai-plugins
```

Iniciá o reiniciá Claude Code para cargar las skills y herramientas del plugin.

Para actualizar el catálogo:

```bash
claude plugin marketplace update padma-ai-plugins
```

## Plugins disponibles

### Learn

Conecta al teacher con la administración de sus escuelas en
[Learn](https://learn.derose.app/) mediante el servidor MCP `learn` y la skill
`padma-learn`. Requiere que Learn tenga habilitado su MCP docente y que Accounts
admita el scope `learn`; instalar este paquete no despliega esos cambios.

Permite administrar publicaciones con contenido y enlaces suministrados,
alumnos y accesos, suscripciones, cursos y sus miembros, reservas y check-ins.
Incluye reportes estructurados de check-ins, reservas, distribución de check-ins
y clases por instructor, conservando permisos, períodos y filtros de `/admin`.
Las operaciones de suscripciones respetan las reglas existentes de Stripe,
MercadoPago y suscripciones manuales.

No administra cuentas de teachers ni configuración global; no automatiza
duplicación avanzada, híbridos, reuniones Zoom ni grabaciones. Las reservas
personales de alumnos usan su integración propia.

#### Configurar el acceso

1. Instalá `learn` e iniciá una tarea nueva.
2. Conectá el MCP mediante Accounts OAuth. El cliente descubre CIMD/DCR y usa
   PKCE; no configures un Client ID ni un Client Secret compartidos.
3. Autorizá las escuelas necesarias con `openid profile account learn`.
4. Verificá con `Listá mis escuelas autorizadas de Learn.` y después consultá
   `get_account_context` de la escuela seleccionada. El teacher debe existir y
   conservar su vinculación en Learn.

El recurso predeterminado es `https://learn.derose.app/mcp`; la alternativa
PADMA es `https://learn.padm.am/mcp`. Al cambiar el endpoint, la URL configurada,
el resource OAuth y la dependencia de la skill deben coincidir. Cada recurso
requiere su grant: una conexión CRM o Money no autoriza Learn.

Toda escritura usa `request_id` para reintentos; las modificaciones y
eliminaciones comprueban la revisión vigente con `expected_updated_at`.
La skill enseña a releer el resultado y distinguir cambios locales, efectos
confirmados por gateways y sincronizaciones pendientes.
Consultá el [contrato de operaciones](plugins/learn/skills/padma-learn/references/mcp-operations.md)
y la [guía de reportes](plugins/learn/skills/padma-learn/references/reports.md).

### PADMA

Coordina los plugins CRM y Money para trabajar con la situación comercial y
financiera de una escuela sin perder los límites entre productos. No declara
servidores MCP propios: las herramientas son provistas exclusivamente por los
plugins `crm` y `money`.

Permite:

- ubicar cada pregunta en su fuente de verdad dentro de PADMA;
- buscar o registrar contactos y comunicaciones, y analizar métricas comerciales mediante CRM;
- consultar y administrar las operaciones financieras disponibles en Money;
- relacionar un contacto confirmado en CRM con su registro, docente, Learn ID, LTV, plan actual y movimientos de Money mediante el `padma_id` compartido;
- preparar panoramas combinados con períodos, organizaciones y fuentes claras;
- reconocer cuándo una solicitud pertenece a Learn u otra app que
  todavía no está conectada por este plugin.

El plugin incluye la skill `padma-assistant`, una versión orientada al usuario
final del mapa de ecosistema que usan los developers. Evita detalles de
repositorios, modelos y rutas internas; enseña al agente a elegir el MCP
correcto y a no mezclar tenants, identificadores, monedas ni fechas.

#### Elegir el modo de instalación

- Instalá `crm` y `money` para disponer de sus herramientas MCP.
- Instalá también `padma` cuando quieras que el agente coordine ambos productos.
- Instalá sólo `crm` o `money` cuando necesites un único producto.

#### Configurar el acceso

1. Instalá `crm`, `money` y `padma`, e iniciá una tarea nueva.
2. Conectá CRM y Money cuando el cliente lo solicite. Cada servidor tiene su
   propio recurso y grant OAuth; ambos usan DCR y PKCE sin Client Secret.
3. Autorizá las organizaciones necesarias en cada producto.
4. Verificá CRM con `Listá las cuentas de CRM que tengo autorizadas.`
5. Verificá Money con `Listá los negocios de Money que tengo autorizados.`
6. Para un análisis combinado, seleccioná la organización de cada producto de
   forma independiente; nombres parecidos no prueban que sean el mismo tenant.

#### Relacionar un contacto entre CRM y Money

1. Buscá el contacto dentro de la cuenta CRM seleccionada y conservá el
   `padma_id` devuelto.
2. Seleccioná el negocio Money de forma independiente mediante
   `list_businesses`; el `padma_id` no reemplaza al `business_id`.
3. Usá `search_contacts` de Money con `padma_id` para verificar una coincidencia
   exacta dentro de ese negocio. La coincidencia incluye `id`, `name`,
   `padma_id` y `status`, y puede incluir `teacher`, `learn_id`, `ltv` y
   `current_plan`; cada uno puede ser nulo independientemente.
4. Usá `search_movements` con `contact_padma_id`, un período explícito y el
   mismo `business_id` para consultar directamente sus movimientos.
5. No envíes `contact_id` y `contact_padma_id` juntos, y recorré
   `next_cursor` cuando la búsqueda tenga más páginas.

Que no haya coincidencia en un negocio no prueba que el contacto no exista en
otro. CRM sigue siendo la fuente de relación y actividad del contacto; Money,
la fuente de planes y movimientos financieros.

### Money

Conecta el agente con [PADMA Money](https://money.derose.app/) mediante su servidor MCP oficial.

Permite:

- descubrir y seleccionar entre los negocios autorizados por OAuth;
- consultar saldos de cuentas al cierre de una fecha, en la zona horaria del negocio y la moneda de cada cuenta;
- consultar cuentas, categorías, contactos enriquecidos con docente, Learn ID, LTV y plan actual, y movimientos;
- identificar planes con o sin deuda de pagos en un rango mensual inclusivo de hasta 36 meses, incluidos planes ya terminados;
- buscar contactos por `padma_id` exacto y movimientos por `contact_padma_id`;
- filtrar movimientos por una o más categorías junto con todas sus subcategorías;
- analizar gastos, ingresos, períodos y posibles anomalías;
- crear, corregir, dividir y eliminar movimientos financieros;
- prorratear gastos en meses sucesivos, subdividir movimientos y revertir esas divisiones de forma segura;
- administrar cuentas, categorías y sus presupuestos mensuales en cualquiera de las monedas soportadas, movimientos recurrentes, planes y automatizaciones, incluida la eliminación segura de reglas recurrentes;
- aplicar confirmación, idempotencia y verificación en operaciones de escritura.

El plugin incluye la skill `padma-money`, que enseña al agente el modelo financiero de Money, sus workflows seguros y las limitaciones reales de las herramientas disponibles.

Para consultar un saldo por fecha, usá `get_account_balance` con el `account_id` de `list_accounts` y una fecha `YYYY-MM-DD`. Incluye ese día completo; admite cuentas archivadas y excluye pendientes. Consultá el [contrato y ejemplo](plugins/money/skills/padma-money/references/mcp-operations.md#saldo-de-cuenta-en-get_account_balance).

Para buscar deuda de planes, usá `search_plans` con `has_debt: true` y ambas fechas `from`/`to` en formato `YYYY-MM-DD`. Los días se normalizan al mes; no combines el rango con `active_on`. Un mes activo impago cuenta cuando su primer día es anterior a hoy en la zona horaria del negocio: el mes actual participa desde el segundo día. `has_debt: false` devuelve el complemento entre los planes activos en el rango; omitirlo permite buscar todos esos planes. Este filtro no calcula un saldo ni un total adeudado. Consultá el [contrato completo y los ejemplos](plugins/money/skills/padma-money/references/mcp-operations.md#deuda-de-pagos-en-search_plans).

#### Configurar el acceso

1. Instalá el plugin e iniciá una tarea nueva.
2. Cuando el cliente lo solicite, conectá Money e iniciá sesión mediante OAuth.
   El cliente descubre automáticamente el método de registro OAuth compatible
   (CIMD o DCR); no configures un Client ID ni un Client Secret compartidos.
3. Autorizá el acceso a una o más cuentas. Money limitará cada operación a los negocios habilitados que también puedas usar localmente.
4. Probá la conexión con: `Listá los negocios de Money que tengo autorizados.`

El `mcp.json` portable declara OAuth explícitamente para los hosts de OpenAI.
El plugin no requiere una API key ni una variable de entorno. El cliente administra la sesión OAuth; no pegues códigos de autorización ni tokens en prompts, archivos del repositorio, logs o URLs.

Si una instalación anterior tenía un Client ID OAuth estático, actualizá el
plugin, eliminá esa configuración y desconectá/reconectá Money para que el
cliente use DCR.

### CRM

Conecta el agente con [PADMA CRM](https://crm.derose.app/) mediante su servidor
MCP oficial.

Permite:

- descubrir y seleccionar cuentas autorizadas por OAuth;
- buscar contactos por identidad, cumpleaños, estado, vínculo con la cuenta, actividad, fechas y motivos de baja;
- agregar o quitar etiquetas existentes de un contacto cuando el servidor expone `add_contact_tags` y `remove_contact_tags` (CRM MCP 1.19.0 o posterior), conservando las demás asignaciones y sin borrar etiquetas;
- descubrir etiquetas, métodos de marketing, motivos de baja y listas guardadas antes de usarlos;
- consultar una lista guardada respetando sus filtros, orden y columnas configuradas, incluida la edad calculada sin exponer la fecha de nacimiento; inspeccionar sus reglas mediante `list.filters` cuando el servidor las expone;
- agregar un contacto a una lista mediante una etiqueta existente cuando sus reglas de inclusión lo permiten, comprobar las demás condiciones y verificar la pertenencia después de asignarla;
- descubrir propiedades personalizadas y consultar valores seleccionados del contacto;
- consultar datos operativos del contacto dentro de la cuenta seleccionada;
- consultar bajo demanda el identificador de usuario de Learn y el resumen de actividad y riesgo de abandono calculado por Learn;
- recorrer el historial de actividad del contacto con paginación segura;
- crear contactos o reutilizar coincidencias exactas de email o teléfono sin reemplazar datos existentes;
- crear propiedades de sistema o de texto personalizadas sin duplicar valores normalizados;
- crear comunicaciones idempotentes bajo el usuario autenticado;
- corregir campos editables de una comunicación existente sin cambiar su contacto, autor ni metadatos de idempotencia;
- crear comentarios visibles para la cuenta en el contacto seleccionado;
- listar y administrar proyectos operativos compartidos, sus miembros y el orden de sus secciones según el rol del usuario;
- crear y ordenar secciones de proyectos con `create_operations_project_section` y `reorder_operations_project_sections` (CRM MCP 1.20.0 o posterior), con permiso de escritura y rol admin o director; descubrir y reutilizar las secciones existentes, enviar la lista completa de IDs al ordenar y verificar cada cambio mediante lectura, sin mover tareas;
- listar, filtrar por proyecto y sección, asignar colaboradores, crear, editar, completar, reabrir y eliminar tareas operativas según los permisos del usuario, incluidos los accesos de colaboradores y miembros de proyecto;
- asignar una misma tarea a varios proyectos de la cuenta, mover su sección en uno sin alterar los demás y quitar asociaciones concretas sin borrar la tarea;
- consultar comentarios y cambios de tareas operativas en orden cronológico y publicar comentarios con autoría autenticada y paginación segura;
- configurar recurrencias diarias, semanales, mensuales o anuales y obtener la siguiente tarea al completar una ocurrencia;
- leer series mensuales persistidas y su fecha de actualización;
- comparar métricas con el mes anterior y el promedio de los tres meses previos;
- analizar contactos y conversión por método de marketing durante un rango mensual;
- analizar bajas por motivo durante un rango mensual;
- revisar las cinco etapas actuales de seguimiento comercial y abrir la lista de contactos de cada etapa;
- analizar el funnel histórico de procura, visitas, visitas perfil y matrículas durante un período.

El plugin incluye la skill `padma-crm`, que enseña al agente a preservar el
aislamiento entre cuentas, paginar búsquedas, minimizar la exposición de datos
personales y distinguir estadísticas faltantes de valores cero.

El agente prioriza e intenta primero el MCP. Si le pedís explícitamente usar el
navegador para CRM, puede acceder a la interfaz oficial después de comprobar e
intentar el MCP disponible, incluso si sus herramientas no están expuestas.
Por ejemplo: “Usá el navegador para consultar la lista de seguimiento de alumnos
en mi cuenta seleccionada”. Antes verifica identidad, cuenta y permisos en la
sesión de CRM. La excepción mantiene el alcance solicitado, la minimización de
datos y las confirmaciones de escritura; no permite eludir denegaciones,
autenticación, permisos ni restricciones de documentos gubernamentales. Sin esa
solicitud no cambia automáticamente de vía. Money conserva acceso solo por MCP.

#### Configurar el acceso

1. Instalá el plugin e iniciá una tarea nueva.
2. Cuando el cliente lo solicite, conectá CRM e iniciá sesión mediante OAuth.
   El cliente registrará automáticamente un cliente público mediante DCR; no
   configures un Client ID ni un Client Secret compartidos.
3. Autorizá una o más cuentas habilitadas. El hostname del MCP selecciona el
   recurso OAuth, pero no restringe la marca de las cuentas autorizadas.
4. Probá la conexión con: `Listá las cuentas de CRM que tengo autorizadas.`
5. Elegí una cuenta devuelta y verificá una llamada real, por ejemplo:
   `Mostrame las definiciones de estadísticas mensuales de esta cuenta.`

El plugin no requiere una API key ni una variable de entorno. El cliente
administra la sesión OAuth. Las escrituras disponibles permiten crear o
reutilizar contactos, agregar o quitar asignaciones de etiquetas existentes, crear propiedades, crear o corregir comunicaciones,
crear comentarios y gestionar proyectos y tareas operativas autorizadas.
También permiten consultar la actividad de cada tarea: comentarios, creación,
ediciones, movimientos y finalización, del más antiguo al más reciente.
Se pueden publicar comentarios; no se pueden editar ni eliminar mediante MCP.

## Ejemplos

### PADMA

- “Dame un panorama comercial y financiero de mi escuela este trimestre.”
- “¿La mejora del funnel coincide con mayores ingresos? Separá hechos de interpretación.”
- “Buscá este contacto en CRM y revisá si tiene movimientos relacionados en Money.”
- “Tomá el `padma_id` de este contacto de CRM y listá sus movimientos de Money del último año.”
- “Tomá el `padma_id` de este contacto de CRM y mostrame su docente, Learn ID, LTV y plan actual en Money.”
- “¿Qué parte de esta consulta corresponde a CRM, Money o Learn?”

### Money

- “Mostrame el saldo de la cuenta Caja al cierre del 31 de octubre de 2026.”
- “Mostrame los planes con deuda de pagos de enero a marzo de 2026, incluidos los que ya terminaron.”
- “Buscá este contacto y mostrame su docente, Learn ID, LTV y plan actual.”
- “¿Cuánto gastamos el mes pasado, separado por categoría?”
- “Mostrame los movimientos de esta categoría y todas sus subcategorías.”
- “Configurá un presupuesto mensual para esta categoría después de mostrarme el cambio.”
- “Buscá movimientos sin categoría y proponé cómo clasificarlos.”
- “Registrá este gasto después de mostrarme exactamente qué vas a crear.”
- “Eliminá este movimiento después de mostrarme sus datos y pedirme confirmación.”
- “Eliminá esta recurrencia después de mostrarme la regla y confirmar que los movimientos ya generados se conservan.”
- “Prorrateá este gasto en seis meses, empezando por su mes de reporte actual.”
- “Dividí este movimiento entre materiales y honorarios, conservando el total.”
- “Revertí esta división si ninguna de sus partes cambió.”
- “Compará este mes con el anterior y explicá las variaciones relevantes.”
- “Revisá esta cuenta contra el extracto y listá las diferencias sin modificar nada.”

### CRM

- “Buscá a Ana por email en la cuenta de Cerviño.”
- “¿Quién cumple años hoy en esta cuenta?”
- “Mostrame los contactos dados de baja por mudanza.”
- “Mostrame los contactos de esta lista guardada con sus columnas configuradas.”
- “Mostrame la edad actual de este contacto sin devolver su fecha de nacimiento.”
- “Mostrame la actividad reciente de este contacto.”
- “Mostrame el resumen de actividad de Learn de este contacto.”
- “Listá las propiedades personalizadas disponibles y mostrame el apodo de este contacto.”
- “Agregá la etiqueta existente que seleccioné a este contacto.”
- “Quitá esta etiqueta del contacto sin borrar la etiqueta de la cuenta.”
- “Agregá este teléfono al contacto que acabo de seleccionar.”
- “Registrá a Ana como prospect con este email y teléfono.”
- “Guardá esta llamada saliente en el contacto que acabo de seleccionar.”
- “Corregí el medio y la fecha de esta comunicación.”
- “Agregá este comentario al contacto que acabo de seleccionar.”
- “Listá los proyectos operativos disponibles en esta cuenta.”
- “Creá una sección en este proyecto operativo y ordená sus secciones como te indiqué.”
- “Mostrame todas mis tareas operativas activas, incluidas las de más adelante.”
- “Mostrame las tareas operativas que no tienen proyecto.”
- “Asigná esta tarea a dos proyectos y mostrame en qué sección quedó en cada uno.”
- “Mové esta tarea a otra sección del proyecto seleccionado, conservando sus otros proyectos.”
- “Creá una tarea para llamar a este contacto mañana y asignásela a esta persona.”
- “Completá esta tarea; si te pido eliminarla, mostrame sus datos y confirmá antes.”
- “Mostrame los comentarios y cambios de esta tarea operativa en orden cronológico.”
- “Publicá este mensaje en la tarea operativa que acabo de seleccionar.”
- “Mostrame alumnos y bajas mes a mes durante el último año.”
- “Compará la efectividad de este mes con el mes anterior.”
- “Compará la conversión por método de marketing de los últimos seis meses.”
- “Mostrame las bajas agrupadas por motivo durante el último año.”
- “Mostrame cuántos contactos necesitan seguimiento ahora en cada etapa y abrí la lista de Perfil.”
- “Analizá el funnel histórico de conversión de los últimos seis meses.”

## Estructura

```text
.agents/plugins/marketplace.json   catálogo de Codex
.claude-plugin/marketplace.json    catálogo de Claude Code
plugins/                           plugins instalables
  padma/
    .codex-plugin/plugin.json      manifiesto de Codex
    .claude-plugin/plugin.json     manifiesto de Claude Code
  money/                           integración MCP con PADMA Money
  crm/                             integración MCP con PADMA CRM
```

Los catálogos no son intercambiables: cada cliente usa un esquema de
`marketplace.json` distinto. Los manifiestos específicos sólo describen el
empaquetado; el contenido compartido permanece en `skills/` y `.mcp.json`.

Las skills específicas de un producto viajan dentro de su plugin. Las skills
independientes podrán publicarse bajo `skills/` cuando no necesiten MCP ni otro
componente adicional.

## Seguridad y alcance

- Cada integración debe respetar la lista de organizaciones autorizadas por sus credenciales y usar cualquier selector de organización solo dentro de esa lista.
- Los secretos deben permanecer fuera del repositorio.
- El agente debe mostrar y confirmar cambios financieros cuando el usuario todavía no haya autorizado la operación exacta.
- Los datos personales de CRM deben limitarse a lo necesario para responder la solicitud y nunca mezclarse entre cuentas.
- Las reglas de negocio, permisos e invariantes siguen viviendo en las aplicaciones PADMA; las skills orientan al agente, no reemplazan esas protecciones.

## Contribuir

Consultá [CONTRIBUTING.md](CONTRIBUTING.md) para agregar o actualizar un plugin o una skill.

## Documentación relacionada

- [Plugins de Codex](https://developers.openai.com/codex/plugins)
- [Crear y distribuir plugins](https://developers.openai.com/codex/plugins/build)
- [Plugins de Claude Code](https://code.claude.com/docs/en/plugins)
- [Marketplaces de Claude Code](https://code.claude.com/docs/en/plugin-marketplaces)

## Publicación de PADMA CRM en ChatGPT

El plan, los requisitos pendientes y la verificación están en [docs/crm-publication.md](docs/crm-publication.md). El paquete está en preparación; esta documentación no implica publicación ni aprobación.
