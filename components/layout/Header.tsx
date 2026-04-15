'use client'

import { usePathname } from 'next/navigation'
import { Menu, Store, CheckCircle2, AlertTriangle } from 'lucide-react'
import type { UsuarioConDeposito } from '@/lib/supabase/queries/usuarios'

interface HeaderProps {
  usuario: UsuarioConDeposito
  tcDisponible: boolean
  onMenuClick: () => void
}

// ─── Mapeo pathname → nombre del módulo ───────────────────────────────────────

const MODULE_NAMES: Record<string, string> = {
  '/dashboard': 'Dashboard',
  '/tipo-cambio': 'Tipo de Cambio',
  '/ventas': 'Ventas',
  '/presupuestos': 'Presupuestos',
  '/separas': 'Separas',
  '/clientes': 'Clientes',
  '/productos': 'Catálogo',
  '/inventario': 'Inventario',
  '/proveedores': 'Proveedores',
  '/usados': 'Usados',
  '/precios': 'Precios',
  '/caja': 'Caja',
  '/vendedores': 'Vendedores',
  '/reportes': 'Reportes',
  '/configuracion': 'Configuración',
  '/novedades': 'Novedades',
  '/demanda': 'Demanda',
}

function getModuleName(pathname: string): string {
  // Extraer el primer segmento: /ventas/nueva → /ventas
  const segment = '/' + (pathname.split('/').filter(Boolean)[0] ?? '')
  return MODULE_NAMES[segment] ?? 'iChaco ERP'
}

const ROL_LABELS: Record<string, string> = {
  superadmin: 'Super Admin',
  admin: 'Admin',
  vendedor: 'Vendedor',
  tecnico: 'Técnico',
  deposito: 'Depósito',
}

// ─── Header ───────────────────────────────────────────────────────────────────

export function Header({ usuario, tcDisponible, onMenuClick }: HeaderProps) {
  const pathname = usePathname()
  const moduleName = getModuleName(pathname)

  return (
    <header className="h-14 bg-white border-b border-blue-border flex items-center gap-3 px-4 shrink-0">
      {/* Hamburger — solo en mobile */}
      <button
        onClick={onMenuClick}
        className="md:hidden p-2 rounded-lg text-gray-500 hover:bg-gray-100 hover:text-navy transition-colors"
        aria-label="Abrir menú de navegación"
      >
        <Menu className="w-5 h-5" aria-hidden="true" />
      </button>

      {/* Nombre del módulo activo */}
      <h1 className="font-bold text-navy text-sm flex-1 truncate">{moduleName}</h1>

      {/* ── Zona derecha ── */}
      <div className="flex items-center gap-3 shrink-0">
        {/* Indicador TC del día */}
        <div className="hidden sm:flex items-center gap-1.5">
          {tcDisponible ? (
            <>
              <CheckCircle2 className="w-4 h-4 text-green-500 shrink-0" aria-hidden="true" />
              <span className="text-xs font-medium text-green-600">TC cargado</span>
            </>
          ) : (
            <>
              <AlertTriangle className="w-4 h-4 text-amber-500 shrink-0" aria-hidden="true" />
              <span className="text-xs font-medium text-amber-600">Sin TC</span>
            </>
          )}
        </div>

        {/* Chip del depósito activo */}
        {usuario.deposito && (
          <div className="hidden sm:flex items-center gap-1.5 bg-blue-light border border-blue-border rounded-full px-3 py-1">
            <Store className="w-3 h-3 text-navy shrink-0" aria-hidden="true" />
            <span className="text-xs font-medium text-navy truncate max-w-[120px]">
              {usuario.deposito.nombre}
            </span>
          </div>
        )}

        {/* Usuario */}
        <div className="flex items-center gap-2">
          <div className="text-right hidden sm:block">
            <p className="text-xs font-semibold text-gray-900 leading-tight">
              {usuario.nombre} {usuario.apellido}
            </p>
            <p className="text-[10px] text-gray-400 leading-tight">
              {ROL_LABELS[usuario.rol] ?? usuario.rol}
            </p>
          </div>
          {/* Avatar con inicial */}
          <div
            className="w-8 h-8 rounded-full bg-navy flex items-center justify-center shrink-0"
            aria-hidden="true"
          >
            <span className="text-white text-xs font-bold">
              {usuario.nombre.charAt(0).toUpperCase()}
            </span>
          </div>
        </div>
      </div>
    </header>
  )
}
