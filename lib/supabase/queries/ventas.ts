import { createClient } from '@/lib/supabase/server'
import type { Venta, VentaConDetalle } from '@/lib/types'

interface FiltrosVentas {
  estado?: string
  cursor?: string
}

interface PaginatedVentas {
  data: Venta[]
  nextCursor: string | null
}

const getFechaAR = () => {
  const now = new Date()
  now.setHours(now.getHours() - 3)
  return now.toISOString().split('T')[0]
}

export async function getVentasDelDia(depositoId: string): Promise<Venta[]> {
  const supabase = await createClient()
  const hoy = getFechaAR()

  const { data } = await supabase
    .from('ventas')
    .select('*')
    .eq('deposito_id', depositoId)
    .gte('created_at', `${hoy}T00:00:00`)
    .lte('created_at', `${hoy}T23:59:59`)
    .order('created_at', { ascending: false })

  return data ?? []
}

export async function getVentas(filtros: FiltrosVentas = {}): Promise<PaginatedVentas> {
  const supabase = await createClient()
  const { estado, cursor } = filtros

  let q = supabase
    .from('ventas')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(20)

  // Cursor-based: para lista descendente, usar lt con created_at
  if (cursor) q = q.lt('created_at', cursor)
  if (estado) q = q.eq('estado', estado as Venta['estado'])

  const { data } = await q
  const rows = data ?? []

  return {
    data: rows,
    nextCursor: rows.length === 20 ? (rows[19].created_at ?? null) : null,
  }
}

export async function getVentaById(id: string): Promise<VentaConDetalle | null> {
  const supabase = await createClient()

  const { data: venta } = await supabase
    .from('ventas')
    .select('*')
    .eq('id', id)
    .single()

  if (!venta) return null

  const [{ data: items }, { data: pagos }, { data: cliente }] = await Promise.all([
    supabase.from('items_venta').select('*').eq('venta_id', id),
    supabase.from('pagos_venta').select('*').eq('venta_id', id),
    venta.cliente_id
      ? supabase.from('clientes').select('*').eq('id', venta.cliente_id).single()
      : Promise.resolve({ data: null }),
  ])

  return {
    ...venta,
    items: items ?? [],
    pagos: pagos ?? [],
    cliente: cliente ?? null,
  }
}
