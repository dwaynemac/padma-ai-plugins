---
name: padma-crm
description: Use PADMA CRM through its remote MCP server to find authorized accounts; search or create account-scoped contacts and assign or remove existing tags and marketing methods; inspect saved-list rules and retrieve their contacts, properties, ages, Learn links, activity, and history; create or update communications and comments; manage authorized Operations projects, sections, multi-project task assignments, collaborators, recurrence, comments, and task change history; and analyze school statistics, acquisition, dropout reasons, commercial follow-up, and historical lead funnels. Use for requests about CRM contacts, prospects, students, saved lists, ages, custom properties, Learn activity or churn risk, dropout segmentation, marketing attribution, communications, operational projects, tasks, messages or task history, enrollment metrics, monthly performance, or commercial funnels stored in PADMA CRM.
---

# Use PADMA CRM

Prefer the `crm` MCP server and attempt it first for CRM data. Browser access is allowed only when the user explicitly requests it and the conditions below are met. MCP OAuth determines the account allowlist; `account_name` only selects one account from that authorized set.

Para priorizar a quién contactar después de una clase de prueba, usá [Seguimiento de pruebas](../seguimiento-de-pruebas/SKILL.md).

## Reject government identifier requests before using tools

When a request involves collecting, looking up, storing, updating, or returning government identifiers or identity documents (including DNI, CPF, RG, national IDs, or passports), refuse that part immediately, before account discovery or any other CRM tool call for that purpose. This applies even when the user has not supplied a number: do not ask for the number, document, attachment, contact, or account to complete the restricted request.

Do not offer or use custom properties, comments, messages, communications, or any other field as a workaround, even if the user explicitly requests one. If a value or document was already supplied or appears in tool output, do not repeat it or pass it to another tool. For a mixed request, proceed only with separable supported work that does not use the restricted data.

For example, respond to “Guardá el número de documento gubernamental de este contacto en CRM.” with: “No puedo solicitar ni guardar documentos gubernamentales mediante el plugin PADMA CRM.” Do not follow this refusal with a request for the missing number or a suggestion to store it elsewhere.

MCP 2.0.0 removes structured government-identifier filters, property types, and projections. These skill instructions do not imply server-side redaction of arbitrary text. CRM's regular UI retains its identification features.

## Prepare

For supported requests:

1. Discover available `crm` tools and attempt the required MCP workflow first, starting with `list_accounts` when exposed. Missing tools are an availability limitation, not an authorization denial. Without an explicit browser request, explain the limitation and how to enable or reconnect MCP; do not switch execution paths automatically. If the user explicitly requests browser access, follow “Explicit browser access” below. Never substitute database access or another integration.
2. For the MCP path, call `list_accounts` first. Treat it as the authoritative list for the current OAuth session. Steps 3–5 apply to this MCP path; use the UI scope checks below for explicitly requested browser access.
3. If one account is authorized, use it automatically. If several are authorized, select an account explicitly identified by the user or ask which one to use. Never infer an account from unrelated context.
4. Keep the selected `account_name` on every account-scoped call in the workflow.
5. Call `get_account_context` to obtain roles, valid contact statuses, capabilities, and current limits.
6. Read [references/mcp-operations.md](references/mcp-operations.md) for connection, selection, tool, pagination, and error contracts.
7. Read [references/objects-and-attributes.md](references/objects-and-attributes.md) for the product meaning of CRM objects.
8. Read [references/contacts.md](references/contacts.md) for contact searches, detail handling, and privacy rules.
9. Read [references/learn-activity-summary.md](references/learn-activity-summary.md) before interpreting Learn activity deltas, flags, timestamps, or churn risk.
10. Read [references/monthly-statistics.md](references/monthly-statistics.md) before answering metric, comparison, trend, or either funnel question.

## Explicit browser access

- A request to use the browser must be explicit; a general request to complete the task or an unavailable MCP does not authorize it. Check MCP availability and attempt exposed tools first even when the user requests the browser. After that attempt, honor the explicit browser request within the same authorized task; do not require MCP to succeed before proceeding.
- Use only the official PADMA CRM UI at `https://crm.derose.app/` and its normal sign-in flow. Let the user complete login or MFA when needed; never request credentials, OAuth codes, or tokens in chat or extract them from the session. If browser tools are unavailable, explain the limitation.
- Verify the signed-in identity, accessible accounts, selected account, and applicable role and write permissions from the UI before accessing account data. When MCP discovery succeeded, keep the workflow within its authorized account allowlist as well. When MCP is not exposed, use only accounts visibly available to the authenticated UI user; a user-supplied account name, URL, or ID never grants access. Resolve ambiguous account selection with the user.
- Never use the browser to bypass `401`, `403`, `forbidden`, an account absent from MCP discovery, missing write capability, role or feature restrictions, or any other authentication, authorization, or data restriction. Reconnect or resolve the permission issue through the normal authorized flow first. Browser consent does not override a denied action or denied tool execution.
- Keep the requested operation, contact/list identity, account, filters, pagination, and minimum necessary data unchanged. The government-identifier refusal above applies equally in the browser, including lists whose filters or columns expose restricted data. Do not use private endpoints, database access, arbitrary integrations, or direct network calls as a browser substitute.
- For writes, preserve all operation-specific authorization, exact-text approval, destructive-action confirmation, duplicate prevention, and readback requirements below. Browser access does not authorize extra operations or unsupported writes. Do not assume MCP request IDs or atomicity exist in the UI; after an uncertain result, inspect the UI before retrying and stop if the outcome cannot be established safely.
- For example, if MCP tools are not exposed and the user explicitly asks to inspect a student follow-up list in the browser, verify the UI account and inspect only that list's rules and requested contacts. Do not change its filters or membership unless separately authorized. Report browser-observed facts as such, including incomplete coverage; never present them as MCP-confirmed results.

The workflows below describe MCP tools and contracts. On the explicitly requested browser path, use the equivalent visible UI controls only where the same supported operation, identity, scope, permissions, and required safeguards can be verified. Do not require unavailable MCP tools to verify UI-only access or assume UI actions accept MCP identifiers or payloads. If a required safeguard cannot be verified, stop that operation and explain the limitation.

## Search contacts

1. Use `search_contacts` with the narrowest useful identity, relationship, activity, and date filters. For birthdays, use `birthday_day` and `birthday_month`; add `birthday_year` only when the birth year must also match, or omit the day to search a whole birthday month.
2. Before filtering by tags, marketing methods, dropout reasons, or saved lists, call `list_tags`, `list_marketing_methods`, `list_dropout_reasons`, or `list_contact_lists` in the selected account. Use only IDs returned by those current calls.
3. Use `intersect_list_ids` for membership in every selected list, `union_list_ids` for membership in any selected list, and `not_in_list_ids` for exclusions.
4. Paginate when the requested scope exceeds one page. Do not present a truncated page as a complete result or reuse a cursor after changing filters.
5. Use only returned `padma_id` values with `get_contact` or `get_contact_history`; never invent or substitute an identifier.
6. Treat email, phone, Learn user IDs, visits, status, coefficient, teacher, tags, and list membership as personal data. Return only fields needed for the user's request.
7. State the selected account and material filters. Keep facts returned by CRM separate from interpretation.

## Summarize contact history

Use `get_contact_history` in the selected account. Include communications returned from other DeROSE schools and identify the school for each entry. Follow the [history guidance](references/contacts.md#history) for attribution and detail.

## Add or remove contact tags

1. Confirm that `add_contact_tags` or `remove_contact_tags` is available in the connected server and that `get_account_context` includes write capability. These tools require CRM MCP 1.19.0 or later; documentation alone does not prove deployment.
2. Resolve the contact with `search_contacts` in the selected account and discover existing tags with `list_tags`. Disambiguate the contact or requested tag before writing if needed.
3. For the user's requested assignment change, pass `account_name`, the contact's `padma_id`, and a nonempty `tag_ids` array of returned positive integer IDs. Never send tag names or IDs from another account.
4. Use `add_contact_tags` to add assignments and `remove_contact_tags` to remove only the requested assignments. Neither creates nor deletes the account's tags, and unrelated assignments remain unchanged.
5. Both tools are atomic and idempotent. Repeated IDs are normalized; an already assigned tag or an absent assignment is a successful no-op. A retry must keep the same account, contact, operation, and IDs.
6. Report `changed_tag_ids` and the returned final `tags` for the selected account. An empty `changed_tag_ids` means no change, not a failure. Read [references/contacts.md](references/contacts.md#tag-assignments) for the response and error contract.

## Manage a contact's marketing methods

1. Confirm the connected server exposes the CRM MCP 2.1.0 contract and that `get_account_context` grants write capability before changing assignments.
2. Resolve the contact with `search_contacts`. Use `get_contact` with `response_fields: ["marketing_methods"]` for its assignments and `get_contact_history` to see the methods on each communication in the selected account.
3. To add a method, resolve its active ID with `list_marketing_methods`. Call `add_contact_marketing_methods` with `account_name`, `padma_id`, and `marketing_method_ids`. CRM uses the latest incoming communication, falls back to the latest communication, or creates an internal incoming messaging record without sending a message.
4. To remove a method, look up its ID with the contact selector above. Use `remove_contact_marketing_methods` for removal from all of the contact's communications in the selected account. It accepts assigned active and archived methods. For a change to one communication, follow “Update a contact communication”.
5. Read back the assignments with `get_contact` and report the result. An empty `removed_marketing_method_ids` means no assignments were removed. See [references/contacts.md](references/contacts.md#marketing-method-assignments) for the response contract.

## Add a contact to a saved list

1. When the user asks to “add a contact to a list”, first resolve the contact and saved list in the selected account with `search_contacts` and `list_contact_lists`. Saved lists are dynamic searches: adding an inclusion tag can be equivalent to adding the contact to the list.
2. Call `get_contact_list` with the resolved `list_id` and inspect `list.filters` to identify inclusion tags and other conditions. Follow [references/contacts.md](references/contacts.md#saved-lists) for stored filter types and referenced lists; list names, matching tag names, columns, or current members do not prove that dependency. If the tools do not expose the filters, ask the user for the list's filter configuration or confirmation of the exact inclusion tag and any other conditions. Do not invent a filter-inspection tool. Inspect the UI only under “Explicit browser access”; otherwise keep the limitation explicit.
3. When the inclusion tag is established and assigning it implements the requested membership, resolve its existing ID with `list_tags` and follow “Add or remove contact tags” using `add_contact_tags`. The request to add the contact to that list authorizes this tag assignment; no separate tag request is needed. Do not create tags, modify the list's filters, remove exclusion tags, or change unrelated contact data.
4. Check membership after assignment with `search_contacts`, combining the resolved contact's identity with `intersect_list_ids: [list_id]`, or inspect `get_contact_list` and paginate as needed. Confirm the returned `padma_id` matches the intended contact before reporting that it belongs to the list. This checks membership without reconstructing the saved filters.
5. Adding a tag alone does not prove membership when other filters apply. If the contact still does not match, report the tag assignment separately and explain any known unmet conditions. If the dependency cannot be established or no supported tag assignment implements the request, explain the limitation instead of claiming the contact was added.

## Retrieve a saved contact list

1. Call `list_contact_lists` in the selected account and resolve the requested list to a current `list_id`.
2. Call `get_contact_list` when the user wants the saved rules or contacts produced by that list. Inspect `list.filters` when present; these are persisted CRM keys and values, not a payload to copy into `search_contacts`. Do not recreate it with `search_contacts`: CRM applies the list's persisted filters, ordering, and membership semantics.
3. Do not send property selectors. The saved list controls projection through its configured UI columns, and every returned contact includes a `properties` array even when it is empty.
4. Use `list.columns` to report the saved configuration and `list.property_selection` to explain which system property types and custom definitions CRM projected. A saved `age` column returns top-level `age` without exposing a birthday property; other computed, operational, and stale columns can remain in `columns` without producing properties.
5. Paginate with `next_cursor` until the requested scope is complete. Reuse the cursor only with the same account, list ID, and page size.

## Select contact response fields

1. Without response selectors, preserve the compact default projection from `search_contacts` and `get_contact`.
2. Use `response_fields: ["age"]` when the workflow needs the contact's current age rather than the birthdate. The top-level field is `null` when CRM cannot calculate or estimate it.
3. Use `response_fields: ["learn_user_id"]` only when the workflow needs the contact's Learn identifier. The field is `null` when the contact is not linked to Learn.
4. Use `response_fields: ["learn_activity_summary"]` to add the stored Learn snapshot as a top-level field on every returned contact. Combine response field values in one array when several are needed.
5. For system properties, pass only the needed `property_types`: `email`, `telephone`, `birthday`, `address`, or `occupation`. Age is a response field, not a property type.
6. For custom properties, call `list_custom_property_definitions` in the selected account, then pass only returned `property_configuration_id` values as `property_configuration_ids`.
7. Treat all three selectors as response projection. They do not filter which contacts match a search, and changing them invalidates an existing search cursor.
8. Expect every matching account-owned property value in `properties`, not only the primary one. A selected type or definition with no value returns an empty array.
9. For a `Contact` definition, use only the nested `related_contact.padma_id` and `friendly_name`. CRM omits relationships whose target is not connected to the selected account.

## Inspect Learn activity

1. Resolve the contact in the selected account with a current `padma_id`.
2. Call `get_contact` with `account_name`, `padma_id`, and `response_fields: ["learn_activity_summary"]`. Use the same `response_fields` selector with `search_contacts` when summaries are needed for several matching contacts.
3. Interpret the returned values using [references/learn-activity-summary.md](references/learn-activity-summary.md). In particular, treat deltas as ratios rather than percentage-point changes.
4. Report only the returned activity, attendance, cancellation, and churn-risk signals. The summary is `null` when Learn has not calculated it.
5. Treat the values as a snapshot calculated by Learn, not a prediction or diagnosis made by the agent.

## Analyze statistics and funnels

1. Discover stable metric names with `list_monthly_stat_definitions`; do not invent a `stat_name` from a translated label.
2. Use `get_monthly_stats` for exact series and freshness and `compare_monthly_stats` for shared dashboard comparison semantics.
3. Use `get_marketing_method_statistics` for distinct communication, qualified communication, qualified interview, and enrollment contact counts by marketing method, with CRM-calculated conversion percentages.
4. Use `get_dropout_reason_statistics` for distinct dropout contact counts by account-defined reason. Call `list_dropout_reasons` first when the user names a reason or needs its current ID.
5. Both ranking tools accept optional strict `start_month` and `end_month` values, default to the 12 months ending with the current account-local month, and accept at most 36 months.
6. Use `get_commercial_funnel` when the question is operational: which prospects need attention now, how many contacts are in each current follow-up stage, or which stage list to work. Use a returned `list_id` with `get_contact_list` and paginate that list when contacts are requested.
7. Use `get_lead_funnel` when the question is analytical: how demand converted through visits and profile visits into enrollments over a monthly range.
8. Never treat commercial-funnel stage counts as a historical conversion series or calculate conversion rates from them. They are live saved contact searches, not one period cohort.
9. The first `get_commercial_funnel` call may initialize missing internal system searches, as the CRM dashboard does; it does not modify contacts.
10. Preserve missing absolute values as unknown. Never convert `value: null` into zero or calculate a missing absolute statistic outside CRM.
11. Do not request deprecated rate `stat_name` values. Derive a requested percentage from the documented absolute numerator and denominator only when both are present and the denominator is greater than zero.
12. State the selected account and resolved monthly range for ranking and historical-funnel results. For a commercial funnel, state that the counts are a current snapshot. Include missing months and freshness when they affect an analytical answer.

## Create a contact comment

1. Use `create_contact_comment` only when the user explicitly asks to record a comment and supplies or approves the exact text.
2. Resolve the selected account and contact first. Use a current `padma_id` from `search_contacts`, and disambiguate same-name contacts before writing.
3. State the selected account and contact before the write when identity could be ambiguous. Never send a comment to a merely similar contact.
4. Call `create_contact_comment` once with `account_name`, `padma_id`, and `observations`. The server records the authenticated username and current time; the comment is visible to the selected account.
5. Treat the tool as non-idempotent. If the result is uncertain, inspect `get_contact_history` before retrying so the same comment is not created twice.
6. Report the created comment and contact. Do not claim success from intent or an OAuth login alone.

## Create or reuse a contact

1. Use `create_contact` only when the user asks to register a person and provides a first name plus an email or phone.
2. Call `search_contacts` first when human review of possible name matches is useful. The write tool itself matches only exact normalized email and phone values in the selected account.
3. Pass `first_name`, at least one of `email` or `phone`, and only the supplied optional `last_name`, two-letter `phone_country`, and `status`.
4. Use only `prospect`, `student`, or `former_student` for `status`; omit it to use `prospect`.
5. If `created` is false, report `matched_by` and `enriched_fields`. Existing names and values are preserved; the tool only fills missing fields.
6. Stop on `identity_conflict`. Do not choose between ambiguous contacts or retry with altered identity data unless the user resolves the conflict.

## Create a contact property

1. Resolve the selected account and contact before writing, and call `create_contact_property` only when the user asks to add the value.
2. Pass `padma_id`, `property_type`, and `value`. Supported types are `email`, `telephone`, `birthday`, `address`, `occupation`, and `custom`.
3. Include only metadata accepted by that type: `phone_country`; address label and location fields; or `custom_label` for a custom string property.
4. Before using a custom label, call `list_custom_property_definitions`. CRM creates a missing String definition, reuses a matching one, and rejects a label configured with another data type.
5. Treat the write as idempotent. Report the returned normalized property and status instead of assuming creation.
6. For birthdays, distinguish `birthday_assigned`, `birthday_unchanged`, and `birthday_preserved_as_custom`; a conflicting incoming date does not replace the canonical birthday.

## Record a communication

1. Resolve the existing contact in the selected account with `search_contacts` or `create_contact`.
2. Call `list_marketing_methods` before sending `marketing_method_ids`, and use only active IDs returned for the selected account.
3. Generate a fresh opaque `request_id` of at most 64 characters for each new communication. Reuse that exact key only when retrying the same payload.
4. Call `create_contact_communication` with the exact approved `observations`, a supported `media`, and only the optional direction, timestamp, coefficient, or marketing methods supplied by the user.
5. Do not supply a username. CRM records the authenticated principal and sanitizes the observations.
6. A replay of the same key and payload returns the original record with `created: false`. Stop on `idempotency_conflict`; use a new key only for a genuinely new communication.
7. Report the persisted communication and contact. Use `get_contact_history` when the user asks to verify its visibility.

## Update a contact communication

1. Use `update_contact_communication` only when the user explicitly asks to correct an existing communication.
2. Resolve the selected account and exact communication first. Use the `object_id` from its `Communication` entry in `get_contact_history`, or the `id` returned by `create_contact_communication`.
3. Pass `communication_id` and only the approved editable fields: `observations`, `media`, `communicated_at`, `incoming`, `estimated_coefficient`, or `marketing_method_ids`. Omitted fields are preserved.
4. Treat `marketing_method_ids` as a complete replacement. Read the target entry's `marketing_methods` in `get_contact_history` before changing its assignments. If the field is absent, treat the current assignments as unknown and do not attempt a partial correction. Keep the IDs that should remain, including archived methods already assigned to that communication. Resolve new active IDs with `list_marketing_methods`. Send an empty array only when the user explicitly wants to clear every method on that communication.
5. Do not attempt to change the account, contact, author, request ID, or idempotency metadata; the tool does not accept them.
6. Repeating the same update is idempotent and returns `updated: false`. Report whether CRM changed the record and verify attribution edits on the target entry in `get_contact_history`.

## Manage Operations projects, tasks, and activity

Para revisar vencimientos, responsables y bloqueos del equipo, usá
[Pendientes del equipo](../pendientes-del-equipo/SKILL.md).

1. Confirm the connected server exposes the multi-project `project_assignments` contract and the section tools before using them; documentation in this checkout does not prove deployment. Call `list_operations_projects` when a request names a project, needs project discovery, or will assign or filter tasks by project or section. It returns each project's sorted `member_usernames` and ordered sections; use only a returned `project_id`, `project_section_id`, and username for the selected account. Do not send the retired singular task project fields.
2. Use `list_operations_tasks` for task requests. It defaults to every active task the authenticated user can read, including later work; use `status`, `due_group`, `assignee_username`, `contact_padma_id`, `project_id`, or `project_section_id` only when needed. `project_id: null` selects main tasks with no projects. `project_section_id: null` selects tasks with no assigned section in any project unless a concrete `project_id` selects that project's section. Both concrete filters must match the same assignment.
3. Follow `next_cursor` until the requested scope is complete. Never reuse a task cursor after changing the account, filters, or page size.
4. Call `list_operations_activities` with the exact readable `task_id` for comments and task changes. Confirm the connected server exposes this tool; it replaces `list_operations_messages` without an alias. Entries arrive oldest first; follow `next_cursor` forward with the same account, task, and page size. Read `type: "message"` entries for comments and `type: "event"` entries for changes. A task without comments still has creation activity; `messages_count` counts only comments, not all activity.
5. Call `create_operations_message` only when the user explicitly asks to post the exact supplied body to a resolved readable task. CRM records the authenticated author, may add a nonimplicit sender as a collaborator, and notifies the other participants. The write is not idempotent: if the result is uncertain, inspect `type: "message"` entries with `list_operations_activities`, following forward pages through the attempted posting time before retrying. The first page contains the oldest activity, so it cannot establish that a recent comment is absent. CRM does not expose message editing or deletion through MCP.
6. Call `list_operations_assignees` before creating a task or changing its assignee or collaborators, and use only usernames returned for the selected account.
7. Resolve a linked contact through `search_contacts` and pass its public `padma_id`; never pass CRM's internal contact ID.
8. Create a task only when the user explicitly requests it. State the selected account, title, assignee, due date, linked contact, project assignments, description, and recurrence before writing when any value is ambiguous. Pass `project_assignments: [{project_id, project_section_id?}]` for the requested projects; omit a section to use that project's first section. Creation is not idempotent, so inspect the task list before retrying an uncertain result.
9. Pass recurrence as `null` or `{ frequency, interval, ends_on }`. Frequency is `daily`, `weekly`, `monthly`, or `yearly`; interval is a positive integer and defaults to `1`; `ends_on` is an optional strict `YYYY-MM-DD`. A recurring task requires `due_on`.
10. For updates, resolve the exact `task_id` from `list_operations_tasks` and pass only approved editable fields. `collaborator_usernames` is a complete replacement of account users; omit it to preserve collaborators or send `[]` to clear them. Creator and assignee are implicit participants and are ignored in that list. `project_assignments` adds or changes only listed projects; include the explicit `project_id` when moving a task between sections and omit `project_section_id` to keep an existing section. Use `remove_project_ids` to detach only the named projects. Omitted or empty arrays preserve all assignments. Other omitted fields stay unchanged; `null` clears description, due date, linked contact, or recurrence. Once a task has generated its successor, change recurrence on that successor instead.
11. Use `complete_operations_task` and `reopen_operations_task` only for the exact resolved task. Both are idempotent. Completing a recurring task atomically creates at most one successor on the first future occurrence and returns `next_task_id`; reopening preserves that successor and completing again does not duplicate it. Report whether the response changed state and identify the successor when present.
12. Treat `delete_operations_task` as permanent and destructive. Show the resolved task and obtain explicit confirmation immediately before deleting it.
13. Create, rename, change the complete project member list, add or reorder sections, or delete a project only for an authenticated admin or director with CRM write capability. `create_operations_project` accepts optional `member_usernames`; `update_operations_project` requires at least one of `name` or `member_usernames`, preserves omitted fields, and uses `[]` to clear every member. `create_operations_project_section` appends a unique name; `reorder_operations_project_sections` requires every current section ID exactly once in the desired order. Project names, members, and sections are account-scoped; resolve the exact project and discover usernames and section IDs before updating it.
14. Treat `delete_operations_project` as destructive even though it preserves tasks and their other project assignments. Show the resolved project, obtain explicit confirmation immediately before deletion, and report `unassigned_tasks_count` as the number of tasks detached from that project.
15. Project members can read every task in their project. Respect `forbidden` as an authorization boundary and do not attempt to bypass assignment, creator, collaborator, project membership, role, account, write-capability, or feature-level restrictions.

## Manage Operations project sections

1. Use `create_operations_project_section` and `reorder_operations_project_sections` only when exposed by the connected server (CRM MCP 1.20.0 or later). Both require write capability and an authenticated admin or director. Plugin documentation alone does not establish live tool availability.
2. Discover the selected account's project and ordered sections with `list_operations_projects`. Reuse existing names and IDs before creating anything; never infer IDs or borrow them from another account or project.
3. To append a missing section, pass `project_id` and `name` to `create_operations_project_section`. Names are trimmed, nonblank, at most 255 characters, and unique within the project ignoring case. Creation is not idempotent: after an uncertain result, read the project before retrying.
4. To reorder, pass the complete ordered `section_ids` list to `reorder_operations_project_sections`, containing every current section ID exactly once. Preserve sections outside the requested ordering unless the user specifies their placement. An empty list is valid only for a project without sections. The replacement is atomic and idempotent and preserves section IDs and task assignments.
5. Read back the project after each write and confirm its names, IDs, and order. After a stale-list rejection, rediscover the complete list before retrying. These tools do not rename or delete sections, move tasks, or reclassify historical work.

## Protect authorization and scope

- Never ask the user to paste an OAuth authorization code or access token into a prompt.
- Never place OAuth credentials in files, URLs, logs, or MCP arguments. The client manages OAuth and DCR.
- Never treat an `account_name` supplied by the user as authorization. For MCP, use only an account returned by `list_accounts`; for the explicitly requested browser path, apply the account checks above.
- Do not switch accounts during a workflow unless the user explicitly asks.
- Do not combine contacts or statistics from different accounts unless the user explicitly requests a clearly separated comparison and each account is authorized.

## Respect write limits

- CRM can assign or remove existing contact tags and marketing methods, create or reuse contacts, create supported system or custom contact properties, create or update communications, create contact comments, manage Operations projects, their sections, and tasks, and participate in readable task conversations within the authenticated user's permissions.
- Contact creation only enriches missing identity and relationship fields; it does not overwrite existing contact data.
- Property writes add values and preserve birthday conflicts; they do not expose `public` or `primary` controls.
- CRM cannot otherwise update contacts, statuses, or statistics.
- Do not emulate unsupported writes through browser automation or unrelated tools. Supported writes through the UI require the explicit browser request and all safeguards above.
- Do not call missing-stat calculation paths or present derived values as persisted CRM statistics.
- If a requested operation is unsupported, explain the boundary and offer the closest available operation.
