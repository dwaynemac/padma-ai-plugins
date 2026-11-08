# Suscripciones de alumnos

La suscripción de Learn gobierna acceso educativo y puede estar vinculada a
cobros externos. No es el plan financiero de Money ni la suscripción SaaS de la
escuela a PADMA.

Antes de un cambio, leé la suscripción y su plantilla: alumno, escuela, estado,
gateway, importes/moneda, fechas y cambios programados. Mostrá el efecto
concreto si el pedido no lo determina claramente.

- Las lecturas usan `list_subscriptions`, `get_subscription`,
  `list_subscription_templates` y `list_subscription_payments`. La v1 no tiene
  una tool para crear una suscripción desde cero.
- Una suscripción externa debe cambiar mediante las operaciones que exponga
  Learn para su gateway. No fuerces su estado local para simular una respuesta
  de Stripe o MercadoPago.
- `update_subscription` requiere `local_only` explícito: `true` modifica sólo
  Learn y `false` usa la sincronización existente con el proveedor. Nunca
  elijas `true` para eludir un rechazo del gateway.
- `cancel_subscription` cancela Stripe al final del período y MercadoPago
  inmediatamente. No ofrece un selector para intercambiar esas modalidades.
  Una petición de pausa no autoriza cancelación ni reembolso.
- `pause_subscription` y `reactivate_subscription` son exclusivamente de
  MercadoPago; cambian entre `authorized` y `paused` según el estado actual.
- Reembolsar requiere que el usuario haya pedido devolver ese pago y que se
  haya verificado el identificador de pago, moneda e importe.
  `refund_subscription_payment` usa `id` de suscripción y `payment_id`; admite
  únicamente el reembolso total de un pago aprobado de MercadoPago.
- `import_subscription` importa una suscripción existente de MercadoPago con
  `gateway_id` y `external_id`; no crea una autorización ni un cobro nuevo.
- `sync_subscription` refresca los datos de Stripe o MercadoPago desde el
  proveedor. `delete_subscription` elimina sólo cuando los permisos actuales
  permiten quitar el registro local.
- No elimines un registro para sustituir la cancelación que requiere el gateway.

## Cambios programados

`list_subscription_updates` consulta cambios. `create_subscription_update`
requiere `subscription_id`, su `expected_updated_at`, `run_update_on` y al menos
un nuevo valor. `create_subscription_updates_batch` admite hasta 100
suscripciones explícitas, cada una con su revisión; un `multiplier` se excluye
con `new_amount_cents`.

`update_subscription_update` y `delete_subscription_update` operan sobre el
`id` y la revisión del cambio programado. `run_subscription_update` ejecuta
sólo un cambio pendiente ya vencido y requiere, además,
`expected_subscription_updated_at`, obtenido al releer la suscripción.

## Resultado externo incierto

Toda escritura usa `request_id`; las operaciones que cambian registros
existentes usan su revisión vigente según el schema. Ante
`operation_uncertain`:

1. Consultá `get_write_request` con la clave original. No cambies argumentos ni
   claves para repetir el efecto.
2. Releé la suscripción. Para operaciones compatibles, usá
   `reconcile_subscription_operation` con `id`, `expected_updated_at`, el
   `operation_request_id` original y un `request_id` nuevo para la conciliación.
3. La conciliación consulta el proveedor sin repetir el efecto. Si
   `reconciled` es `false`, informá que sigue sin confirmarse; no simules éxito
   ni vuelvas a solicitar el cobro o reembolso.

La conciliación cubre cancelación, pausa, reactivación, sincronización,
actualización y reembolso, además de cambios programados verificables e
importaciones cuyo registro local ya existe. Si una importación no llegó a
guardar el registro local, seguirá incierta y requiere revisión; no recrees
identificadores ni repitas la operación para resolverla.
No llames directamente a Stripe, MercadoPago ni Money para completar una acción
fallida en Learn.

Informá por separado el estado guardado en Learn, el efecto confirmado por el
gateway y cualquier sincronización pendiente. No afirmes que hubo un cobro,
reembolso o acceso efectivo sólo por haber solicitado la operación.
