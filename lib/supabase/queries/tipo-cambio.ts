import { createClient } from '@/lib/supabase/server'
import type { TipoCambio } from '@/lib/types'

const getFechaAR = () => {
  const now = new Date()
  now.setHours(now.getHours() - 3)
  return now.toISOString().split('T')[0]
}

export async function getTipoCambioHoy(): Promise<TipoCambio | null> {
  const supabase = await createClient()
  const hoy = getFechaAR()

  const { data } = await supabase
    .from('tipos_cambio_dolar')
    .select('*')
    .eq('fecha', hoy)
    .single()

  return data ?? null
}

export async function getTipoCambioById(id: string): Promise<TipoCambio | null> {
  const supabase = await createClient()

  const { data } = await supabase
    .from('tipos_cambio_dolar')
    .select('*')
    .eq('id', id)
    .single()

  return data ?? null
}

export async function getHistorialTC(limit = 30): Promise<TipoCambio[]> {
  const supabase = await createClient()

  const { data } = await supabase
    .from('tipos_cambio_dolar')
    .select('*')
    .order('fecha', { ascending: false })
    .limit(limit)

  return data ?? []
}

// =============================================================================
// HELPER OBLIGATORIO — usar en TODA Server Action que dependa del TC
// =============================================================================
//
// Uso en una Server Action:
//   try {
//     const tc = await requireTCDelDia()
//     // usar tc.id y tc.valor_ars
//   } catch (e) {
//     if ((e as Error).message === 'SIN_TC_DEL_DIA')
//       return { error: 'Cargá el tipo de cambio del día antes de continuar' }
//     throw e
//   }
//
export async function requireTCDelDia(): Promise<TipoCambio> {
  const tc = await getTipoCambioHoy()
  if (!tc) throw new Error('SIN_TC_DEL_DIA')
  return tc
}
