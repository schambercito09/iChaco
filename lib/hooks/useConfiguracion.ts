'use client'

import { useEffect, useRef, useState } from 'react'
import { createClient } from '@/lib/supabase/client'

type ConfigMap = Record<string, string>

interface UseConfiguracionResult {
  getParametro: (clave: string) => string | null
  loading: boolean
}

export function useConfiguracion(): UseConfiguracionResult {
  const [config, setConfig] = useState<ConfigMap>({})
  const [loading, setLoading] = useState(true)
  const fetchedRef = useRef(false)

  useEffect(() => {
    if (fetchedRef.current) return
    fetchedRef.current = true

    const supabase = createClient()

    const fetchConfig = async () => {
      try {
        const { data } = await supabase
          .from('configuracion_sistema')
          .select('clave, valor')
        if (data) {
          const map: ConfigMap = {}
          for (const row of data) map[row.clave] = row.valor
          setConfig(map)
        }
      } catch {
        // error de red — loading se libera en finally
      } finally {
        setLoading(false)
      }
    }
    void fetchConfig()
  }, [])

  return {
    getParametro: (clave: string) => config[clave] ?? null,
    loading,
  }
}
