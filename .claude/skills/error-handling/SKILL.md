---
name: error-handling
description: Manejo de errores y monitoreo para el ERP/CRM. Usar al crear Server Actions, configurar error boundaries, y al preparar el deploy. Un error silencioso en ventas o caja puede costar dinero real.
---

# Skill: `error-handling`
> **Activar con:** `[Skills activas: error-handling]`
> **Propósito:** Errores visibles, logging útil y alertas cuando algo crítico falla en producción

---

## Filosofía del proyecto

```
Error del usuario  → mensaje claro en la UI, toast rojo, no registrar en Sentry
Error del sistema  → toast rojo genérico + registrar en Sentry con contexto completo
Error crítico      → toast + notificación al admin + bloquear la operación si es necesario

Nunca mostrar al usuario: stack traces, queries SQL, IDs internos, mensajes técnicos
```

---

## 1. Clasificación de errores — qué hacer con cada tipo

```typescript
// lib/utils/errors.ts

export class ErrorNegocio extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'ErrorNegocio'
  }
}

export class ErrorSinTC extends Error {
  constructor() {
    super('SIN_TC_DEL_DIA')
    this.name = 'ErrorSinTC'
  }
}

export class ErrorStockInsuficiente extends Error {
  constructor(public variante: string, public disponible: number) {
    super(`Stock insuficiente para ${variante}: disponible ${disponible}`)
    this.name = 'ErrorStockInsuficiente'
  }
}

export class ErrorPermiso extends Error {
  constructor(public accion: string) {
    super(`Sin permiso para: ${accion}`)
    this.name = 'ErrorPermiso'
  }
}

// Helper central para manejar errores en Server Actions:
export function manejarError(error: unknown, contexto: string): { error: string } {
  // Errores de negocio → mensaje directo al usuario, no loguear en Sentry
  if (error instanceof ErrorNegocio) {
    return { error: error.message }
  }
  if (error instanceof ErrorSinTC) {
    return { error: 'Cargá el tipo de cambio del día antes de continuar' }
  }
  if (error instanceof ErrorStockInsuficiente) {
    return { error: error.message }
  }
  if (error instanceof ErrorPermiso) {
    return { error: 'No tenés permisos para realizar esta acción' }
  }

  // Errores de validación Zod → primer mensaje de error
  if (error instanceof Error && error.name === 'ZodError') {
    const zodError = error as any
    return { error: zodError.errors?.[0]?.message ?? 'Datos inválidos' }
  }

  // Errores del sistema → loguear + mensaje genérico
  console.error(`[${contexto}]`, error)
  logErrorSistema(error, contexto)  // ver sección 3

  return { error: 'Ocurrió un error inesperado. Intentá de nuevo o contactá al soporte.' }
}
```

---

## 2. Patrón de Server Action con manejo completo

```typescript
// lib/actions/ventas.ts
import { manejarError, ErrorSinTC, ErrorStockInsuficiente, ErrorPermiso } from '@/lib/utils/errors'
import { requireTCDelDia } from '@/lib/supabase/queries/tipo-cambio'

export async function confirmarVentaAction(datos: VentaDatos): Promise<ActionResult<{ id: string; numero: string }>> {
  try {
    // 1. Verificar TC
    const tc = await requireTCDelDia()

    // 2. Verificar permisos
    const usuario = await getUsuarioActual()
    if (!usuario) throw new ErrorPermiso('confirmar ventas')

    // 3. Verificar stock antes de la RPC
    for (const item of datos.items) {
      if (item.unidad_serializada_id) {
        const unidad = await getUnidadById(item.unidad_serializada_id)
        if (unidad?.estado !== 'disponible') {
          throw new ErrorStockInsuficiente(item.descripcion, 0)
        }
      }
    }

    // 4. Ejecutar RPC (transacción atómica)
    const { data, error } = await supabase.rpc('confirmar_venta', {
      p_datos: { ...datos, tipo_cambio_id: tc.id, usuario_vendedor_id: usuario.id }
    })

    if (error) throw error
    if (!data?.success) throw new ErrorNegocio(data?.error ?? 'Error al confirmar la venta')

    return actionSuccess({ id: data.id, numero: data.numero })

  } catch (error) {
    return manejarError(error, 'confirmarVentaAction')
  }
}
```

---

## 3. Logging estructurado — lib/utils/logger.ts

```typescript
// lib/utils/logger.ts
type LogLevel = 'info' | 'warn' | 'error'

interface LogEntry {
  level: LogLevel
  mensaje: string
  contexto?: string
  datos?: Record<string, unknown>
  usuarioId?: string
  timestamp: string
}

function log(level: LogLevel, mensaje: string, extra?: Omit<LogEntry, 'level' | 'mensaje' | 'timestamp'>) {
  const entry: LogEntry = {
    level,
    mensaje,
    timestamp: new Date().toISOString(),
    ...extra,
  }

  if (process.env.NODE_ENV === 'development') {
    const icon = { info: '📘', warn: '⚠️', error: '🔴' }[level]
    console.log(`${icon} [${entry.contexto ?? 'app'}]`, mensaje, extra?.datos ?? '')
  } else {
    // En producción: loguear como JSON para herramientas de monitoring
    console.log(JSON.stringify(entry))
  }
}

export const logger = {
  info:  (msg: string, extra?: LogEntry['datos']) => log('info',  msg, { datos: extra }),
  warn:  (msg: string, extra?: LogEntry['datos']) => log('warn',  msg, { datos: extra }),
  error: (msg: string, extra?: LogEntry['datos']) => log('error', msg, { datos: extra }),
  accion: (msg: string, usuarioId: string, datos?: LogEntry['datos']) =>
    log('info', msg, { contexto: 'accion', usuarioId, datos }),
}

// Uso en Server Actions:
logger.accion('Venta confirmada', usuario.id, { venta_id: data.id, total_usd: datos.total_usd })
logger.warn('Descuento supera el límite del rol', { usuario_id: usuario.id, descuento: datos.descuento })
logger.error('RPC confirmar_venta falló', { error: String(error), datos })

// Helper para registrar en Sentry (cuando se integre):
export function logErrorSistema(error: unknown, contexto: string) {
  logger.error(`Error en ${contexto}`, {
    error: error instanceof Error ? error.message : String(error),
    stack: error instanceof Error ? error.stack : undefined,
  })
  // Sentry.captureException(error, { extra: { contexto } })
}
```

---

## 4. Error Boundaries — por módulo

```tsx
// app/(dashboard)/ventas/error.tsx
'use client'
import { useEffect } from 'react'
import { logger } from '@/lib/utils/logger'

export default function ErrorVentas({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    logger.error('Error en módulo Ventas', {
      mensaje: error.message,
      digest: error.digest,
    })
  }, [error])

  return (
    <div className="flex flex-col items-center justify-center min-h-96 gap-4">
      <div className="text-center">
        <h2 className="text-xl font-semibold text-gray-800 mb-2">
          Algo salió mal en Ventas
        </h2>
        <p className="text-gray-500 text-sm mb-4">
          El error fue registrado. Podés intentar de nuevo o contactar soporte.
        </p>
        {error.digest && (
          <p className="text-xs text-gray-400">Código: {error.digest}</p>
        )}
      </div>
      <button
        onClick={reset}
        className="px-4 py-2 bg-navy text-white rounded-lg hover:bg-navy-dark"
      >
        Intentar de nuevo
      </button>
    </div>
  )
}

// Crear error.tsx en CADA módulo crítico:
// app/(dashboard)/ventas/error.tsx
// app/(dashboard)/caja/error.tsx
// app/(dashboard)/separas/error.tsx
// app/(dashboard)/inventario/error.tsx
```

---

## 5. Validación de variables de entorno al arrancar

```typescript
// lib/env.ts — validar al iniciar la app, no cuando se usa
import { z } from 'zod'

const envSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url('NEXT_PUBLIC_SUPABASE_URL debe ser una URL válida'),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(10, 'NEXT_PUBLIC_SUPABASE_ANON_KEY es inválida'),
})

const parsed = envSchema.safeParse({
  NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
  NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
})

if (!parsed.success) {
  console.error('❌ Variables de entorno inválidas:')
  parsed.error.errors.forEach(e => console.error(`   ${e.path}: ${e.message}`))
  throw new Error('Variables de entorno mal configuradas — ver console para detalles')
}

export const env = parsed.data
```

---

## 6. Errores de Supabase — mensajes amigables

```typescript
// lib/utils/supabase-errors.ts
export function mensajeErrorSupabase(error: { code?: string; message?: string }): string {
  const mensajes: Record<string, string> = {
    '23505': 'Ya existe un registro con esos datos (duplicado)',
    '23503': 'No se puede realizar esta operación — hay datos relacionados',
    '42501': 'Sin permisos para esta operación',
    'PGRST116': 'No se encontró el registro',
    'PGRST301': 'Sesión expirada — volvé a iniciar sesión',
  }

  if (error.code && mensajes[error.code]) {
    return mensajes[error.code]
  }

  // Error de RLS (no exponer detalles)
  if (error.message?.includes('row-level security')) {
    return 'No tenés permisos para esta operación'
  }

  // Conexión
  if (error.message?.includes('Failed to fetch')) {
    return 'Error de conexión — verificá tu internet'
  }

  return 'Error inesperado — intentá de nuevo'
}

// Uso en Server Actions:
const { data, error } = await supabase.from('ventas').insert(...)
if (error) return actionError(mensajeErrorSupabase(error))
```

---

## 7. Notificación de errores críticos al admin

```typescript
// Cuando falla algo crítico (venta, sepa, caja), crear novedad urgente al admin
// lib/utils/errors.ts

export async function notificarErrorCritico(
  supabase: SupabaseClient,
  modulo: string,
  descripcion: string,
  depositoId: string
) {
  await supabase.from('novedades_turno').insert({
    deposito_id: depositoId,
    tipo: 'tarea_admin',
    prioridad: 'urgente',
    titulo: `⚠️ Error en ${modulo}`,
    descripcion,
    generada_por: 'sistema',
  })
}

// Uso: cuando la RPC confirmar_venta falla inesperadamente
await notificarErrorCritico(supabase, 'Ventas',
  `La venta de ${cliente.nombre} falló: ${errorMsg}`, depositoId)
```

---

## 8. Checklist de error handling por módulo

```
Server Actions:
- [ ] Cada action tiene try/catch con manejarError()
- [ ] Errores de negocio usan clases específicas (ErrorNegocio, ErrorSinTC)
- [ ] Nunca retornar error.message directamente al cliente
- [ ] logger.error() para errores del sistema

Error Boundaries:
- [ ] error.tsx en cada módulo crítico (ventas, caja, separas, inventario)
- [ ] Muestra código de digest para debugging
- [ ] Botón "Intentar de nuevo" que llama a reset()

Variables de entorno:
- [ ] lib/env.ts valida al arrancar (no lazy)
- [ ] Si falta una variable → error claro en el log

Operaciones críticas (venta, caja, sepa):
- [ ] Si falla la RPC → crear novedad urgente al admin
- [ ] El usuario recibe mensaje descriptivo (no genérico)
- [ ] El error queda registrado con contexto suficiente para debuggear
```
