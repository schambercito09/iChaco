import { Suspense } from 'react'
import { LoginForm } from './_components/LoginForm'

export const metadata = { title: 'Iniciar sesión — iChaco ERP' }

export default function LoginPage() {
  return (
    <main className="min-h-screen flex items-center justify-center bg-blue-light px-4">
      <div className="w-full max-w-sm">
        <div className="mb-8 text-center">
          <h1 className="text-2xl font-bold text-navy">iChaco ERP</h1>
          <p className="mt-1 text-sm text-gray-500">Sistema de gestión integral</p>
        </div>
        <Suspense fallback={null}>
          <LoginForm />
        </Suspense>
      </div>
    </main>
  )
}
