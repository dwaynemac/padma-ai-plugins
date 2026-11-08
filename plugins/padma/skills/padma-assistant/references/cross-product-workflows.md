# Cross-product workflows

## School overview

1. Resolve the CRM account and Money Business independently.
2. Confirm one common calendar period.
3. In CRM, use persisted monthly statistics, comparisons, `get_marketing_method_statistics`, `get_dropout_reason_statistics`, or `get_lead_funnel` for the historical commercial context that matches the question. Use `get_commercial_funnel` only when the overview also needs the contacts requiring follow-up now.
4. In Money, use category subtotals and deterministic movement analysis for financial context.
5. Si el panorama incluye actividad educativa, consultá Learn mediante `padma-learn` y conservá escuela, período, timezone y filtros de sus reportes. Presentá por separado la evidencia de cada producto antes de interpretarla.
6. Label CRM missing months, Money date basis, pagination, currencies, freshness, and material filters.

Do not imply that commercial changes caused financial changes solely because the periods align. Describe correlation as interpretation unless the returned data directly establishes a relationship.

## Contact and payment questions

1. Resolve the CRM account and Money Business independently through `list_accounts` and `list_businesses`. Keep `account_name` only on CRM calls and `business_id` only on Money calls.
2. Find the person in CRM within the selected account using the minimum personal data needed. Confirm the intended result and retain its current `padma_id`.
3. For Money contact metadata or membership verification, call `search_contacts(padma_id: crm_contact.padma_id)` inside the selected Money Business. This is an exact match and returns an empty collection when that contact is not connected to the Business. A match preserves its Money `id`, `name`, `padma_id`, and `status`, and can also provide nullable `teacher` (`{id, name}`), `learn_id` (string), `ltv` (`{cents, currency}`), and `current_plan` (`{id, name}`).
4. For realized movements, call `search_movements(contact_padma_id: crm_contact.padma_id, ...)` directly with an explicit date field and period. Do not perform an intermediate lookup merely to obtain Money's integer `contact_id`.
5. Do not send `contact_id` together with `contact_padma_id`. An unknown or out-of-Business `contact_padma_id` returns `not_found`.
6. Paginate Money movement results when `next_cursor` is present and preserve the same contact, period, page size, and Business filters on every page.
7. Distinguish CRM relationship status from Money payment expectation and realized financial movements.

The cross-product call shape is:

```text
CRM search_contacts(account_name: selected_crm_account, ...)
  -> crm_contact.padma_id
Money search_contacts(business_id: selected_money_business, padma_id: crm_contact.padma_id)
Money search_movements(business_id: selected_money_business, contact_padma_id: crm_contact.padma_id, date_field: ..., from: ..., to: ...)
```

`padma_id` is the shared identity key. It does not authorize either product, select an organization, or prove that similarly named CRM and Money tenants correspond.

Absence from one account or Business does not prove that the person does not exist elsewhere. A CRM student status does not prove payment, and a Money plan does not prove learning access.

Treat every nullable Money contact enrichment independently. Do not turn a missing `teacher`, `learn_id`, `ltv`, or `current_plan` into a claim about CRM relationship data, Learn access, or realized payments. When presenting LTV, retain its exact cents and currency.

## Relacionar un alumno de Learn con CRM y Money

1. Descubrí y seleccioná las organizaciones por separado: CRM `list_accounts`,
   Learn `list_accounts` y Money `list_businesses`, con sus consultas de contexto.
   Usá sólo los productos necesarios para la solicitud.
2. Si comenzás en Learn, usá `list_users` y luego `get_user(user_id: ...)` para
   confirmar el alumno dentro de la escuela. El `id` de un item de `list_users`
   es `accounts_user_id`, no `user_id`; este último puede ser nulo para una
   invitación pendiente. No intentes resolver esa invitación como alumno activo.
3. Buscá candidatos en CRM con los filtros de identidad realmente disponibles,
   usando sólo los datos necesarios devueltos por Learn. Pedí
   `response_fields: ["learn_user_id"]`. Confirmá el contacto comparando ese
   campo con el `user_id` de Learn; el nombre o email por sí solos no prueban el
   vínculo. Si no hay filtro exacto por Learn ID, recorré las páginas necesarias
   y compará los valores devueltos, sin inventar parámetros de búsqueda.
4. Si comenzás en CRM, pedí el mismo campo en `get_contact` o `search_contacts`
   y usá su valor no nulo en Learn `get_user`, con el `account_name` de Learn.
   Una lectura exitosa verifica el alumno y su acceso en esa escuela; el ID
   guardado en CRM por sí solo no confirma su acceso educativo actual.
5. Con el `padma_id` del contacto CRM confirmado, usá Money
   `search_contacts(padma_id: ...)` y, si corresponde, `search_movements` con
   `contact_padma_id` y período explícito, siempre en el negocio seleccionado.
   Conservá las reglas de [contactos y pagos](#contact-and-payment-questions).
6. Si comenzás en Money, verificá su `padma_id` en CRM `get_contact` con
   `response_fields: ["learn_user_id"]` y continuá hacia Learn. El `learn_id`
   nullable de Money es una referencia adicional: no lo sustituyas por
   `padma_id`, `accounts_user_id` ni un ID local de contacto. Contrastalo con
   el vínculo CRM y la lectura Learn antes de presentar una identidad conjunta.
7. Si falta el vínculo, hay varios contactos para el mismo alumno, los IDs no
   coinciden o un producto devuelve `not_found`/`forbidden`, informá qué parte
   no pudo confirmarse. No crees contactos, invites alumnos ni repares vínculos
   como efecto implícito de una consulta. No pruebes otras escuelas por el error.

El recorrido confirmado desde CRM usa identificadores diferentes:

```text
CRM get_contact(account_name: crm_account, padma_id: confirmed_padma_id,
                response_fields: ["learn_user_id"])
  -> contact.learn_user_id
Learn get_user(account_name: learn_account, user_id: contact.learn_user_id)
Money search_contacts(business_id: money_business, padma_id: confirmed_padma_id)
```

Consultá accesos, cursos, suscripciones y asistencia actuales en Learn según
`padma-learn`. Un `learn_activity_summary` leído en CRM es un snapshot guardado,
no una consulta actual a Learn. Un plan o pago de Money no prueba acceso a
contenido ni asistencia; una suscripción Learn no prueba un movimiento
financiero registrado en Money. Conservá fuente, fecha, timezone y cobertura.

## Deuda de pagos de planes

1. Resolvé el negocio Money con `list_businesses` y fijá el período solicitado.
2. Usá `search_plans(has_debt: true, from: ..., to: ...)` con fechas ISO y ambos meses inclusivos, hasta 36 meses. No combines `active_on` con el rango.
3. Paginá conservando el negocio, rango, `has_debt` y demás filtros. Los planes pueden haber terminado: alcanza con que hayan estado activos en el rango y tengan un mes activo impago cuyo primer día sea anterior a hoy en el negocio.
4. El mes actual participa desde su segundo día. No presentes el resultado como saldo de cuenta, importe total adeudado ni prueba del estado comercial o de acceso a clases.
5. Para planes sin meses que cumplan ese criterio dentro del rango, usá `has_debt: false`; para todos los planes activos en el rango, omití `has_debt`. Un plan futuro sin meses vencidos también puede cumplir `false`.

Si necesitás contexto CRM, vinculá identidades sólo mediante el `padma_id` confirmado y resolvé cada organización por separado. La fuente del filtro de deuda sigue siendo Money; seguí su referencia de operaciones para el contrato completo.

## Funnel and financial comparison

1. Use CRM `get_lead_funnel` for demand, visits, profile visits, enrollments, and conversions.
2. Use CRM `get_marketing_method_statistics` when the comparison needs acquisition and conversion by method, or `get_dropout_reason_statistics` when it needs dropout counts by reason.
3. Use CRM monthly series when zero versus missing funnel source data matters.
4. Use Money reporting-period aggregates for income or expense comparisons; specify `report_on` when the question is about an accounting month.
5. Align CRM `start_month` and `end_month` with the Money reporting period, but preserve each product's date semantics and source.
6. Keep rate deltas as percentage points and financial values in their currencies.
7. Explain changes with evidence from each product; do not manufacture per-contact attribution that the tools did not return.

`get_commercial_funnel` answers a different question: it is a current
operational snapshot of acquisition, qualified, booked, trialed, and enrolled
contact lists. Use it when the user wants present follow-up workload, then open
a returned `list_id` with `get_contact_list`. Do not compare those live list
counts with historical Money periods as if they were conversion metrics.

## Writes in a combined workflow

CRM can assign or remove existing contact tags through available tag tools, create or reuse contacts, create supported properties, create or update communications, and create account-visible contact comments. Money supports typed creates and updates for movements and selected financial configuration, plus recoverable movement deletion.

### CRM contact and communication writes

Follow the `padma-crm` skill and keep the selected `account_name`:

- For tag assignments, follow `padma-crm`: confirm tool availability, resolve the CRM contact and existing tags in the selected account, then use `add_contact_tags` or `remove_contact_tags`. Report actual changes and final tags; do not create or delete tags.
- For a new person, call `create_contact` with a first name and exact email or phone. Stop on ambiguous identity instead of choosing a candidate.
- For a contact property, resolve the contact, discover custom definitions when relevant, and call `create_contact_property` with only type-specific fields. Treat normalized duplicates as successful reuse.
- For a new communication, resolve the contact, discover any marketing methods, and call `create_contact_communication` with one fresh `request_id`. Reuse it only for an identical retry.
- To correct a communication, identify its `object_id` in contact history and call `update_contact_communication` with only the approved fields. Treat marketing methods as a complete replacement.
- For a comment, use the exact user-approved text, call `create_contact_comment` once, and inspect contact history before retrying an uncertain result.

Do not treat CRM contact creation as permission to create a related Money contact or record.

### Escrituras Learn

Seguí `padma-learn` para la operación explícitamente solicitada, sus efectos,
permisos, idempotencia, control de revisión y lectura posterior. Una consulta
combinada no autoriza sincronizar identidades, accesos o cobros. Ante una
escritura fallida en otro producto, informá los resultados parciales; no
prometas atomicidad ni ejecutes compensaciones no solicitadas.

### Money writes

1. Search and fetch the intended Money records inside the selected Business.
2. Resolve every related Money ID; never reuse a CRM identifier.
3. Check plausible duplicates for new movements.
4. Show Business, operation, account/currency, amount, dates, category, description, and, for updates, only the fields that will change.
5. Obtain confirmation unless the identical proposal was already confirmed.
6. Use one fresh UUID `request_id`; for updates and movement deletion, pass the latest `updated_at` as `expected_updated_at`.
7. Verify and report the result. Refetch creates and updates; for a deleted movement, verify that normal Money reads return `not_found`. On conflict or uncertain timeout, inspect current state before retrying.

Never create a missing account, category, contact, or other related record implicitly. Never present a CRM read as verification that a Money write persisted.

## Combined answer format

Lead with the outcome, then keep sources auditable:

```markdown
## Panorama

CRM account: <account_name>
Money Business: <business>
Learn school: <account_name, si se usó>
Period: <inclusive period>

### Commercial and contacts — CRM
<confirmed metrics, filters, missing months, freshness>

### Financial — Money
<confirmed totals/findings, date basis, currencies, filters>

### Educational access and activity — Learn
<accesos, cursos o asistencia confirmados, período, timezone y filtros; si se usó>

### Interpretation
<clearly labeled cross-product observations>

### Coverage
<pagination, exclusions, unavailable tools, unresolved identity links>
```
