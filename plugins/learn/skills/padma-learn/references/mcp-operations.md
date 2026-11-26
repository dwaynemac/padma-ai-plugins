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

Para conectarse como docente, la persona inicia sesión en Accounts con su
usuario de PADMA. Ese usuario debe estar habilitado como docente en Learn y
conservar su vinculación a la escuela. El MCP no convierte alumnos en teachers
ni crea cuentas administrativas durante la conexión.

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
| Módulos de cursos | `list_course_modules`, `get_course_module`, `create_course_module`, `update_course_module`, `delete_course_module`; asignación mediante `set_course_content` |
| Suscripciones | `list_subscriptions`, `get_subscription` y las operaciones específicas de [suscripciones](subscriptions.md) |
| Reservas | `list_bookings`, `get_booking`, `create_booking`, `update_booking`; `confirm_booking`, `cancel_booking`, `late_cancel_booking`, `promote_booking`, `mark_booking_attended`, `mark_booking_no_show`; tools de reservas recurrentes |
| Precios para invitados | `get_guest_booking_config`, `update_guest_booking_config`, `list_guest_booking_payment_templates`; precios por clase mediante `create_post` / `update_post` |
| Check-ins | `list_check_ins`, `get_check_in`, `create_check_in`, `update_check_in`, `delete_check_in` |
| Reportes | Consultar las cuatro vistas descritas en [reportes](reports.md) |

Para actualizar un miembro o vínculo de contenido existente mediante
`set_course_member` o `set_course_content`, usá el `updated_at` de ese vínculo,
no el del curso ni el de la publicación. El orden del contenido se cambia con
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

## Cambiar una plantilla de acceso desde una fecha futura

Un pedido como «pasá a Julia de 8 clases por mes a Premium el 3 de diciembre»
es un cambio de acceso. Si ya hay un cambio de precio agendado, usá su fecha
como referencia cuando el usuario pida que coincidan. El precio y el acceso se
guardan por separado.

1. Identificá la escuela, el alumno y la fecha. Usá la zona horaria de
   `get_account_context`. Para un día sin hora, tomá el inicio del día local y
   reportá la hora elegida. Buscá al alumno con `list_users` y leé los grants en
   `get_user.access.grants` o en `list_users.items[].grants`. Identificá el
   `accounts_user_id`, el grant a reemplazar y su `updated_at`. Con
   `list_access_templates`, confirmá la plantilla de destino y sus permisos.
   Si hay varios grants posibles, aclaralo antes de escribir.
2. Revisá si la membresía seguirá habilitada al momento del cambio y si otro
   grant vigente o futuro seguirá dando el acceso que se quiere reemplazar.
   Los permisos se combinan entre grants vigentes. Si el grant anterior está
   ligado a una suscripción, verificá con `get_subscription` que sea del mismo
   alumno en esa escuela y conservá su `subscription_id` en el nuevo grant si
   el pedido cambia sólo el acceso del mismo plan de cobro. Si no queda claro
   qué suscripción debe regular el nuevo permiso, resolvelo antes de escribir.
   Un grant con suscripción sólo da acceso mientras esa suscripción esté activa.
3. Para un cambio por vigencia, creá con `create_access_grant` un grant
   vinculado a `access_template_id` con `enables_access_since` en la fecha
   acordada. Enviá la fecha en ISO 8601 con offset. La plantilla vinculada
   aporta sus modalidades, contenido y cupo. Conservá el vencimiento anterior
   si sigue siendo aplicable y el pedido no cambia la duración. Si el grant
   anterior vence antes de la transición o el cambio requiere matrícula en
   PADMA, asignaciones individuales de una plantilla con `unlinked_grant`,
   o un cambio de la regulación de la membresía, resolvé ese alcance antes
   de escribir. `apply_access_template` aplica en el momento y `disable_at`
   fija una fecha de vencimiento.
4. Creá primero el futuro grant, salvo que la lectura ya muestre uno equivalente
   para esa transición. Luego usá `update_access_grant` para fijar
   `enables_access_until` del grant anterior en el mismo instante de transición,
   con su revisión recién leída. Ambos límites son inclusivos en ese instante.
   Usá un `request_id` por escritura y seguí el contrato de reintentos ante
   errores. Si sólo se guardó el grant nuevo, releé y conciliá antes de
   reintentar el vencimiento. Mientras falte verificarlo, informá que el
   reemplazo quedó incompleto.
5. Releé ambos grants y confirmá plantilla, fechas y vínculo de suscripción
   cuando corresponda. Informá qué permiso sigue vigente y cuál quedó
   programado. Learn recalcula las modalidades y el cupo en un ciclo periódico,
   por lo que el acceso efectivo puede reflejar el cambio unos minutos después.

## Módulos de cursos

Comprobá que el servidor conectado anuncie las cinco tools de módulos y el campo
`course_module_id` de `set_course_content`. Actualizar el plugin no despliega
Learn; si faltan, informá qué capacidad sigue pendiente.

Las tools de módulos requieren `course_id` de un curso propio de la escuela
seleccionada y conservan los permisos docentes. Elegí el módulo dentro de ese
curso; un módulo de otro curso, incluso de la misma escuela, no sirve.

| Tool | Uso |
| --- | --- |
| `list_course_modules` | Lista módulos con paginación por ID; recorré todas las páginas y ordená por `position`, luego `id`, para mostrar el curso |
| `get_course_module` | Lee un módulo mediante `course_module_id` |
| `create_course_module` | Crea con `title` obligatorio y `position` entero no negativo opcional (default 0) |
| `update_course_module` | Cambia `title` y/o `position`; requiere `course_module_id` y el `expected_updated_at` del módulo |
| `delete_course_module` | Elimina mediante `course_module_id` y la revisión del módulo; conserva las publicaciones en el curso, sin módulo |

Las lecturas y las creaciones/ediciones devuelven `id`, `work_group_id`, `title`,
`position` y `updated_at`; las respuestas individuales usan `course_module` y
la lista usa `items`. La eliminación devuelve `deleted_course_module_id`.
Todas las escrituras requieren `request_id` según el contrato común. Estas
tools no exponen progreso por alumno.

`set_course_content` acepta `course_module_id` al agregar o editar el vínculo
entre curso y publicación. Usá un ID del mismo curso para asignar o mover,
`null` para dejar sin módulo y omití el campo para conservar la asignación
existente. Un vínculo nuevo sin ese campo queda sin módulo. Las respuestas de
`list_course_content` y `set_course_content` incluyen `course_module_id`, que
puede ser nulo. La asignación no altera la publicación en otros cursos.

Al editar un vínculo existente, incluso sólo para cambiar su módulo, enviá el
`expected_updated_at` del vínculo de contenido, no el del módulo ni del curso.
Eliminar un módulo también invalida las revisiones de sus vínculos al quitarles
la asignación: releé el contenido antes de volver a editarlo. Verificá cada
cambio mediante la lectura del módulo o del contenido correspondiente.

## Precios de reservas de invitados

Comprobá que el servidor conectado anuncie estas tools y campos en su schema.
Actualizar el plugin no despliega Learn; si faltan, informá la capacidad pendiente.

- `get_guest_booking_config` devuelve `guest_booking_config`: default escolar,
  `updated_at`, `payment_template_id`, resumen `payment_template` y
  `payment_template_eligible`. Leer una escuela sin configuración no crea
  registros: su ID, revisión y template son nulos.
- `list_guest_booking_payment_templates` lista los templates existentes,
  elegibles y autorizados de esa escuela, con paginación. Devuelve importe en
  `amount_cents`, moneda en `amount_currency` y resumen del gateway; no crea
  templates ni cambia sus precios. Elegí el ID de esta lista.
- `update_guest_booking_config` cambia sólo el default escolar mediante
  `payment_template_id`; `null` lo elimina. Usá el `updated_at` de la
  configuración como `expected_updated_at`, no el de la escuela o del template.
  Enviá una revisión explícitamente nula sólo si la lectura anterior no encontró
  configuración. Aplican `request_id`, replay y conflictos del contrato común.

Para clases `Live` e `InPersonLive` propias, `create_post` y `update_post` aceptan:

| Campo | Comportamiento |
| --- | --- |
| `guest_booking_payment_mode: "inherit"` | Usa el default escolar; sin default no cobra |
| `guest_booking_payment_mode: "free"` | Sin costo aunque haya un default escolar |
| `guest_booking_payment_mode: "custom"` | Usa `guest_booking_payment_template_id`, que debe ser elegible y de esa escuela |

Al cambiar a `inherit` o `free`, podés enviar
`guest_booking_payment_template_id: null` para quitar la selección guardada.
No asignes templates de otra escuela en ningún modo. Al actualizar una clase,
usá la revisión del post como `expected_updated_at`.

`get_post`, `list_posts` y los resultados de escritura incluyen
`guest_booking_pricing` para clases propias: `mode`, `payment_template_id`,
`status`, `confirmation` y `effective_payment_template`. Este último contiene
el precio efectivo (`amount_cents` y `amount_currency`), el template y su gateway.
Con `status: "valid"`, `confirmation` es `"payment"` o `"manual"`.
Con `status: "invalid"`, la confirmación es `"unavailable"` y el template
efectivo es nulo: no lo interpretes como una clase gratis.

Un default con `payment_template_eligible: false` requiere corrección; ese campo
es nulo cuando no hay default. Las lecturas no exponen datos de templates o
gateways ajenos aunque una referencia histórica haya quedado inválida.
Estas escrituras configuran futuras reservas de invitados: sin cobro conservan
confirmación manual, no cobran al visitante ni modifican pagos ya creados o
reservas ordinarias de alumnos. Releé la configuración o clase para verificar
el cambio y su precio efectivo.

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
