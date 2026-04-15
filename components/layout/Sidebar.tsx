'use client'

import { useTransition } from 'react'
import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { toast } from 'sonner'
import {
  LayoutDashboard,
  DollarSign,
  ShoppingCart,
  FileText,
  BookmarkCheck,
  Users,
  Package,
  Boxes,
  Truck,
  Smartphone,
  Tag,
  Landmark,
  BarChart3,
  TrendingUp,
  LogOut,
  X,
  AlertCircle,
  type LucideIcon,
} from 'lucide-react'
import { logout } from '@/app/(auth)/login/actions'
import type { UsuarioConDeposito } from '@/lib/supabase/queries/usuarios'

// ─── Tipos ────────────────────────────────────────────────────────────────────

interface NavItem {
  href: string
  label: string
  icon: LucideIcon
}

interface SidebarProps {
  usuario: UsuarioConDeposito
  tcDisponible: boolean
  isOpen: boolean
  onClose: () => void
}

// ─── Definición de secciones de nav ───────────────────────────────────────────

const NAV_PRINCIPAL: NavItem[] = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
]

const NAV_OPERACIONES: NavItem[] = [
  { href: '/tipo-cambio', label: 'Tipo de Cambio', icon: DollarSign },
  { href: '/ventas', label: 'Ventas', icon: ShoppingCart },
  { href: '/presupuestos', label: 'Presupuestos', icon: FileText },
  { href: '/separas', label: 'Separas', icon: BookmarkCheck },
  { href: '/clientes', label: 'Clientes', icon: Users },
]

const NAV_INVENTARIO: NavItem[] = [
  { href: '/productos', label: 'Catálogo', icon: Package },
  { href: '/inventario', label: 'Inventario', icon: Boxes },
  { href: '/proveedores', label: 'Proveedores', icon: Truck },
]

const NAV_ADMIN: NavItem[] = [
  { href: '/usados', label: 'Usados', icon: Smartphone },
  { href: '/precios', label: 'Precios', icon: Tag },
  { href: '/caja', label: 'Caja', icon: Landmark },
  { href: '/vendedores', label: 'Vendedores', icon: BarChart3 },
  { href: '/reportes', label: 'Reportes', icon: TrendingUp },
]

const ADMIN_ROLES = new Set(['admin', 'superadmin'])

// ─── NavLink ──────────────────────────────────────────────────────────────────

function NavLink({
  href,
  label,
  icon: Icon,
  badge,
  pathname,
  onClick,
}: NavItem & { badge?: boolean; pathname: string; onClick?: () => void }) {
  const isActive =
    href === '/dashboard'
      ? pathname === '/dashboard'
      : pathname === href || pathname.startsWith(href + '/')

  return (
    <li>
      <Link
        href={href}
        onClick={onClick}
        aria-current={isActive ? 'page' : undefined}
        className={[
          'relative flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors',
          isActive
            ? 'bg-navy-light text-white'
            : 'text-white/70 hover:bg-white/10 hover:text-white',
        ].join(' ')}
      >
        {/* Borde izquierdo activo */}
        {isActive && (
          <span
            className="absolute left-0 top-1 bottom-1 w-[3px] bg-white rounded-r-full"
            aria-hidden="true"
          />
        )}
        <Icon className="w-4 h-4 shrink-0" aria-hidden="true" />
        <span className="flex-1">{label}</span>
        {badge && (
          <span
            className="w-2 h-2 rounded-full bg-red-400 shrink-0"
            aria-label="Requiere atención"
          />
        )}
      </Link>
    </li>
  )
}

// ─── NavSection ───────────────────────────────────────────────────────────────

function NavSection({ label, children }: { label?: string; children: React.ReactNode }) {
  return (
    <div className="space-y-0.5">
      {label && (
        <p className="px-3 mb-1 text-[10px] font-semibold uppercase tracking-widest text-white/30 select-none">
          {label}
        </p>
      )}
      <ul className="space-y-0.5">{children}</ul>
    </div>
  )
}

// ─── Contenido del sidebar ─────────────────────────────────────────────────────

function SidebarContent({
  usuario,
  tcDisponible,
  onClose,
}: {
  usuario: UsuarioConDeposito
  tcDisponible: boolean
  onClose?: () => void
}) {
  const pathname = usePathname()
  const router = useRouter()
  const [pending, startTransition] = useTransition()
  const isAdmin = ADMIN_ROLES.has(usuario.rol)

  function handleLogout() {
    startTransition(async () => {
      const result = await logout()
      if ('error' in result) {
        toast.error(result.error)
      } else {
        router.replace('/login')
      }
    })
  }

  return (
    <div className="flex flex-col h-full bg-navy">
      {/* ── Logo ── */}
      <div className="px-4 py-4 border-b border-white/10 flex items-center justify-between shrink-0">
        <span className="text-white font-bold text-base tracking-tight">iChaco ERP</span>
        {/* Botón cerrar — solo visible en mobile */}
        {onClose && (
          <button
            onClick={onClose}
            className="md:hidden p-1 rounded text-white/60 hover:text-white hover:bg-white/10 transition-colors"
            aria-label="Cerrar menú"
          >
            <X className="w-4 h-4" />
          </button>
        )}
      </div>

      {/* ── Navegación ── */}
      <nav
        className="flex-1 overflow-y-auto py-3 px-2 space-y-4"
        aria-label="Navegación principal"
      >
        <NavSection>
          {NAV_PRINCIPAL.map((item) => (
            <NavLink key={item.href} {...item} pathname={pathname} onClick={onClose} />
          ))}
        </NavSection>

        <div className="border-t border-white/10" />

        <NavSection label="Operaciones">
          {NAV_OPERACIONES.map((item) => (
            <NavLink
              key={item.href}
              {...item}
              badge={item.href === '/tipo-cambio' && !tcDisponible}
              pathname={pathname}
              onClick={onClose}
            />
          ))}
        </NavSection>

        <div className="border-t border-white/10" />

        <NavSection label="Inventario">
          {NAV_INVENTARIO.map((item) => (
            <NavLink key={item.href} {...item} pathname={pathname} onClick={onClose} />
          ))}
        </NavSection>

        {isAdmin && (
          <>
            <div className="border-t border-white/10" />
            <NavSection label="Administración">
              {NAV_ADMIN.map((item) => (
                <NavLink key={item.href} {...item} pathname={pathname} onClick={onClose} />
              ))}
            </NavSection>
          </>
        )}
      </nav>

      {/* ── Footer: alerta TC + usuario + logout ── */}
      <div className="shrink-0 border-t border-white/10 p-3 space-y-2">
        {/* Alerta sin TC */}
        {!tcDisponible && (
          <div className="flex items-center gap-2 bg-red-500/20 rounded-lg px-3 py-2">
            <AlertCircle className="w-3.5 h-3.5 text-red-400 shrink-0" aria-hidden="true" />
            <p className="text-xs text-red-300 font-medium">Sin tipo de cambio</p>
          </div>
        )}

        {/* Usuario + logout */}
        <div className="flex items-center gap-2">
          {/* Avatar inicial */}
          <div className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center shrink-0">
            <span className="text-white text-xs font-bold">
              {usuario.nombre.charAt(0).toUpperCase()}
            </span>
          </div>

          {/* Nombre y rol */}
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-white truncate leading-tight">
              {usuario.nombre} {usuario.apellido}
            </p>
            <p className="text-[11px] text-white/50 capitalize leading-tight">{usuario.rol}</p>
          </div>

          {/* Logout */}
          <button
            onClick={handleLogout}
            disabled={pending}
            className="p-2 rounded-lg text-white/60 hover:bg-white/10 hover:text-white
                       transition-colors disabled:opacity-50 shrink-0"
            aria-label="Cerrar sesión"
            title="Cerrar sesión"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  )
}

// ─── Sidebar principal ────────────────────────────────────────────────────────

export function Sidebar({ usuario, tcDisponible, isOpen, onClose }: SidebarProps) {
  return (
    <>
      {/* Desktop: siempre visible */}
      <aside className="hidden md:flex w-60 shrink-0 flex-col min-h-screen">
        <SidebarContent usuario={usuario} tcDisponible={tcDisponible} />
      </aside>

      {/* Mobile: panel deslizable sobre overlay */}
      {isOpen && (
        <div className="md:hidden fixed inset-0 z-40 flex" role="dialog" aria-modal="true" aria-label="Menú de navegación">
          {/* Overlay */}
          <div
            className="absolute inset-0 bg-black/50"
            onClick={onClose}
            aria-hidden="true"
          />
          {/* Panel */}
          <aside className="relative w-60 flex flex-col animate-in slide-in-from-left duration-200">
            <SidebarContent usuario={usuario} tcDisponible={tcDisponible} onClose={onClose} />
          </aside>
        </div>
      )}
    </>
  )
}
