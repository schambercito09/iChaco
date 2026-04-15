import { Suspense } from 'react'
import { AlertTriangle } from 'lucide-react'
import { PageHeader } from '@/components/ui'
import { getTipoCambioHoy } from '@/lib/supabase/queries/tipo-cambio'

export const metadata = { title: 'Dashboard — iChaco ERP' }

// ─── Skeleton de métricas ─────────────────────────────────────────────────────

function MetricCardSkeleton() {
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-5 animate-pulse">
      <div className="h-3 bg-gray-200 rounded w-2/3 mb-3" />
      <div className="h-7 bg-gray-200 rounded w-1/2" />
    </div>
  )
}

// ─── Métricas del día — Server Component async ────────────────────────────────
// Se completarán en los pasos siguientes con datos reales de cada módulo.

async function DashboardMetrics() {
  const placeholders = [
    { label: 'Ventas hoy', valor: '—' },
    { label: 'Separas activas', valor: '—' },
    { label: 'Items con stock bajo', valor: '—' },
    { label: 'TC del día (USD)', valor: '—' },
  ]

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      {placeholders.map(({ label, valor }) => (
        <div key={label} className="bg-white rounded-xl border border-gray-200 p-5">
          <p className="text-sm text-gray-500">{label}</p>
          <p className="mt-2 text-2xl font-bold text-navy">{valor}</p>
        </div>
      ))}
    </div>
  )
}

// ─── Página ───────────────────────────────────────────────────────────────────

export default async function DashboardPage() {
  const tc = await getTipoCambioHoy()

  return (
    <div className="space-y-6">
      {/* Banner: sin tipo de cambio del día */}
      {!tc && (
        <div
          className="flex items-start gap-3 bg-navy text-white rounded-xl px-5 py-4"
          role="alert"
        >
          <AlertTriangle
            className="w-5 h-5 shrink-0 text-yellow-300 mt-0.5"
            aria-hidden="true"
          />
          <div>
            <p className="text-sm font-semibold">Sin tipo de cambio hoy</p>
            <p className="text-xs text-white/70 mt-0.5">
              Las ventas están bloqueadas hasta que un administrador cargue el TC del día.
            </p>
          </div>
        </div>
      )}

      <PageHeader title="Dashboard" />

      {/* Métricas con Suspense + skeleton */}
      <Suspense
        fallback={
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {Array.from({ length: 4 }).map((_, i) => (
              <MetricCardSkeleton key={i} />
            ))}
          </div>
        }
      >
        <DashboardMetrics />
      </Suspense>
    </div>
  )
}
