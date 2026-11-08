# Conexión y operaciones de Learn

## Conexión docente

| Servidor | Resource predeterminado | Scopes | Primera verificación |
| --- | --- | --- | --- |
| `learn` | `https://learn.derose.app/mcp` | `openid profile account learn` | `list_accounts`, luego `get_account_context` |

El endpoint alternativo es `https://learn.padm.am/mcp`. El resource OAuth y el
audience del token deben coincidir exactamente con el endpoint configurado.
Cada host publica `/.well-known/oauth-protected-resource/mcp`, que indica el
authorization server de Accounts correspondiente.

El cliente usa Authorization Code y PKCE, con descubrimiento de CIMD/DCR. No se
configuran Client ID/Secret compartidos ni API keys. Instalar o cambiar de host
requiere conectar el recurso elegido y autorizar las escuelas necesarias; una
sesión en CRM/Money o en el navegador no autentica este MCP.

El teacher debe existir en Learn y conservar su vinculación a la escuela. El
MCP no convierte alumnos en teachers ni crea cuentas administrativas durante
la conexión.

## Contrato común

- `list_accounts` es la fuente de las escuelas permitidas por el grant actual.
- `account_name` selecciona una de esas escuelas. Puede omitirse si hay una sola;
  con varias, conservá explícitamente el valor seleccionado en todas las calls.
- `get_account_context` informa capacidades y configuración de la escuela.
- Los argumentos son campos propios de cada tool; no hay un objeto genérico
  `attributes`. Publicaciones usan `post_id`, cursos `course_id`, alumnos
  `user_id`; suscripciones, reservas y check-ins usan `id`. No sustituyas un
  nombre de identificador por otro.
- `list_users` lista accesos escolares: el `id` de cada item es
  `accounts_user_id`, mientras que `user_id` identifica al alumno y puede ser
  nulo en una invitación pendiente. `get_user(user_id: ...)` devuelve el alumno,
  `access`, `course_memberships` y `shares` de la escuela seleccionada.
- Toda escritura requiere `request_id` estable. Las actualizaciones y
  eliminaciones requieren `expected_updated_at` cuando corresponda al registro.
  Usá el valor exacto de la lectura, sin truncarlo ni reconstruirlo.
- Las lecturas y resultados devuelven JSON estructurado. Las listas paginadas
  usan `cursor` y `page_size` (50 por defecto, máximo 100); seguí `next_cursor`
  sin cambiar escuela, período ni filtros.
- El servidor valida reglas y permisos de la aplicación. La presencia de una
  tool no garantiza que el teacher pueda ejecutar esa operación en su escuela.

## Familias de operaciones

| Familia | Uso |
| --- | --- |
| Publicaciones | `list_posts`, `get_post`, `create_post`, `update_post`, `set_post_publication`, `delete_post`; `list_timers` descubre timers autorizados |
| Alumnos | `list_users`, `get_user`, `invite_user` |
| Accesos | `update_user_access`, `list_access_templates`, `apply_access_template`, grants y shares con sus tools de creación/edición/eliminación |
| Cursos | `list_courses`, `get_course`, `create_course`, `update_course`, `delete_course`; `list_course_content`, `set_course_content`, `remove_course_content`; `list_course_members`, `set_course_member`, `remove_course_member` |
| Suscripciones | `list_subscriptions`, `get_subscription` y las operaciones específicas de [suscripciones](subscriptions.md) |
| Reservas | `list_bookings`, `get_booking`, `create_booking`, `update_booking`; `confirm_booking`, `cancel_booking`, `late_cancel_booking`, `promote_booking`, `mark_booking_attended`, `mark_booking_no_show`; tools de reservas recurrentes |
| Check-ins | `list_check_ins`, `get_check_in`, `create_check_in`, `update_check_in`, `delete_check_in` |
| Reportes | Consultar las cuatro vistas descritas en [reportes](reports.md) |

Para actualizar un miembro o vínculo de contenido existente mediante
`set_course_member` o `set_course_content`, usá el `updated_at` de ese vínculo,
no el del curso ni el de la publicación. El orden se cambia con
`set_course_content(order_position: ...)`; no existe una tool independiente
de reordenamiento. El curso debe usar `order_by: "order_position"` para mostrar
ese orden manual; verificá también `order_direction` antes de cambiar posiciones.
Quitar relaciones usa `member_id` o `content_id` junto a `course_id` y la
revisión de la relación.

`create_post` y `create_course` heredan la publicación inmediata de Learn si no
se indican ventanas de publicación; no crean borradores implícitos. Si el pedido
exige contenido aún no visible, acordá y enviá los valores de publicación que
cumplan ese pedido desde la creación. `set_post_publication` cambia el estado
de una publicación existente; los cursos usan sus campos de publicación en
`update_course`.

Las modificaciones de acceso escolar usan `accounts_user_id`, las de grants
`access_grant_id` y las de shares `share_id`, siempre con la revisión del
registro correspondiente. La aplicación de una plantilla requiere la revisión
del acceso escolar, aunque agregue permisos nuevos.

La v1 no automatiza duplicación avanzada, creación/vinculación de híbridos,
reuniones Zoom ni obtención de grabaciones. No reemplaces esas funciones con
cambios de campos internos.

## Recuperación de errores

| Resultado | Acción |
| --- | --- |
| `401` / token inválido | Reconectar OAuth y comprobar el resource exacto |
| `403` / `forbidden` | Revisar escuela y capacidades; no intentar otra vía para eludir la denegación |
| `not_found` | Releer dentro de la escuela elegida; no buscar el mismo ID en tenants ajenos |
| Validación rechazada | Corregir únicamente lo que pueda resolverse con datos autorizados por el usuario |
| `conflict` | Revisar la revisión del recurso y si se reutilizó una clave con otra carga; no usar una clave nueva para forzar la operación |
| `operation_uncertain` | Consultar `get_write_request` con el `request_id` original; una operación externa puede requerir conciliación |
| `429` | Esperar el tiempo de `Retry-After` |
| `503` / servicio externo indisponible | Informar la falta de verificación y reintentar después; conservar la clave si la escritura pudo haber empezado |

Verificá el código y los detalles reales de la respuesta. No interpretes un
timeout como prueba de que nada cambió.

`get_write_request` es una lectura y acepta el `request_id` original. Devuelve
`request.status` (`executing`, `succeeded` o `uncertain`), tool y resultado
guardado dentro de la escuela y teacher actuales. Un resultado guardado prueba
esa ejecución; releé el recurso para conocer su estado actual.
