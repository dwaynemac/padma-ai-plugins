---
name: padma-money
description: Use PADMA Money through its remote MCP server to inspect accounts and their balances at a date, categories and their monthly budgets, contacts, movements and their splits, financial reports, recurrent movements, plans with payment debt over a bounded monthly range, and automation rules; create, update, prorate, subdivide, revert splits, soft-delete movements, or delete recurrent movement rules safely. Use for requests such as cuanto gastamos, ingresos del mes, flujo de caja, compara periodos, revisa pagos, configura un presupuesto de categoria, registra un gasto, corrige, categoriza, divide, prorratea o elimina un movimiento, elimina una recurrencia, revierte una division, concilia una cuenta, detecta anomalias, or otherwise consults or manages an organization's financial information stored in Money.
---

# Use Money MCP

Use the `money` MCP server as the only execution path for Money data. OAuth determines the Business allowlist; `business_id` only selects one Business from that authorized set.

## Prepare

1. Confirm that `money` tools are available. Do not substitute browser automation or another integration when the MCP server is unavailable.
2. Call `list_businesses` first. It is the authoritative list of Businesses this OAuth session may use.
3. If the list contains one Business, use it automatically. If it contains several, use a Business explicitly identified by the user or ask which one to use; never guess from unrelated context.
4. Call `get_business_context` for the selected Business. When more than one Business is authorized, pass the selected `id` returned by `list_businesses` as `business_id` and keep that same selector on every contextual tool call in the workflow.
5. State the selected business, currency, and timezone when they matter.
6. Read [references/mcp-operations.md](references/mcp-operations.md) for connection, selection, tool, date, amount, and error contracts.
7. Read [references/domain-model.md](references/domain-model.md) before calculations or when terms could be confused.
8. Read [references/objects-and-attributes.md](references/objects-and-attributes.md) when interpreting a returned object, choosing or changing attributes, or explaining lifecycle and currency effects.
9. Read only the relevant sections of [references/money-product-guide.md](references/money-product-guide.md) when broader product semantics affect the request.
10. Read [references/workflows-and-output.md](references/workflows-and-output.md) for monthly reports, reconciliation, anomaly review, or mutation presentation.

## Read and analyze

1. Use the narrowest typed search tool and filters that answer the question.
2. Use `search_contacts` with `padma_id` for an exact Money contact lookup. Keep `text` for partial name-or-PADMA-ID discovery. Each result preserves `id`, `name`, `padma_id`, and `status`, and also returns the assigned `teacher`, `learn_id`, stored `ltv`, and `current_plan` when available; treat each nullable field independently and do not infer missing data.
3. When a confirmed PADMA contact ID is already available, pass it directly as `contact_padma_id` to `search_movements`; do not make an extra lookup only to translate it into Money's integer `contact_id`.
4. Never send `contact_id` and `contact_padma_id` together. They are mutually exclusive filters.
5. Use `category_tree_ids` on `search_movements` when the request covers one or more categories plus all their descendants. Resolve every root ID with `search_categories`; keep `category_id` for one exact category.
6. Read `monthly_budget` from `search_categories` when the user asks about a category's configured monthly budget. It is either null or an object with integer `cents` and the category's stored `currency`; it is not the monthly budget report. Do not assume that its currency matches the Business base currency.
7. Paginate when the requested scope exceeds one page. Do not infer a complete result from a truncated page.
8. Preserve Money semantics: `report_on` selects reporting months; `movement_at` and `reconciled_at` select actual dates.
9. Prefer `category_subtotals` for category totals and `analyze_movements` for deterministic findings. Use movement search for detail, audit, categorization, reconciliation, or explaining an aggregate.
10. Calculate from structured integer values, never from formatted display text. Do not add unlike currencies or silently convert them.
11. Present monetary values in human units with their currency while retaining exact integer cents when precision matters.
12. State the business or account scope, period, date basis, currency, filters, and material exclusions.
13. Separate MCP-confirmed facts from interpretation or recommendations. Do not label derived output as an official accounting statement.

## Saldo de una cuenta por fecha

Usá `get_account_balance` con un `account_id` obtenido de `list_accounts` y `date` en formato estricto `YYYY-MM-DD`. Incluye el día completo en la zona horaria del negocio y devuelve la moneda de la cuenta. Para encontrar una cuenta archivada, consultá `list_accounts(archived: true)`; su saldo también se puede consultar. No calcules el saldo sumando una página de movimientos ni lo confundas con un reporte por categoría. Para un saldo de apertura, consultá el cierre del día anterior al inicio del período. Seguí el [contrato y ejemplo](references/mcp-operations.md#saldo-de-cuenta-en-get_account_balance).

## Deuda de pagos de planes

Usá `search_plans(has_debt: true, from: ..., to: ...)` con ambos extremos de un rango mensual inclusivo de hasta 36 meses. `has_debt: false` devuelve los planes activos en ese rango sin meses que cumplan el criterio de deuda; omitirlo permite ver todos los planes activos en el rango. Conservá `business_id` y todos los filtros al paginar. `active_on` sigue disponible por separado y no se combina con el rango.

Seguí el contrato y los ejemplos de [references/mcp-operations.md](references/mcp-operations.md#deuda-de-pagos-en-search_plans). Puede incluir planes que ya terminaron. El mes actual participa después de su primer día; no infieras deuda por saldo de cuenta ni un importe adeudado a partir de este filtro.

## Movement permalinks

When the user requests a direct link to a movement:

1. Use the authenticated `business.id` from `get_business_context` and the `movement.id` from a current `get_movement` or search response.
2. Build `https://<configured-money-host>/businesses/<business.id>/movements/<movement.id>`, preserving the configured MCP server host and removing only its trailing `/mcp` path.
3. Return the result as a clickable Markdown link. Never infer an ID, select a host from the business name, or construct a link for an unverified movement.

## Write safely

1. Read or search the current records before proposing a mutation.
2. Show the exact proposed change, including business, record, amount and currency, dates, and related IDs. Obtain confirmation unless the user already confirmed that exact mutation in the current conversation.
3. Never silently create a missing account, category, contact, or other related record. Search first and ask before creating a missing persistent record.
4. Generate a fresh UUID `request_id` for each intended write. Reuse it only when retrying the identical operation after an uncertain response.
5. For updates, deletion, proration, and subdivision, fetch the affected record immediately before writing and pass its latest `updated_at` as `expected_updated_at`. On conflict, refetch, explain the intervening change, and reconfirm if the proposal changed.
6. Change only explicitly requested fields. Correct an existing record in place instead of creating a duplicate.
7. Before `revert_split`, call `get_split` immediately before confirmation. Show the original and every resulting movement, then pass the exact returned target IDs and `updated_at` values as `expected_movements`. Never omit a target or bypass a conflict.
8. Refetch or search after the write and report the persisted result. After splitting, verify with `get_split`; after `revert_split`, verify the restored original; after `delete_movement`, verify that normal reads return `not_found` and report the returned deletion timestamp; after `delete_recurrent_movement`, verify that `get_recurrent_movement` returns `not_found`. Do not treat a successful request alone as verification.
9. For a category budget, pass `monthly_budget_cents` as a non-negative integer and, when requested, `monthly_budget_currency` as one of `usd`, `brl`, `eur`, `ars`, or `btc`; uppercase variants are accepted and stored lowercase. Omitting currency on creation defaults to the Business base currency. On update, changing only cents preserves the stored currency, changing only currency preserves cents, and `monthly_budget_cents: null` removes both fields. Never combine that null with a currency. A category cannot have a budget when an ancestor or descendant in the same branch already has one.

## Protect credentials and tenant scope

- Never ask the user to paste an OAuth authorization code or access token into a prompt.
- Never place OAuth credentials in files, URLs, logs, or MCP arguments. The client manages the OAuth session.
- Never invent a `business_id` or treat one supplied by the user as authorization. Resolve it through `list_businesses` and use only an ID returned there.
- Treat granted read or write access as permission to operate only within the user's request.
- Do not switch Businesses during a workflow unless the user explicitly asks. If the intended Business is not listed, stop and ask the user to reconnect and grant the required account.

## Handle unavailable or unsupported operations

- If the server or expected tool is unavailable, report the missing capability plainly and provide connection checks from the operations reference.
- Do not emulate deferred capabilities such as the monthly budget report, restoring an independently deleted movement, physical deletion beyond recurrent movement rules, deletion of other record types, batch mutation, imports, automatic bank-statement matching, or contact mutation through unrelated tools. Category budget fields are available through category tools; `revert_split` is limited to atomically restoring the original movement and removing every unchanged target of that split.
- For authentication, authorization, validation, conflict, or rate-limit errors, follow the response-specific recovery in the operations reference. Do not retry writes blindly.
