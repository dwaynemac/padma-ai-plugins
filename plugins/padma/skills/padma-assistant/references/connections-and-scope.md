# Connections and organizational scope

## MCP connections

| Server | Resource | Required scope | First proof call |
|---|---|---|---|
| `crm` | `https://crm.derose.app/mcp` | `openid profile account crm` | CRM `list_accounts` |
| `money` | `https://money.derose.app/mcp` | `openid profile account money` | Money `list_businesses` |
| `learn` | `https://learn.derose.app/mcp` | `openid profile account learn` | Learn `list_accounts` |

Los tres servidores usan PADMA Accounts OAuth, registro dinámico de clientes y PKCE. El cliente administra las credenciales; no configures Client ID ni Client Secret compartidos. El audience del token debe coincidir exactamente con su recurso MCP, incluidos esquema, hostname y `/mcp`.

Each server has its own OAuth grant and resource. Una conexión exitosa con un producto no autoriza los otros. Learn también ofrece `https://learn.padm.am/mcp`; seguí `padma-learn` para configurar ese recurso y su grant independiente. Login/configuration alone is not live verification: require the first proof call and at least one contextual tool call.

## Independent selectors

CRM uses stable `account_name`. Money uses the integer `business_id` returned by `list_businesses`. Learn también usa `account_name`, pero debe descubrirse y verificarse mediante su propio `list_accounts` y `get_account_context`. La coincidencia de selectores no comparte permisos entre productos.

- With one authorized organization, each MCP can usually select it automatically.
- With several, explicitly select from the discovery response or ask the user.
- Never pass a CRM selector to Money or a Money ID to CRM.
- Similar display names are not proof that two tenants represent the same organization.
- Do not probe names or IDs not returned by discovery.

A contact `padma_id` is different from these organization selectors. A current CRM result may provide it as a stable identity bridge for an exact Money `padma_id` or `contact_padma_id` filter, but the Money call must still use a separately authorized and selected `business_id`.

## Availability and authorization

- Missing tools: install or update the affected `crm`, `money` or `learn` plugin, start a new task, and then reconnect that MCP. For CRM only, first check and attempt MCP, then honor an explicit browser request under `padma-crm` “Explicit browser access”. Verify UI account scope when MCP is not exposed; never use this exception for a denied account/action, authentication failure, or restricted data. Money y Learn usan sólo MCP.
- `401`: reconnect the affected server and verify its exact resource URL.
- `403` or `forbidden`: refresh discovery and authorization; do not probe other tenants.
- `429`: wait for `Retry-After` instead of looping.
- `503`: Accounts could not validate the credential; retry later without treating the grant as rejected.
- Intended organization absent from discovery: reconnect that product and authorize the required account.

If one MCP is unavailable during a combined request, continue with a useful, clearly partial result, or the explicitly requested CRM browser path under its safeguards. State each source and what could not be verified; CRM browser access does not authorize Money or Learn access.
