---
name: typescript-advanced
description: Patrones avanzados de TypeScript para el ERP/CRM con Next.js App Router y Supabase. Usar al construir módulos complejos, tipos para queries con joins, o cuando el agente pierde los tipos en operaciones multi-tabla.
---

# Skill: `typescript-advanced`
> **Activar con:** `[Skills activas: typescript-advanced]`
> **Propósito:** Tipos precisos para el dominio del ERP — sin any, sin as, sin sorpresas

---

## 1. ActionResult — tipo discriminado preciso

```typescript
// lib/utils/actions.ts — versión completa con helpers

export type ActionResult<T = void> =
  | { success: true; data: T }
  | { success: true }           // cuando no hay data que retornar
  | { error: string }

// Type guards para usar en Client Components:
export function isSuccess<T>(result: ActionResult<T>): result is { success: true; data: T } {
  return 'success' in result && result.success === true && 'data' in result
}

export function isError(result: ActionResult<any>): result is { error: string } {
  return 'error' in result
}

// Helpers de construcción:
export const actionSuccess = <T>(data: T): { success: true; data: T } =>
  ({ success: true, data })

export const actionOk = (): { success: true } =>
  ({ success: true })

export const actionError = (msg: string): { error: string } =>
  ({ error: msg })

// Uso en Client Component:
const result = await confirmarVenta(datos)

if (isError(result)) {
  toast.error(result.error)
  return
}

if (isSuccess(result)) {
  toast.success(`Venta ${result.data.numero} confirmada`)
  router.push(`/ventas/${result.data.id}`)
}
```

---

## 2. Branded types — evitar confusión USD vs ARS

```typescript
// lib/types/money.ts
// Previene pasar un monto ARS donde se espera USD (y viceversa)

declare const __brand: unique symbol
type Brand<T, B> = T & { [__brand]: B }

export type USD = Brand<number, 'USD'>
export type ARS = Brand<number, 'ARS'>
export type ExchangeRate = Brand<number, 'ExchangeRate'>

// Constructores:
export const usd = (n: number): USD => n as USD
export const ars = (n: number): ARS => n as ARS
export const exchangeRate = (n: number): ExchangeRate => n as ExchangeRate

// Funciones de conversión — el compilador verifica que los tipos sean correctos:
export function calcularARS(montoUsd: USD, tc: ExchangeRate): ARS {
  return (montoUsd * tc) as ARS
}

export function calcularMargen(precioUsd: USD, costoUsd: USD): number {
  if (costoUsd === 0) return 0
  return ((precioUsd - costoUsd) / costoUsd) * 100
}

// Uso:
const precio = usd(800)
const tc = exchangeRate(1215)
const precioArs = calcularARS(precio, tc)  // ✅ ARS = 972.000

// calcularARS(ars(972000), tc)  // ❌ Error de TypeScript: ARS donde se esperaba USD
```

---

## 3. Tipos para queries Supabase con joins

```typescript
// lib/types/queries.ts
// En lugar de usar any para los resultados de queries con joins

import type { Tables } from './database.types'

// Tipo base
type Venta = Tables<'ventas'>
type Cliente = Tables<'clientes'>
type ItemVenta = Tables<'items_venta'>
type VarianteProducto = Tables<'variantes_producto'>
type Producto = Tables<'productos'>
type PagoVenta = Tables<'pagos_venta'>
type MetodoPago = Tables<'metodos_pago'>
type Usuario = Tables<'usuarios'>

// Tipos compuestos para queries específicas:

// Para el listado de ventas (select parcial + joins básicos)
export type VentaListado = Pick<Venta,
  'id' | 'numero_venta' | 'created_at' | 'total_usd' | 'total_ars' | 'estado' | 'canal'
> & {
  cliente: Pick<Cliente, 'nombre' | 'apellido'> | null
  vendedor: Pick<Usuario, 'nombre'>
}

// Para el detalle completo de una venta
export type VentaDetalle = Venta & {
  cliente: Cliente | null
  vendedor: Usuario
  deposito: Tables<'depositos'>
  items: (ItemVenta & {
    variante: VarianteProducto & {
      producto: Pick<Producto, 'nombre' | 'garantia_meses'>
    }
    unidad: Tables<'unidades_serializadas'> | null
  })[]
  pagos: (PagoVenta & {
    metodo: Pick<MetodoPago, 'nombre' | 'acepta_usd'>
  })[]
}

// Para el POS — variantes disponibles en un depósito
export type VarianteConStock = VarianteProducto & {
  producto: Pick<Producto, 'nombre' | 'tipo' | 'garantia_meses'>
  precio: Tables<'precios_variante'> | null
  stock_disponible: number
  unidades_disponibles: Tables<'unidades_serializadas'>[]
}

// Para separas en el listado
export type SepaListado = Pick<Tables<'separas'>,
  'id' | 'numero_sepa' | 'precio_acordado_usd' | 'monto_seña_usd' |
  'saldo_pendiente_usd' | 'fecha_vencimiento' | 'estado'
> & {
  cliente: Pick<Cliente, 'nombre' | 'apellido' | 'telefono'>
  variante: Pick<VarianteProducto, 'sku_variante' | 'color' | 'capacidad_gb'>
  unidad: Pick<Tables<'unidades_serializadas'>, 'imei'> | null
}
```

---

## 4. Enums como const objects — con helpers

```typescript
// lib/types/enums.ts — patrón completo con type guards y labels

export const EstadoVenta = {
  PRESUPUESTO:  'presupuesto',
  CONFIRMADA:   'confirmada',
  ENTREGADA:    'entregada',
  CANCELADA:    'cancelada',
  CON_CAMBIO:   'con_cambio',
} as const

export type EstadoVenta = typeof EstadoVenta[keyof typeof EstadoVenta]

// Type guard:
export function isEstadoVenta(value: string): value is EstadoVenta {
  return Object.values(EstadoVenta).includes(value as EstadoVenta)
}

// Label para la UI:
export const LABELS_ESTADO_VENTA: Record<EstadoVenta, string> = {
  presupuesto:  'Presupuesto',
  confirmada:   'Confirmada',
  entregada:    'Entregada',
  cancelada:    'Cancelada',
  con_cambio:   'Con cambio',
}

// Estados que permiten ser cancelados:
export const ESTADOS_CANCELABLES: EstadoVenta[] = [
  EstadoVenta.PRESUPUESTO,
  EstadoVenta.CONFIRMADA,
]

export function puedeSerCancelada(estado: EstadoVenta): boolean {
  return ESTADOS_CANCELABLES.includes(estado)
}

// Uso en componentes:
<StatusBadge status={venta.estado} label={LABELS_ESTADO_VENTA[venta.estado]} />
{puedeSerCancelada(venta.estado) && <Button variant="danger">Cancelar</Button>}
```

---

## 5. Componentes con tipos estrictos

```typescript
// Sin genéricos perdidos, sin props opcionales innecesarias

// ✅ Props bien tipadas con discriminated union para variantes de componente
type ButtonProps =
  | {
      variant: 'primary' | 'secondary' | 'danger' | 'ghost'
      onClick: () => void
      href?: never
      type?: 'button' | 'submit'
      loading?: boolean
      disabled?: boolean
      children: React.ReactNode
    }
  | {
      variant: 'primary' | 'secondary'
      href: string
      onClick?: never
      children: React.ReactNode
    }

// ✅ Tabla genérica con tipo inferido de las columnas
interface Column<T> {
  key: keyof T | string
  header: string
  render?: (row: T) => React.ReactNode
}

interface TableProps<T extends { id: string }> {
  data: T[]
  columns: Column<T>[]
  onRowClick?: (row: T) => void
  caption: string
}

// El tipo de row en render es inferido automáticamente:
const columns: Column<VentaListado>[] = [
  { key: 'numero_venta', header: 'N° Venta' },
  {
    key: 'cliente',
    header: 'Cliente',
    render: (row) => row.cliente?.nombre ?? 'Anónimo'  // ✅ row es VentaListado
  },
]
```

---

## 6. Tipos para searchParams y params de Next.js

```typescript
// app/(dashboard)/ventas/page.tsx
// Next.js 14: searchParams puede tener string | string[] | undefined

type SearchParams = {
  cursor?: string
  estado?: EstadoVenta
  desde?: string
  hasta?: string
  q?: string
}

// Helper para parsear searchParams de forma segura:
function parseSearchParams(raw: Record<string, string | string[] | undefined>): SearchParams {
  return {
    cursor: typeof raw.cursor === 'string' ? raw.cursor : undefined,
    estado: typeof raw.estado === 'string' && isEstadoVenta(raw.estado) ? raw.estado : undefined,
    desde:  typeof raw.desde  === 'string' ? raw.desde  : undefined,
    hasta:  typeof raw.hasta  === 'string' ? raw.hasta  : undefined,
    q:      typeof raw.q      === 'string' ? raw.q      : undefined,
  }
}

export default async function VentasPage({
  searchParams: rawParams,
}: {
  searchParams: Record<string, string | string[] | undefined>
}) {
  const params = parseSearchParams(rawParams)
  const { data, nextCursor } = await getVentas(params)
  // ...
}
```

---

## 7. Checklist TypeScript por módulo

```
Tipos:
- [ ] Sin 'any' explícito en ningún archivo
- [ ] Queries con joins usan tipos compuestos de lib/types/queries.ts
- [ ] Enums usan const objects con type guards
- [ ] Props de componentes tienen interfaces explícitas

Dinero:
- [ ] Montos USD y ARS usan branded types donde hay riesgo de confusión
- [ ] calcularARS() recibe USD y ExchangeRate, no números sueltos

ActionResult:
- [ ] Todas las Server Actions retornan ActionResult<T>
- [ ] Client Components usan isError() e isSuccess() para discriminar

Verificación:
- [ ] npx tsc --noEmit da 0 errores
- [ ] Sin @ts-ignore ni @ts-expect-error sin justificación
```
