---
name: pendientes-del-equipo
description: Usar cuando un administrador de escuela o estudio quiera revisar qué quedó pendiente o trabado en Operaciones de PADMA CRM, qué tareas vencieron o están por vencer y cuáles necesitan revisar su responsable. Entrega una lista priorizada con próximos pasos.
---

# Pendientes del equipo en CRM

1. Con `crm`, llamá a `list_accounts`, seleccioná la escuela autorizada y
   consultá `get_account_context`. Si hay varias cuentas y la escuela no está
   identificada, preguntá cuál usar. Conservá `account_name` en las consultas.
   Si el usuario acotó la revisión a un proyecto o sección, resolvé sus IDs con
   `list_operations_projects` en esa cuenta.
2. Para la revisión general, paginá `list_operations_tasks` con `status: "active"`
   y sin `due_group` ni filtro de responsable. Así también entran las tareas
   sin fecha o con vencimiento lejano que necesitan revisar su asignación.
   Conservá los filtros al paginar y usá `task_id` para contar una sola vez cada
   tarea aunque esté en varios proyectos. Si el pedido se limita a un grupo de
   vencimiento, usá ese filtro desde la consulta.
3. Usá el `due_group` de CRM en la zona horaria de la cuenta. Priorizá `overdue`,
   `today` y `upcoming` (los siete días siguientes a hoy). Si el usuario pide
   fechas concretas, aplicá ese rango a `due_on`. Para revisar responsables,
   contrastá `assignee_username` con `list_operations_assignees`. CRM exige un
   responsable al crear tareas. Si encontrás un valor vacío, indicalo como
   «sin responsable registrado». Si hay un nombre fuera de la lista de
   asignables, mostralo como una asignación a revisar y conservá el nombre
   registrado. Una falla al consultar la lista deja esa verificación pendiente.
4. Para los casos prioritarios que necesiten contexto, consultá
   `list_operations_activities` con el `task_id` devuelto. Las páginas empiezan
   por la actividad más antigua. Avanzá hasta cubrir el período relevante
   antes de afirmar qué se dijo o cambió recientemente. Identificá un bloqueo
   cuando la descripción o el historial lo respalden. Si sólo consta una fecha
   vencida, indicá el atraso y dejá el motivo por confirmar.
5. Entregá la escuela, el alcance visible, las fechas y una lista breve con
   tarea, proyecto o sección cuando corresponda, vencimiento, responsable y
   próximo paso. Indicá qué pasos están registrados en CRM y cuáles sugerís.
   Señalá por separado las asignaciones a revisar, sin duplicar sus tareas en
   el total. Si una consulta o la paginación quedó incompleta, indicá el alcance
   que pudiste revisar.

Usá herramientas de lectura durante la revisión y resumí sólo la información
necesaria. Para una reasignación, cambio de fecha o comentario solicitado
aparte, seguí [PADMA CRM](../padma-crm/SKILL.md). Consultá el
[contrato de Operaciones](../padma-crm/references/mcp-operations.md#operations-projects-tasks-and-conversations)
para filtros, visibilidad e historial.
