# Money domain model

Use these distinctions before selecting tools or calculating results.

## Business

The PADMA tenant whose financial data is available. OAuth resolves one or more authorized Businesses. `list_businesses` exposes that allowlist, and `business_id` selects one member for a contextual tool call; the ID never grants access by itself.

## Account

A balance-bearing location such as cash, bank, card processor, virtual wallet, or internal current account. Each account has one currency.

An account is not a reporting category. Moving money between two business accounts is a transfer, not income or expense.

## Movement

A financial record with a type, state, source account, amount, movement date, reporting month, and optional related records.

- Income increases the business total.
- Expense decreases the business total.
- Transfer moves value between accounts and must not be counted as income or expense.

Movement state controls balance timing. Reporting month controls report attribution. See `mcp-operations.md` for exact date behavior.

## Split

A split replaces one original movement with two or more target movements while preserving a PaperTrail snapshot of the original.

- Proration creates equal installments from a non-Transfer movement in consecutive reporting months, beginning with the original `report_on`; the final installment receives any cent remainder.
- Subdivision creates explicit positive parts that exactly total the original. Omitted description, category, and agent values inherit from the original.
- A resulting movement exposes `split_id`, which can be passed to `get_split`.
- Reversal is all-or-nothing: it restores the original and physically removes every target only when the complete target list and timestamps still match.

Do not treat a split as duplication: after a successful split, the original is absent from normal movement reads and only the targets affect reports and balances.

## Category

A hierarchical reporting classification, separate from an account. Child-category values roll up to parent totals. Categories have income or expense sections and may define one monthly budget in a supported currency, independently of the Business base currency. Monthly reports convert it to the Business currency using the applicable reporting-month rate. A configured category budget is not a balance or the monthly budget report; only one category in an ancestor-descendant branch may carry a budget.

## Contact and agent

Related people used for selection, attribution, filtering, and analysis. The MCP can search contacts but cannot create or update them.

## Plan

A forecast of expected monthly income associated with a contact and category. A plan does not itself create a movement or change category reports.

## Recurrent movement

A rule that creates actual movements over time. Unlike a plan, the generated movements affect reports and potentially balances according to their states.

## Automation rule

A rule applied only when a movement is created. It can assign metadata or convert matching movement types into transfers. Updating a rule does not retroactively change old movements.

## Reporting concepts

- Actual movement date: when the money moved.
- Settlement date (`settled_at`): when a pending movement began affecting the account balance.
- Reporting month: the administrative month used for reports and plan matching.
- Category subtotal: a deterministic aggregate of report-attributed movements.
- Analysis finding: evidence produced by Money for trends, variance, missing categorization, aging, duplicates, outliers, or date/report-month mismatch.

## Guardrails

- Do not mix realized movements with plan forecasts without labeling them separately.
- Do not add different currencies unless an explicit supported conversion basis is available.
- Do not infer a missing payment until the relevant accounts, date basis, period, pagination, and filters have been checked.
- Consultá saldos de cuentas por fecha con `get_account_balance`; no los infieras de reportes por categoría. No inventes compromisos, cuentas por pagar o cobrar ni resultados del reporte de presupuesto mensual: esas consultas no tienen herramientas específicas en el MCP.
