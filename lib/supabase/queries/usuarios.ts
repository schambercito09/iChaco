import { createClient } from '@/lib/supabase/server'
import type { Usuario, Deposito } from '@/lib/types'

export type UsuarioConDeposito = Usuario & { deposito: Deposito | null }

export async function getUsuarioActual(): Promise<UsuarioConDeposito | null> {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return null

  // ── Intento 1: query completa con join a depositos ─────────────────────────
  // Funciona cuando la migration 002_fix_usuarios.sql ya fue ejecutada.
  const { data, error } = await supabase
    .from('usuarios')
    .select('*, deposito:depositos(*)')
    .eq('id', user.id)
    .single()

  if (!error && data) {
    const { deposito, ...usuario } = data as Usuario & { deposito: Deposito | null }
    return { ...usuario, deposito }
  }

  // ── Intento 2: fallback sin join ───────────────────────────────────────────
  // Tolera el schema en transición (antes de correr la migration):
  // la tabla real puede tener es_admin/sucursal_id en lugar de rol/deposito_id.
  const { data: raw, error: rawError } = await supabase
    .from('usuarios')
    .select('*')
    .eq('id', user.id)
    .single()

  if (rawError || !raw) return null

  // Coerce a la forma esperada por el código con defaults seguros
  const r = raw as Record<string, unknown>

  const usuarioFallback: UsuarioConDeposito = {
    id: String(r.id ?? ''),
    nombre: String(r.nombre ?? ''),
    apellido: String(r.apellido ?? ''),
    email: String(r.email ?? user.email ?? ''),
    // Mapear es_admin (schema viejo) → rol (schema nuevo)
    rol: (
      typeof r.rol === 'string'
        ? r.rol
        : r.es_admin === true
          ? 'admin'
          : 'vendedor'
    ) as Usuario['rol'],
    // Mapear sucursal_id (schema viejo) → deposito_id (schema nuevo)
    deposito_id: (r.deposito_id ?? r.sucursal_id ?? null) as string | null,
    comision_porcentaje: (r.comision_porcentaje ?? null) as number | null,
    meta_mensual_usd: (r.meta_mensual_usd ?? null) as number | null,
    activo: typeof r.activo === 'boolean' ? r.activo : true,
    created_at: (r.created_at ?? null) as string | null,
    updated_at: (r.updated_at ?? null) as string | null,
    deposito: null,
  }

  return usuarioFallback
}

export async function getUsuarios(): Promise<Usuario[]> {
  const supabase = await createClient()

  const { data } = await supabase
    .from('usuarios')
    .select('*')
    .eq('activo', true)
    .order('nombre')

  return data ?? []
}
