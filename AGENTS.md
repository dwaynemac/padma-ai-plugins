# AGENTS.md

## Propósito del repositorio

Este repositorio publica plugins y skills para que agentes compatibles con
Codex trabajen con productos PADMA mediante sus servidores MCP oficiales.

No implementa reglas de negocio ni clientes MCP. Los permisos, validaciones e
invariantes pertenecen a las aplicaciones PADMA. Los plugins deben mantenerse
delgados: describen conexiones, contexto y workflows seguros.

## Estructura

- `.agents/plugins/marketplace.json`: catálogo público para Codex.
- `.claude-plugin/marketplace.json`: catálogo público para Claude Code.
- `plugins/<nombre>/plugin.json`: manifiesto portable de Agent Plugins.
- `plugins/<nombre>/mcp.json`: servidores MCP portables de Agent Plugins,
  cuando corresponda.
- `plugins/<nombre>/.codex-plugin/plugin.json`: manifiesto publicado para Codex.
- `plugins/<nombre>/.claude-plugin/plugin.json`: manifiesto publicado para
  Claude Code.
- `plugins/<nombre>/.mcp.json`: servidores MCP declarados para Codex y Claude
  Code.
- `plugins/<nombre>/skills/<skill>/SKILL.md`: instrucciones principales.
- `plugins/<nombre>/skills/<skill>/agents/openai.yaml`: metadatos y
  dependencias de la skill.
- `plugins/<nombre>/skills/<skill>/references/`: documentación cargada bajo
  demanda.
- `README.md`: instalación, capacidades y ejemplos para usuarios.
- `CONTRIBUTING.md`: requisitos para contribuciones.

## Compatibilidad con Agent Plugins

- Mantené cada plugin publicado conforme a la especificación portable de
  [Agent Plugins](https://agent-plugins.org/).
- Tratá `plugins/<nombre>/plugin.json`, `plugins/<nombre>/skills/` y, cuando el
  plugin sea dueño de una conexión MCP, `plugins/<nombre>/mcp.json` como el
  contrato portable canónico. Usá los nombres, ubicaciones, schemas y
  transportes definidos por la versión de Agent Plugins declarada en esos
  archivos.
- Conservá cada `SKILL.md` conforme a la especificación de Agent Skills que
  adopta Agent Plugins, incluidos el frontmatter, los límites de sus campos y
  la coincidencia entre `name` y el nombre del directorio.
- Mantené la configuración y metadatos específicos de Codex y Claude Code como
  superficies adicionales. No reemplaces ni contradigas el contrato portable
  con manifiestos, marketplaces o extensiones propios de un cliente.
- Ubicá cualquier extensión específica de un cliente bajo `extensions` o el
  namespace de dominio inverso que corresponda, según Agent Plugins. No
  agregues campos específicos de clientes al nivel superior del manifiesto
  portable.
- Cuando cambie una capacidad, sincronizá el contrato portable con las
  superficies específicas de cada cliente sin duplicar la propiedad de skills
  ni servidores MCP.

## Límites de cada plugin

- `crm` es dueño de la conexión `crm` y de los workflows de contactos,
  actividad, estadísticas y funnel comercial.
- `money` es dueño de la conexión `money` y de los workflows financieros.
- `learn` es dueño de la conexión `learn` y de la administración docente de
  publicaciones, alumnos, accesos, suscripciones, cursos y asistencia.
- `padma` coordina CRM y Money. No declara un servidor MCP propio ni duplica los
  servidores de los plugins de producto.
- No publiques el mismo servidor MCP desde más de un plugin. Las dependencias
  declaradas por una skill coordinadora no transfieren la propiedad del
  servidor.
- No simules acceso a Accounts u otros productos que no estén expuestos
  por las herramientas disponibles.

## Cómo hacer cambios

1. Identificá el plugin y la fuente de verdad afectados antes de editar.
2. Leé el `SKILL.md` completo y sólo las referencias relacionadas con el
   cambio.
3. Mantené la solución pequeña y explícita. Preferí actualizar una referencia
   existente antes que crear capas o documentos redundantes.
4. Si cambia una capacidad publicada, sincronizá:
   - el `SKILL.md` y sus referencias;
   - `agents/openai.yaml`;
   - `plugin.json` y `mcp.json`, cuando corresponda;
   - `.codex-plugin/plugin.json`;
   - `.claude-plugin/plugin.json`;
   - `.mcp.json`, si cambia la conexión;
   - `README.md`, si cambia la experiencia del usuario.
5. Al modificar el contenido publicado de un plugin, incrementá su versión.
   Conservá el formato existente: SemVer y, cuando corresponda, el sufijo
   `+codex.YYYYMMDDHHMMSS`.
6. No cambies versiones ni archivos de plugins que no fueron afectados.

## Convenciones de contenido

- Los nombres de plugins, skills y carpetas usan minúsculas y guiones.
- Todo `SKILL.md` comienza con frontmatter que contiene `name` y `description`.
- La descripción debe explicar cuándo activar la skill, no sólo qué es.
- Usá enlaces relativos para referencias internas y comprobá que existan.
- Conservá las instrucciones operativas en `SKILL.md`; mové detalles extensos
  de dominio a `references/` y enlazá sólo lo necesario.
- El texto dirigido a usuarios usa español rioplatense claro. Los identificadores
  técnicos y nombres de herramientas conservan su forma exacta.
- Los ejemplos y capacidades deben corresponder a herramientas disponibles
  actualmente. No presentes trabajo futuro como implementado.
- Diferenciá hechos devueltos por MCP de interpretaciones del agente.

## Seguridad y contratos MCP

- Nunca agregues tokens, secretos, códigos OAuth, datos personales reales ni
  identificadores internos al repositorio, ejemplos, logs o URLs.
- OAuth define las organizaciones autorizadas. Un `account_name` o
  `business_id` sólo selecciona dentro de esa lista; nunca otorga acceso.
- CRM comienza por `list_accounts` y conserva `account_name` en todo el
  workflow.
- Money comienza por `list_businesses` y conserva `business_id` en todo el
  workflow.
- Learn comienza por `list_accounts` y conserva `account_name` en todo el workflow.
- No mezcles tenants, identificadores, cursores, monedas ni permisos entre
  productos u organizaciones.
- Las escrituras deben respetar las confirmaciones, idempotencia y
  verificaciones documentadas por cada skill.
- Un login exitoso o una configuración válida no prueban el funcionamiento
  end-to-end. Cuando cambie una integración, verificá con una llamada real a
  una herramienta y describí con precisión cualquier prueba que no haya podido
  ejecutarse.

## Validación

El repositorio sólo tiene una prueba de compatibilidad basada en la biblioteca
estándar de Ruby y no tiene dependencias de desarrollo. No instales paquetes
únicamente para validar estos archivos.

Ejecutá primero la prueba:

```bash
rbenv exec ruby test/marketplace_compatibility_test.rb
```

Validá todos los JSON:

```bash
find .agents .claude-plugin plugins -name '*.json' -print0 |
  xargs -0 -n1 jq empty
```

Para validar YAML, usá una versión de Ruby instalada y seleccionada con rbenv;
el repositorio no fija una versión en `.ruby-version`:

```bash
rbenv exec ruby -rpsych \
  -e 'ARGV.each { |path| Psych.safe_load_file(path, aliases: false) }' \
  plugins/*/skills/*/agents/openai.yaml
```

Completá siempre las verificaciones locales:

```bash
git diff --check
git status --short
```

Además, revisá manualmente que:

- cada plugin cumpla la versión declarada de
  [Agent Plugins](https://agent-plugins.org/), incluidos su `plugin.json`, sus
  skills y, cuando corresponda, su `mcp.json`;
- ambos marketplaces publiquen el mismo conjunto de plugins;
- cada entrada del marketplace apunte a un plugin existente con el formato de
  fuente correspondiente al cliente;
- cada manifiesto apunte a skills y archivos MCP existentes;
- los manifiestos Codex y Claude de cada plugin tengan el mismo nombre y
  versión;
- los nombres y URLs MCP coincidan entre `.mcp.json` y `agents/openai.yaml`;
- `padma` siga sin declarar `mcpServers`;
- todos los enlaces Markdown modificados resuelvan;
- no haya placeholders, credenciales ni datos personales;
- README, manifiestos, skills y referencias describan el mismo contrato.

Si está disponible un validador oficial o una instalación aislada de Codex o
Claude Code, usala como verificación adicional. No ocultes que esa validación o
una prueba MCP en vivo quedó pendiente.

## Alcance de entrega

- Conservá cambios ajenos presentes en el worktree.
- No edites copias instaladas o caches de plugins; este checkout es la fuente a
  modificar.
- No hagas commit, push, publicación ni cambios en servicios externos salvo que
  el usuario lo pida explícitamente.
- Al entregar, resumí los archivos modificados, las validaciones ejecutadas y
  cualquier límite de verificación.
