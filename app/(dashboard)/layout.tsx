// INMUTABLE — layout del dashboard. Obtiene usuario + TC y envuelve con DashboardShell.

import type { ReactNode } from 'react'
import { redirect } from 'next/navigation'
import { DashboardShell } from '@/components/layout/DashboardShell'
import { getUsuarioActual } from '@/lib/supabase/queries/usuarios'
import { getTipoCambioHoy } from '@/lib/supabase/queries/tipo-cambio'

export default async function DashboardLayout({ children }: { children: ReactNode }) {
  const [usuario, tcHoy] = await Promise.all([
    getUsuarioActual(),
    getTipoCambioHoy(),
  ])

  if (!usuario) redirect('/login')

  return (
    <DashboardShell usuario={usuario} tcDisponible={!!tcHoy}>
      {children}
    </DashboardShell>
  )
}
