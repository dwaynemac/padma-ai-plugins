# CRM MCP operations

MCP is the preferred and first attempted execution path. For an explicit user request to use the browser, follow [the skill’s browser conditions](../SKILL.md#explicit-browser-access); the MCP schemas below do not describe UI inputs. Unavailable tools alone do not authorize switching paths, and browser access never bypasses authentication, authorization, or data restrictions.

## Connection and OAuth

The plugin configures the `crm` Streamable HTTP MCP server at `https://crm.derose.app/mcp`. The client discovers PADMA Accounts as the authorization server, registers a public client through Dynamic Client Registration, and uses Authorization Code with PKCE. Do not configure a shared client secret.

The grant requires `openid profile account crm`, and the token audience must exactly match the MCP URL including scheme, hostname, and `/mcp`. A completed login is not proof that the integration works; verify it with `list_accounts` and at least one account-scoped tool call.

The CRM hostname selects the OAuth issuer and resource. It does not restrict authorized accounts by brand.

## Account selection

1. Call `list_accounts` before using account-scoped tools.
2. Select by stable `account_name`; database IDs are not part of the public contract.
3. Omit `account_name` only when one account is authorized. Pass it consistently once selected.
4. With several authorized accounts, ask the user when their request does not identify one unambiguously.
5. Call `get_account_context` after selection to inspect roles, valid statuses, read/write capabilities, and limits.

## Tools

| Tool | Main input | Use |
|---|---|---|
| `list_accounts` | none | Discover authorized accounts, brands, and grant roles. |
| `get_account_context` | optional `account_name` | Get selected account, user, roles, statuses, capabilities, and limits. |
| `list_tags` | optional `account_name` | Discover account tag IDs and names for `tag_ids`. |
| `add_contact_tags` | optional account; required `padma_id`, nonempty `tag_ids` | Idempotently assign existing account tags to a contact. |
| `remove_contact_tags` | optional account; required `padma_id`, nonempty `tag_ids` | Idempotently remove selected assignments without deleting tags. |
| `list_marketing_methods` | optional `account_name` | Discover active account marketing method IDs and values. |
| `add_contact_marketing_methods` | optional account, required `padma_id`, nonempty `marketing_method_ids` | Assign active methods via a contact's communication in the selected account. |
| `remove_contact_marketing_methods` | optional account, required `padma_id`, nonempty `marketing_method_ids` | Remove active or archived assignments from all of the contact's communications in the selected account. |
| `list_dropout_reasons` | optional `account_name` | Discover account dropout reason IDs and values for `dropout_reason_ids`. |
| `list_contact_lists` | optional `account_name` | Discover saved contact-list IDs and names. |
| `get_contact_list` | optional account, required `list_id`; optional `page_size`, `cursor` | Execute one saved list, expose its persisted rules as `list.filters` when supported, and return its contacts with fields derived from its configured columns, including top-level age. |
| `list_custom_property_definitions` | optional `account_name` | Discover account-owned custom property IDs, labels, and data types. |
| `search_contacts` | optional account, filters, response selectors, `page_size`, `cursor` | Search account-scoped contact summaries and optionally project age, selected properties, Learn user IDs, or activity summaries. |
| `get_contact` | optional `account_name`, required `padma_id`; optional response selectors | Read one account-scoped contact detail and optionally project age, selected properties, its Learn user ID, or activity summary. |
| `get_contact_history` | optional account, required `padma_id`; optional `page_size`, `cursor` | Read the activity feed newest first, including account-scoped marketing methods per communication when exposed. |
| `create_contact` | optional account; required `first_name` plus `email` or `phone` | Create a contact or reuse an exact account-owned identity, enriching only missing fields. |
| `create_contact_comment` | optional account, required `padma_id` and `observations` | Create an account-visible follow-up comment as the authenticated user. |
| `create_contact_property` | optional account; required `padma_id`, `property_type`, and `value` | Idempotently create a supported account-owned system or custom contact property. |
| `create_contact_communication` | optional account; required `request_id`, `padma_id`, `observations`, and `media` | Create an idempotent account-scoped communication as the authenticated user. |
| `update_contact_communication` | optional account; required `communication_id` and at least one editable field | Update approved fields on an account-scoped communication. |
| `list_operations_assignees` | optional `account_name` | Discover usernames available for Operations task assignment. |
| `list_operations_projects` | optional `account_name` | List account-scoped Operations projects in alphabetical order with sorted members and ordered sections. |
| `create_operations_project` | optional account; required `name`; optional `member_usernames` | Create an Operations project and optional complete member list when authorized. |
| `update_operations_project` | optional account; required `project_id` and at least one of `name` or `member_usernames` | Partially update a project; membership is a complete replacement and `[]` clears it. |
| `create_operations_project_section` | optional account; required `project_id`, `name` | Append a uniquely named section to an authorized project. |
| `reorder_operations_project_sections` | optional account; required `project_id`, complete `section_ids` | Atomically set the complete section order, preserving task assignments. |
| `delete_operations_project` | optional account; required `project_id` | Delete a project, preserve its tasks, and report how many became unassigned. |
| `create_operations_project_section` | optional `account_name`; required `project_id`, `name` | Append a section and return the updated project; requires admin/director and write capability. |
| `reorder_operations_project_sections` | optional `account_name`; required `project_id`, complete `section_ids` | Atomically replace section order and return the updated project; requires admin/director and write capability. |
| `list_operations_tasks` | optional account, task filters, `page_size`, `cursor` | List signed-cursor pages of Operations tasks readable by the authenticated user. |
| `create_operations_task` | optional account; required `title`; optional `project_assignments`, collaborators, and recurrence | Create an Operations task with zero or more account-scoped project assignments. |
| `update_operations_task` | optional account; required `task_id` and at least one editable field | Partially update an authorized task; change only listed project assignments and remove only explicit project IDs. |
| `complete_operations_task` | optional account; required `task_id` | Idempotently complete a task and return any recurring successor. |
| `reopen_operations_task` | optional account; required `task_id` | Idempotently reopen a completed task. |
| `delete_operations_task` | optional account; required `task_id` | Permanently delete a task when authorized. |
| `list_operations_activities` | optional account; required `task_id`; optional `page_size`, `cursor` | Read comments and task changes oldest first, paging forward. |
| `create_operations_message` | optional account; required `task_id`, `body` | Post a non-idempotent Markdown message as the authenticated user to a readable task. |
| `list_monthly_stat_definitions` | optional `account_name` | Discover stable metric names, localized metadata, types, and availability. |
| `get_monthly_stats` | `stat_names`; optional account and month range | Read dense persisted monthly series. |
| `compare_monthly_stats` | `stat_names`; optional account and month | Compare current, previous, and prior-three-month baselines. |
| `get_lead_funnel` | optional account and month range | Analyze the historical four-stage conversion funnel from persisted monthly statistics. |
| `get_commercial_funnel` | optional `account_name` | Read the five live operational follow-up stages with localized labels, descriptions, contact counts, and actionable saved-list IDs. |
| `get_marketing_method_statistics` | optional account, `start_month`, `end_month` | Count distinct communication and enrollment contacts by marketing method and return conversion percentages. |
| `get_dropout_reason_statistics` | optional account, `start_month`, `end_month` | Count distinct dropout contacts by account-defined reason. |

## WhatsApp Business

Check that the connected server exposes the required CRM MCP 2.2.0 tools.
Every call uses the selected `account_name`. CRM must enable the line for
MCP, and the user needs the corresponding web inbox permissions. Sending
and reacting also require MCP write capability and use the authenticated CRM
user's identity.

| Tool | Input in the selected account | Use |
|---|---|---|
| `waba_list_conversations` | Optional `connection_id`, `contact_padma_id`, `unread_only`, `cursor` | List conversations by recent activity. |
| `waba_list_inbound_messages` | Optional `connection_id`, `page_size`, `cursor`, `from_beginning` | Poll live inbound messages. |
| `waba_get_conversation` | `conversation_id`; optional `page_size`, `cursor` | Read history and eligibility without marking the conversation read. |
| `waba_send_message` | `conversation_id`, `body`, `request_id` | Queue a text reply in an existing conversation. |
| `waba_set_reaction` | `conversation_id`, `message_id`, `emoji`, `request_id` | Add or replace the business reaction. Pass `emoji: ""` to remove it. |
| `waba_get_delivery_status` | `outbound_request_id` | Read the request's queue status and any provider delivery status. |

- Resolve the contact with `search_contacts` when needed and use its returned `padma_id` as `contact_padma_id`. Use line, conversation, message, and outbound request IDs returned in the same account. Use the inbox list for unread chats and the inbound feed for new events.
- Inbox cursors preserve the initial order for up to 15 minutes. Continue with the same filters when `next_cursor` is present, even on a short page. Start without a cursor to refresh or recover from expiration. For older conversation history, follow that conversation's own `next_cursor`.
- The first inbound poll starts at the current end of the feed. Use `from_beginning: true` on the first call only when replaying retained live messages. Save `next_cursor` after processing each page, including the first or an empty page. Keep the same account and line filter and continue immediately while `has_more` is true. Newly enabled lines start at their current end when resuming a saved cursor. The feed excludes imported history, outgoing echoes, reactions, revoked and suppressed messages, and currently ignored identities.
- Check `reply_eligibility.eligible` for a text reply and the target entry's `reactions.eligible` for a reaction. CRM enforces the 24-hour reply window and applicable line and message rules. If a write returns `validation_failed`, use `details.reason` to explain why. These tools support text replies in existing chats and reactions.
- Generate an opaque `request_id` of up to 191 characters for each approved action. Retry an uncertain request or queue failure with the same key and payload. A changed payload with the same key returns `idempotency_conflict`. A retry that still needs a delivery job must pass current eligibility. On `reaction_pending`, check the existing request's status before attempting another reaction change.
- Keep `outbound_request_id` from the write or queue error for readback. Report `request_status` separately from `delivery_status`. A queued request or a null provider status does not establish delivery.

## Ranking statistics

Use `get_marketing_method_statistics` to compare account-defined acquisition
methods over a resolved monthly range. Each row identifies the current
marketing method, whether it is archived, distinct contact counts for
communications, qualified communications, qualified interviews, and
enrollments, plus CRM-calculated communication-to-enrollment and
interview-to-enrollment percentages. A percentage can be `null` when its
denominator is zero.

Use `get_dropout_reason_statistics` to compare distinct dropout contacts by
reason. Call `list_dropout_reasons` first when the user names a reason or needs
the current account-owned ID. Reasons are account-defined; do not infer a
standard meaning from their label.

Both tools accept optional strict `start_month` and `end_month` values in
`YYYY-MM`. They default to the 12 months ending with the current account-local
month, reject reversed ranges, and accept at most 36 months. Their results are
calculated from CRM communication, enrollment, and dropout records for the
selected range; they are not persisted monthly-stat series. Keep accounts
separate and report the resolved range from the response.

## Choose the correct funnel

Use `get_commercial_funnel` for current operational work. It answers “Which
contacts need follow-up now?” and returns acquisition, qualified, booked,
trialed, and enrolled stages. Each stage includes a `list_id`; pass that ID to
`get_contact_list` and follow its cursor when the user asks for the contacts.
The stage counts are live saved-search populations, not a historical cohort, so
do not derive conversion percentages from them. Like the web dashboard, the
first call may initialize missing internal system searches without modifying
contacts.

Use `get_lead_funnel` for historical analysis. It answers “How did demand
convert into enrollments over this monthly range?” and returns demand, visits,
profile visits, and enrollments with percent-of-initial and transition
conversion values. Query the corresponding monthly series when the difference
between a persisted zero and missing source data matters.

## Saved contact lists

Use `list_contact_lists` for lightweight discovery. Use `get_contact_list` with one returned `list_id` when the user wants that saved list's rules or contacts. CRM executes the saved filters, ordering, and membership semantics; do not attempt to reconstruct the list with `search_contacts`.

The response contains the selected `account_name`, list metadata, contact summaries, and `next_cursor`. List metadata includes `filters` when supported by the connected server (see [Saved lists](contacts.md#saved-lists) for stored values, dependencies, and availability), the ordered normalized `columns` and a derived `property_selection`. Each contact always has a `properties` array, including an empty array when no configured property has a value.

CRM derives projection from the saved columns:

- `email`, `telephone`, `birthday`, and `occupation` select the matching system type;
- `age` adds top-level computed age without selecting or exposing `birthday`;
- `primary_address` and each `primary_*` address component select `address` once;
- a column exactly matching an account-owned custom-property label selects that definition once.

Computed, operational, duplicate, and stale columns remain visible in `list.columns` but do not add unsupported properties. The saved list is authoritative, so `get_contact_list` does not accept caller property selectors.

## Contact response projection

`list_custom_property_definitions` returns every definition available to the selected account, ordered by label. Each item contains `property_configuration_id`, `label`, and `data_type`: `String`, `Date`, `Integer`, or `Contact`.

Both `get_contact` and `search_contacts` accept these optional selectors:

- `response_fields`: unique values from the additional top-level fields currently supported: `age`, `learn_user_id`, and `learn_activity_summary`;
- `property_types`: unique values from `email`, `telephone`, `birthday`, `address`, and `occupation`;
- `property_configuration_ids`: unique positive IDs from the current account's definition list.

When either property selector is present, each contact includes a flat `properties` array with every matching account-owned value. Selecting `age` adds CRM's current computed or estimated age as a top-level field; it is `null` when unavailable and does not expose the birthdate. Selecting `learn_user_id` adds the contact's Learn identifier as a top-level field; it is `null` when the contact is not linked to Learn. Selecting `learn_activity_summary` adds the latest normalized Learn snapshot; it is `null` when Learn has not calculated one. The selectors can be combined and change only response projection, never search matching. Without selectors, the existing compact response is unchanged. Search cursors are bound to all selectors and cannot be reused after changing them.

System values include their applicable phone, address, or birthday metadata. Custom values identify their definition, label, and data type. A `Contact` value returns a nested related contact with only `padma_id` and `friendly_name`; CRM omits a relationship when its target is unavailable in the selected account.

The CRM MCP 2.1.0 `get_contact` contract also supports `marketing_methods` in `response_fields`, for distinct current assignments including archived methods. See [contact marketing method assignments](contacts.md#marketing-method-assignments).

## Contact tag writes

`add_contact_tags` and `remove_contact_tags` require CRM MCP 1.19.0 or later and write capability. Check live tool availability before use. Inputs are the selected `account_name`, a confirmed contact `padma_id`, and a nonempty `tag_ids` array of positive integers returned by `list_tags` in that account. Names and foreign-account IDs are not accepted.

Batches are atomic, preserve unrelated assignments, normalize duplicate IDs, and are idempotent. Existing additions and absent removals are successful no-ops. Responses contain `account_name`, `contact: {padma_id}`, `changed_tag_ids` in request order, and final account-scoped `tags: [{tag_id, name}]` ordered by name and ID. Removal is marked destructive but only removes assignments, never the tags themselves. See [contacts.md](contacts.md#tag-assignments) for errors and result interpretation.

## Contact marketing method writes

Verify that the connected server exposes `add_contact_marketing_methods` or `remove_contact_marketing_methods` (CRM MCP 2.1.0) before use. Both require write capability and a nonempty array of positive integer method IDs in the selected account. For addition, use active IDs from `list_marketing_methods`. For removal, use assigned active or archived IDs from `get_contact`. Use `update_contact_communication` for a correction limited to one communication. See [contacts.md](contacts.md#marketing-method-assignments) for response fields and scope.

## Contact and communication writes

`create_contact` requires `first_name` and at least one exact identity:

- `email` and `phone` are normalized by CRM and matched only against properties owned by the selected account.
- Optional inputs are `last_name`, two-letter `phone_country`, and `status`: `prospect`, `student`, or `former_student`.
- A unique match is reused without replacing existing values. CRM only fills a missing last name, email, phone, or local status.
- Ambiguous matches or an email and phone belonging to different contacts return `identity_conflict` without writing.
- The response reports `created`, `matched_by`, and `enriched_fields`.

For `create_contact_property`:

- Resolve an existing account-scoped contact and pass `padma_id`, `property_type`, and `value`.
- `property_type` accepts `email`, `telephone`, `birthday`, `address`, `occupation`, or `custom`.
- Telephone accepts `phone_country`; address accepts its label and postal/location fields; custom requires `custom_label`.
- Do not send type-specific fields to another type, and do not send `public` or `primary`.
- Custom properties are String-only for this write. CRM creates or reuses an account-scoped String definition and rejects a label already configured with another data type.
- Exact normalized matches return `existing`. Other successful statuses are `created`, `birthday_assigned`, `birthday_unchanged`, and `birthday_preserved_as_custom`.
- A conflicting birthday remains canonical and the incoming value is preserved as the `incoming_birthday` custom property.

For `create_contact_communication`:

- Resolve `padma_id` with `search_contacts` or `create_contact`.
- Pass a fresh opaque `request_id` of 1–64 characters for a new communication.
- `media` must be `social`, `website_contact`, `email`, `messaging`, `phone_call`, or `interview`.
- Optional inputs are ISO 8601 `communicated_at`, `incoming`, `estimated_coefficient`, and active account-owned `marketing_method_ids`.
- `estimated_coefficient` accepts `unknown`, `fp`, `pmenos`, `perfil`, or `pmas`.
- CRM derives the username from OAuth and sanitizes `observations`.
- Replaying the same key and payload returns the original communication with `created: false`. The same key with different data returns `idempotency_conflict`.

For `update_contact_communication`:

- Resolve the exact communication in the selected account. Use the `object_id` from its `Communication` history entry or the `id` returned by `create_contact_communication`.
- Pass `communication_id` and at least one of `observations`, `media`, ISO 8601 `communicated_at`, `incoming`, `estimated_coefficient`, or `marketing_method_ids`.
- Omitted fields are preserved. `marketing_method_ids` is a complete replacement. Under the CRM MCP 2.1.0 contract, use the history entry's `marketing_methods` to preserve the intended assignments, including archived methods already assigned to that communication. New assignments require active IDs. An empty array clears every method.
- Account, contact, username, request ID, and idempotency fingerprint cannot be changed.
- Repeating an identical update returns `updated: false`. The response includes readable marketing method IDs from the selected account under the CRM MCP 2.1.0 contract.

For `create_contact_comment`, pass only the resolved `padma_id` and exact approved `observations`. Each call creates a new comment, so inspect `get_contact_history` before retrying an uncertain result.

## Operations project section writes

CRM MCP 1.20.0 adds `create_operations_project_section` and
`reorder_operations_project_sections`. Check actual tool availability before use.
Both resolve `project_id` within the selected authorized account and require
write capability plus existing project-management admin/director authorization.

Creation accepts `name`, trims whitespace, rejects blank names, limits names to
255 characters, and enforces case-insensitive uniqueness within the project.
It appends under the project lock. It is not idempotent: read back the project
before retrying an uncertain response and reuse an already-created section.

Reordering accepts `section_ids`: the complete ordered list of positive integer
IDs, each appearing exactly once and all belonging to that project. Missing,
foreign, extra, or duplicate IDs cannot produce a partial reorder. `[]` is valid
only when the project has no sections. The operation is atomic and idempotent;
existing IDs and task assignments remain intact. On a stale list, rediscover
sections and rebuild the complete order before retrying.

Both return `{ account_name, project }`, with the project ID, name, members, and
ordered `sections` containing `project_section_id`, `name`, and `position`.
Read back with `list_operations_projects` after every write. Respect standard
schema, validation, not-found, and forbidden errors; never bypass tenant or role
checks. Section renaming and deletion are not exposed by these tools.

## Operations projects, tasks, and conversations

Operations tools use the same account, feature-level, assignment, creator,
collaborator, project-membership, and role authorization as CRM's task interface. A regular authorized member can
read and update tasks assigned to them or created by them, and can delete tasks
they created. A project member can read every task in that project without gaining
task mutation rights. Account admins and directors can manage team tasks. A principal
without write capability can list readable tasks but cannot mutate them. Every
user who can access Operations tasks can list the selected account's projects;
only account admins and directors with write capability can create, rename,
delete, or change the sections of projects.

`list_operations_projects` returns the current account's projects alphabetically
as stable `project_id`, `name`, sorted `member_usernames`, and ordered `sections`.
Each section exposes an account-scoped `project_section_id`, `name`, and
`position`; discover these values in the selected account and never reuse them
in another account.

Call `list_operations_tasks` without filters to get every active readable task,
including later work. Optional filters are:

- `status`: `active`, `completed`, or `all`;
- `due_group`: `overdue`, `today`, `upcoming`, `later`, or `unscheduled`;
- `assignee_username`, discovered with `list_operations_assignees`;
- `contact_padma_id`, resolved through CRM contact tools;
- `project_id`: omit it to include every project, pass `null` for only main
  tasks without project assignments, or pass an ID from `list_operations_projects`.
- `project_section_id`: omit it to include every section, or pass a section ID
  from `list_operations_projects`. Pass `null` without a concrete project for
  tasks with no assigned section in any project; with a concrete `project_id`,
  it selects tasks with no section in that project's assignment. Concrete
  project and section IDs must match the same assignment.

Do not combine a due group with `status: completed`. Responses include
`task_id`, editable fields, creator and completion attribution, `due_group`,
audit timestamps, a linked contact's public `padma_id` and friendly name,
sorted `collaborator_usernames`, `project_assignments` ordered by `project_id`
as `[{ project: { project_id, name, member_usernames }, project_section:
{ project_section_id, name } | null }]`, `recurrence` as
`{ frequency, interval, ends_on }` or `null`, `generated_from_task_id`, and
`next_task_id`. `messages_count` reports the conversation size and is `0` when
the task has no conversation. The task ID is account-scoped and must come from
a current list response. List, create, update, complete, and reopen responses
use this task projection; singular task `project` and `project_section` fields
are absent. Each task appears once per list page even if assigned to several
projects.

For task writes:

- `create_operations_task` requires `title` and accepts `description`,
  `assignee_username`, complete-replacement `collaborator_usernames`, strict
  `YYYY-MM-DD` `due_on`, `contact_padma_id`, `parent_task_id`,
  `project_assignments`, and `recurrence`. The assignment list contains zero or more
  `{ project_id, project_section_id? }` objects. Omit the section to use that
  project's first section, or no section if the project has none. Explicit
  `null` for a new assignment is invalid when the project has sections. Every
  collaborator and project must belong to the selected account; creator
  and assignee are implicit participants and are omitted from the stored list.
  The server supplies the account and creator, and defaults the assignee to the
  authenticated user. Creation is not idempotent.
- `recurrence` is `null` or `{ frequency, interval, ends_on }`. Frequency is
  `daily`, `weekly`, `monthly`, or `yearly`; interval is a positive integer and
  defaults to `1`; `ends_on` is an optional strict `YYYY-MM-DD` inclusive limit.
  Setting recurrence requires `due_on`.
- `update_operations_task` accepts only `title`, `description`,
  `assignee_username`, `collaborator_usernames`, `due_on`, `contact_padma_id`,
  `project_assignments`, `remove_project_ids`, and `recurrence` (plus supported
  `parent_task_id`). `project_assignments` adds or updates only the listed
  projects; `remove_project_ids` removes only those explicit associations.
  Omitted or empty arrays preserve every association. Omit a section to keep
  an existing assignment's section or default a new one to its project's first
  section. Send `project_section_id: null` to clear an existing section. To
  move a task between sections in one project, send
  `project_assignments: [{ project_id: selected_project_id, project_section_id: selected_section_id }]`
  with that project's resolved IDs; its other projects remain assigned.
  Duplicate IDs within either array, IDs in both arrays, foreign projects, and
  sections outside their project are rejected. Task and assignment changes are
  atomic; `updated` reports actual changes to either. Other omitted fields are
  preserved; `collaborator_usernames` is a complete replacement and `[]` clears
  it; `null` clears description, due date, contact, or recurrence.
  Recurrence cannot change after a task has generated a successor; update the
  active successor instead. Creator, completion attribution, account, and task
  ID cannot be changed.
- Subtasks have no project assignments or recurrence. Setting a parent clears
  both; clearing `parent_task_id` makes the task a main task again. Assignee,
  completion, due date, content, and conversation are shared across every
  project. A recurring successor retains all projects and starts each in that
  project's first section.
- Completion and reopening are idempotent and report whether they changed the
  task. Completing a recurring task atomically creates at most one successor on
  the first future occurrence, skips missed dates, respects the inclusive end
  date, and returns `next_task_id`. Reopening preserves an existing successor,
  and completing the same task again does not duplicate it. Deletion is
  permanent, destructive, and not idempotent.
- Resolve and show the exact task before a destructive deletion. If a create
  result is uncertain, list matching tasks before retrying.

Task activity inherits the task's read authorization. Use
`list_operations_activities` with an exact current `task_id`; this replaces
`list_operations_messages` without an alias. Start a new pagination sequence;
old message-list cursors cannot be reused. Confirm live tool availability.

The response contains `account_name`, `task_id`, `activities`, and `next_cursor`.
Every entry has `type` and `created_at`:

- `type: "message"` retains `message_id`, `author_username`, Markdown `body`,
  and `updated_at`.
- `type: "event"` contains `activity_id`, `actor_username`, `event_type`, and
  structured `details` with the recorded changes. A null author means System;
  a null activity ID denotes reconstructed legacy history.

Entries are chronological, oldest first, with events before messages at equal
timestamps and stable tie ordering. Page size defaults to 50 (maximum 200).
The signed cursor moves forward and is bound to account, task, and page size.
Known legacy creation and current completion are included without writes;
pagination remains stable if backfill persists them between pages. Listing
never creates a conversation or event. A task without comments still returns
its creation; `messages_count` on task responses counts comments only.

`create_operations_message` additionally requires write capability and accepts
only `task_id` and a nonblank Markdown `body`. CRM owns the account,
conversation, and authenticated author. Posting may add a sender who is not the
creator or assignee as a collaborator and notifies the other task participants.
The call is not idempotent: before retrying an uncertain result, inspect
`type: "message"` entries through forward pages covering the attempted posting
time. The oldest page cannot establish that a recent comment is absent. The MCP does not expose message updates or deletions.

Project writes use an exact account-scoped `project_id`. Names are trimmed, at
most 255 characters, and unique within the account without regard to case.
`create_operations_project` requires a name and accepts optional
`member_usernames`. `update_operations_project` requires at least one of `name`
or complete-replacement `member_usernames`; omitted fields remain unchanged and
an empty member list clears membership. Every member must be a current user of
the selected account. Both tools return the project metadata.
`create_operations_project_section` takes `project_id` and a 1–255 character
`name`; it trims the name, requires uniqueness within the project ignoring case,
and appends the section. Creation is not idempotent, so list sections before
retrying an uncertain result. `reorder_operations_project_sections` takes
`project_id` and the complete ordered `section_ids` array, each positive ID
exactly once; `[]` is valid only for a project without sections. Missing, extra,
or foreign IDs fail atomically. Reordering is idempotent and preserves each
task's section assignment. Both tools return `{ account_name, project }` with
ordered sections and require admin/director authorization plus write capability.

`delete_operations_project` returns the deleted project and
`unassigned_tasks_count`; it never deletes tasks or their other project
assignments. The count reports tasks detached from that project. Confirm this
destructive project deletion immediately before calling it.

## Pagination and limits

- Contact pages default to 50 and accept at most 200 records.
- A returned contact cursor is signed and bound to its account, filters, and response projection. Reuse it only for the next page of the identical search.
- A saved-list cursor is signed and bound to its account, list ID, and page size. Reuse it only for the next page of that same list request.
- Contact-history pages use the same 1–200 page-size limit. Reuse their signed cursor only with the same account, `padma_id`, and page size.
- Operations task pages use the same 1–200 page-size limit. Reuse their signed cursor only with the same account, filters, and page size.
- Operations activity pages default to 50 and accept 1–200 entries. Reuse their signed cursor only with the same account, task ID, and page size; each next page moves forward through comments and changes.
- Explicit contact-search dates use strict `YYYY-MM-DD` values.
- Birthday filters use integer `birthday_day`, `birthday_month`, and optional `birthday_year`; omit any component that should not constrain the search.
- `status` accepts one value; `statuses` accepts several. Do not send both.
- Call the matching discovery tool before using `tag_ids`, `marketing_method_ids`, `dropout_reason_ids`, `intersect_list_ids`, `union_list_ids`, or `not_in_list_ids`. IDs from another account are rejected.
- Monthly series and ranking-statistics ranges default to 12 months ending with the current account-local month and accept at most 36 months.
- Statistics tools accept 1–20 supported `stat_names` per call.
- Month strings are strict `YYYY-MM` values.

## Error handling

Tool-level domain errors return `isError: true` with a stable code:

- `account_required`: select an account returned by `list_accounts`.
- `forbidden`: do not retry with invented account names; refresh authorization and account discovery.
- `not_found`: confirm the current account and identifier.
- `validation_failed`: correct names, dates, statuses, cursor, or other input.
- `identity_conflict`: stop and resolve the ambiguous email or phone identity before retrying.
- `idempotency_conflict`: do not retry the changed payload with the same `request_id`.
- `limit_exceeded`: narrow the page, date range, or metric list.
- `internal_error`: report the correlation ID and avoid blind retries.

HTTP authentication and availability errors have different recovery:

- `401`: reconnect OAuth; verify the exact MCP resource URL.
- `403`: request the `crm` scope or authorize an enabled account.
- `429`: wait for `Retry-After` before retrying.
- `503`: Accounts could not validate the token; retry later without treating it as invalid credentials.

## MCP 2.0.0 identification boundary

Government identification properties and filters are unavailable. Saved lists with identification filters, including nested dependencies, fail validation. Identification columns are omitted from list metadata. MCP full-text and property searches exclude structured identification values; ordinary CRM UI searches remain unchanged. Never use custom fields or free text to work around this boundary. Existing arbitrary text is not automatically redacted.
