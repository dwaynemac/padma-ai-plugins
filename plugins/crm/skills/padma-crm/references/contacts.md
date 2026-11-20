# CRM contacts

## Search

Use `search_contacts` for names, stable `padma_id` values, emails, phones, account relationship state, and recorded activity. Use `status` for one value or `statuses` for several values from the selected account's `contact_statuses`; never send both.

Use the exact input names published by the tool schema:

| Group | Inputs |
|---|---|
| General | `text`, `status`, `statuses` |
| Identity and location | `first_name`, `last_name`, `email`, `telephone`, `gender`, `occupation`, `address`, `neighborhood`, `city`, `state`, `country`, `postal_code`, `younger_than`, `older_than` |
| Birthday | `birthday_day`, `birthday_month`, `birthday_year` |
| Current account relationship | `local_teacher`, `coefficient`, `level`, `access_type`, `filiation_tier`, `in_professional_training`, `professional_training_level`, `followed_by_user` |
| Stored relationship dates | `student_on`, `first_enrolled_on_gte`, `first_enrolled_on_lte`, `last_enrolled_on_gte`, `last_enrolled_on_lte`, `first_communicated_at_gte`, `first_communicated_at_lte`, `last_communicated_at_gte`, `last_communicated_at_lte`, `last_seen_at_gte`, `last_seen_at_lte`, `last_seen_days_ago_gt`, `last_seen_days_ago_lte`, `last_booking_on_gte`, `last_booking_on_lte` |
| Presence and integrations | `seen`, `never_seen`, `booked`, `never_booked`, `has_gympass`, `has_totalpass`, `has_learn`, `owe_medical_check` |
| Communications | `communication_period`, `communication_period_start`, `communication_period_end`, `communication_direction`, `communication_media`, `contacts_closest_communication_media`, `communication_estimated_coefficient`, `communication_is_trial` |
| Next actions | `next_action_quick_period`, `next_action_period_start`, `next_action_period_end`, `next_action_responsible`, `next_action_booked_by` |
| Visits and remote visits | `televisit_period_start`, `televisit_period_end`, `televisit_usernames`, `visit_period_start`, `visit_period_end`, `visit_usernames`, `has_visits`, `has_no_visits` |
| Trial lessons | `trial_on_lt`, `trial_on_gt`, `with_trial_gt_ago`, `with_trial_lt_ago`, `assisted`, `didnt_trial` |
| Enrollments | `enrolled_days_ago_gt`, `enrolled_days_ago_lt`, `enrollment_period`, `enrollment_period_start`, `enrollment_period_end`, `enrollment_month`, `enrollment_usernames`, `enrollment_access_type` |
| Dropouts | `dropout_period`, `dropout_period_start`, `dropout_period_end`, `drop_out_access_type`, `dropout_reason_ids` |

Explicit dates use `YYYY-MM-DD`. Named period values and other enums must come from the live tool schema. Boolean presence filters apply when sent as `true`; omit them when they should not constrain the search.

Birthday components are integers and can be combined independently. Use `birthday_day` and `birthday_month` for birthdays on a calendar date, only `birthday_month` for the whole month, and add `birthday_year` when the year must match. Omit components that should not constrain the search; valid ranges are 1–31 for the day, 1–12 for the month, and a positive year.

`first_enrolled_on_gte` and `first_enrolled_on_lte` filter by the contact's first recorded enrollment. `last_enrolled_on_gte` and `last_enrolled_on_lte` filter by the most recent enrollment recorded in the selected account.

## Discover IDs before filtering

- Call `list_tags`, then pass returned `tag_id` values as `tag_ids`.
- Call `list_marketing_methods`, then pass returned active `marketing_method_id` values as `marketing_method_ids`.
- Call `list_dropout_reasons`, then pass returned `dropout_reason_id` values as `dropout_reason_ids`.
- Call `list_contact_lists`, then pass returned `list_id` values as `intersect_list_ids`, `union_list_ids`, or `not_in_list_ids`.
- Call `list_custom_property_definitions`, then pass returned `property_configuration_id` values only as response selectors, never as contact filters.

List conjunction semantics are explicit: intersection requires membership in every selected list, union requires membership in any selected list, and exclusion removes members of every selected list. Never copy an ID from another account or reuse discovery results after switching accounts.

Search results are account-scoped summaries. Paginate until the requested scope is complete, or state clearly that the answer covers only the returned page. Do not reuse a cursor after changing the account, any filter, response selector, or page size.

## Tag assignments

With CRM MCP 1.19.0 or later, use `add_contact_tags` or `remove_contact_tags` only if the connected server exposes that tool. Both require write capability. Resolve the contact and existing tags in the selected account first; pass `account_name`, `padma_id`, and a nonempty array of positive integer `tag_ids` returned by `list_tags`.

These operations change assignments, not the tags themselves. They preserve unrelated assignments and never create tags. Removal does not delete the account's tag. A tag from another account or an unknown ID rejects the whole batch with `validation_failed`; a contact outside the selected account returns `not_found`, and missing write permission returns `forbidden`.

Each batch is atomic and idempotent. Duplicate IDs are normalized. Adding an existing assignment or removing an absent one succeeds without changing it. Report the returned `account_name`, `contact: {padma_id}`, `changed_tag_ids` (unique IDs actually changed, in request order), and `tags: [{tag_id, name}]` (final assignments in the selected account, ordered by name and ID). Empty `changed_tag_ids` is a successful no-op. Do not interpret the response as assignments in any other account.

## Marketing method assignments

Verify that the connected server exposes the CRM MCP 2.1.0 contract. Read `contact.marketing_methods` via `get_contact` with `response_fields: ["marketing_methods"]`. It lists distinct active and archived assignments as `{marketing_method_id, value}`, where `value` is the name. An empty list means the contact has no assignments in the selected account.

Both write tools require write capability and take `account_name`, the contact's `padma_id`, and a nonempty `marketing_method_ids` array. Resolve IDs in the selected account.

- `add_contact_marketing_methods` accepts active IDs from `list_marketing_methods`. CRM uses the latest incoming communication, falls back to the latest communication, or creates an internal incoming messaging record without sending a message. The result includes `communication_id` and the readable `marketing_method_ids` on that communication from the selected account. Existing assignments are preserved.
- `remove_contact_marketing_methods` accepts active or archived IDs from the contact's assignments. It removes the selected methods from all communications for the contact in that account and preserves the communications and catalog entries. CRM validates the whole selection before writing. `removed_marketing_method_ids` lists only methods actually removed and is empty when a repeat call finds no assignments.

## Saved lists

`list_contact_lists` discovers current list IDs and names. To retrieve one saved list, pass its `list_id` to `get_contact_list`; do not translate the list into `search_contacts` filters. The saved list's persisted filters and ordering determine which contacts are returned. Use the same tool to inspect its rules through `list.filters` when that field is exposed by the connected server.

`list.filters` preserves stored CRM keys, arrays, blank values, and value types on every page, including when no contacts match. It is `{}` when no filters are saved. These keys may differ from `search_contacts` inputs; never pass the object directly to that tool. List-combination filters contain referenced list IDs rather than expanded rules: resolve those lists within the selected account and inspect their filters when needed, stopping if a dependency repeats or cannot be resolved. Nonblank government-identification filters are rejected, including nested dependencies; blank identification fields are omitted.

To add a contact through an inclusion tag, establish that dependency from the returned rules, resolve the tag with `list_tags`, and use the tag-assignment workflow. Names, columns, and current members alone do not establish the rule. Verify actual membership afterward; assigning a tag may leave other conditions unmet. A missing `list.filters` field means the connected server has not exposed this capability, not that the list has no conditions; ask for the filter configuration before inferring an inclusion tag.

`get_contact_list` projects fields automatically from the list's saved UI columns. It maps the system columns for email, telephone, birthday, and occupation directly; returns a saved `age` column as top-level computed age without exposing birthday; maps `primary_address` and `primary_*` address components to address once; and maps exact account-owned custom-property labels to their definition IDs. Callers cannot add response selectors.

The response preserves all configured column names in `list.columns`, including computed, operational, or stale columns that do not project a contact property. `list.property_selection` reports the property types and custom definition IDs that were derived.

Every returned contact has the same base summary shape as `search_contacts` plus a `properties` array, which can be empty. Custom contact relationships remain visible only when the related contact belongs to the selected account.

Paginate with `next_cursor` when needed. A cursor is valid only for the same selected account, list ID, and page size.

## Detail

Use `get_contact` only with a `padma_id` returned by a current CRM call or supplied by the user and confirmed in the selected account. Detail can include name, email, phone, status, teacher, coefficient, last visit, and update timestamp.

Email and phone are resolved from properties belonging to the selected account. Do not infer that another account has the same contact state or operational properties.

To expand contacts returned by `get_contact` or `search_contacts`, pass any needed response selectors:

- `response_fields`: accepts `age` for the contact's current age, `learn_user_id` for the contact's Learn identifier, and `learn_activity_summary` for the stored Learn snapshot. With CRM MCP 2.1.0, `get_contact` also accepts `marketing_methods`;
- `property_types`: `email`, `telephone`, `birthday`, `address`, or `occupation`;
- `property_configuration_ids`: IDs returned by `list_custom_property_definitions` for the selected account.

Selectors control response projection only and can be combined. They do not filter search matches. Property selectors add a flat `properties` array containing every matching account-owned value in deterministic order. Without selectors, responses retain their compact shape, including the existing top-level email and phone on `get_contact`.

Selecting `age` adds the CRM-calculated current age as a top-level field. It can use the canonical birthday or CRM's maintained estimated age and is `null` when neither is available. Age is not a contact property and does not expose the birthdate.

Selecting `learn_user_id` adds that identifier as a top-level field. It is `null` when the contact is not linked to Learn. Request it only when the workflow requires the Learn identity; selecting it does not grant access to Learn or prove that Learn tools are available.

Custom definitions have `String`, `Date`, `Integer`, or `Contact` data types. Custom values include their definition ID, label, and type. Relationships expose only a nested related contact's `padma_id` and `friendly_name`; a target outside the selected account is omitted.

## Create or reuse a contact

Use `create_contact` with `first_name` and at least one of `email` or `phone`. Optional inputs are `last_name`, a two-letter `phone_country`, and `status`: `prospect`, `student`, or `former_student`.

CRM normalizes email and phone using its contact rules and matches only properties owned by the selected account. It never matches by name. When one contact matches, existing values are preserved and only a missing last name, email, phone, or local status is added. Read `created`, `matched_by`, and `enriched_fields` from the response instead of assuming a new person was created.

If multiple candidates exist, or the supplied email and phone identify different contacts, CRM returns `identity_conflict` without writing. Ask the user to resolve the identity; do not select a candidate or alter the identifiers automatically.

## Create a contact property

Use `create_contact_property` only for a contact confirmed in the selected account. Required inputs are `padma_id`, `property_type`, and `value`. Supported property types are `email`, `telephone`, `birthday`, `address`, `occupation`, and `custom`.

Send only metadata relevant to the selected type. Telephone accepts a two-letter `phone_country`; address accepts `address_label`, postal code, city, state, neighborhood, and country; custom requires `custom_label`. Do not send `public` or `primary`.

Call `list_custom_property_definitions` before selecting a custom label. This write supports String custom values only. A missing String definition is created, an existing String definition is reused, and a label configured with another data type is rejected.

The operation is idempotent after CRM normalization. Report the returned property and status: `created`, `existing`, `birthday_assigned`, `birthday_unchanged`, or `birthday_preserved_as_custom`. A conflicting incoming birthday is preserved as a custom value and does not replace the contact's canonical birthday.

## Learn activity summary

Use `get_contact` with `response_fields: ["learn_activity_summary"]` only for a `padma_id` confirmed in the selected account. For several contacts, use the same selector with `search_contacts`. Each returned contact includes the latest normalized Learn snapshot stored on that account-contact relationship, including available attendance, activity-change, cancellation, last-seen, and churn-risk signals.

Read [learn-activity-summary.md](learn-activity-summary.md) before interpreting its fields. Deltas are ratios calculated by Learn, not differences or percentage-point changes.

The `learn_activity_summary` value is `null` when Learn has not calculated a summary. Do not substitute CRM history, a missing summary, or agent interpretation for Learn data. When a calculated timestamp is returned, state that the signals reflect that snapshot rather than current real-time activity.

## History

Use `get_contact_history` only with a `padma_id` confirmed in the selected account. It returns the newest activity first and can include communications, comments visible to the current user, enrollments, dropouts, sent campaigns, and tracked contact changes.

Each entry includes `id`, `type`, `object_id`, `content`, `username`, `account_name`, `activity_at`, `created_at`, and `updated_at`. `object_id` identifies the underlying activity record when available; use it as `communication_id` only for an entry whose type is `Communication`. Paginate with the returned `next_cursor` when the requested history exceeds one page. Do not reuse that cursor after changing the account, `padma_id`, or page size.

History content can contain sensitive free text. Summarize only the entries relevant to the request, identify their activity dates, and avoid reproducing unrelated notes verbatim.

For a general history summary, include the `Communication` entries from other DeROSE schools that the MCP returns, including entries with a null `object_id`. Attribute each entry using its own `account_name`. Prefer the school's display name when the response provides it, and use the account name otherwise. Keep the selected account unchanged when reading the history.

For a nonpublic communication, report the summary returned in `content`. Include trial attendance and `estimated_coefficient` when supplied. Treat an unknown coefficient as unknown and leave private details out.

With the CRM MCP 2.1.0 contract, a `Communication` entry in the selected account includes a `marketing_methods` array with its active and archived assignments as `{marketing_method_id, value}`. An empty array means that communication has no assignments. An omitted field provides no assignment information.

## Create a contact comment

Use `create_contact_comment` only after resolving the contact in the selected account and confirming the exact comment text from the user's request. Pass:

- `account_name`: the current account returned by `list_accounts`;
- `padma_id`: the resolved contact identifier;
- `observations`: the exact comment text to record.

The server creates an account-visible `FollowUp` comment under the authenticated username and current time. Do not supply or invent author, visibility, type, or timestamp values.

The operation is non-idempotent. Call it once. If the response is lost or uncertain, read the contact history before retrying and compare the content, username, and activity time to avoid a duplicate.

## Record a communication

Use `create_contact_communication` only for a `padma_id` confirmed in the selected account. Required inputs are:

- `request_id`: an opaque client-generated key of 1–64 characters;
- `padma_id`: the resolved contact;
- `observations`: the exact communication text;
- `media`: `social`, `website_contact`, `email`, `messaging`, `phone_call`, or `interview`.

Optional inputs are ISO 8601 `communicated_at` (default current time), `incoming` (default `true`), `estimated_coefficient` (`unknown`, `fp`, `pmenos`, `perfil`, or `pmas`), and `marketing_method_ids`. Discover active marketing methods in the selected account before sending their IDs.

CRM derives the username from the authenticated principal and sanitizes observations. Generate a fresh `request_id` for each new communication. Reuse it only to retry the identical payload: a valid replay returns the original record with `created: false`, while changed data returns `idempotency_conflict`.

## Update a contact communication

Use `update_contact_communication` only after identifying the exact communication in the selected account. Pass its `object_id` from a `Communication` entry returned by `get_contact_history`, or its `id` from `create_contact_communication`, as `communication_id`.

Supply at least one editable field: `observations`, `media`, ISO 8601 `communicated_at`, `incoming`, `estimated_coefficient`, or `marketing_method_ids`. Omitted fields remain unchanged. Marketing methods are a complete replacement. Read that communication's current assignments from `get_contact_history` and include the IDs to keep, including archived methods already assigned there under the CRM MCP 2.1.0 contract. Resolve new active IDs with `list_marketing_methods`. Send an empty array only to clear every method on that communication.

The tool preserves the account, contact, author, request ID, and idempotency metadata. Repeating values already stored is safe and returns `updated: false`.

## Privacy and presentation

- Return the minimum personal data needed to answer the request.
- Treat `learn_user_id` as a personal integration identifier and omit it unless the requested workflow needs it.
- Do not enumerate contact details when an aggregate or count is sufficient.
- Avoid copying emails or phones into logs, filenames, URLs, or unrelated tools.
- State the selected account when contact identity could be ambiguous.
- Treat `not_found` as absence from the selected authorized account, not proof that the person does not exist elsewhere.
- Keep returned CRM facts separate from guesses about identity, intent, or personal characteristics.

CRM can assign or remove existing contact tags and marketing methods, create or reuse contacts, create supported contact properties, create or update communications, and create contact comments through this plugin. Contact creation enriches only missing fields, and property writes only add normalized values. Do not promise status changes, other contact edits, imports, merges, or deletions.
