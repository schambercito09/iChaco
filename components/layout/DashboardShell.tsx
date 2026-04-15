'use client'

// Estructura base del dashboard. Gestiona el estado del sidebar en mobile.
// Para agregar secciones al sidebar, editar Sidebar.tsx.

import { useState, type ReactNode } from 'react'
import { Sidebar } from './Sidebar'
import { Header } from './Header'
import type { UsuarioConDeposito } from '@/lib/supabase/queries/usuarios'

interface DashboardShellProps {
  children: ReactNode
  usuario: UsuarioConDeposito
  tcDisponible: boolean
}

export function DashboardShell({ children, usuario, tcDisponible }: DashboardShellProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false)

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar
        usuario={usuario}
        tcDisponible={tcDisponible}
        isOpen={sidebarOpen}
        onClose={() => setSidebarOpen(false)}
      />

      <div className="flex flex-col flex-1 min-w-0">
        <Header
          usuario={usuario}
          tcDisponible={tcDisponible}
          onMenuClick={() => setSidebarOpen(true)}
        />

        <main className="flex-1 p-5 overflow-y-auto" id="main-content">
          {children}
        </main>
      </div>
    </div>
  )
}
