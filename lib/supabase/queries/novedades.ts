import { createClient } from '@/lib/supabase/server'
import type { NovedadTurno } from '@/lib/types'

export async function getNovedadesPendientes(depositoId: string): Promise<NovedadTurno[]> {
  const supabase = await createClient()

  const { data } = await supabase
    .from('novedades_turno')
    .select('*')
    .eq('deposito_id', depositoId)
    .in('estado', ['pendiente', 'vista'])
    .order('prioridad', { ascending: false }) // urgente primero (desc: urgente, normal, informativa)
    .order('created_at', { ascending: false })

  return data ?? []
}
