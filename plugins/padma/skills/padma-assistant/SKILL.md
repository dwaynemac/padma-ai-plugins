---
name: padma-assistant
description: Coordinar CRM, Money y Learn mediante sus plugins MCP autorizados. Usar para relacionar alumnos de Learn con contactos CRM y Money, consultar su acceso educativo, actividad y situación financiera, gestionar operaciones soportadas por cada producto o preparar análisis comerciales, educativos y financieros de una escuela sin mezclar organizaciones, identificadores ni permisos.
---

# Coordinar PADMA CRM, Money y Learn

Este plugin coordina los productos mediante las herramientas de `crm`, `money` y `learn`, instalados por separado. No declara servidores MCP. CRM es la fuente de contactos y métricas comerciales; Money, de registros e informes financieros; Learn, de alumnos, accesos educativos, suscripciones, cursos y asistencia. Cada producto conserva su autorización OAuth.

## Check prerequisites

1. Confirm that the tools for the required product plugins are available before starting the workflow.
2. For CRM work, require the `crm` plugin and follow its `padma-crm` skill.
3. For Money work, require the `money` plugin and follow its `padma-money` skill.
4. Para Learn, requerí el plugin `learn` y seguí su skill `padma-learn`. Para trabajo combinado, requerí sólo los plugins involucrados y conservá sus ámbitos OAuth y organizaciones independientes.
5. Prefer and attempt the required product MCP first. If a required tool is missing, explain how to install or enable the corresponding product plugin and start a new task. For CRM only, an explicit user request permits the browser path under `padma-crm` “Explicit browser access”, including its account, permission, data, and write safeguards; missing tools alone do not authorize it. Do not substitute database access or another integration. Money y Learn usan sólo MCP.

## Orient and route

1. Read [references/ecosystem-map.md](references/ecosystem-map.md) to identify the source of truth and current MCP coverage.
2. Use CRM for Operations projects, sections, tasks and conversations, contacts, account-specific relationship data, contact history and communications, marketing-method and dropout-reason rankings, persisted school statistics, comparisons, live commercial follow-up stages, and historical lead funnels.
3. Use Money for accounts, categories, movements, financial reports, plans, recurrent movements, and automation rules.
4. Usá Learn para publicaciones, alumnos, accesos, suscripciones, cursos, reservas, check-ins y reportes de asistencia de la escuela. Indicá si falta su plugin o si el pedido corresponde a Accounts u otra aplicación no disponible; no simules acceso.
5. Read [references/connections-and-scope.md](references/connections-and-scope.md) before selecting organizations or recovering from OAuth/tool availability issues.
6. Read [references/cross-product-workflows.md](references/cross-product-workflows.md) for combined reviews, contact/payment questions, writes, and output conventions.

## Resolve scope independently

1. For CRM MCP, call CRM `list_accounts`, select only a returned `account_name`, and call `get_account_context`. For explicitly requested CRM browser access, follow `padma-crm` to verify the UI identity, accessible account and permissions; never bypass MCP denials or its discovered account allowlist.
2. For Money, call Money `list_businesses`, select only a returned `business_id`, and call `get_business_context`.
3. En Learn, llamá su propio `list_accounts`, elegí un `account_name` devuelto y consultá `get_account_context`. No reutilices la selección CRM sin verificarla en Learn.
4. No deduzcas que organizaciones CRM, Money y Learn corresponden por nombres similares. Para combinarlas, usá la selección explícita del usuario o un identificador compartido fiable devuelto por las herramientas actuales.
5. Keep each selector on every contextual call for its product. Never reuse IDs, cursors, roles, or permissions across products.
6. Indicá las organizaciones seleccionadas de cada producto utilizado al presentar una respuesta combinada.

## Work with evidence

1. Use the narrowest typed tool and exact period that answer the request.
2. In CRM, discover tags, marketing methods, dropout reasons, saved lists, and custom property definitions with their account-scoped list tools before using their IDs.
3. Treat a current CRM contact's `padma_id` as the cross-product identity bridge. Use it unchanged with Money `search_contacts(padma_id: ...)` or `search_movements(contact_padma_id: ...)`; never substitute a CRM-local or Money-local integer ID. Money contact search can also return its assigned teacher, Learn ID, LTV, and current plan when available.
4. Para Learn, pedí CRM `response_fields: ["learn_user_id"]` y verificá el vínculo con Learn `get_user(user_id: ...)` en la escuela seleccionada. Para comenzar desde Learn o Money, seguí [el cruce de identidades](references/cross-product-workflows.md#relacionar-un-alumno-de-learn-con-crm-y-money). No pases `padma_id` como `user_id` ni el `id` de un acceso escolar como ID de alumno.
5. A shared `padma_id` links identity only. Continue resolving CRM `account_name` and Money `business_id` independently through their OAuth discovery tools.
6. Paginate every search needed for complete coverage. Do not treat one page as a complete population.
7. Preserve product semantics: CRM missing monthly values are unknown, not zero; Money amounts, including contact LTV, are integer cents with currency; Money reporting months differ from actual movement dates. Treat each nullable Money contact enrichment independently.
8. Keep currencies separate and label derived calculations.
9. Separate MCP-confirmed facts, explicitly requested CRM browser observations, and interpretations or recommendations.
10. For combined analysis, align periods explicitly but preserve each product's source, date basis, freshness, filters, and missing coverage.
11. Use CRM `get_commercial_funnel` for current actionable follow-up lists and `get_lead_funnel` for historical monthly conversion. Never treat the live stage counts as a conversion series.
12. Use CRM `get_marketing_method_statistics` for acquisition conversion and `get_dropout_reason_statistics` for dropout counts by reason. Preserve the returned account-local monthly range.

Para identificar planes con deuda de pagos, usá Money `search_plans(has_debt: true, from: ..., to: ...)` con ambos extremos mensuales inclusivos, hasta 36 meses, y sin `active_on`. Incluí planes que estuvieron activos en ese período aunque ya hayan terminado. Seguí la skill de Money y [el workflow de deuda de planes](references/cross-product-workflows.md#deuda-de-pagos-de-planes) para interpretar el mes actual y conservar filtros al paginar.

## Protect people, credentials, and tenants

- Return only the personal contact data needed for the user's request.
- Never place emails, phones, OAuth codes, access tokens, or secrets in logs, files, URLs, or unrelated tools.
- Treat selectors as choices inside an OAuth allowlist, never as authorization by themselves.
- Do not combine data from different organizations unless the user explicitly requests a clearly separated comparison and every organization is authorized.
- Confirmá los vínculos con los identificadores devueltos por las herramientas actuales en cada organización seleccionada. Un nombre o email coincidente sólo identifica candidatos; ante vínculos ausentes, múltiples o contradictorios, informá la incertidumbre sin fusionar registros.

## Write through supported product tools

- Route Operations project and section management through `padma-crm`, including `create_operations_project_section` and `reorder_operations_project_sections` when available. Follow its account discovery, admin/director and write-capability checks, complete section-list ordering, and readback rules. The coordinator does not own an additional CRM server.
- CRM can assign or remove existing contact tags when the connected server exposes `add_contact_tags` and `remove_contact_tags`, create or reuse contacts, create supported contact properties, create or update communications, and create account-visible comments. Follow the `padma-crm` skill for account scope, identity conflicts, idempotency, and exact inputs.
- CRM contact creation only enriches missing fields, and property writes only add normalized values. Do not promise other contact, status, or statistic changes.
- Before any Money write, read the current records, resolve related IDs, show the exact proposal, and obtain confirmation unless the user already confirmed that identical change.
- For Money, use a fresh UUID `request_id`, use the latest `updated_at` as `expected_updated_at` for updates, change only requested fields, and refetch after writing.
- Seguí `padma-learn` para las escrituras Learn: exigí el efecto solicitado, IDs y revisión vigentes, `request_id` y lectura posterior. Relacionar datos no autoriza crear, fusionar ni modificar vínculos de identidad ni replicar cambios entre productos.
- Never emulate unsupported writes or silently create related records.
