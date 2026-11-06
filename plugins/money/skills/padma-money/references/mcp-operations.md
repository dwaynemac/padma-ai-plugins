# Money MCP operations

## Contents

- Connection
- Verification
- Tool surface
- Shared contracts
- Safe write patterns
- Errors

## Connection

- Server: `https://money.derose.app/mcp`
- Transport: Streamable HTTP
- Authentication: OAuth managed by the MCP client
- Client registration: automatic OAuth discovery (CIMD or DCR)
- OAuth resource: `https://money.derose.app/mcp`

Connect Money when the client requests authorization, sign in, and authorize the intended account or accounts. The plugin does not require an API key or environment variable. Never paste authorization codes or access tokens into prompts, files, logs, URLs, or MCP arguments.

Do not configure a shared `oauth_client_id`, Client ID, or Client Secret. The
client discovers the Accounts OAuth metadata and uses CIMD or registers its exact
callback through DCR as a public PKCE client. Callback
wildcards such as `http://127.0.0.1/callback/*` are not supported.

The portable `mcp.json` explicitly declares OAuth in
`extensions.com.openai.auth.type`. The Codex and Claude compatibility file
`.mcp.json` uses the following configuration and relies on OAuth discovery:

```json
{
  "mcpServers": {
    "money": {
      "type": "http",
      "url": "https://money.derose.app/mcp"
    }
  }
}
```

### Codex

The plugin deliberately omits `oauth_client_id` so Codex can discover a supported
OAuth client registration method. If Money was
previously added manually with the shared static client, replace that entry:

```bash
codex mcp logout money
codex mcp remove money
codex mcp add money \
  --url https://money.derose.app/mcp \
  --oauth-resource https://money.derose.app/mcp
codex mcp login money --scopes openid,profile,account,money
```

### Claude Code

The plugin also omits advanced OAuth credentials for Claude Code. If the MCP
server must be added manually, use:

```bash
claude mcp add --transport http money https://money.derose.app/mcp
```

Then run `/mcp`, select Money, and complete authentication. Leave Client ID and
Client Secret empty so Claude Code can use DCR.

Accounts accepts up to 10 dynamic registrations per IP address every 60
seconds. On `429 Too Many Requests`, wait for the `Retry-After` interval instead
of looping.

## Verification

1. Call `list_businesses` with no arguments.
2. If it returns one Business, use it automatically. If it returns several, select only one explicitly identified by the user or ask which one to use.
3. Call `get_business_context` with the selected `business_id` when selection is required.
4. Confirm the business, currency, timezone, capabilities, and limits.
5. Run a scoped read such as `list_accounts`, preserving the same `business_id` throughout the workflow.
6. Before the first write, preview the exact proposal and confirm it.

## Tool surface

### Discovery

- `list_businesses`

It accepts no arguments and returns only locally usable Businesses authorized by OAuth, with `id`, `name`, `currency`, and `timezone`.

### Context and reads

- `get_business_context`
- `list_accounts`
- `get_account_balance`
- `search_categories`
- `search_contacts`
- `search_movements`
- `get_movement`
- `get_split`
- `search_recurrent_movements`
- `get_recurrent_movement`
- `search_plans`
- `get_plan`
- `search_automation_rules`
- `get_automation_rule`

Selection guidance:

- Use `search_contacts(padma_id: ...)` for an exact PADMA ID match inside the selected Business. Its `text` filter remains a partial name-or-PADMA-ID search.
- Every `search_contacts` result contains `id`, `name`, `padma_id`, and `status`, plus nullable enriched fields: `teacher` as `{id, name}` for the authorized local Agent, `learn_id` as a string, stored `ltv` as `{cents, currency}`, and `current_plan` as `{id, name}` for an authorized Plan in the selected Business. `teacher` and `current_plan` are null when their records are unavailable or inaccessible. These additions do not change filters, inputs, or cursor pagination.
- Use `search_movements(contact_padma_id: ...)` when the stable PADMA contact ID is already known, including when it came from a current CRM response. Do not first translate it into a Money-local integer ID.
- `contact_id` and `contact_padma_id` are mutually exclusive movement filters. Supplying both returns `validation_failed`.
- Use `search_movements(category_tree_ids: [...])` to include movements assigned to any selected category or its descendants. Resolve every root with `search_categories`; use `category_id` for an exact category. If both filters are supplied, Money returns their intersection.
- `search_categories` returns `monthly_budget` as null or `{cents, currency}`. The currency is the value stored for that category and may differ from the selected Business's base currency.
- Use `search_movements` for audit, reconciliation, category review, finding a specific payment, duplicate checks, or explaining an aggregate.
- Use `get_movement` immediately before updating, deleting, prorating, or subdividing one movement. A non-null `split_id` identifies the split that owns a resulting movement.
- Use `get_split` to inspect the original snapshot, every resulting movement—including soft-deleted targets—and whether the split is currently revertible.
- Use `category_subtotals` for category totals instead of summing a partially paginated movement page.
- Use `analyze_movements` for deterministic trends, variance, uncategorized items, aging, probable duplicates, outliers, and reporting-month mismatches.
- Use `search_plans` for forecast records and `search_recurrent_movements` for rules that create realized movements. Do not confuse the two.

### Saldo de cuenta en `get_account_balance`

Es una consulta de solo lectura. Requiere `account_id` entero y `date` como string en formato estricto `YYYY-MM-DD`; acepta el `business_id` opcional habitual. Resolvé la cuenta con `list_accounts` dentro del mismo negocio. Para cuentas archivadas, usá `list_accounts(archived: true)`.

Devuelve `account: {id, name}`, `date`, `timezone` y `balance: {cents, currency}`. El saldo incluye el día completo en la zona horaria del negocio y usa la moneda de la cuenta, que puede diferir de la moneda base del negocio. Incluye ingresos, egresos y transferencias con su conversión; los movimientos hechos impactan desde `movement_at`, los saldados desde `settled_at` y los pendientes no afectan el saldo. Las cuentas archivadas se pueden consultar; las eliminadas quedan excluidas. Una fecha futura calcula el saldo con los movimientos registrados hasta ese corte; no es una proyección de planes ni recurrencias todavía no generadas.

Ejemplo, después de resolver el negocio y el ID de la cuenta:

```json
{"account_id": 123, "date": "2026-10-31"}
```

Agregá el `business_id` autorizado cuando corresponda. Una fecha inválida devuelve `validation_failed`; una cuenta inexistente, eliminada o de otro negocio devuelve `not_found`; un acceso no autorizado devuelve `forbidden`. Para obtener el saldo de apertura de un período, consultá el cierre del día anterior. No sumes una página de movimientos para sustituir este cálculo.

### Deuda de pagos en `search_plans`

| Parámetro | Tipo y contrato |
| --- | --- |
| `from`, `to` | Strings de fecha ISO `YYYY-MM-DD`, siempre juntos. Se normalizan al mes y abarcan ambos meses completos. El mes de `from` debe ser anterior o igual al de `to`; máximo 36 meses inclusivos. |
| `has_debt` | Booleano opcional. Tanto `true` como `false` requieren `from` y `to`. Omitirlo no filtra por deuda. |
| `active_on` | Conserva el filtro existente por fecha cuando se usa solo. Es incompatible con `from` o `to`. |

El rango selecciona los planes activos en algún momento de esos meses, sin exigir que sigan activos hoy. `has_debt: true` conserva un plan cuando existe al menos un mes del rango cuyo primer día es anterior a la fecha de hoy en la zona horaria del negocio, el plan estaba activo en ese mes y `paid?` es falso para ese mes. Coincide con el reporte de planes impagos de la grilla. `has_debt: false` es el complemento dentro de los planes activos en el rango: también puede incluir planes cuyos únicos meses activos son futuros. No significa que todos sus pagos futuros ya estén hechos.

El primer día del mes actual todavía no cuenta para deuda; desde el segundo día, ese mes ya puede contar. Los meses futuros no cuentan. La regla usa el estado de pago del plan y no su saldo de cuenta. El filtro identifica planes, no calcula ni devuelve un total de deuda.

Ejemplos (agregá el `business_id` resuelto con `list_businesses` cuando corresponda):

```json
{"has_debt": true, "from": "2026-01-15", "to": "2026-03-20"}
```

Busca deuda en enero, febrero y marzo completos. Un plan terminado en febrero puede aparecer si quedó impago un mes en el que estuvo activo.

```json
{"has_debt": false, "from": "2026-01-01", "to": "2026-03-01"}
```

Devuelve los planes activos en ese rango sin meses que cumplan el criterio de deuda. Para buscar todos los planes activos en el rango, omití `has_debt`.

```json
{"has_debt": true, "from": "2026-09-01", "to": "2026-09-30"}
```

Si hoy es 8 de septiembre de 2026 en el negocio, septiembre participa; si hoy fuera el 1 de septiembre, todavía no. No sustituyas esta regla por «solo meses cerrados».

Las fechas incompletas, inválidas, invertidas por mes, `has_debt` sin rango y las combinaciones con `active_on` devuelven `validation_failed`. Los rangos mayores a 36 meses devuelven `limit_exceeded`. En cada página conservá el negocio, los filtros y el tamaño de página: los cursores firmados están asociados al alcance y a los filtros de la búsqueda. No reutilices un cursor para otro rango o valor de `has_debt`.

### Analysis

- `category_subtotals`
- `analyze_movements`

The aging finding is `aged_unsettled`: it flags movements older than the configured threshold unless their state is `settled`.

### Writes

- `create_movement`, `update_movement`, `delete_movement`
- `prorate_movement`, `subdivide_movement`, `revert_split`
- `create_category`, `update_category`
- `create_account`, `update_account`
- `create_recurrent_movement`, `update_recurrent_movement`, `delete_recurrent_movement`
- `create_plan`, `update_plan`
- `create_automation_rule`, `update_automation_rule`

The implemented MCP exposes thirty-four tools: `list_businesses` plus thirty-three Business-contextual tools. `delete_movement` performs a recoverable soft delete. `delete_recurrent_movement` permanently removes one recurrent rule while preserving movements it already generated. `revert_split` atomically restores one split's original movement and removes all unchanged targets. The MCP does not expose general movement restoration, physical deletion beyond recurrent movement rules, deletion of other record types, batch mutation, import, contact mutation, automatic bank-statement reconciliation, or the monthly budget report.
It also does not expose dedicated payable, receivable, or projected-cash-flow tools. Account balances at a date are available through `get_account_balance`. Category tools expose the configured monthly budget only; never claim that this is the report or that unsupported outputs are directly available.

## Shared contracts

- `business_id` is an optional integer on every tool except `list_businesses`. It selects from the OAuth-derived allowlist; it never grants access by itself.
- With one authorized Business, contextual tools select it automatically when `business_id` is omitted. With several, omission returns `business_required`.
- Use only IDs returned by `list_businesses`. An unknown or unauthorized selector returns `forbidden` without revealing whether another tenant exists.
- Record IDs are integers and are resolved only inside the selected Business.
- Monetary values use integer cents and always carry a currency. For example, ARS 1,000 is `100000` cents.
- Category responses from `search_categories`, `create_category`, and `update_category` expose `monthly_budget` as null or `{cents, currency}` using the category's stored currency.
- `request_id` is a client-generated UUID for durable write idempotency.
- `expected_updated_at` is the latest ISO 8601 timestamp from a read and protects updates, deletion, proration, and subdivision with optimistic concurrency.
- `revert_split` requires the exact `expected_movements` list returned by `get_split`, containing every target `id` and `updated_at`. A changed, deleted, added, duplicated, or omitted target produces `conflict`.
- Search responses are cursor-paginated. Default and maximum page sizes may vary by tool.
- Nullable `search_contacts` enrichments are independent: a missing teacher, Learn ID, LTV, or current plan does not establish that any of the others is missing.
- `search_contacts.padma_id` and `search_movements.contact_padma_id` are exact matches. An unknown `search_contacts.padma_id` returns an empty collection; an unknown or out-of-Business `contact_padma_id` returns `not_found`.
- `search_movements.category_tree_ids` is an array of category roots from the selected Business. Each root includes itself and all descendants; an unknown or out-of-Business root returns `not_found`.
- Related account, category, contact, agent, and target-account IDs must belong to the selected Business.
- Records belonging to another business appear as `not_found` to avoid leaking their existence.
- The rate limit is shared by the OAuth token across all its authorized Businesses.

### Dates and reporting months

- Use `movement_at` for when money actually moved.
- Use `settled_at` for when a pending movement affected the account balance.
- Use `report_on` for the reporting month. Its `from` and `to` inputs include whole calendar months, even when day components are supplied.
- Movement searches default to a recent period; specify the intended range rather than assuming all history was searched.

### Movement states

- `pending` movements count in reports but do not change account balances.
- `created` movements count in reports and change balances on `movement_at`.
- `settled` movements count in reports and change balances from `settled_at`. Settlement means completion of a formerly pending payment or transfer; bank-statement reconciliation is a separate process.

## Safe write patterns

### Create

1. Search all referenced records and resolve their IDs.
2. Preview the complete proposed record.
3. Confirm the exact mutation.
4. Generate one UUID `request_id` and call the matching `create_*` tool.
5. Read the created record back or locate it with a scoped search.

Never create related records implicitly. If a requested category or account is missing, ask before creating it with its explicit tool.

For `create_category`, `monthly_budget_cents` is optional. When supplied, it must be a non-negative integer. `monthly_budget_currency` is also optional and accepts `usd`, `brl`, `eur`, `ars`, or `btc`, including uppercase variants that Money normalizes to lowercase; when omitted, Money stores the Business base currency for compatibility with existing clients. Supplying currency without cents returns `validation_failed`. The created response returns the budget with its stored currency.

### Update

1. Fetch the current record.
2. Preview only the requested field changes.
3. Confirm the exact mutation.
4. Generate a UUID `request_id` and pass the latest `updated_at` as `expected_updated_at`.
5. Call the matching `update_*` tool with only changed fields.
6. Refetch and verify.

If `expected_updated_at` is stale, do not overwrite. Refetch and reconcile with the current record.

For `update_category`, `monthly_budget_cents` accepts a non-negative integer to set or change the configured budget, or null to remove it. `monthly_budget_currency` accepts `usd`, `brl`, `eur`, `ars`, or `btc`, including uppercase variants that Money normalizes to lowercase. Sending cents alone preserves the stored currency, or defaults to the Business currency when setting the first budget; sending currency alone preserves existing cents and requires a configured budget. Sending `monthly_budget_cents: null` clears both stored fields and must not be combined with `monthly_budget_currency`. Both fields participate in idempotency and optimistic concurrency, and explicitly supplied fields include their transitions in `changed_fields`. A category budget cannot overlap another configured budget on an ancestor or descendant; invalid amounts, currencies, field combinations, or overlapping values return `validation_failed`.

### Delete a movement

1. Fetch the current movement immediately before proposing deletion.
2. Show the Business, movement ID, type, account, amount and currency, dates, category, and description.
3. Explain that `delete_movement` is a soft delete: normal reads stop returning the movement, while Money preserves its record and audit history.
4. Obtain explicit confirmation for that exact movement.
5. Generate a UUID `request_id` and call `delete_movement` with the movement ID and latest `updated_at` as `expected_updated_at`.
6. Verify that `get_movement` returns `not_found`, then report the returned `deleted_at` timestamp.

Do not use deletion as a substitute for correcting an amount, date, category, or other editable field. Movement restoration and general physical deletion are not exposed; recurrent movement rules use the separate permanent-deletion workflow below, and `revert_split` applies only to a complete, unchanged split.

### Delete a recurrent movement

1. Fetch the recurrent movement immediately before proposing deletion.
2. Show the Business, recurrent movement ID, type, state, amount and currency, accounts, description, and recurrence limits.
3. Explain that `delete_recurrent_movement` permanently removes the recurrence rule and prevents future generation while preserving movements already created from it.
4. Obtain explicit confirmation for that exact recurrence.
5. Generate a UUID `request_id` and call `delete_recurrent_movement` with the recurrent movement ID and latest `updated_at` as `expected_updated_at`.
6. Verify that `get_recurrent_movement` returns `not_found`.

Do not delete the rule when an update to its state or limits satisfies the request. The operation does not delete movements previously generated by the recurrence.

### Prorate or subdivide a movement

Both operations replace the original movement with a new split. Obtain explicit confirmation after showing the complete result that will replace it.

For `prorate_movement`:

1. Fetch the movement immediately before writing and confirm it is neither a Transfer nor already part of a split.
2. Show the number of installments, their exact amounts, and their reporting months. The first uses the original `report_on`, later installments advance one month, and any cent remainder belongs to the last installment.
3. Generate a UUID `request_id` and call `prorate_movement` with the movement ID, latest `updated_at`, and `installments`.

For `subdivide_movement`:

1. Fetch the movement immediately before writing.
2. Show at least two positive integer-cent parts whose amounts exactly total the original. State every description, category, and agent override; omitted fields inherit from the original.
3. Resolve category and agent IDs inside the selected Business.
4. Generate a UUID `request_id` and call `subdivide_movement` with the movement ID, latest `updated_at`, and complete `parts`.

After either operation, use the returned split ID with `get_split` and verify the complete target list. Do not split a resulting movement again.

### Revert a split

1. Call `get_split` immediately before proposing the reversal.
2. Require `revertible: true`. Show the original movement that will be restored and every target that will be physically removed, including soft-deleted targets.
3. Obtain explicit confirmation for that exact split composition.
4. Generate a UUID `request_id` and call `revert_split` with the split ID and the exact target `id` and `updated_at` pairs returned by `get_split`.
5. Verify the restored movement with `get_movement`.

There is no `force` option. On `conflict`, stop, call `get_split` again, explain what changed, and request new confirmation. Never remove, add, or rewrite entries in `expected_movements` to bypass the conflict.

### Retry

Reuse a `request_id` only when the prior response was uncertain and the payload is byte-for-byte equivalent in meaning. A different payload requires a new UUID. Never retry a timed-out write with a new request ID before checking whether it persisted.

## Errors

- `401`: the OAuth session is missing, invalid, or expired. Reconnect Money and complete authorization.
- `403`: the OAuth session lacks the required access, the business is disabled, the user cannot authorize the action, or the client origin is rejected.
- `404` or `not_found`: the record is absent from the selected Business; verify the ID through a scoped search.
- `business_required`: more than one Business is authorized and a contextual tool omitted `business_id`; call `list_businesses`, select one, and retry.
- MCP `forbidden`: the requested `business_id` is not in the authorized allowlist or the local user cannot perform the action. Do not probe other IDs.
- Validation error: correct the typed inputs; do not bypass schemas.
- Conflict: refetch the record, or call `get_split` again for a reversal, and inspect any idempotency input mismatch before retrying.
- Rate limit: wait for the indicated retry interval. Do not loop aggressively.
- No tools: verify that the URL ends in `/mcp`, reconnect Money, complete OAuth authorization, and start a new task.
- Intended Business missing from `list_businesses`: reconnect Money and grant the corresponding account in OAuth.

Source: [Money MCP documentation in Notion](https://app.notion.com/p/39e3160bddf28027a1fbec7a5102e070), fetched 2026-07-16, reconciled with the implemented Money MCP contract. Authentication and multi-Business selection updated on 2026-07-21; split tool catalog updated on 2026-07-27; category-tree movement filtering updated on 2026-07-29; category budget currencies updated on 2026-07-31.
