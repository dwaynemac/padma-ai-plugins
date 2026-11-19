---
name: revision-de-mensualidades
description: Usar cuando un administrador de escuela o estudio quiera revisar mensualidades vencidas, detectar quién tiene meses impagos o preparar el seguimiento de cobros en PADMA Money. Devuelve los meses de cada plan agrupados por contacto.
---

# Revisión de mensualidades en Money

1. Con `money`, llamá a `list_businesses` y consultá `get_business_context` del
   negocio autorizado. Si hay varios y el usuario no identificó el suyo,
   preguntá cuál usar. Conservá `business_id` en las consultas. Usá el período
   solicitado o, si falta, el mes en curso y los dos anteriores según la zona
   horaria del negocio.
2. Identificá las categorías de ingresos de mensualidades con
   `search_categories(section: "incomes")`. Si el alcance incluye subcategorías,
   recorré las páginas y relaciones `parent.id` pertinentes y usá cada
   `category_id`, ya que `search_plans` filtra por categoría exacta. Para períodos
   históricos, buscá también las categorías archivadas pertinentes con
   `archived: true`. Si hay más de una interpretación que cambie qué planes
   entran, consultalo con el usuario.
3. Llamá a `search_plans` por cada mes y categoría del alcance, con
   `has_debt: true` y `from` y `to` en ese mismo mes, en formato `YYYY-MM-DD`.
   Paginá con los mismos filtros. Una búsqueda de varios meses sólo confirma
   que hay al menos uno impago. Conservá los planes terminados que aparezcan y
   usá el resultado de Money para saber si el vencimiento ya pasó. Consultá el
   [contrato de deuda](../padma-money/references/mcp-operations.md#deuda-de-pagos-en-search_plans).
4. Agrupá por `contact.id` y conservá cada combinación de plan y mes
   confirmada. Si consultás el instructor, pasá a `search_contacts` el
   `padma_id` que devolvió el plan y comprobá que el resultado corresponda al
   contacto del mismo negocio. Si falta el vínculo o `teacher` es nulo, indicá
   que el instructor no pudo confirmarse.
5. Entregá negocio, período, categorías y una fila por contacto con sus planes,
   meses y docente cuando esté disponible. Ordená por el mes vencido más
   antiguo, salvo que el usuario prefiera otro criterio. Indicá los meses o
   categorías con cobertura incompleta. El valor mensual de un plan representa
   una expectativa. Evitá usar ese valor como saldo adeudado o sumar
   expectativas de planes del mismo contacto y categoría.

La revisión es de lectura. Para registrar un pago o ajustar un plan o su
expectativa, seguí el flujo de confirmación y verificación de
[PADMA Money](../padma-money/SKILL.md).
