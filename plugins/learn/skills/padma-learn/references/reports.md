# Reportes administrativos de asistencia

Los reportes se entregan como JSON estructurado por las tools del MCP docente.
Permiten analizar las mismas vistas de asistencia de `/admin` sin leer HTML ni
descargar un CSV. Su período, filtros y permisos forman parte del resultado;
conservá esa información al explicar los números.

| Tool | Vista administrativa |
| --- | --- |
| `get_check_ins_report` | Reporte de check-ins |
| `get_bookings_report` | Reporte de reservas |
| `get_check_ins_distribution_report` | Distribución de check-ins |
| `get_instructor_classes_report` | Clases por instructor |

Los filtros van dentro de `filters`, con los nombres admitidos por cada tool;
no se envían como campos superiores ni como un `q` genérico.

## Defaults que afectan el resultado

- `get_check_ins_report` usa `scope: "not_copies_not_on_user_timer"` por defecto
  y, si falta el inicio, comienza tres meses atrás. Admite también `all`,
  `on_user_timer`, `not_copies` y `copies`.
- `get_bookings_report` usa `scope: "future_not_cancelled"` por defecto.
  Para un reporte histórico elegí `scope: "all"` o `scope: "past"` de forma
  explícita: `past` excluye cancelaciones tempranas, `all` las conserva.
- Distribución y clases por instructor requieren una escuela de pago y
  conservan el período predeterminado del reporte administrativo. Enviá fechas
  explícitas para comparaciones y consultas históricas.
- Distribución e instructor devuelven `items` paginados con `cursor` y
  `page_size`; sus `totals` y `summary` corresponden al reporte completo, no a
  la página. Los otros dos reportes devuelven agregados y series.

Ejemplo de reservas de octubre, sujeto a la escuela previamente seleccionada:

```json
{
  "scope": "all",
  "filters": {
    "booked_date_gteq": "2026-10-01",
    "booked_date_lteq": "2026-10-31"
  }
}
```

El período de check-ins y distribución usa `checked_in_at_gteq` y
`checked_in_at_lteq`; instructor usa `start_date` y `end_date` dentro de
`filters`. Conservá los límites y timezone devueltos por el reporte.

## Elegir y leer el reporte

1. Resolvé la escuela con `list_accounts` y su timezone con
   `get_account_context`.
2. Elegí el reporte según el hecho que se quiere medir: reservar, asistir,
   distribuir asistencias o contabilizar clases de un instructor.
3. Completá un período explícito y los filtros admitidos por el schema. Si el
   usuario pidió «este mes», resolvé las fechas en la zona horaria de la escuela.
4. Respetá las agrupaciones y los filtros efectivos del reporte, incluidos el
   estado del alumno, los contenidos considerados y el instructor cuando
   corresponda. No cambies un filtro para que el total coincida con una expectativa.
5. Recorré todas las páginas necesarias para afirmar que un detalle está
   completo. Usá los totales del reporte cuando existan, en lugar de sumar una
   página parcial.

## Interpretación

- Una reserva no demuestra asistencia; un check-in puede existir sin reserva.
- El total de eventos, el de clases y el de personas únicas responden preguntas
  diferentes. Conservá la unidad de la respuesta.
- No compares reportes con períodos, escuelas o filtros distintos sin señalarlo.
- Cuando se consulta por un alumno ausente del resultado, revisá filtros y
  paginación antes de inferir que no tiene actividad.
- `include_students_wout_checkins` agrega alumnos **actuales de CRM** sin
  asistencia al reporte de distribución. No reconstruye quién era alumno
  durante el período histórico consultado.
- Las cifras son las que confirmó el MCP. Separá cualquier cálculo derivado o
  interpretación y expresá sus supuestos.

Al entregar el análisis, indicá escuela, período, timezone, reporte y filtros
materiales. Informá cobertura parcial si una página o consulta no pudo leerse.
