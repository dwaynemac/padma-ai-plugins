# CRM objects and attributes

Interpret CRM records with these product semantics. The names shown are the MCP names when a direct equivalent exists; consult `mcp-operations.md` for the available tool schemas.

## Contact

- A contact is a person related to the school, such as a prospect, student, former student, teacher, or another relationship represented by that school's configured statuses.
- Contact details, status, activity, assigned teacher, tags, marketing methods, and list membership are scoped to the selected account. Do not infer that another school has the same information for the person.

## Contact properties

- System properties represent email, telephone, birthday, address, and occupation values owned by the selected account.
- Age is a computed top-level response field, not a contact property. Requesting it does not expose the birthday, and it can be `null` when CRM cannot calculate or estimate it.
- Custom property definitions are account-scoped labels with `String`, `Date`, `Integer`, or `Contact` data types. Their numeric IDs are selectors, not portable identifiers across accounts.
- Property selectors on contact reads control projection only; they do not filter the contacts returned by a search.
- A `Contact` custom property is a relationship. CRM exposes the related person's stable `padma_id` and friendly name only when that person is also connected to the selected account.
- `create_contact_property` supports String custom writes. Existing Date, Integer, and Contact definitions remain readable but are not writable through that tool.

## Tags

- Tags (`tag_ids`) are free-form labels created by each school to organize or segment its contacts.
- Their names and meanings are defined by that school. A tag is not a standardized PADMA classification, so do not infer its meaning from its name alone.
- Discover current tags with `list_tags` before filtering or changing assignments. Use the returned IDs only in the same selected account.

- `add_contact_tags` and `remove_contact_tags` change a contact's assignments to existing tags in the selected account. They do not create tags or delete the account's tags. Use them only when exposed by the connected server.

## Marketing methods

- Marketing methods (`marketing_method_ids`) represent the school's marketing campaigns or acquisition methods, for example a specific campaign.
- Each school defines its own methods and names. `list_marketing_methods` lists active methods for discovery and filtering. Assigned archived methods are visible on the contact and on the communication that carries the assignment. See [contact marketing method assignments](contacts.md#marketing-method-assignments).

## Dropout reasons

- Dropout reasons (`dropout_reason_ids`) are the account-defined reasons recorded on dropout events.
- Discover current reasons with `list_dropout_reasons` before filtering. Their IDs and meanings belong only to the selected account.

## Contact lists

- Contact lists are saved groups of contacts that the school can reuse for segmentation.
- List membership is not equivalent to a contact status, tag, or marketing method. Use list filters only when the requested segment is explicitly defined by the saved list.
- Discover lists with `list_contact_lists`. Use intersection, union, or exclusion filters when combining list memberships in `search_contacts`.
- Use `get_contact_list` to execute one list with its persisted filters and ordering. Its saved UI columns control the returned property projection.
- A configured list column can remain visible without projecting a property when it is computed, operational, or stale.

## Contact history

- Contact history is the chronological activity feed for one contact. It can include communications, comments, enrollments, dropouts, sent campaigns, and tracked changes.
- It records activity; it is not a complete profile of the person's intent or circumstances. Keep conclusions tied to the returned entries and dates.

## Contact comments

- A comment is a new account-visible `FollowUp` entry attached to one contact.
- CRM records the authenticated user and current time. The agent supplies only the resolved contact and exact comment text.
- Repeating `create_contact_comment` creates another entry; comments are not idempotent.

## Communications

- A communication records an interaction with one existing contact in the selected account.
- CRM owns author attribution and sanitizes the supplied observations.
- `media` describes the channel; `incoming` describes its direction; `communicated_at` is the activity timestamp.
- Marketing methods are account-scoped acquisition or campaign references and must be discovered before use.
- `request_id` is an idempotency key scoped to the selected account. It is not a communication ID or contact identifier.
- A communication history entry's `object_id`, or the `id` returned on creation, identifies the record accepted by `update_contact_communication`.
- Communication updates can replace approved activity fields and marketing methods, but cannot move the record to another account or contact or change its author or idempotency metadata.

## Operations projects

- An Operations project is an account-scoped category used to group tasks and has a sorted complete-replacement `member_usernames` list and ordered sections.
- `project_id` and each section's `project_section_id` are stable MCP identifiers within the selected account. Discover them with `list_operations_projects`.
- Project names are unique within an account without regard to case. Project members can read every task in the project without task mutation rights. Only admins and directors with write capability can create projects, rename them, replace membership, or delete them.
- Deleting a project preserves every task and its assignments to other projects.

Section names are trimmed, nonblank, at most 255 characters, and unique within
their project ignoring case. Authorized section creation appends; reordering
replaces the complete order atomically while preserving IDs and task assignments.

## Operations tasks

- An Operations task is account-scoped work with a title, optional description and due date, one assignee, one creator, optional collaborators, an optional linked CRM contact, zero or more project assignments, and optional daily, weekly, monthly, or yearly recurrence.
- `task_id` is the MCP mutation identifier. A linked person is always identified publicly by `contact.padma_id`, never by the task's internal contact foreign key.
- Task responses return `project_assignments` ordered by `project_id`. Each assignment contains `project: { project_id, name, member_usernames }` and `project_section: { project_section_id, name } | null`. There are no singular task `project` or `project_section` fields.
- Omit the `project_id` filter to include every readable task; pass `null` to select main tasks without projects. Omit `project_section_id` to include every section; pass `null` to select tasks with no assigned section anywhere, or with a concrete `project_id` to select that project's sectionless assignments. Concrete project and section filters must match the same assignment.
- Active due groups are calculated in the selected account's timezone: `overdue`, `today`, `upcoming` (the next seven days), `later`, and `unscheduled`. Completed tasks use `completed` as their returned due group.
- `recurrence` is `null` or `{ frequency, interval, ends_on }`; recurring tasks require a due date. `generated_from_task_id` identifies the prior occurrence and `next_task_id` identifies the generated successor.
- Creator, completion user, completion time, account, task ID, and recurrence lineage are server-owned. Title, description, assignee, due date, linked contact, and project assignments are editable; recurrence cannot change after the task has generated a successor.
- Project assignment sections and order are independent. Due date, assignee, content, conversation, and completion state belong to the shared task. Subtasks have no project assignments. A recurring successor retains all project IDs and starts in each project's first section.
- `collaborator_usernames` is sorted in responses and is a complete-replacement write field. Every collaborator belongs to the task account; creator and assignee are implicit participants and are not stored as collaborators. Collaborators can read the task without gaining task mutation rights.
- `messages_count` is the number of messages in the task conversation and is `0` when no conversation exists.
- Task visibility and mutations depend on the authenticated user's current account permissions. A task returned to one user is not evidence that another user or account can access it.
- Task creation is not idempotent. Completion and reopening are idempotent; completing a recurring task creates at most one future successor, and reopening does not remove it. Deletion is permanent and destructive.

## Operations task messages

- An Operations message belongs to one task conversation and exposes `message_id`, `author_username`, Markdown `body`, `created_at`, and `updated_at`.
- Conversation visibility is inherited from the task. An account or user that cannot read the task cannot list or post its messages.
- `list_operations_activities` combines comments and task changes oldest first and paginates forward. A task without a conversation still has creation activity. Use the entry type to distinguish messages from events; `messages_count` counts only messages. See [mcp-operations.md](mcp-operations.md) for entry fields and legacy history behavior.
- CRM owns author attribution. Posting is not idempotent, can enroll a nonimplicit sender as a task collaborator, and notifies the other task participants.
- The MCP does not expose message updates or deletions.

## Monthly statistics and lead funnel

- Monthly statistics are persisted account metrics with system-wide standardized definitions, names, and localized labels.
- The lead funnel aggregates persisted stages and transitions. It describes the account's stored commercial funnel data for the requested period; do not treat it as a full reconstruction of every contact's history.
