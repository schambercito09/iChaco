import { Suspense } from 'react'
import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { LoginForm } from './_components/LoginForm'

export const metadata = { title: 'Iniciar sesión — iChaco ERP' }

export default async function LoginPage() {
  // Si ya hay sesión activa, redirigir al dashboard
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (user) redirect('/dashboard')

  return (
    <main className="min-h-screen flex items-center justify-center bg-blue-light px-4">
      <div className="w-full max-w-sm">
        {/* Card con header navy */}
        <div className="bg-white rounded-xl shadow-md border border-blue-border overflow-hidden">
          {/* Header azul marino */}
          <div className="bg-navy px-6 py-7 text-center">
            <div
              className="inline-flex items-center justify-center w-12 h-12 rounded-full
                          bg-white/10 border border-white/20 mb-4"
            >
              <span className="text-white font-bold text-xl leading-none">i</span>
            </div>
            <h1 className="text-lg font-bold text-white tracking-tight">iChaco ERP</h1>
            <p className="mt-1 text-xs text-white/60">Sistema de gestión integral</p>
          </div>

          {/* Cuerpo del formulario */}
          <div className="px-6 py-6">
            <Suspense fallback={null}>
              <LoginForm />
            </Suspense>
          </div>
        </div>
      </div>
    </main>
  )
}
