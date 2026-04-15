// INMUTABLE — layout del dashboard. Obtiene usuario y envuelve con DashboardShell.

import type { ReactNode } from 'react'
import { redirect } from 'next/navigation'
import { DashboardShell } from '@/components/layout/DashboardShell'
import { getUsuarioActual } from '@/lib/supabase/queries/usuarios'

export default async function DashboardLayout({ children }: { children: ReactNode }) {
  const usuario = await getUsuarioActual()
  if (!usuario) redirect('/login')

  return (
    <DashboardShell usuario={usuario}>
      {children}
    </DashboardShell>
  )
}
