---
name: padma-learn
description: "Administrar una escuela de PADMA Learn o Learn DeROSE mediante su MCP docente: publicaciones, alumnos y accesos, suscripciones, cursos y miembros, reservas, check-ins y reportes de asistencia. Usar para solicitudes de gestión de teachers o administradores de escuela. Las reservas personales de un alumno usan la integración de alumnos, no este MCP."
---

# Administrar Learn

Usá el servidor MCP `learn` para las tareas administrativas de la escuela. Los
permisos son los del teacher autenticado; elegir una escuela o conocer un ID
no concede acceso adicional.

## Elegir la escuela

1. Comprobá que estén disponibles las tools de `learn` y llamá `list_accounts`.
2. Si hay una sola escuela, usala. Si hay varias, elegí la que el usuario haya
   identificado claramente o pedí selección; conservá su `account_name` durante
   todo el trabajo.
3. Consultá `get_account_context` antes de operar para conocer permisos,
   módulos habilitados y zona horaria.
4. Usá IDs obtenidos de lecturas de Learn dentro de esa escuela. Un `padma_id`,
   un contacto de CRM y un usuario de Learn son identificadores distintos.

El cliente administra OAuth con Accounts. No pidas tokens ni códigos en el chat.
Si falta la conexión, seguí [conexión y operaciones](references/mcp-operations.md).
Una sesión OAuth exitosa se verifica con una llamada real a `list_accounts` y
una consulta contextual.

## Consultar y administrar

- Buscá y leé el recurso antes de modificarlo; conservá su ID y `updated_at`.
- **Publicaciones:** trabajá con contenido y enlaces suministrados por el usuario.
  Crear contenido, publicarlo y cambiar quién puede acceder son decisiones
  distintas; respetá el estado solicitado. No generes reuniones Zoom ni
  grabaciones como efecto implícito.
- **Alumnos y accesos:** consultá usuarios existentes o usá la invitación
  soportada. Los accesos a la escuela, los permisos de contenido y las
  inscripciones a cursos tienen efectos distintos. No crees teachers, cambies
  roles administrativos ni borres identidades de alumno.
- **Cursos:** administrá sus datos, contenido, orden y miembros. Antes de quitar
  un miembro, verificá si el acceso proviene de una suscripción o plantilla; no
  uses otro permiso para eludir una restricción del servidor.
- **Suscripciones:** leé [suscripciones](references/subscriptions.md) antes de
  modificar cobros, cancelaciones, cambios programados o reembolsos. El servidor
  conserva las reglas de Stripe/MercadoPago y de las suscripciones manuales.
- **Reservas y check-ins:** distinguí la reserva de una plaza de la asistencia
  registrada. Usá `mark_booking_attended` sólo cuando se solicita registrar la
  asistencia. Crear una reserva pasada puede generar un check-in
  automáticamente por la regla vigente de Learn; tené en cuenta ese efecto
  al interpretar el pedido. Conservá fecha de ocurrencia, modalidad y timezone.
- **Reportes:** usá la tool del reporte correspondiente, con período y filtros
  explícitos. Leé [reportes](references/reports.md) para interpretar alcance,
  totales y paginación.

La referencia de [operaciones](references/mcp-operations.md) explica las familias
de tools y su contrato común. Consultá el schema real antes de completar
parámetros; no adivines nombres de campos ni uses opciones de `/admin` ausentes
de la tool conectada.

## Escribir y verificar

1. Concretá escuela, recurso, cambio y efectos. La solicitud explícita ya
   autoriza ese cambio; pedí aclaración sólo si falta una decisión que afecta
   identidad, alcance o cobros. Para eliminar, cancelar o reembolsar, asegurate
   de que el usuario haya pedido ese efecto concreto.
2. Generá un UUID `request_id` nuevo por escritura. Si la respuesta es incierta,
   consultá `get_write_request` con esa clave antes de reintentar. Reutilizala
   únicamente para repetir exactamente la misma operación; para efectos de
   gateway seguí la conciliación de [suscripciones](references/subscriptions.md).
3. Para actualizar o eliminar, usá el `updated_at` recién leído como
   `expected_updated_at` cuando lo exija la tool. Ante conflicto, releé y
   conciliá el cambio antes de volver a escribir.
4. Enviá sólo campos solicitados y relaciones verificadas en la escuela elegida.
   No crees duplicados ni cambies el `request_id` para superar un error.
5. Releé después de escribir y reportá el resultado persistido. Una operación
   enviada al gateway, un job en cola y un cambio confirmado son estados
   distintos; informá el que devolvió realmente Learn.

## Límites y errores

- Si falta una tool o el MCP no está disponible, explicá qué capacidad falta.
  No sustituyas automáticamente el acceso por navegador, base de datos u otro MCP.
- Ante `forbidden` o `not_found`, no pruebes escuelas ni IDs ajenos a la selección.
- `conflict` puede indicar una revisión vieja o una clave reutilizada con otra
  carga. Conservá la operación original y revisá ambas antes de reintentar.
  Ante `operation_uncertain`, consultá `get_write_request`; no dupliques
  invitaciones, reservas ni acciones de cobro con una clave nueva.
- Respetá `Retry-After` para límites de frecuencia. Ante indisponibilidad de
  Accounts o del gateway, informá que el resultado no pudo verificarse.
- Este plugin administra escuelas PADMA/DeROSE. No ofrece configuración global,
  automatización avanzada de Zoom/grabaciones/híbridos, ni funciones de alumno.
