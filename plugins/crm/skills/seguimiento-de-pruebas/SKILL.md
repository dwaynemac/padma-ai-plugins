---
name: seguimiento-de-pruebas
description: Usar cuando un administrador de escuela o estudio quiera saber a quién contactar después de una clase de prueba. Prioriza en PADMA CRM a los prospectos con asistencia a una prueba registrada que siguen sin matricularse, según su última comunicación.
---

# Seguimiento de pruebas en CRM

1. Con `crm`, llamá a `list_accounts`, seleccioná la escuela autorizada y
   consultá `get_account_context`. Si hay varias cuentas y la escuela no está
   identificada, preguntá cuál usar. Conservá ese `account_name` en las consultas.
2. Usá `search_contacts` con `status: "prospect"` y `assisted: true`. Si el
   usuario indicó fechas de prueba, usá los límites estrictos `trial_on_gt` y
   `trial_on_lt`, ajustándolos un día cuando corresponda incluir los extremos.
   Si falta el período, usá `with_trial_lt_ago: 30` e informá el alcance.
   Interpretá «¿a quién contacto hoy?» como una prioridad de seguimiento.
3. Si el usuario acotó la búsqueda a una lista guardada, resolvela con
   `list_contact_lists` y agregá su ID en `intersect_list_ids`. Mantené los
   criterios de prospecto y asistencia incluso para la etapa `trialed`, que
   también puede incluir exalumnos y contactos con visitas. Si el usuario
   pidió abrir el embudo, `get_commercial_funnel` puede inicializar búsquedas
   de sistema y requiere permiso de escritura en CRM.
4. Paginá conservando los filtros. Para cada candidato que vayas a priorizar,
   usá `get_contact_history` con su `padma_id`. Buscá la entrada `Communication`
   más reciente de la escuela y fechala con `activity_at`. Revisá páginas
   siguientes si hace falta. Si el historial confirma una matrícula posterior
   a la prueba, descartá ese caso. Si el estado y el historial se contradicen,
   o la lectura quedó incompleta, marcá el caso para verificar.
5. Priorizá casos sin comunicación registrada o con la comunicación más
   antigua. Si el historial muestra un próximo contacto acordado, tenelo en
   cuenta. Entregá escuela, período y lista ordenada con nombre, fecha de la
   última comunicación o estado de verificación y un próximo paso por caso.
   Indicá qué cobertura tuvo la priorización si acotaste el detalle. Mostrá la
   fecha de la prueba sólo cuando haya evidencia específica para ese contacto.

La revisión entrega sugerencias. Resumí sólo los hechos necesarios del
historial. Si el MCP no permite comprobar la asistencia, indicá esa limitación.
Consultá los [filtros de contactos y el contrato de historial](../padma-crm/references/contacts.md)
cuando necesites más detalle. Para registrar una comunicación, comentar o
modificar datos, seguí los permisos, confirmaciones y lecturas posteriores de
[PADMA CRM](../padma-crm/SKILL.md).
