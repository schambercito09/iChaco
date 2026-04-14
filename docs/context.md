# context.md — ERP/CRM Pyme de Tecnología

> Fuente de verdad del proyecto. Claude Code debe leerlo completo al inicio
> de cada sesión antes de escribir cualquier línea de código.

---

## 1. DESCRIPCIÓN DEL NEGOCIO

**Nombre:** (a confirmar con el cliente)
**Rubro:** Venta de tecnología — celulares nuevos y usados, pantallas, hardware de PC, accesorios
**Ubicaciones:**
- Tienda principal → vende, tiene caja, atiende clientes
- Depósito separado → recibe mercadería, hace transferencias, no vende directamente

**Operatoria clave:**
- Productos nuevos y usados (celulares con IMEI individual)
- Parte de pago (trade-in): cliente entrega su equipo para descontar del precio
- Compra de usados a particulares y recuperadoras
- Servicio técnico propio
- Múltiples vendedores con métricas y comisiones individuales
- Precios en USD y ARS (tipo de cambio diario, snapshot inmutable por transacción)
- Inteligencia competitiva: registro de precios y productos de la competencia

---

## 2. STACK TÉCNICO

| Capa | Tecnología |
|---|---|
| Framework | Next.js 14 App Router |
| Lenguaje | TypeScript (strict) |
| Estilos | Tailwind CSS |
| Base de datos | Supabase (PostgreSQL) |
| Auth | Supabase Auth |
| Deploy | Vercel |
| Validación | Zod (todas las Server Actions) |
| Toasts | Sonner |
| PDF / Etiquetas | Fase 2 — librería a definir |
| WhatsApp | Fase 4 — Meta Cloud API |

**Paleta de colores:**
- Azul marino principal: `#1E3A5F` (headers, sidebar, elementos de marca)
- Azul marino oscuro: `#142842`
- Azul marino medio: `#2D5F8A`
- Azul claro fondo: `#EFF6FF`
- Azul acento: `#3B82F6`
- Blanco: `#FFFFFF` (fondo predominante)

---

## 3. CONVENCIONES OBLIGATORIAS

### Rutas
- Auth: `app/(auth)/login/page.tsx`
- Dashboard: `app/(dashboard)/dashboard/page.tsx`
- Módulos: `app/(dashboard)/[modulo]/page.tsx`
- Cada módulo nuevo va en su propia carpeta dentro de `(dashboard)`

### Next.js / Supabase
- Usar `proxy.ts` en la raíz (NO `middleware.ts` — jamás)
- Usar `lib/supabase/proxy.ts` para el cliente Supabase
- Nunca usar `localStorage` o `sessionStorage`
- Server Actions en `lib/actions/[modulo].ts`
- Tipos TypeScript generados en `lib/types/database.types.ts`
- Importar componentes UI siempre desde `@/components/ui` (barrel export)

### Patrón obligatorio de Server Actions
```typescript
// Retorno estándar — usar en TODAS las actions:
export type ActionResult<T = void> =
  | { success: true; data?: T }
  | { error: string }

// Helpers en lib/utils/actions.ts:
export const actionSuccess = <T>(data?: T): ActionResult<T> =>
  ({ success: true, data })
export const actionError = (msg: string): ActionResult =>
  ({ error: msg })

// Esquema de cada action:
// 1. Validar con Zod (schema.parse — lanza si falla)
// 2. Verificar rol/permisos
// 3. Operar en BD (o llamar RPC para transacciones)
// 4. Crear log_actividad
// 5. revalidatePath(...)
// 6. return actionSuccess(data) | actionError(msg)
```

### Validación con Zod
- Zod en TODAS las Server Actions antes de tocar la BD
- Los schemas viven en `lib/validations/[modulo].ts`
- Usar `schema.parse()` (lanza ZodError) o `schema.safeParse()` si se prefiere

### Loading states y toasts
- Loading state: `useTransition` + botón deshabilitado durante la acción
- Feedback: Sonner — `toast.success()`, `toast.error()`, `toast.loading()`
- El layout raíz (`app/layout.tsx`) debe tener `<Toaster position="top-right" />`

### Paginación cursor-based
- NUNCA usar OFFSET en listados — produce queries lentas con volumen
- Patrón estándar con Supabase:
```typescript
async function getItems(cursor?: string) {
  let q = supabase.from('tabla').select('*').order('id').limit(20)
  if (cursor) q = q.gt('id', cursor)
  const { data } = await q
  return {
    data: data ?? [],
    nextCursor: data?.length === 20 ? data[19].id : null
  }
}
// cursor se pasa como searchParam: ?cursor=UUID
```

### Helper requireTCDelDia
- Usar en TODAS las actions que involucren precios, ventas o separas
```typescript
// lib/supabase/queries/tipo-cambio.ts
async function requireTCDelDia(): Promise<TipoCambio> {
  const tc = await getTipoCambioHoy()
  if (!tc) throw new Error('SIN_TC_DEL_DIA')
  return tc
}
// En la action:
// try {
//   const tc = await requireTCDelDia()
// } catch (e) {
//   if ((e as Error).message === 'SIN_TC_DEL_DIA')
//     return actionError('Cargá el tipo de cambio del día antes de continuar')
//   throw e
// }
```

### Nomenclatura
- Tablas: `snake_case` en plural (ej: `ventas`, `items_venta`)
- Componentes React: `PascalCase`
- Variables y funciones: `camelCase`
- Constantes: `UPPER_SNAKE_CASE`
- Números de documentos via SEQUENCE PostgreSQL: `V-00042`, `SEP-00023`, `ST-00015`

### TypeScript
- Ejecutar `npx tsc --noEmit` al final de cada paso
- Sin `any` explícito — usar tipos del schema
- Props de componentes siempre tipadas con interfaces

### Mobile-first
- Diseño funcional desde 375px en todos los módulos

---

## 4. REGLAS DE NEGOCIO CRÍTICAS

### Tipo de cambio (TC)
- Existe un TC por día en la tabla `tipos_cambio_dolar`
- Si no hay TC del día, el sistema bloquea ventas hasta que el admin lo cargue
- Al confirmar cualquier transacción (venta, compra, sepa), el TC se guarda
  como snapshot INMUTABLE en el campo `tipo_cambio_valor_ars`
- El precio USD es siempre la fuente de verdad; ARS = `precio_usd × tc_del_dia`
- Usar `requireTCDelDia()` al inicio de toda action que dependa del TC

### Vendedores
- `usuario_vendedor_id` en `ventas` es OBLIGATORIO — nunca nullable
- Los descuentos tienen límite por rol; superar el límite genera
  `aprobaciones_descuento` pendiente y bloquea la confirmación de la venta

### Productos serializados
- Cada unidad tiene IMEI o número de serie único en `unidades_serializadas`
- Estados: `disponible | vendido | reservado | en_reparacion | en_garantia_proveedor | baja`
- `reservado` → vinculado a una sepa via `sepa_id` (campo en unidades_serializadas)
- `en_garantia_proveedor` → equipo enviado al distribuidor para reclamo

### Usados
- Precio sugerido = `precio_nuevo × factor_condicion − Σ(reduce_precio_por_defecto)`
- Costo real = `costo_adquisicion + Σ(costos_preventa_unidad)`
- Defecto `bloqueante` (ej: iCloud activo) → NO se puede vender hasta resolver
- Acta de recepción obligatoria (módulo 17) al recibir un equipo

### Separas
- Precio USD pactado es INMUTABLE
- Precio ARS al concretar se recalcula con el TC del día de concreción
  (no el TC del día de la seña) → campo `tipo_cambio_concrecion_id`
- Vencimiento configurable via `configuracion_sistema.sepa_dias_vencimiento`

### Caja
- Maneja ARS y USD por separado en cada sesión
- `sesion_caja_id` en `pagos_sepa` es nullable (transferencias fuera de turno)
- El cobro de servicio técnico genera una venta con `canal = 'servicio_tecnico'`

### Transacciones atómicas
- Las operaciones que tocan múltiples tablas (confirmar venta, crear sepa)
  se ejecutan via funciones RPC de PostgreSQL — NO con llamadas JS secuenciales
- La función `confirmar_venta(p_datos JSONB)` existe en el schema (Paso 2b)
- Esto garantiza rollback automático ante cualquier error

### Numeración de documentos
- Los números (V-XXXXX, PRS-XXXXX, SEP-XXXXX, etc.) se generan via
  SEQUENCE de PostgreSQL y triggers BEFORE INSERT
- NUNCA usar COUNT(*)+1 — produce duplicados con acceso concurrente

### Auditoría
- Toda acción sensible se registra en `log_actividad` con snapshot JSONB
- Acciones que siempre generan log: cambios de precio, cancelación de ventas,
  ajustes de stock, cambios en `configuracion_sistema`, aprobaciones de descuento

---

## 5. SCHEMA DE BASE DE DATOS

### Fase 1 (MVP — operativo desde el día 1)

**Core**
- `tipos_cambio_dolar` — TC por día, bloqueante si falta
- `configuracion_sistema` — parámetros globales editables sin deploy
- `depositos` — tienda y depósito
- `usuarios` — con rol y depósito asignado
  Nota: se crea automáticamente via trigger `on_auth_user_created`
  cuando se registra un usuario en Supabase Auth
- `log_actividad` — auditoría con JSONB antes/después

**Catálogo**
- `categorias` (auto-referencial para subcategorías)
- `marcas`
- `productos` (tipo: serializado / generico / servicio)
- `variantes_producto` (color, capacidad_gb, ram_gb, version, modelo)
- `imagenes_producto`

**Inventario**
- `stock` (PK compuesta: variante_id + deposito_id)
- `unidades_serializadas` (IMEI/serie, condicion, es_usado, sepa_id, costo_total_usd)
- `movimientos_stock` (referencia_tipo cubre todos los orígenes)
- `ajustes_stock` (requieren aprobación de admin si el solicitante es vendedor)

**Precios**
- `listas_precio`
- `precios_variante` (precio_usd + opcional precio_ars_fijo)
- `historial_precios`
- `reglas_descuento`
- `aprobaciones_descuento`

**Proveedores / Compras**
- `proveedores` (con score de performance cacheado)
- `recepciones_mercaderia` + `detalle_recepciones`

**Clientes**
- `clientes`
- `garantias_cliente`
- `cuentas_corriente_cliente` (se crea automáticamente al crear cliente)
- `movimientos_cuenta_corriente`

**Ventas**
- `ventas` (canal incluye 'servicio_tecnico')
- `items_venta`
- `metodos_pago` (incluye 'parte_de_pago')
- `pagos_venta`
- `presupuestos` + `items_presupuesto`

**Usados**
- `catalogo_detalles_usados` (severidad: informativo|leve|moderado|grave|bloqueante)
- `detalles_unidad_usada`
- `partes_de_pago` (trade-in)

**Demanda**
- `demandas_no_satisfechas`

**Separas**
- `separas` (con tipo_cambio_concrecion_id)
- `pagos_sepa` (sesion_caja_id nullable)

**Caja**
- `cajas`, `sesiones_caja`, `movimientos_caja`
- `gastos` + `categorias_gasto`

**Operaciones**
- `novedades_turno` (briefing automático al iniciar sesión)

**Vendedores**
- `objetivos_vendedor`

### Fase 2
- `ordenes_compra` + `detalle_ordenes_compra`
- `transferencias_stock` + `detalle_transferencias`
- `costos_preventa_unidad` (COGS real de usados)
- `compras_usados` + `items_compra_usados`
- `actas_recepcion` (PDF automático)
- `garantias_proveedor` + `historial_garantia_proveedor`
- `ordenes_servicio`, `cobros_orden_servicio`, `presupuestos_servicio`, `repuestos_orden`
- `interacciones_crm`, `recordatorios_crm`
- `competidores`, `observaciones_competencia`, `items_observacion_competencia`, `alertas_competencia`
- `precios_mercado_externo`, `eventos_mercado`
- `v_depreciacion_stock`, `v_performance_proveedores` (vistas)
- `devoluciones`, `items_devolucion`, `items_cambio`
- `comisiones_vendedor`, `pagos_comisiones`, `metricas_vendedor_diarias`
- `plantillas_etiqueta`, `lotes_etiquetas`, `items_lote_etiquetas`

### Fase 3 — Vistas analíticas
- `v_elasticidad_precio`, `v_ciclo_compra_clientes`, `v_rotacion_specs`

### Fase 4 — Automatización
- API tipo de cambio (BCRA / Bluelytics)
- WhatsApp (Meta Cloud API)
- ML scraping para `precios_mercado_externo`
- Sincronización MercadoLibre

---

## 6. ESTRUCTURA DE CARPETAS

```
/
├── app/
│   ├── layout.tsx                  ← Toaster de Sonner aquí
│   ├── error.tsx, loading.tsx, not-found.tsx
│   ├── (auth)/
│   │   └── login/
│   │       ├── page.tsx
│   │       ├── actions.ts
│   │       └── _components/LoginForm.tsx
│   └── (dashboard)/
│       ├── layout.tsx              ← INMUTABLE
│       ├── dashboard/page.tsx      ← INMUTABLE
│       ├── error.tsx, loading.tsx
│       ├── tipo-cambio/page.tsx
│       ├── catalogo/page.tsx
│       ├── inventario/page.tsx
│       ├── precios/page.tsx
│       ├── proveedores/page.tsx
│       ├── clientes/page.tsx
│       ├── ventas/page.tsx
│       ├── presupuestos/page.tsx
│       ├── separas/page.tsx
│       ├── usados/page.tsx
│       ├── caja/page.tsx
│       ├── vendedores/page.tsx
│       ├── demanda/page.tsx
│       ├── novedades/page.tsx
│       └── configuracion/page.tsx
├── components/
│   ├── layout/
│   │   ├── DashboardShell.tsx      ← INMUTABLE
│   │   ├── Sidebar.tsx             ← INMUTABLE
│   │   └── Header.tsx              ← INMUTABLE
│   └── ui/
│       ├── index.ts                ← barrel export (importar siempre desde @/components/ui)
│       ├── Button.tsx, Input.tsx, Badge.tsx, Modal.tsx, Drawer.tsx
│       ├── Table.tsx, Card.tsx, SearchInput.tsx
│       ├── CurrencyDisplay.tsx, StatusBadge.tsx
│       ├── EmptyState.tsx, PageHeader.tsx
│       └── ...
├── lib/
│   ├── supabase/
│   │   ├── client.ts
│   │   ├── server.ts
│   │   ├── proxy.ts                ← INMUTABLE
│   │   ├── storage.ts              ← helpers de Supabase Storage
│   │   └── queries/                ← helpers server-side por módulo
│   │       ├── tipo-cambio.ts      ← incluye requireTCDelDia()
│   │       ├── productos.ts, stock.ts, clientes.ts
│   │       ├── ventas.ts, usuarios.ts, configuracion.ts
│   │       └── novedades.ts, log.ts
│   ├── actions/                    ← Server Actions por módulo
│   │   ├── tipo-cambio.ts, catalogo.ts, inventario.ts
│   │   ├── precios.ts, ventas.ts, presupuestos.ts
│   │   ├── clientes.ts, proveedores.ts, caja.ts
│   │   ├── separas.ts, usados.ts, demanda.ts, novedades.ts
│   │   └── ...
│   ├── types/
│   │   ├── database.types.ts       ← generado por Supabase CLI
│   │   ├── index.ts                ← tipos derivados
│   │   └── enums.ts                ← enums del dominio como const objects
│   ├── validations/                ← schemas Zod por módulo
│   │   ├── ventas.ts, clientes.ts, inventario.ts, ...
│   └── utils/
│       └── actions.ts              ← ActionResult<T>, actionSuccess, actionError
├── proxy.ts                        ← INMUTABLE (raíz)
└── .env.local
```

---

## 7. ARCHIVOS INMUTABLES — NUNCA MODIFICAR

```
proxy.ts
lib/supabase/proxy.ts
components/layout/DashboardShell.tsx
components/layout/Sidebar.tsx
components/layout/Header.tsx
app/(auth)/login/page.tsx
app/(auth)/login/_components/LoginForm.tsx
app/(auth)/login/actions.ts
app/(auth)/loading.tsx
app/(dashboard)/layout.tsx
app/(dashboard)/dashboard/page.tsx
```

**Señal de alerta:** Menos de 20 líneas o solo `return null` → fue revertido
por el agente → restaurar antes de continuar con cualquier otra cosa.

---

## 8. SEGURIDAD Y RLS

- RLS activado en Supabase para todas las tablas (nunca desactivar)
- `superadmin` y `admin` ven todo
- `vendedor` solo ve sus propias ventas y métricas
- `tecnico` solo ve órdenes de servicio de su depósito
- `deposito` solo ve stock, recepciones y transferencias
- Funciones helper en BD: `get_user_rol()`, `get_user_deposito_id()`, `is_admin()`
- Nunca exponer `service_role` key en el cliente
- Variables de entorno en `.env.local`, nunca hardcodeadas
- Trigger `on_auth_user_created` → crea fila en `usuarios` automáticamente

---

## 9. PARÁMETROS DE CONFIGURACIÓN (configuracion_sistema)

| Clave | Default | Descripción |
|---|---|---|
| sepa_dias_vencimiento | 15 | Días hasta vencimiento de sepa |
| sepa_dias_alerta_previo | 3 | Días antes del vencimiento para alertar |
| postventa_dias_recordatorio | 7 | Días post-venta para recordatorio automático |
| descuento_maximo_vendedor_pct | 10 | % máximo sin aprobación |
| margen_minimo_alerta_pct | 15 | % mínimo de margen antes de alertar |
| tc_variacion_reimprimir_etiquetas_pct | 3 | % variación TC para marcar etiquetas desactualizadas |
| elasticidad_ventana_dias | 30 | Días para análisis de elasticidad |
| stock_muerto_dias | 60 | Días sin movimiento = stock muerto |
| ciclo_upgrade_margen_tolerancia_pct | 20 | Tolerancia sobre ciclo promedio |
| presupuesto_dias_seguimiento | 3 | Días sin respuesta para recordatorio |

---

## 10. PRD COMPLETO

El PRD detallado con todas las tablas, vistas SQL, flujos y reglas de negocio
está en: `docs/prd-v7.md`

Ante cualquier duda sobre un módulo, campo o regla → consultar ese archivo
antes de asumir.
