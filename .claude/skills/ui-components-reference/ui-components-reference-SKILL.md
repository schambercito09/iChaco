---
name: ui-components-reference
description: Referencia de componentes UI del proyecto ERP/CRM. Usar SIEMPRE junto con frontend-design cuando se construyan módulos del dashboard. Especifica exactamente cómo usar cada componente, qué props acepta, y en qué situaciones aplicar cada uno. Evita que el agente reimplemente componentes que ya existen.
---

# Skill: `ui-components-reference`
> **Activar con:** `[Skills activas: ui-components-reference]`
> **Propósito:** Referencia de uso de Button, Modal, Drawer, Table y todos los componentes UI

---

## Importación — SIEMPRE desde el barrel export

```typescript
import {
  Button, Input, Badge, Modal, Drawer,
  Table, Card, SearchInput,
  CurrencyDisplay, StatusBadge,
  EmptyState, PageHeader
} from '@/components/ui'
```

Nunca importar desde rutas individuales como `@/components/ui/Button`.

---

## Button

```typescript
// Variantes
<Button variant="primary">Confirmar venta</Button>      // azul marino, acción principal
<Button variant="secondary">Cancelar</Button>           // borde azul, acción secundaria
<Button variant="danger">Eliminar</Button>              // rojo, acción destructiva
<Button variant="ghost">Ver detalle</Button>            // sin fondo, acción terciaria

// Tamaños
<Button size="sm">Agregar</Button>
<Button size="md">Guardar</Button>   // default
<Button size="lg">Confirmar venta</Button>

// Loading state (deshabilitar durante Server Action)
<Button loading={pending} disabled={pending}>Guardando...</Button>

// Con ícono
import { Plus, Trash2 } from 'lucide-react'
<Button icon={Plus}>Nueva venta</Button>
<Button variant="danger" icon={Trash2}>Eliminar</Button>

// Como link
<Button href="/ventas/nueva">Nueva venta</Button>
```

---

## Input

```typescript
// Básico
<Input name="nombre" label="Nombre completo" required />

// Con placeholder y helper
<Input
  name="email"
  label="Email"
  type="email"
  placeholder="cliente@email.com"
  helperText="Solo se usa para comunicaciones importantes"
/>

// Con error (validación)
<Input
  name="precio"
  label="Precio USD"
  type="number"
  error={errors.precio?.message}
/>

// Deshabilitado
<Input name="vendedor" label="Vendedor" value={usuario.nombre} disabled />
```

---

## Badge

```typescript
// Colores semánticos
<Badge variant="success">Activo</Badge>      // verde
<Badge variant="warning">Pendiente</Badge>   // amarillo
<Badge variant="danger">Cancelado</Badge>    // rojo
<Badge variant="info">En proceso</Badge>     // azul
<Badge variant="neutral">Borrador</Badge>    // gris

// Variante outline
<Badge variant="success" outline>Vigente</Badge>

// Variante subtle (fondo claro)
<Badge variant="info" subtle>Mayorista</Badge>
```

---

## StatusBadge — para estados del negocio

```typescript
// Mapea automáticamente estados a colores:
<StatusBadge status="disponible" />       // verde
<StatusBadge status="confirmada" />       // azul marino
<StatusBadge status="entregada" />        // verde oscuro
<StatusBadge status="cancelada" />        // rojo
<StatusBadge status="presupuesto" />      // gris
<StatusBadge status="pendiente" />        // amarillo
<StatusBadge status="reservado" />        // azul claro
<StatusBadge status="en_reparacion" />   // naranja
<StatusBadge status="baja" />             // rojo oscuro
<StatusBadge status="activa" />           // verde (separas)
<StatusBadge status="vencida" />          // rojo (separas)
```

---

## CurrencyDisplay — siempre mostrar ARS y USD juntos

```typescript
// Mostrar ambas monedas con el TC
<CurrencyDisplay
  amountUsd={800}
  amountArs={972000}
  exchangeRate={1215}
/>
// Muestra: "USD 800 / ARS 972.000 (TC: $1.215)"

// Solo USD (cuando no hay TC disponible)
<CurrencyDisplay amountUsd={800} />
// Muestra: "USD 800"

// Monto grande destacado (para totales)
<CurrencyDisplay amountUsd={800} amountArs={972000} size="lg" />
```

---

## Modal

```typescript
// Modal básico
const [open, setOpen] = useState(false)

<Button onClick={() => setOpen(true)}>Abrir modal</Button>

<Modal
  open={open}
  onClose={() => setOpen(false)}
  title="Nuevo proveedor"
  size="md"    // 'sm' | 'md' | 'lg' | 'xl'
>
  <MiFormulario onSuccess={() => setOpen(false)} />
</Modal>

// Modal de confirmación destructiva
<Modal
  open={confirmOpen}
  onClose={() => setConfirmOpen(false)}
  title="Cancelar venta"
  variant="danger"
>
  <p>¿Confirmás la cancelación de la venta V-00042?</p>
  <p className="text-sm text-gray-500 mt-2">Esta acción no se puede deshacer.</p>
  <div className="flex gap-2 mt-4">
    <Button variant="danger" loading={pending} onClick={handleCancel}>
      Cancelar venta
    </Button>
    <Button variant="secondary" onClick={() => setConfirmOpen(false)}>
      Volver
    </Button>
  </div>
</Modal>
```

---

## Drawer — para fichas de detalle

```typescript
// Drawer lateral para ficha de cliente, producto, IMEI, etc.
const [selected, setSelected] = useState<Cliente | null>(null)

<Table data={clientes} onRowClick={setSelected} />

<Drawer
  open={!!selected}
  onClose={() => setSelected(null)}
  title={selected ? `${selected.nombre} ${selected.apellido}` : ''}
  subtitle={selected?.dni ? `DNI: ${selected.dni}` : undefined}
>
  {selected && (
    <FichaCliente cliente={selected} onUpdate={() => setSelected(null)} />
  )}
</Drawer>
```

---

## Table

```typescript
// Definir columnas
const columns = [
  { key: 'numero_venta', header: 'N° Venta', sortable: true },
  { key: 'cliente',      header: 'Cliente',
    render: (row) => row.cliente?.nombre ?? 'Anónimo' },
  { key: 'total_usd',    header: 'Total',
    render: (row) => <CurrencyDisplay amountUsd={row.total_usd} amountArs={row.total_ars} /> },
  { key: 'estado',       header: 'Estado',
    render: (row) => <StatusBadge status={row.estado} /> },
]

<Table
  data={ventas}
  columns={columns}
  onRowClick={(venta) => router.push(`/ventas/${venta.id}`)}
  emptyState={<EmptyState title="Sin ventas hoy" />}
  loading={isLoading}
/>
```

---

## SearchInput — búsqueda con debounce

```typescript
// Server-side search (con searchParams)
// En el Server Component page.tsx:
// const query = searchParams.q as string | undefined
// const ventas = await getVentas({ busqueda: query })

// Client-side con router.push:
'use client'
import { useRouter, useSearchParams } from 'next/navigation'

function Buscador() {
  const router = useRouter()
  return (
    <SearchInput
      placeholder="Buscar por nombre, DNI, teléfono..."
      defaultValue={searchParams.get('q') ?? ''}
      onSearch={(q) => {
        const params = new URLSearchParams(searchParams)
        if (q) params.set('q', q)
        else params.delete('q')
        router.push(`?${params}`)
      }}
      minChars={3}
    />
  )
}
```

---

## Card

```typescript
// Card básico
<Card>
  <h3>Ventas del día</h3>
  <p className="text-3xl font-bold text-navy">USD 2.400</p>
</Card>

// Card con header y acciones
<Card
  title="Separas activas"
  action={<Button size="sm" href="/separas/nueva">Nueva sepa</Button>}
>
  contenido...
</Card>

// Card de alerta (para banners de error o advertencia)
<Card variant="warning">
  ⚠️ No hay tipo de cambio cargado hoy
</Card>

<Card variant="danger">
  🔴 3 separas vencen hoy
</Card>
```

---

## EmptyState

```typescript
import { ShoppingCart, Users, Package } from 'lucide-react'

// Para listados vacíos
<EmptyState
  icon={ShoppingCart}
  title="Sin ventas hoy"
  description="Las ventas confirmadas del día aparecerán aquí"
  action={{ label: "Nueva venta", href: "/ventas/nueva" }}
/>

// Sin acción (solo informativo)
<EmptyState
  icon={Package}
  title="Sin productos en esta categoría"
/>
```

---

## PageHeader

```typescript
// Header estándar de cada módulo
<PageHeader
  title="Ventas"
  breadcrumb={[{ label: 'Dashboard', href: '/dashboard' }, { label: 'Ventas' }]}
  actions={
    <Button href="/ventas/nueva" icon={Plus}>Nueva venta</Button>
  }
/>

// Con estadísticas
<PageHeader
  title="Presupuestos"
  stats={[
    { label: 'Enviados', value: 43 },
    { label: 'Convertidos', value: '62%', variant: 'success' },
    { label: 'Rechazados', value: '20%', variant: 'danger' },
  ]}
  actions={<Button href="/presupuestos/nueva">Nuevo presupuesto</Button>}
/>
```