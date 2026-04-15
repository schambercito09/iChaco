'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { TipoCambio } from '@/lib/types'

interface UseTipoCambioResult {
  tc: TipoCambio | null
  bloqueado: boolean
  loading: boolean
}

export function useTipoCambio(): UseTipoCambioResult {
  const [tc, setTc] = useState<TipoCambio | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const supabase = createClient()
    const getFechaAR = () => {
      const now = new Date()
      now.setHours(now.getHours() - 3)
      return now.toISOString().split('T')[0]
    }
    const hoy = getFechaAR()

    const fetchTC = async () => {
      try {
        const { data } = await supabase
          .from('tipos_cambio_dolar')
          .select('*')
          .eq('fecha', hoy)
          .single()
        setTc(data ?? null)
      } catch {
        // error de red — loading se libera en finally
      } finally {
        setLoading(false)
      }
    }
    void fetchTC()
  }, [])

  return {
    tc,
    bloqueado: !loading && tc === null,
    loading,
  }
}
