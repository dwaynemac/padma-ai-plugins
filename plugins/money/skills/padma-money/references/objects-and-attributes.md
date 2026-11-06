# Money objects and attributes

Interpret Money records with these product semantics. The field names shown are the MCP names when a direct equivalent exists; consult `mcp-operations.md` for implemented tool schemas and write contracts.

## Contents

- Business
- Account
- Movement
- Split
- Category
- Plan
- Recurrent movement
- Automation rule
- Contact
- Currency and exchange-rate attributes
- Lifecycle distinctions
- Source pages

## Business

- `currency` is the school's base or global currency. It is used to present category subtotals after monthly conversion.
- A configured display currency or the UI's `view_in_currency` preview does not change the base currency or underlying records.
- OAuth fixes the Business allowlist. A `business_id` returned by `list_businesses` selects one authorized Business for contextual calls; any other identifier is context, not permission to switch tenants.

## Account

- `currency` is the single currency of the account. Interpret every movement amount in that account's currency unless the structured MCP result explicitly provides another currency field.
- An account represents where value is held: bank, cash, card processor, wallet, payment platform, or an internal current account. It is not a reporting category.
- An archived account stops appearing in forms and stops contributing to total balances. Its movements remain in history and continue contributing to category totals.
- Deleting an account is different: the product deletes its movements and removes them from balances and category totals. The MCP does not expose account deletion.
- The product can store a default import type per account. This is UI/import behavior and is not exposed by the MCP.

## Movement

- `type` describes the financial effect:
  - Income increases the source account and business total.
  - Expense decreases the source account and business total.
  - Transfer decreases one account and increases another without changing the business total.
- `account_id` identifies the source or owning account. For transfers, `target_account_id` identifies the destination account.
- `amount_cents` is an integer number of minor currency units. Determine its currency from the structured currency field or account; never parse formatted display text.
- `movement_at` is the actual movement date.
- `report_on` is the administrative reporting month. It controls monthly reports, category subtotals, and matching a payment to a plan; it can differ from `movement_at`.
- `state` controls balance timing, not report inclusion:
  - `pending`: included in reports; excluded from account balance.
  - `created`: included in reports; affects balance on `movement_at`.
  - `settled`: included in reports; affects balance from `settled_at`.
- `settled_at` is meaningful for a settled movement and records when a formerly pending movement began affecting the balance.
- `category_id` classifies the movement for reporting; it does not identify where money is held.
- `contact_id` attributes the movement to a person and affects that contact's LTV.
- `agent_id` attributes an instructor or agent. Do not confuse it with the contact.
- `split_id` is null for an unsplit movement and identifies the owning split for a resulting movement. Use `get_split`; do not infer sibling movements from IDs or descriptions.
- A transfer between accounts in different currencies may have a movement-specific exchange rate. That rate can differ from the reference rate for the month.

## Split

- `original_movement` is the immutable snapshot that existed before proration or subdivision.
- `movements` contains every target created by the split, including targets later soft-deleted.
- Each target exposes `updated_at` and `deleted_at`; preserve the exact IDs and `updated_at` values when proposing `revert_split`.
- `revertible` reports whether current authorization, blocked-period rules, Business consistency, and target state permit reversal.
- Reversal is conservative and atomic. It has no `force` or partial mode.

## Category

- Categories classify income or expense for subtotals and reports. They do not carry balances.
- `parent_id` places a category in the hierarchy. Values assigned to a child roll up into its ancestors.
- `monthly_budget` is null or `{cents, currency}` using the category's stored budget currency, which can differ from the Business base currency. It is the configured monthly target, not an account balance or a monthly report result.
- `create_category.monthly_budget_cents` optionally sets the budget and `monthly_budget_currency` optionally selects `usd`, `brl`, `eur`, `ars`, or `btc`; uppercase codes are accepted and normalized to lowercase. Omitting currency defaults to the Business base currency. Supplying currency without cents is invalid.
- `update_category` may change cents, currency, or both. Cents alone preserve the current currency, except that setting the first budget defaults to the Business currency; currency alone preserves existing cents and requires an existing budget. `monthly_budget_cents: null` removes both values and is invalid when combined with `monthly_budget_currency`. Ancestor and descendant categories cannot both have configured budgets in the same branch.
- Notes describe the organization's classification convention. They are guidance for categorization, not financial data; the MCP does not expose note editing.
- An archived category is removed from forms, the category screen, and reports. Existing records remain stored, but their historical values do not appear in category reports while the category is archived.
- A category linked to movements, recurrent movements, or plans cannot be deleted in the product until those links are changed. The MCP does not expose deletion.

## Plan

- A plan is a monthly income forecast over a period. It does not create movements, affect balances, or enter category reports.
- It requires a contact and category. Interpret its value as expected income, not realized income.
- A payment fulfills the corresponding plan month according to the movement's `report_on`, not necessarily `movement_at`.
- When forecast and payment currencies differ, the product allows a 1% conversion margin when determining fulfillment.
- A primary plan is the one synchronized to PADMA when a contact has multiple plans.
- Learn-synchronized plans can have contact, category, value, and end date overwritten on later synchronizations; a canceled Learn subscription cancels its plan.

## Recurrent movement

- A recurrent movement is a rule that creates actual income or expense movements each month. Its generated movements affect reports and balances according to their own states.
- It may be limited by recurrence count or end date.
- It can be used alongside a plan, but they represent different facts: realized repeated movements versus forecast monthly income.

## Automation rule

- An automation rule runs only when a movement is created, including manual creation, import, and synchronization. Updating a rule does not reprocess historical movements.
- A metadata rule derives category, agent/instructor, or contact from the movement description.
- A convert-to-transfer rule converts matching credits or debits into transfers involving the selected account.

## Contact

- A contact represents a related person used for attribution, selection, plans, and analysis. The MCP exposes contact search but not contact mutation.
- Contact search preserves `id`, `name`, `padma_id`, and `status`. It also returns nullable `teacher` (`{id, name}` for the authorized local Agent), `learn_id` (string), stored `ltv` (`{cents, currency}`), and `current_plan` (`{id, name}` for an authorized Plan in the selected Business).
- Interpret `teacher` and `current_plan` as compact related-record summaries, not complete records. Both are null when their related records are unavailable or inaccessible. Use their returned IDs only inside the selected Business and do not invent details that are not present.
- LTV is total income attributed to the contact minus attributed expenses. When returned by MCP, use the exact integer `cents` and accompanying `currency`.
- In the documented Argentina behavior, LTV is shown in USD by converting each ARS movement with the exchange rate for that movement's corresponding month.

## Currency and exchange-rate attributes

- Supported documented account currencies are ARS, BRL, EUR, USD, and BTC.
- Automatic conversions use one configured exchange rate per month. Category subtotals use the rate for the subtotal month.
- A cross-currency transfer can store its own rate on the movement. Treat it as transaction-specific and do not replace it with the monthly reference rate.
- UI currency preview uses the current rate and changes presentation only. Do not use a previewed value as the stored amount or as evidence that the business base currency changed.
- Do not add values in different currencies unless the MCP returns an explicit supported conversion basis.

## Lifecycle distinctions

| Action | Account effect | Category effect |
|---|---|---|
| Archive | Hidden from forms and excluded from total balances; movements remain in history and category totals | Hidden from forms and reports; stored historical values stop appearing in category reports |
| Delete | Product deletes the account's movements and removes their effects; unsupported by MCP | Product requires linked records to be changed first; unsupported by MCP |

## Source pages

Fetched from the canonical [Money documentation](https://app.notion.com/p/d3f8c1b5da5c44be8ec38d06891c185c) on 2026-07-16:

- [Accounts](https://app.notion.com/p/73c5ffd7acdf437ab6b60e8800a0b83f) and [archive versus delete](https://app.notion.com/p/c0f0259394aa4518bf82a22b850988a4)
- [Movements](https://app.notion.com/p/153638ddc21440eeaf7ca24887da4758)
- [Categories](https://app.notion.com/p/105d8b73df8744b2948fea7eee990af3)
- [Plans](https://app.notion.com/p/a0ac2e68f9ef45c783d0e79f1d0bdd1c) and [recurrent movements](https://app.notion.com/p/2c36e123f6e74df29233d64ddcd1b68a)
- [Currencies](https://app.notion.com/p/3a2b7491a0bf4b958618bba0790ea7f4), [exchange rates](https://app.notion.com/p/2bf3160bddf280119e71da42c3c79a4d), and [currency preview](https://app.notion.com/p/85748507d7614d98ac8f3a78ec6de91a)
- [Automations](https://app.notion.com/p/323e1c1a77084930aa31f78b57d30511), [contacts](https://app.notion.com/p/1af3160bddf280418491f02df0578535), and [Learn synchronization](https://app.notion.com/p/8e49a633ffb24aa2baf17036f8159775)
