# PADMA ecosystem for clients

PADMA is a modular suite for operating schools and boutique studios. Each product owns one business domain; using several products together does not merge their ownership or authorization.

## Source of truth

| Business question | Product | Available through companion plugin |
|---|---|---|
| Who can sign in and which organizations they may access | Accounts | Indirectly, through each MCP's OAuth grant |
| Who is the person and what is their relationship/status with a school | CRM | Yes, read plus safe contact and property creation and comments |
| What communication data, including WhatsApp interactions, is recorded for a contact | CRM | Yes, read plus communication creation |
| Which contacts need follow-up now, and how are acquisition, dropout, and historical commercial metrics evolving | CRM | Yes, through live commercial stages, marketing-method and dropout-reason rankings, and monthly lead-funnel analysis |
| How operational projects, sections, tasks, and conversations are organized | CRM | Yes, authorized project and task management; section creation and ordering through CRM MCP 1.20.0 or later |
| What income, expenses, movements, plans, and financial rules exist | Money | Yes, read and supported writes |
| Alumnos, accesos, suscripciones, publicaciones, cursos, reservas, check-ins y reportes de asistencia | Learn | Sí, mediante el MCP docente y la skill `padma-learn` |
| Certificates, office stock/sales, manuals, or branded links | Specialized DeROSE Apps | No |

## Ownership rules

- Accounts owns identity and the organizational access context. An MCP's discovery tool exposes only the organizations usable by that OAuth session.
- CRM owns the contact-centered relationship, available communication data, and school-level commercial/pedagogical state.
- Money owns financial commitments, realized movements, classification, and financial reporting.
- Learn owns educational access and activity; Money plans do not determine learning access.

## Client-facing language

Speak in terms of the user's school, contacts, commercial activity, and finances. Avoid repository names, models, routes, ports, database IDs, or internal architecture unless the user explicitly asks as a developer.

When a requested domain is unavailable, identify the owning PADMA product and identify which required companion plugin (`crm`, `money` or `learn`) is missing or which capability is unsupported. Do not answer with guessed data from another product.
