---
name: proyecto-patterns
description: Patrones específicos del ERP/CRM de pyme de tecnología. Usar en TODOS los pasos junto con otras skills. Contiene los patrones únicos de este proyecto que el agente debe seguir consistentemente: ActionResult, requireTCDelDia, RPC transactions, cursor pagination, componentes UI, y convenciones de nomenclatura.
---

# Skill: `proyecto-patterns`
> **Activar con:** `[Skills activas: proyecto-patterns]`
> **Propósito:** ActionResult, requireTCDelDia, componentes UI y patrones del ERP

---

## ActionResult<T> — patrón de retorno de Server Actions

```typescript
// lib/utils/actions.ts — ya existe, importar desde aquí
import { actionSuccess, actionError } from '@/lib/utils/actions'
import type { ActionResult } from '@/lib/utils/actions'

// Uso en Server Actions:
export async function miAction(formData: FormData): Promise<ActionResult<{ id: string }>> {
  try {
    // 1. Validar
    const data = miSchema.parse(Object.fromEntries(formData))

    // 2. Verificar TC si la action toca precios
    const tc = await requireTCDelDia()

    // 3. Operar
    const result = await supabase.rpc('mi_rpc', { p_datos: data })
    if (!result.data?.success) return actionError(result.data?.error ?? 'Error')

    // 4. Log + revalidate
    await crearLog({ accion: 'crear', tabla: 'mi_tabla', descripcion: '...' })
    revalidatePath('/mi-modulo')

    return actionSuccess({ id: result.data.id })

  } catch (e) {
    if ((e as Error).message === 'SIN_TC_DEL_DIA')
      return actionError('Cargá el tipo de cambio del día antes de continuar')
    if (e instanceof ZodError)
      return actionError(e.errors[0].message)
    console.error(e)
    return actionError('Error interno del servidor')
  }
}

// Uso en Client Component:
const [pending, startTransition] = useTransition()

const handleSubmit = (formData: FormData) => {
  startTransition(async () => {
    const result = await miAction(formData)
    if ('error' in result) {
      toast.error(result.error)
    } else {
      toast.success('Operación exitosa')
      router.push('/mi-modulo')
    }
  })
}

// Botón durante la acción:
<Button type="submit" loading={pending} disabled={pending}>
  Guardar
</Button>
```

---

## requireTCDelDia — helper de tipo de cambio

```typescript
// lib/supabase/queries/tipo-cambio.ts — ya definido
import { requireTCDelDia } from '@/lib/supabase/queries/tipo-cambio'

// Uso en Server Action que dependa del TC:
const tc = await requireTCDelDia()
// tc.id          → UUID para guardar como snapshot
// tc.valor_ars   → NUMERIC para calcular ARS

// Precio ARS = precio_usd * tc.valor_ars
const precioArs = Number(precioUsd) * Number(tc.valor_ars)
```

---

## Componentes UI — cómo usarlos

```typescript
// Importar SIEMPRE desde el barrel export:
import {
  Button, Input, Badge, Modal, Drawer,
  Table, Card, SearchInput,
  CurrencyDisplay, StatusBadge,
  EmptyState, PageHeader
} from '@/components/ui'

// Button — variantes y loading:
<Button variant="primary" loading={pending}>Confirmar venta</Button>
<Button variant="secondary" onClick={onCancel}>Cancelar</Button>
<Button variant="danger" disabled={!canDelete}>Eliminar</Button>

// CurrencyDisplay — siempre mostrar ARS y USD juntos:
<CurrencyDisplay amountUsd={800} amountArs={972000} exchangeRate={1215} />
// Muestra: "USD 800 / ARS 972.000"

// StatusBadge — estados del negocio:
<StatusBadge status="confirmada" />   // verde
<StatusBadge status="pendiente" />    // amarillo
<StatusBadge status="cancelada" />    // rojo
<StatusBadge status="reservado" />    // azul

// SearchInput — con debounce:
<SearchInput
  placeholder="Buscar por nombre, DNI..."
  onSearch={(q) => setQuery(q)}  // debounce 300ms interno
  minChars={3}
/>

// EmptyState — para listados vacíos:
<EmptyState
  icon={ShoppingCart}
  title="Sin ventas hoy"
  description="Las ventas del día aparecerán aquí"
  action={{ label: "Nueva venta", href: "/ventas/nueva" }}
/>

// PageHeader — header estándar de cada módulo:
<PageHeader
  title="Ventas"
  actions={<Button href="/ventas/nueva">Nueva venta</Button>}
/>
```

---

## Cursor-based pagination — componente estándar

```typescript
// En el Server Component (page.tsx):
interface PageProps {
  searchParams: { cursor?: string; [key: string]: string | undefined }
}

export default async function MiModuloPage({ searchParams }: PageProps) {
  const { data, nextCursor } = await getItems(searchParams.cursor, {
    estado: searchParams.estado,
  })

  return (
    <>
      <Table data={data} columns={columns} />
      <div className="flex justify-between mt-4">
        {searchParams.cursor && (
          <Link href="?">← Primeros</Link>
        )}
        {nextCursor && (
          <Link href={`?cursor=${nextCursor}`}>Siguiente →</Link>
        )}
      </div>
    </>
  )
}
```

---

## Formularios con Server Actions — patrón estándar

```typescript
'use client'
import { useTransition } from 'react'
import { toast } from 'sonner'
import { Button, Input } from '@/components/ui'
import { miAction } from '@/lib/actions/mi-modulo'

export function MiFormulario({ onSuccess }: { onSuccess?: () => void }) {
  const [pending, startTransition] = useTransition()

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const formData = new FormData(e.currentTarget)
    startTransition(async () => {
      const result = await miAction(formData)
      if ('error' in result) {
        toast.error(result.error)
        return
      }
      toast.success('Guardado correctamente')
      onSuccess?.()
    })
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <Input name="nombre" label="Nombre" required />
      <Button type="submit" loading={pending} className="w-full">
        Guardar
      </Button>
    </form>
  )
}
```

---

## Drawer para fichas (clientes, productos, IMEIs)

```typescript
// Patrón estándar: listado + drawer de detalle
'use client'
import { useState } from 'react'
import { Drawer } from '@/components/ui'

export function ListadoConFicha({ items }: { items: Item[] }) {
  const [selected, setSelected] = useState<Item | null>(null)

  return (
    <>
      <Table
        data={items}
        onRowClick={(item) => setSelected(item)}
      />
      <Drawer
        open={!!selected}
        onClose={() => setSelected(null)}
        title={selected?.nombre ?? ''}
      >
        {selected && <FichaDetalle item={selected} />}
      </Drawer>
    </>
  )
}
```

---

## Validaciones Zod — schemas del proyecto

```typescript
// Los schemas viven en lib/validations/[modulo].ts
// Ejemplo: lib/validations/ventas.ts

import { z } from 'zod'

// Reutilizar estos refiners comunes:
const uuidReq = z.string().uuid('ID inválido')
const uuidOpt = z.string().uuid('ID inválido').optional()
const montoPos = z.number({ coerce: true }).positive('Debe ser mayor a 0')
const porcentaje = z.number({ coerce: true }).min(0).max(100)
const fechaFutura = z.string().refine(
  d => new Date(d) > new Date(),
  'La fecha debe ser futura'
)

// Exportar para usar en la action:
export const ventaSchema = z.object({
  cliente_id: uuidOpt,
  deposito_id: uuidReq,
  tipo_cambio_id: uuidReq,
  total_usd: montoPos,
  total_ars: montoPos,
  items: z.array(itemVentaSchema).min(1, 'Agregá al menos un producto'),
  pagos: z.array(pagoSchema).min(1, 'Agregá al menos un método de pago'),
})

// En la action:
import { ventaSchema } from '@/lib/validations/ventas'
const data = ventaSchema.parse(rawData)
```

---

## Novedades automáticas — llamar desde Server Actions

```typescript
// Cada vez que ocurre un evento relevante, crear una novedad:
import { crearNovedad } from '@/lib/actions/novedades'

// Dentro de tu Server Action:
await crearNovedad({
  deposito_id: depositoId,
  tipo: 'sepa_vence_hoy',       // ver enum TipoNovedad
  prioridad: 'urgente',          // 'urgente' | 'normal' | 'informativa'
  titulo: `Sepa ${numero} vence hoy`,
  descripcion: `Cliente: ${cliente.nombre} | Producto: ${descripcion}`,
  sepa_id: sepaId,               // link al objeto relacionado
  generada_por: 'sistema',
})
```

---

## Convenciones de nomenclatura — números de documentos

```
ventas        → V-XXXXX     (seq_numero_venta)
presupuestos  → PRS-XXXXX   (seq_numero_presupuesto)
separas       → SEP-XXXXX   (seq_numero_sepa)
demandas      → DNS-XXXXX   (seq_numero_demanda)
partes pago   → PP-XXXXX    (seq_numero_ppago)
órdenes ST    → ST-XXXXX    (seq propio Fase 2)

Se generan AUTOMÁTICAMENTE via trigger en el INSERT.
NO pasar numero_venta al insertar — el trigger lo pone.
```

---

## Log de actividad — cuándo y cómo registrar

```typescript
// Registrar SIEMPRE para estas acciones:
// - cambios en precios_variante
// - cancelación/modificación de ventas confirmadas
// - aprobaciones/rechazos de descuentos
// - ajustes de stock
// - cambios en configuracion_sistema

await crearLog({
  usuario_id: usuarioActual.id,
  accion: 'editar',          // 'crear'|'editar'|'eliminar'|'anular'|'aprobar'|'rechazar'
  tabla_afectada: 'ventas',
  registro_id: ventaId,
  datos_anteriores: ventaAnterior,  // snapshot JSONB del estado previo
  datos_nuevos: ventaNueva,          // snapshot JSONB del estado nuevo
  descripcion: `Venta V-00042 cancelada por ${usuario.nombre}`,
})
```