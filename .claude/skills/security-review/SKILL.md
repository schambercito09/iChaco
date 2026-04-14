---
name: security-review
description: Usar al agregar autenticación, manejar input del usuario, crear endpoints, trabajar con secrets, o implementar funcionalidades con datos sensibles. Incluye patrones específicos de RLS para este proyecto.
---

# Skill: `security-review`
> **Activar con:** `[Skills activas: security-review]`
> **Propósito:** Seguridad, RLS, autenticación y checklist pre-deploy

---

## Cuándo activar esta skill

- Implementando autenticación o autorización
- Creando nuevas Server Actions
- Manejando input del usuario o subida de archivos
- Configurando RLS en nuevas tablas
- Trabajando con variables de entorno o secrets
- Antes de cada deploy a producción

---

## 1. Gestión de Secrets

```typescript
// ❌ NUNCA hardcodear
const url = "https://xyz.supabase.co"
const key = "eyJhbGciOiJIUzI1NiIsInR..."

// ✅ SIEMPRE desde env vars
const url = process.env.NEXT_PUBLIC_SUPABASE_URL
const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

// Verificar al iniciar (en lib/supabase/client.ts)
if (!url || !key) {
  throw new Error('Variables de entorno de Supabase no configuradas')
}
```

**Checklist:**
- [ ] Sin keys ni URLs hardcodeadas
- [ ] `.env.local` en `.gitignore`
- [ ] Variables de producción en Vercel Dashboard (no en código)
- [ ] Sin secrets en historial de git (`git log --all -S "supabase"`)

---

## 2. RLS — patrones del proyecto

### Funciones helper ya creadas en el schema

```sql
-- SIEMPRE usar estas funciones en las políticas, nunca auth.uid() directo en USING
get_user_rol()           -- 'superadmin'|'admin'|'vendedor'|'tecnico'|'deposito'
get_user_deposito_id()   -- UUID del depósito del usuario actual
is_admin()               -- true si rol IN ('admin','superadmin')

-- Optimización crítica: envolver en SELECT para evaluar una sola vez
USING ((SELECT auth.uid()) = user_id)   -- ✅ rápido
USING (auth.uid() = user_id)            -- ❌ lento (evalúa por fila)
```

### Verificar RLS antes de cada deploy

```sql
-- Tablas sin RLS (deben ser 0):
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
AND tablename NOT IN (
  SELECT tablename FROM pg_policies WHERE schemaname = 'public'
);

-- Políticas activas por tabla:
SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename;
```

---

## 3. Validación de input en Server Actions

```typescript
// ✅ SIEMPRE validar con Zod antes de tocar la BD
import { z } from 'zod'
import { actionError, actionSuccess } from '@/lib/utils/actions'

const schema = z.object({
  nombre: z.string().min(2).max(100),
  email: z.string().email().optional().or(z.literal('')),
  monto: z.number({ coerce: true }).positive(),
  rol: z.enum(['admin', 'vendedor', 'tecnico', 'deposito']),
})

export async function miAction(formData: FormData) {
  try {
    const data = schema.parse(Object.fromEntries(formData))
    // ... resto de la action
  } catch (e) {
    if (e instanceof z.ZodError) return actionError(e.errors[0].message)
    throw e
  }
}
```

**Checklist:**
- [ ] Zod en TODAS las Server Actions
- [ ] Sin uso directo de `formData.get()` en queries sin validar
- [ ] Mensajes de error no filtran información interna

---

## 4. Autorización en Server Actions

```typescript
// ✅ Verificar rol ANTES de cualquier operación sensible
export async function actualizarPrecio(formData: FormData) {
  const supabase = createServerClient()

  // 1. Obtener usuario actual
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return actionError('No autenticado')

  // 2. Verificar rol desde la tabla usuarios
  const { data: usuario } = await supabase
    .from('usuarios')
    .select('rol')
    .eq('id', user.id)
    .single()

  if (!usuario || !['admin', 'superadmin'].includes(usuario.rol)) {
    return actionError('Sin permisos para modificar precios')
  }

  // 3. Recién ahora operar
  // ...
}
```

---

## 5. Subida de archivos — Supabase Storage

```typescript
// Validar antes de subir
const MAX_SIZE = 5 * 1024 * 1024 // 5MB
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp']

function validarImagen(file: File): string | null {
  if (file.size > MAX_SIZE) return 'El archivo supera los 5MB'
  if (!ALLOWED_TYPES.includes(file.type)) return 'Tipo de archivo no permitido'
  return null
}

// En la Server Action:
const error = validarImagen(file)
if (error) return actionError(error)

const { data, error: uploadError } = await supabase.storage
  .from('productos-imagenes')
  .upload(`${productoId}/${Date.now()}-${file.name}`, file)
```

---

## 6. Manejo de errores — no exponer internos

```typescript
// ❌ Expone detalles internos al cliente
catch (error) {
  return actionError(error.message) // puede revelar queries SQL, paths, etc.
}

// ✅ Log interno + mensaje genérico al cliente
catch (error) {
  console.error('[actualizarPrecio]', error) // solo en servidor
  return actionError('Error al actualizar el precio. Intentá de nuevo.')
}
```

---

## 7. Variables de entorno — verificación al arrancar

```typescript
// lib/supabase/client.ts — verificar al importar
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseKey) {
  throw new Error(
    'Faltan variables de entorno:\n' +
    'NEXT_PUBLIC_SUPABASE_URL y NEXT_PUBLIC_SUPABASE_ANON_KEY\n' +
    'Verificar .env.local'
  )
}
```

---

## 8. Checklist pre-deploy — seguridad completa

```
Secrets y configuración:
- [ ] Sin secrets hardcodeados en ningún archivo TypeScript/TSX
- [ ] .env.local en .gitignore
- [ ] Variables de producción configuradas en Vercel
- [ ] No hay console.log con datos sensibles (emails, montos, IDs de clientes)

Base de datos:
- [ ] RLS habilitado en TODAS las tablas del schema
- [ ] Las funciones helper (is_admin, get_user_rol) existen y funcionan
- [ ] Trigger on_auth_user_created activo
- [ ] No hay tablas con policy permisiva (USING true) salvo las intencionadas

Código:
- [ ] Todas las Server Actions tienen validación Zod
- [ ] Autorización verificada en actions sensibles (precios, usuarios, config)
- [ ] Errores internos no se exponen al cliente
- [ ] Subidas de archivos validadas (tamaño, tipo)
- [ ] proxy.ts existe en la raíz y protege /dashboard

Supabase:
- [ ] URL de Vercel agregada en Authentication → URL Configuration
- [ ] Storage buckets con políticas correctas
- [ ] service_role key nunca usada en código cliente
```