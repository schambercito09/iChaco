import { createClient } from '@/lib/supabase/server'
import type { Producto, VarianteProducto } from '@/lib/types'

interface FiltrosProductos {
  categoria?: string
  busqueda?: string
  cursor?: string
}

interface PaginatedResult<T> {
  data: T[]
  nextCursor: string | null
}

export async function getProductos(
  filtros: FiltrosProductos = {},
): Promise<PaginatedResult<Producto>> {
  const supabase = await createClient()
  const { categoria, busqueda, cursor } = filtros

  // Construimos los filtros por separado para evitar confusión de tipos en el query builder
  const filters: Record<string, string> = {}
  if (cursor) filters.cursor = cursor
  if (categoria) filters.categoria = categoria
  if (busqueda) filters.busqueda = busqueda

  let q = supabase
    .from('productos')
    .select('*')
    .eq('activo', true)
    .order('id')
    .limit(20)

  if (filters.cursor) q = q.gt('id', filters.cursor)
  if (filters.categoria) q = q.eq('categoria_id', filters.categoria)
  if (filters.busqueda) q = q.ilike('nombre', `%${filters.busqueda}%`)

  const { data } = await q
  const rows = (data ?? []) as Producto[]

  return {
    data: rows,
    nextCursor: rows.length === 20 ? (rows[19].id ?? null) : null,
  }
}

export async function getVarianteById(id: string): Promise<VarianteProducto | null> {
  const supabase = await createClient()

  const { data } = await supabase
    .from('variantes_producto')
    .select('*')
    .eq('id', id)
    .single()

  return (data as VarianteProducto | null) ?? null
}

export async function buscarVariantes(
  query: string,
  depositoId: string,
): Promise<VarianteProducto[]> {
  const supabase = await createClient()

  // Paso 1: buscar variantes por sku o nombre de producto
  const { data: variantes } = await supabase
    .from('variantes_producto')
    .select('*, producto:productos!inner(nombre)')
    .eq('activo', true)
    .or(`sku_variante.ilike.%${query}%`)
    .limit(40)

  // Búsqueda por nombre de producto usando filter embebido PostgREST
  const { data: porNombre } = await supabase
    .from('variantes_producto')
    .select('*, producto:productos!inner(nombre)')
    .eq('activo', true)
    .eq('producto.activo', true)
    .filter('producto.nombre', 'ilike', `%${query}%`)
    .limit(40)

  // Unificar resultados eliminando duplicados
  const allRaw = [...(variantes ?? []), ...(porNombre ?? [])]
  const seen = new Set<string>()
  const unique = allRaw.filter((v) => {
    const vTyped = v as { id: string }
    if (seen.has(vTyped.id)) return false
    seen.add(vTyped.id)
    return true
  })

  if (unique.length === 0) return []

  const varianteIds = unique.map((v) => (v as { id: string }).id)

  // Paso 2: filtrar solo las que tienen stock en el depósito
  const { data: stockData } = await supabase
    .from('stock')
    .select('variante_id')
    .eq('deposito_id', depositoId)
    .in('variante_id', varianteIds)
    .gt('cantidad_disponible', 0)

  const conStock = new Set((stockData ?? []).map((s) => s.variante_id))

  return unique
    .filter((v) => conStock.has((v as { id: string }).id))
    .map((v) => {
      const { producto: _, ...variante } = v as Record<string, unknown>
      return variante as unknown as VarianteProducto
    })
    .slice(0, 20)
}
