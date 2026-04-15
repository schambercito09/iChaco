'use client'

import { useTransition, useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { toast } from 'sonner'
import { Button } from '@/components/ui'
import { login } from '../actions'

export function LoginForm() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const redirectTo = searchParams.get('redirectTo') ?? '/dashboard'
  const [pending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setError(null)
    const formData = new FormData(e.currentTarget)

    startTransition(async () => {
      const result = await login(formData)
      if ('error' in result) {
        setError(result.error)
        toast.error(result.error)
      } else {
        router.replace(redirectTo)
        router.refresh()
      }
    })
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-1">
        <label htmlFor="email" className="block text-sm font-medium text-gray-700">
          Email
        </label>
        <input
          id="email"
          name="email"
          type="email"
          autoComplete="email"
          required
          disabled={pending}
          className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg
                     focus:outline-none focus:ring-2 focus:ring-navy focus:border-transparent
                     disabled:opacity-50 transition-colors"
          placeholder="vendedor@ichaco.com"
        />
      </div>

      <div className="space-y-1">
        <label htmlFor="password" className="block text-sm font-medium text-gray-700">
          Contraseña
        </label>
        <input
          id="password"
          name="password"
          type="password"
          autoComplete="current-password"
          required
          disabled={pending}
          className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg
                     focus:outline-none focus:ring-2 focus:ring-navy focus:border-transparent
                     disabled:opacity-50 transition-colors"
          placeholder="••••••••"
        />
      </div>

      {/* Error debajo del campo — mensaje claro, sin detalles técnicos */}
      {error && (
        <p role="alert" className="text-sm text-red-600">
          {error}
        </p>
      )}

      <Button type="submit" loading={pending} className="w-full mt-2">
        Ingresar al sistema
      </Button>
    </form>
  )
}
