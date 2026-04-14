---
name: performance
description: Optimización de performance para el ERP/CRM. Usar cuando se construyan listados grandes, el dashboard, el POS, o cualquier módulo que maneje muchos registros. Cubre caché de Next.js, Suspense, optimistic UI, imágenes y bundle size.
---

# Skill: `performance`
> **Activar con:** `[Skills activas: performance]`
> **Propósito:** Listados rápidos, dashboard ágil y POS fluido en mobile

---

## 1. Caché de Next.js — estrategia por tipo de dato

```typescript
// REGLA: cada dato tiene una vida útil diferente

// Datos que cambian por acción del usuario → revalidar por ruta
// (ventas, stock, clientes, separas)
export async function getVentasDelDia(depositoId: string) {
  const supabase = createServerClient()
  const { data } = await supabase
    .from('ventas')
    .select('...')
    .eq('deposito_id', depositoId)
  return data
}
// En la Server Action que crea una venta:
revalidatePath('/ventas')
revalidatePath('/dashboard')
revalidatePath('/caja')

// Datos semi-estáticos → revalidar cada N segundos
import { unstable_cache } from 'next/cache'

export const getMetodosPago = unstable_cache(
  async () => {
    const supabase = createServerClient()
    const { data } = await supabase.from('metodos_pago').select('*').eq('activo', true)
    return data ?? []
  },
  ['metodos-pago'],
  { revalidate: 3600 } // 1 hora — los métodos de pago casi nunca cambian
)

export const getConfiguracion = unstable_cache(
  async () => {
    const supabase = createServerClient()
    const { data } = await supabase.from('configuracion_sistema').select('*')
    return Object.fromEntries(data?.map(r => [r.clave, r.valor]) ?? [])
  },
  ['configuracion'],
  { revalidate: 300 } // 5 minutos
)

// Datos del catálogo → revalidar al modificar
export const getVariantes = unstable_cache(
  async (categoriaId?: string) => {
    const supabase = createServerClient()
    let q = supabase.from('variantes_producto').select('*, producto:productos(*)')
    if (categoriaId) q = q.eq('productos.categoria_id', categoriaId)
    const { data } = await q
    return data ?? []
  },
  ['variantes'],
  { revalidate: 60, tags: ['catalogo'] }
)
// En la Server Action que modifica el catálogo:
revalidateTag('catalogo')
```

---

## 2. React Suspense — skeletons por sección

```tsx
// page.tsx — cargar secciones en paralelo con Suspense individual
import { Suspense } from 'react'

export default async function DashboardPage() {
  return (
    <div className="space-y-6 p-6">
      {/* Cada sección carga independiente — si una tarda, las otras no esperan */}
      <Suspense fallback={<SkeletonAlertas />}>
        <AlertasCriticas />
      </Suspense>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Suspense fallback={<SkeletonCard />}><CardVentasDia /></Suspense>
        <Suspense fallback={<SkeletonCard />}><CardCaja /></Suspense>
        <Suspense fallback={<SkeletonCard />}><CardSeparas /></Suspense>
        <Suspense fallback={<SkeletonCard />}><CardNovedades /></Suspense>
      </div>

      <Suspense fallback={<SkeletonTabla rows={5} />}>
        <TablaVentasRecientes />
      </Suspense>
    </div>
  )
}

// Skeleton de card (reutilizable)
function SkeletonCard() {
  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6 animate-pulse">
      <div className="h-4 bg-gray-200 rounded w-1/2 mb-3" />
      <div className="h-8 bg-gray-200 rounded w-3/4 mb-2" />
      <div className="h-3 bg-gray-200 rounded w-1/3" />
    </div>
  )
}

// Skeleton de tabla
function SkeletonTabla({ rows = 10 }: { rows?: number }) {
  return (
    <div className="bg-white rounded-lg border border-gray-200 overflow-hidden animate-pulse">
      <div className="h-10 bg-blue-light" />
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="h-12 border-t border-gray-100 px-4 flex items-center gap-4">
          <div className="h-3 bg-gray-200 rounded w-24" />
          <div className="h-3 bg-gray-200 rounded w-32" />
          <div className="h-3 bg-gray-200 rounded w-20 ml-auto" />
        </div>
      ))}
    </div>
  )
}
```

---

## 3. Optimistic UI — acciones frecuentes sin esperar al servidor

```tsx
// Para acciones que se hacen muchas veces por día:
// marcar novedad como vista, cambiar estado de sepa, toggle activo

'use client'
import { useOptimistic, useTransition } from 'react'
import { marcarNovedadVista } from '@/lib/actions/novedades'

export function ListaNovedades({ novedades: initial }: { novedades: NovedadTurno[] }) {
  const [pending, startTransition] = useTransition()
  const [novedades, setOptimistic] = useOptimistic(
    initial,
    (state, id: string) => state.map(n => n.id === id ? { ...n, estado: 'vista' as const } : n)
  )

  const handleMarcarVista = (id: string) => {
    startTransition(async () => {
      setOptimistic(id)              // actualiza la UI inmediatamente
      await marcarNovedadVista(id)   // luego confirma en el servidor
    })
  }

  return (
    <ul>
      {novedades.map(n => (
        <li key={n.id} className={n.estado === 'vista' ? 'opacity-50' : ''}>
          <span>{n.titulo}</span>
          {n.estado === 'pendiente' && (
            <button onClick={() => handleMarcarVista(n.id)}>Marcar vista</button>
          )}
        </li>
      ))}
    </ul>
  )
}
```

---

## 4. Imágenes de productos — next/image

```tsx
import Image from 'next/image'

// ✅ Siempre usar next/image para imágenes del catálogo
<Image
  src={imagen.url}
  alt={`${variante.nombre} - ${variante.color}`}
  width={200}
  height={200}
  className="object-cover rounded-lg"
  loading="lazy"           // lazy por defecto para grillas de productos
  placeholder="blur"       // blur placeholder mientras carga
  blurDataURL="data:image/jpeg;base64,/9j/4AAQ..."
/>

// Para la imagen principal de un producto (above the fold):
<Image
  src={imagenPrincipal.url}
  alt={producto.nombre}
  width={400}
  height={400}
  priority={true}           // cargar antes (no lazy) si está visible al entrar
  className="object-contain"
/>

// Configurar dominios en next.config.ts:
// images: {
//   remotePatterns: [
//     { protocol: 'https', hostname: '*.supabase.co' }
//   ]
// }
```

---

## 5. Queries eficientes — solo los campos necesarios

```typescript
// ❌ Trae todas las columnas (incluye JSONB pesados)
const { data } = await supabase.from('ventas').select('*')

// ✅ Solo lo que necesita el listado
const { data } = await supabase
  .from('ventas')
  .select(`
    id,
    numero_venta,
    created_at,
    total_usd,
    total_ars,
    estado,
    canal,
    cliente:clientes ( nombre, apellido ),
    vendedor:usuarios ( nombre )
  `)
  .order('id', { ascending: false })
  .limit(20)

// Para el detalle completo (solo al abrir una venta específica):
const { data } = await supabase
  .from('ventas')
  .select(`
    *,
    cliente:clientes (*),
    vendedor:usuarios (*),
    items:items_venta (
      *,
      variante:variantes_producto (
        *,
        producto:productos ( nombre, garantia_meses )
      )
    ),
    pagos:pagos_venta ( *, metodo:metodos_pago ( nombre ) )
  `)
  .eq('id', id)
  .single()
```

---

## 6. Bundle size — importaciones correctas

```typescript
// ❌ Importa toda la librería
import * as lucide from 'lucide-react'

// ✅ Solo el ícono que necesitás
import { ShoppingCart, Plus, Search } from 'lucide-react'

// ❌ Importa date-fns completo
import { format } from 'date-fns'
import es from 'date-fns/locale/es'

// ✅ Importación específica
import { format } from 'date-fns/format'
import { es } from 'date-fns/locale/es'

// Para verificar el bundle:
// npm run build → ver el output de Next.js
// Las páginas grandes (>100KB) necesitan revisión
```

---

## 7. Checklist de performance por módulo

Antes de terminar cada paso del roadmap:

```
Listados:
- [ ] Cursor-based pagination (no OFFSET)
- [ ] Select solo los campos necesarios (no SELECT *)
- [ ] Suspense con skeleton específico del módulo
- [ ] Índices correctos en los campos WHERE y ORDER BY

Formularios:
- [ ] useTransition + botón deshabilitado durante submit
- [ ] Validación Zod client-side para errores inmediatos (sin round-trip)

Imágenes:
- [ ] next/image con width y height explícitos
- [ ] loading="lazy" para imágenes fuera del viewport inicial
- [ ] priority={true} solo para la imagen principal above-the-fold

Caché:
- [ ] revalidatePath en todas las Server Actions
- [ ] unstable_cache para datos semi-estáticos (métodos de pago, config)
- [ ] revalidateTag para invalidar grupos relacionados (catálogo, precios)
```
