---
name: revision-de-asistencia
description: Usar cuando un administrador de escuela o estudio quiera comparar asistencia, reservas y cancelaciones en Learn o detectar clases y horarios que merecen revisión. Entrega tendencias comparables y casos concretos para revisar la grilla.
---

# Revisión de asistencia en Learn

1. Con `learn`, llamá a `list_accounts` y obtené la zona horaria de la escuela
   autorizada con `get_account_context`. Si hay varias escuelas y el usuario
   no identificó la suya, preguntá cuál usar. Conservá `account_name` en las
   consultas. Si no hay período, compará la última semana completa, de lunes a
   domingo, con la anterior. Si un período solicitado sigue abierto, explicá
   el corte y compará tramos equivalentes cuando corresponda.
2. Para cada período, consultá `get_bookings_report` con `scope: "all"` y los
   filtros `booked_date_gteq` y `booked_date_lteq`. Conservá cancelaciones
   tempranas, tardías y ausencias según los totales de Learn. `other` agrupa
   las demás reservas. Medí la asistencia con las lecturas del paso siguiente.
3. Consultá `get_check_ins_report` con `scope: "not_copies_not_on_user_timer"`
   y `checked_in_at_gteq`/`checked_in_at_lteq` para los días completos en la
   zona horaria de la escuela. Para clases en vivo y presenciales, usá
   `post_type_in: ["Live", "InPersonLive"]` o `post_id_in` con clases verificadas.
   Usá los mismos filtros entre períodos de cada reporte. Presentá el total de
   check-ins como eventos y dejá explícitas las diferencias de población con
   el reporte de reservas. Calculá una tasa de asistencia a reservas sólo si
   podés verificar las asistencias de ese mismo conjunto de reservas.
4. Si la escuela tiene acceso al reporte por instructor, paginá
   `get_instructor_classes_report` con `start_date` y `end_date` para ambos
   períodos. Agrupá las ocurrencias comparables por clase y horario local a
   partir de `post_ids` y `starts_at`. Cada fila representa una ocurrencia,
   incluso cuando una clase híbrida incluye varios posts. Compará la cantidad
   de ocurrencias y `students_count` por ocurrencia, e indicá las asignaciones
   pendientes con `status: "review"`. Si sólo hay reportes agregados, consultá
   `list_bookings` con `status: "all"` y las fechas `from` y `to`. Usá
   `cached_booked_datetime` cuando esté disponible y presentá esos horarios
   como cobertura parcial de reservas.
5. Entregá escuela, períodos, zona horaria y filtros, con cantidades y cambios
   comparables. Destacá clases u horarios con evidencia suficiente y qué
   conviene revisar en cada caso. Indicá si los permisos, el límite histórico
   o la paginación incompleta restringieron la comparación. Usá herramientas
   de lectura para toda la revisión.

Consultá la [guía de reportes de Learn](../padma-learn/references/reports.md)
para confirmar los filtros, las unidades y el alcance de cada reporte.
