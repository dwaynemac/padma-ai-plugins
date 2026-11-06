# Money product guide

Snapshot of the [Money documentation in Notion](https://app.notion.com/p/d3f8c1b5da5c44be8ec38d06891c185c), fetched 2026-07-16. Use this reference for product meaning; use `mcp-operations.md` for the implemented MCP contract.

## Contents

- Product purpose and first steps
- Accounts and currencies
- Movements and reporting
- Categories
- Plans and recurrent movements
- Automations and imports
- Contacts and LTV
- External reports and links
- Learn synchronization
- Source pages

## Product purpose and first steps

Money tracks income and expenses for participative financial administration. Its setup is intentionally simple and adaptable to different schools.

Recommended first steps:

1. Create the financial accounts: bank accounts, reception cash, card processors, Stripe or MercadoPago, and internal current accounts when applicable.
2. Define income and expense categories such as monthly fees, rent, fixed costs, and variable costs.
3. Add automation rules for repeated classification patterns.

## Accounts and currencies

Every movement belongs to an account. Each account has exactly one currency, and every movement inside it is interpreted in that currency.

The documented currencies are ARS, BRL, EUR, USD, and BTC. The school has one global currency. Category subtotals are presented in that global currency using the relevant month's exchange rate. Transfers between accounts with different currencies may specify their own exchange rate. UI currency previews use the current rate for presentation and do not change the business's base currency.

An archived account disappears from forms and no longer contributes to total balances, but its movements remain in history and category totals. Deleting an account also deletes its movements and removes their effects. The MCP currently supports account archive and unarchive through `update_account`; it does not expose deletion.

## Movements and reporting

Money has three movement types:

- Income increases an account balance and the business total.
- Expense decreases an account balance and the business total.
- Transfer moves value between accounts without changing the business total.

Movement state controls balance impact:

- `pending`: included in reports and category subtotals, but not in account balance.
- `created`: included in reports and reflected in the account balance at the movement date.
- `settled`: included in reports and reflected in the account balance from `settled_at`, when a formerly pending payment or transfer was completed.

The reporting month is independent from the actual movement date. Use it when a payment belongs to a different administrative month, such as a student paying one month's fee during another month.

## Categories

Categories organize reports and subtotals. They form a hierarchy: movements assigned to a child category roll up into its parent totals.

Category notes document the team's classification standard. A category linked to movements, recurrent movements, or plans should be archived rather than deleted when its history must remain. Archived categories leave existing data intact but disappear from forms and reports according to the documented product behavior.

Categories may define a monthly budget in `usd`, `brl`, `eur`, `ars`, or `btc`, independently of the Business base currency. A budget can be zero, but cannot be negative; ancestors and descendants cannot both define budgets in the same branch. Monthly reports convert a foreign-currency budget to the Business currency with the applicable reporting-month rate, so converted progress depends on that rate being available.

The MCP supports creating, renaming, reparenting, archiving, unarchiving, and setting or removing category budgets. `search_categories`, `create_category`, and `update_category` return the configured budget with integer cents and its stored currency. Omitting the currency when creating a budget keeps older clients compatible by using the Business base currency. It does not expose the monthly budget report, category deletion, or category-note editing.

## Plans and recurrent movements

A plan represents expected monthly income during a period. It does not create movements or directly change category reports. A plan belongs to a contact and category and may be marked primary for PADMA synchronization.

A recurrent movement creates actual movements according to its recurrence. It may represent income or expense and can have a count or end-date limit.

The distinction is important:

| Concept | Plan | Recurrent movement |
|---|---|---|
| Represents | Monthly income forecast | Repeated financial movement |
| Included in reports | No | Yes, through created movements |
| Requires contact | Yes | No |
| Requires category | Yes | No |

## Automations and imports

Automation rules run only when a movement is created, whether manually, through import, or through synchronization.

Documented automation types:

- Metadata rules add category, instructor/agent, or contact based on movement description.
- Convert-to-transfer rules turn matching income or expenses into transfers to or from a selected account.

Money's product UI supports file imports and per-account default import types. The MCP does not currently expose import tools.

## Contacts and LTV

Lifetime Value sums income associated with a contact and subtracts associated expenses. In Argentina, the documented LTV is expressed in USD by converting each ARS payment using the exchange rate for its corresponding month.

The MCP can search contacts for selection and analysis but does not expose contact mutation.

## External reports and links

Money can link to external Google Sheets used for monthly movement exports, monthly closing, advanced closing, and arbitrary-period movement reports. External links provide fast access from Money to those reports.

These Sheets workflows are product capabilities outside the Money MCP tool surface.

## Learn synchronization

The Notion documentation describes experimental Learn integrations:

- Payments may be sent to Money as income when the Learn payment account is mapped to a Money account.
- Subscriptions with a valid Money category may be upserted as plans; later synchronizations can overwrite contact, category, value, and end date.

Treat this as background product behavior, not as an MCP operation. Verify current integration behavior before relying on it because the source documentation labels it experimental.

## Source pages

- [Money](https://app.notion.com/p/d3f8c1b5da5c44be8ec38d06891c185c)
- [Primeiros pasos](https://app.notion.com/p/1c13160bddf28024896ed99279913678)
- [Contas](https://app.notion.com/p/73c5ffd7acdf437ab6b60e8800a0b83f)
- [Archivar cuentas vs eliminar cuentas](https://app.notion.com/p/c0f0259394aa4518bf82a22b850988a4)
- [Movimentos](https://app.notion.com/p/153638ddc21440eeaf7ca24887da4758)
- [Categorías](https://app.notion.com/p/105d8b73df8744b2948fea7eee990af3)
- [Planos](https://app.notion.com/p/a0ac2e68f9ef45c783d0e79f1d0bdd1c)
- [Movimentos recorrentes](https://app.notion.com/p/2c36e123f6e74df29233d64ddcd1b68a)
- [Moedas](https://app.notion.com/p/3a2b7491a0bf4b958618bba0790ea7f4)
- [Taxas de câmbio](https://app.notion.com/p/2bf3160bddf280119e71da42c3c79a4d)
- [Previsualizar en otra moneda](https://app.notion.com/p/85748507d7614d98ac8f3a78ec6de91a)
- [Importar movimentos](https://app.notion.com/p/c8727841213c479891d078caad0e9970)
- [Reportes no Google Spreadsheet](https://app.notion.com/p/d2ca50e9ef7340378e76464070286670)
- [Automatizaciones](https://app.notion.com/p/323e1c1a77084930aa31f78b57d30511)
- [Links Externos](https://app.notion.com/p/a57e10af251c46c7832be2100545772c)
- [Sincronização com Learn](https://app.notion.com/p/8e49a633ffb24aa2baf17036f8159775)
- [Contatos](https://app.notion.com/p/1af3160bddf280418491f02df0578535)
- [MCP (AI Agents)](https://app.notion.com/p/39e3160bddf28027a1fbec7a5102e070)
