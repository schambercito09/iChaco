import { createClient } from '@/lib/supabase/server'
import type { Cliente } from '@/lib/types'

interface PaginatedClientes {
  data: Cliente[]
  nextCursor: string | null
}

export async function getClientes(cursor?: string): Promise<PaginatedClientes> {
  const supabase = await createClient()

  let q = supabase
    .from('clientes')
    .select('*')
    .eq('activo', true)
    .order('created_at', { ascending: false })
    .limit(20)

  if (cursor) q = q.lt('created_at', cursor)

  const { data } = await q
  const rows = data ?? []

  return {
    data: rows,
    nextCursor: rows.length === 20 ? (rows[19].created_at ?? null) : null,
  }
}

export async function getClienteById(id: string): Promise<Cliente | null> {
  const supabase = await createClient()

  const { data } = await supabase
    .from('clientes')
    .select('*')
    .eq('id', id)
    .single()

  return data ?? null
}

export async function buscarCliente(query: string): Promise<Cliente[]> {
  const supabase = await createClient()

  const { data } = await supabase
    .from('clientes')
    .select('*')
    .eq('activo', true)
    .or(`nombre.ilike.%${query}%,apellido.ilike.%${query}%,telefono.ilike.%${query}%,dni.ilike.%${query}%`)
    .order('nombre')
    .limit(20)

  return data ?? []
}
