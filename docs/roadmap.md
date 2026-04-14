# roadmap.md — ERP/CRM Pyme de Tecnología

> **v4.0 — Revisión exhaustiva completa. Listo para producción.**
> 17 skills integradas | 30 prompts completos | Fases 0-4 definidas
>
> Formato: [ ] pendiente | [x] completado | [~] en progreso | [!] bloqueado
>
> Cómo usar:
> 1. Pegar el Contexto Base al inicio de CADA sesión nueva de Claude Code
> 2. Copiar el prompt del paso activo y pegarlo en Claude Code
> 3. Completar cada paso antes de avanzar al siguiente
> 4. Antes de cada commit: ejecutar la skill `fix`
> 5. Registrar decisiones técnicas en la sección al final

---

## Contexto Base — Pegar al inicio de CADA sesión nueva de Claude Code

```
Estoy construyendo un ERP/CRM para una pyme de tecnología que vende celulares nuevos
y usados, accesorios y hardware. Tiene una tienda y un depósito separado.

Stack: Next.js 14 App Router + TypeScript + Tailwind CSS + Supabase + Vercel
Paleta: azul marino #1E3A5F (headers/sidebar) y blanco #FFFFFF (fondo predominante)
Roles: superadmin | admin | vendedor | tecnico | deposito (campo rol en tabla usuarios)
Moneda dual: ARS y USD. Tipo de cambio diario en tabla tipos_cambio_dolar (snapshot inmutable)
Productos serializados: tienen IMEI individual en tabla unidades_serializadas
Vendedor obligatorio en cada venta (usuario_vendedor_id nunca nullable)

Convenciones del proyecto:
- Server Components para fetches, Client Components para formularios con estado
- Server Actions para TODAS las mutaciones
- Patrón de retorno en Server Actions: { error: string } | { success: true, data?: T }
- Siempre revalidar con revalidatePath() después de mutaciones
- Validación con Zod en TODAS las Server Actions antes de tocar la BD
- Toasts con Sonner para feedback al usuario (éxito y error)
- Loading states: useTransition + botón deshabilitado durante acción
- Paginación cursor-based (no OFFSET) en todos los listados
  Patrón estándar: .gt('id', lastId).order('id').limit(20)
  Cursor = último id devuelto (string, pasado como searchParam ?cursor=UUID)
  Si cursor es null/undefined → primera página
  nextCursor = data.length === 20 ? data[19].id : null
- RLS real activo desde el inicio (nunca permisivo)
- Nunca hardcodear IDs de depósitos ni usuarios
- Proxy en proxy.ts (raíz), NUNCA middleware.ts
- Mobile-first: diseño funcional desde 375px
- Helper requireTCDelDia() en lib/supabase/queries/tipo-cambio.ts:
  Usar en TODAS las Server Actions que necesitan el TC antes de operar
  Si no existe TC del día → throw new Error('SIN_TC_DEL_DIA')
  El cliente captura ese error y redirige a /tipo-cambio con mensaje

Skills disponibles en .claude/skills/:
Core (usar en casi todos los pasos):
- proyecto-patterns:    patrones únicos del proyecto (ActionResult, requireTCDelDia, cursors, etc.)
- postgres-patterns:    SQL, RLS, índices, RPC, paginación Supabase
- frontend-design:      UI de producción con paleta azul marino del proyecto
- ui-components-reference: cómo usar Button, Modal, Drawer, Table, CurrencyDisplay, etc.
- security-review:      RLS, autenticación, secrets, checklist pre-deploy
- error-handling:       manejo de errores, logging, monitoring en producción
- fix:                  lint, formato y TypeScript antes de cada commit
Por módulo específico:
- accessibility:        ARIA, focus-trap, atajos de teclado para uso diario intensivo
- performance:          caché Next.js, Suspense, optimistic UI, listados rápidos
- typescript-advanced:  branded types USD/ARS, discriminated unions, tipos de queries
- print-styles:         tickets térmicos, etiquetas A4, @media print
- pdf:                  ticket de venta, presupuesto PDF, actas
- xlsx:                 reportes Excel, exportación CSV, comisiones
- diffs:                ver diferencias de código entre versiones
Fases posteriores:
- testing:              Vitest para Server Actions críticas (Paso 18.5)
- animations:           micro-interacciones polish final (Paso 19)
- whatsapp:             Meta Cloud API mensajes automáticos (Fase 4)
```

---

## Inventario de Componentes UI (actualizar al crear nuevos)

> Completar a medida que se crean componentes. Evita que el agente los duplique.

| Componente | Ruta | Descripción |
|---|---|---|
| — | — | — |

---

## FASE 0 — Fundación del Proyecto

### Paso 0 — CLAUDE.md del proyecto
**Acción manual:** Crear el archivo CLAUDE.md en la raíz antes de escribir cualquier código.
**Skills:** ninguna (configuración)

**Prompt para Claude Code:**
```
Crea el archivo CLAUDE.md en la raíz del proyecto. Debe contener el contexto
completo y permanente del sistema ERP/CRM para pyme de tecnología:

1. Descripción del negocio:
   - Pyme de venta de tecnología: celulares nuevos y usados, accesorios, hardware
   - Tienda principal (vende, tiene caja) + Depósito separado (recibe mercadería)
   - Múltiples vendedores con métricas individuales
   - Productos serializados (con IMEI) y genéricos (por cantidad)
   - Parte de pago (trade-in): cliente entrega su equipo al comprar
   - Servicio técnico propio

2. Stack técnico:
   - Next.js 14 App Router + TypeScript + Tailwind + Supabase + Vercel
   - Paleta: azul marino #1E3A5F (headers/sidebar), blanco #FFFFFF (fondo predominante)
   - Azul claro #EFF6FF para fondos de secciones
   - Azul acento #3B82F6 para botones y highlights

3. Convenciones obligatorias:
   - Server Components para fetches
   - Client Components para formularios con estado
   - Server Actions para TODAS las mutaciones
   - Patrón de retorno: { error: string } | { success: true, data?: T }
   - Siempre revalidar con revalidatePath() después de mutaciones
   - Validación con Zod en TODAS las Server Actions
   - Toasts con Sonner para feedback al usuario
   - Loading states: useTransition + botón deshabilitado
   - Paginación cursor-based (no OFFSET)
   - RLS real activo, nunca desactivarlo
   - Usar proxy.ts en la raíz (NUNCA middleware.ts)
   - Números de documentos: prefijo + 5 dígitos (V-00042, SEP-00023, ST-00015)
   - Mobile-first: funcional desde 375px

4. Reglas de negocio críticas:
   - Tipo de cambio: si no hay TC del día, bloquear ventas con banner de alerta
   - Vendedor: usuario_vendedor_id en ventas OBLIGATORIO, nunca nullable
   - Serializados: cada IMEI tiene estado propio
     (disponible | vendido | reservado | en_reparacion | en_garantia_proveedor | baja)
   - Separas: precio USD pactado INMUTABLE; ARS se recalcula al TC del día de concreción
   - Usados: defecto 'bloqueante' (iCloud activo) impide la venta
   - Descuentos: superar límite del rol genera solicitud de aprobación

5. Skills disponibles en .claude/skills/:
   Core: proyecto-patterns, postgres-patterns, frontend-design, ui-components-reference,
         security-review, error-handling, fix
   Módulo: accessibility, performance, typescript-advanced, print-styles, pdf, xlsx, diffs
   Fases: testing (P18.5), animations (P19), whatsapp (Fase 4)

6. Archivos INMUTABLES — nunca modificar al crear nuevos módulos:
   - proxy.ts
   - lib/supabase/proxy.ts
   - lib/actions/layout.ts
   - components/layout/DashboardShell.tsx
   - components/layout/Sidebar.tsx
   - components/layout/Header.tsx
   - app/(auth)/login/page.tsx
   - app/(auth)/login/_components/LoginForm.tsx
   - app/(auth)/login/actions.ts
   - app/(auth)/loading.tsx
   - app/(dashboard)/layout.tsx
   - app/(dashboard)/dashboard/page.tsx

   SEÑAL DE ALERTA: menos de 20 líneas o solo return null → fue revertido → restaurar primero.
```

**Criterio de avance:** CLAUDE.md creado con todo el contenido correcto.

---

### Paso 1 — Crear proyecto Next.js 14
**Acción manual:** Ejecutar en terminal:
```
npx create-next-app@latest nombre-del-proyecto --typescript --tailwind --app --src-dir=false --import-alias="@/*"
cd nombre-del-proyecto
```
**Skills:** [frontend-design]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design]

Configura el proyecto Next.js 14 recién creado para el ERP/CRM.

1. Instalar dependencias:
   npm install @supabase/supabase-js @supabase/ssr lucide-react zod sonner
   npm install -D @types/node

2. Crear estructura de carpetas:
   app/(auth)/login/
   app/(dashboard)/layout.tsx (vacío)
   app/(dashboard)/dashboard/page.tsx (vacío)
   lib/supabase/client.ts
   lib/supabase/server.ts
   lib/supabase/proxy.ts
   lib/types/database.types.ts (vacío)
   lib/actions/
   lib/validations/       ← schemas Zod por módulo
   components/ui/         ← componentes base reutilizables
   components/layout/
   components/modules/

3. Configurar tailwind.config.ts:
   colors: {
     navy:  { DEFAULT: '#1E3A5F', dark: '#142842', light: '#2D5F8A' },
     blue:  { light: '#EFF6FF', accent: '#3B82F6', border: '#BFDBFE' },
   }

4. Crear proxy.ts en la RAÍZ (no middleware.ts):
   export async function proxy() {}

5. Configurar Sonner en app/layout.tsx:
   import { Toaster } from 'sonner'
   → agregar <Toaster position="top-right" /> en el body

6. Crear archivos globales:
   - app/error.tsx: mensaje amigable + botón Reintentar
   - app/loading.tsx: skeleton con animate-pulse azul marino
   - app/not-found.tsx: 404 con diseño consistente + link al dashboard
   - app/(dashboard)/loading.tsx y app/(dashboard)/error.tsx

7. Crear lib/utils/actions.ts con el helper de Server Actions:
   export type ActionResult<T = void> =
     | { success: true; data?: T }
     | { error: string }

   export function actionError(msg: string): { error: string } {
     return { error: msg }
   }
   export function actionSuccess<T>(data?: T): { success: true; data?: T } {
     return { success: true, data }
   }

8. Crear lib/utils/errors.ts con clases de error del negocio:
   export class ErrorNegocio extends Error { constructor(msg: string) { super(msg); this.name = 'ErrorNegocio' } }
   export class ErrorSinTC extends Error { constructor() { super('SIN_TC_DEL_DIA'); this.name = 'ErrorSinTC' } }
   export class ErrorStockInsuficiente extends Error { constructor(public variante: string, public disponible: number) { super(`Stock insuficiente para ${variante}`); this.name = 'ErrorStockInsuficiente' } }
   export class ErrorPermiso extends Error { constructor(public accion: string) { super(`Sin permiso para: ${accion}`); this.name = 'ErrorPermiso' } }
   export function manejarError(error: unknown, contexto: string): { error: string } {
     if (error instanceof ErrorNegocio) return { error: error.message }
     if (error instanceof ErrorSinTC) return { error: 'Cargá el tipo de cambio del día antes de continuar' }
     if (error instanceof ErrorStockInsuficiente) return { error: error.message }
     if (error instanceof ErrorPermiso) return { error: 'No tenés permisos para esta acción' }
     console.error(`[${contexto}]`, error)
     return { error: 'Error inesperado. Intentá de nuevo.' }
   }

9. Crear lib/utils/logger.ts:
   export const logger = {
     info:  (msg: string, data?: Record<string, unknown>) => console.log('📘', msg, data ?? ''),
     warn:  (msg: string, data?: Record<string, unknown>) => console.warn('⚠️', msg, data ?? ''),
     error: (msg: string, data?: Record<string, unknown>) => console.error('🔴', msg, data ?? ''),
     accion:(msg: string, userId: string, data?: Record<string, unknown>) =>
       console.log('📋', msg, { userId, ...data }),
   }

10. Crear lib/utils/money.ts con branded types USD/ARS:
    declare const __brand: unique symbol
    type Brand<T, B> = T & { [__brand]: B }
    export type USD = Brand<number, 'USD'>
    export type ARS = Brand<number, 'ARS'>
    export type ExchangeRate = Brand<number, 'ExchangeRate'>
    export const usd = (n: number): USD => n as USD
    export const ars = (n: number): ARS => n as ARS
    export const exchangeRate = (n: number): ExchangeRate => n as ExchangeRate
    export const calcularARS = (montoUsd: USD, tc: ExchangeRate): ARS => (montoUsd * tc) as ARS
    export const calcularMargen = (precioUsd: USD, costoUsd: USD): number =>
      costoUsd === 0 ? 0 : ((precioUsd - costoUsd) / costoUsd) * 100

11. Crear lib/env.ts con validación de variables de entorno al arrancar:
    import { z } from 'zod'
    const envSchema = z.object({
      NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
      NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(10),
    })
    const parsed = envSchema.safeParse(process.env)
    if (!parsed.success) throw new Error('Variables de entorno inválidas — ver console')
    export const env = parsed.data

12. npm run dev sin errores + npx tsc --noEmit sin errores
```

**Criterio de avance:** `npx tsc --noEmit` sin errores + `npm run dev` levanta + Sonner configurado + lib/utils creado.

---

### Paso 1.5 — Componentes UI compartidos
**Skills:** [frontend-design] | [accessibility]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, accessibility]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Crear los componentes UI base reutilizables que van a usar TODOS los módulos.
Estos componentes deben ser la base consistente del sistema.
Paleta: azul marino #1E3A5F para elementos de marca, blanco #FFFFFF predominante.

Crear en components/ui/:

1. Button.tsx
   Variantes: primary (azul marino), secondary (borde azul), danger (rojo), ghost
   Tamaños: sm, md, lg
   Props: loading (spinner), disabled, icon (lucide)
   En loading: deshabilitar + mostrar spinner azul

2. Input.tsx
   Con label flotante o encima, placeholder, error message, helper text
   Estado error: borde rojo + mensaje debajo
   Estado disabled: fondo gris claro

3. Badge.tsx
   Colores semánticos: success (verde), warning (amarillo), danger (rojo),
   info (azul), neutral (gris)
   Variantes: solid, outline, subtle

4. Modal.tsx
   Overlay oscuro, card blanco centrado, header azul marino, botón cerrar
   Trap focus, cerrar con Escape

5. Drawer.tsx (panel lateral)
   Slide desde la derecha, overlay, header con título y botón cerrar
   Usar para fichas de productos, clientes, etc.

6. Table.tsx
   Header azul marino claro (#EFF6FF), filas alternas, hover sutil
   Empty state integrado, loading skeleton de filas

7. Card.tsx
   Fondo blanco, borde sutil, sombra suave, padding configurable

8. SearchInput.tsx
   Input con ícono lupa, debounce de 300ms, clear button
   Para todos los buscadores del sistema

9. CurrencyDisplay.tsx
   Muestra monto en USD y ARS juntos: "USD 800 / ARS 972.000"
   Recibe: amountUsd, amountArs, exchangeRate

10. StatusBadge.tsx
    Mapeo de estados del negocio a colores:
    - disponible/confirmada/activa → verde
    - pendiente/en_proceso → amarillo
    - reservado → azul
    - cancelada/rechazada/baja → rojo
    - en_reparacion → naranja

11. EmptyState.tsx
    Ícono, título, descripción, botón CTA opcional
    Para todos los listados vacíos

12. PageHeader.tsx
    Título de la página, breadcrumb opcional, acciones a la derecha

Crear components/ui/index.ts que re-exporte todos los componentes:
  export { Button } from './Button'
  export { Input } from './Input'
  export { Badge } from './Badge'
  export { Modal } from './Modal'
  export { Drawer } from './Drawer'
  export { Table } from './Table'
  export { Card } from './Card'
  export { SearchInput } from './SearchInput'
  export { CurrencyDisplay } from './CurrencyDisplay'
  export { StatusBadge } from './StatusBadge'
  export { EmptyState } from './EmptyState'
  export { PageHeader } from './PageHeader'
  // Importar siempre desde '@/components/ui' (no desde rutas individuales)

Agregar la convención al CLAUDE.md sección 3:
  "Importar componentes UI siempre desde '@/components/ui' (barrel export)"

Documentar cada componente creado en el "Inventario de Componentes UI" del roadmap.md.
Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** todos los componentes creados + TypeScript limpio + documentados en el inventario.

---

### Paso 2a — Schema core de Supabase
**Acción manual:** Abrir SQL Editor de Supabase y ejecutar el SQL generado.
**Skills:** [postgres-patterns] | [security-review]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, postgres-patterns, security-review]

Genera el SQL para la PRIMERA MITAD del schema. Guardar en
migrations/001a_schema_core.sql.

TABLAS CORE (en este orden exacto para respetar FKs):

-- 1. Configuración base
CREATE TABLE tipos_cambio_dolar (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha DATE NOT NULL UNIQUE,
  valor_ars NUMERIC(12,4) NOT NULL,
  tipo TEXT NOT NULL CHECK (tipo IN ('oficial','blue','personalizado')),
  fuente TEXT NOT NULL CHECK (fuente IN ('manual','api_bcra','api_bluelytics')),
  usuario_id UUID REFERENCES auth.users,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE configuracion_sistema (
  clave TEXT PRIMARY KEY,
  valor TEXT NOT NULL,
  tipo_valor TEXT NOT NULL CHECK (tipo_valor IN ('integer','decimal','boolean','text','json')),
  descripcion TEXT,
  modulo TEXT,
  updated_at TIMESTAMPTZ DEFAULT now(),
  updated_by_usuario_id UUID REFERENCES auth.users
);

CREATE TABLE depositos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  tipo TEXT NOT NULL CHECK (tipo IN ('tienda','deposito','servicio_tecnico')),
  direccion TEXT,
  activo BOOLEAN DEFAULT true
);

CREATE TABLE usuarios (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  apellido TEXT NOT NULL,
  email TEXT NOT NULL,
  rol TEXT NOT NULL CHECK (rol IN ('superadmin','admin','vendedor','tecnico','deposito')),
  deposito_id UUID REFERENCES depositos,
  comision_porcentaje NUMERIC(5,2),
  meta_mensual_usd NUMERIC(12,2),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Catálogo
CREATE TABLE categorias (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  categoria_padre_id UUID REFERENCES categorias,
  activo BOOLEAN DEFAULT true
);

CREATE TABLE marcas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  pais_origen TEXT,
  logo_url TEXT
);

CREATE TABLE productos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku TEXT UNIQUE NOT NULL,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  categoria_id UUID REFERENCES categorias,
  marca_id UUID REFERENCES marcas,
  tipo TEXT NOT NULL CHECK (tipo IN ('serializado','generico','servicio')),
  requiere_imei BOOLEAN DEFAULT false,
  requiere_numero_serie BOOLEAN DEFAULT false,
  garantia_meses INT DEFAULT 0,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE variantes_producto (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producto_id UUID NOT NULL REFERENCES productos ON DELETE CASCADE,
  color TEXT,
  capacidad_gb INT,
  ram_gb INT,
  version TEXT,
  modelo TEXT,
  sku_variante TEXT UNIQUE NOT NULL,
  activo BOOLEAN DEFAULT true
);

CREATE TABLE imagenes_producto (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producto_id UUID NOT NULL REFERENCES productos ON DELETE CASCADE,
  variante_id UUID REFERENCES variantes_producto,
  url TEXT NOT NULL,
  orden INT DEFAULT 0,
  es_principal BOOLEAN DEFAULT false
);

-- 3. Precios
CREATE TABLE listas_precio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  tipo TEXT NOT NULL CHECK (tipo IN ('minorista','mayorista','distribuidor','empleado')),
  moneda_base TEXT NOT NULL DEFAULT 'USD' CHECK (moneda_base IN ('USD','ARS')),
  activa BOOLEAN DEFAULT true
);

CREATE TABLE precios_variante (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  variante_id UUID NOT NULL REFERENCES variantes_producto ON DELETE CASCADE,
  lista_precio_id UUID NOT NULL REFERENCES listas_precio ON DELETE CASCADE,
  precio_usd NUMERIC(12,2) NOT NULL,
  precio_ars_override NUMERIC(12,2),
  usar_precio_ars_fijo BOOLEAN DEFAULT false,
  margen_porcentaje NUMERIC(5,2) DEFAULT 0,
  vigente_desde DATE DEFAULT CURRENT_DATE,
  vigente_hasta DATE,
  UNIQUE (variante_id, lista_precio_id)
);

CREATE TABLE historial_precios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  variante_id UUID NOT NULL REFERENCES variantes_producto,
  lista_precio_id UUID NOT NULL REFERENCES listas_precio,
  precio_usd_anterior NUMERIC(12,2),
  precio_usd_nuevo NUMERIC(12,2) NOT NULL,
  motivo TEXT,
  usuario_id UUID REFERENCES auth.users,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE reglas_descuento (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  tipo TEXT NOT NULL CHECK (tipo IN ('porcentaje','monto_fijo')),
  valor_descuento NUMERIC(10,2) NOT NULL,
  descuento_maximo_porcentaje NUMERIC(5,2) NOT NULL,
  aplica_a TEXT NOT NULL CHECK (aplica_a IN ('todo','categoria','marca','producto')),
  referencia_id UUID,
  activa BOOLEAN DEFAULT true,
  vigente_desde DATE DEFAULT CURRENT_DATE,
  vigente_hasta DATE
);

-- 4. Inventario
CREATE TABLE stock (
  variante_id UUID NOT NULL REFERENCES variantes_producto ON DELETE CASCADE,
  deposito_id UUID NOT NULL REFERENCES depositos ON DELETE CASCADE,
  cantidad_disponible INT NOT NULL DEFAULT 0,
  cantidad_reservada INT NOT NULL DEFAULT 0,
  cantidad_en_transito INT NOT NULL DEFAULT 0,
  stock_minimo INT NOT NULL DEFAULT 0,
  stock_maximo INT,
  PRIMARY KEY (variante_id, deposito_id)
);

CREATE TABLE unidades_serializadas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  variante_id UUID NOT NULL REFERENCES variantes_producto,
  deposito_id UUID NOT NULL REFERENCES depositos,
  imei TEXT UNIQUE,
  numero_serie TEXT UNIQUE,
  estado TEXT NOT NULL DEFAULT 'disponible'
    CHECK (estado IN ('disponible','vendido','reservado','en_reparacion','en_garantia_proveedor','baja')),
  condicion TEXT NOT NULL DEFAULT 'nuevo'
    CHECK (condicion IN ('nuevo','excelente','muy_bueno','bueno','regular','para_reparar')),
  es_usado BOOLEAN DEFAULT false,
  origen_usado TEXT CHECK (origen_usado IN ('compra_directa','parte_de_pago','recepcion_garantia','otro')),
  precio_venta_sugerido_usd NUMERIC(12,2),
  precio_venta_sugerido_ars NUMERIC(12,2),
  costo_adquisicion_usd NUMERIC(12,2),
  costo_total_usd NUMERIC(12,2),
  fecha_ingreso_stock DATE DEFAULT CURRENT_DATE,
  sepa_id UUID,
  tipo_cambio_id UUID REFERENCES tipos_cambio_dolar,
  notas_estado TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE movimientos_stock (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo TEXT NOT NULL CHECK (tipo IN ('ingreso','egreso','transferencia','ajuste','devolucion')),
  variante_id UUID NOT NULL REFERENCES variantes_producto,
  deposito_origen_id UUID REFERENCES depositos,
  deposito_destino_id UUID REFERENCES depositos,
  cantidad INT NOT NULL,
  motivo TEXT,
  referencia_tipo TEXT CHECK (referencia_tipo IN
    ('venta','compra','compra_usados','transferencia','ajuste','sepa','devolucion','garantia_proveedor')),
  referencia_id UUID,
  usuario_id UUID REFERENCES auth.users,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE ajustes_stock (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  variante_id UUID NOT NULL REFERENCES variantes_producto,
  deposito_id UUID NOT NULL REFERENCES depositos,
  unidad_serializada_id UUID REFERENCES unidades_serializadas,
  tipo_ajuste TEXT NOT NULL CHECK (tipo_ajuste IN ('entrada','salida')),
  cantidad INT NOT NULL,
  motivo TEXT NOT NULL CHECK (motivo IN
    ('defecto_origen','rotura_interna','robo','error_conteo','vencimiento','muestra','otro')),
  descripcion TEXT NOT NULL,
  referencia_tipo TEXT CHECK (referencia_tipo IN ('recepcion','devolucion','garantia_proveedor','manual')),
  referencia_id UUID,
  aprobado_por_usuario_id UUID REFERENCES auth.users,
  usuario_id UUID REFERENCES auth.users,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Proveedores
CREATE TABLE proveedores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  razon_social TEXT NOT NULL,
  nombre_fantasia TEXT,
  cuit TEXT,
  email TEXT,
  telefono TEXT,
  whatsapp TEXT,
  direccion TEXT,
  condicion_pago TEXT CHECK (condicion_pago IN ('contado','15_dias','30_dias','60_dias')),
  moneda_preferida TEXT DEFAULT 'USD' CHECK (moneda_preferida IN ('ARS','USD')),
  tipo_proveedor TEXT CHECK (tipo_proveedor IN
    ('distribuidor_nuevo','recuperadora_usados','particular','empresa_renovacion','otro')),
  vende_usado BOOLEAN DEFAULT false,
  vende_nuevo BOOLEAN DEFAULT true,
  requiere_factura BOOLEAN DEFAULT true,
  riesgo_legal TEXT DEFAULT 'bajo' CHECK (riesgo_legal IN ('bajo','medio','alto')),
  notas_internas TEXT,
  lead_time_promedio_dias NUMERIC(5,1),
  tasa_defectos_porcentaje NUMERIC(5,2),
  cumplimiento_precio_porcentaje NUMERIC(5,2),
  score_general NUMERIC(3,1),
  score_actualizado_at TIMESTAMPTZ,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE recepciones_mercaderia (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  orden_compra_id UUID,
  proveedor_id UUID REFERENCES proveedores,
  deposito_id UUID NOT NULL REFERENCES depositos,
  numero_factura_proveedor TEXT,
  fecha_factura DATE,
  tipo_cambio_id UUID REFERENCES tipos_cambio_dolar,
  usuario_id UUID REFERENCES auth.users,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE detalle_recepciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recepcion_id UUID NOT NULL REFERENCES recepciones_mercaderia ON DELETE CASCADE,
  variante_id UUID NOT NULL REFERENCES variantes_producto,
  cantidad_recibida INT NOT NULL,
  precio_costo_usd NUMERIC(12,2) NOT NULL,
  precio_costo_ars NUMERIC(12,2),
  imeis_ingresados TEXT[]
);

-- 6. Auditoría
CREATE TABLE log_actividad (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES auth.users,
  accion TEXT NOT NULL CHECK (accion IN
    ('crear','editar','eliminar','anular','aprobar','rechazar','login','logout')),
  tabla_afectada TEXT NOT NULL,
  registro_id UUID,
  datos_anteriores JSONB,
  datos_nuevos JSONB,
  ip_address TEXT,
  descripcion TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

TRIGGERS (updated_at automático):
- usuarios, productos, variantes_producto, unidades_serializadas

SEQUENCES — numeración de documentos sin race condition:
CREATE SEQUENCE seq_numero_venta      START 1;
CREATE SEQUENCE seq_numero_presupuesto START 1;
CREATE SEQUENCE seq_numero_sepa        START 1;
CREATE SEQUENCE seq_numero_demanda     START 1;
CREATE SEQUENCE seq_numero_ppago       START 1;
CREATE SEQUENCE seq_numero_oc          START 1;

-- Funciones helper para generar números con prefijo:
CREATE OR REPLACE FUNCTION next_numero_venta()
  RETURNS TEXT LANGUAGE SQL AS $$
  SELECT 'V-' || LPAD(nextval('seq_numero_venta')::TEXT, 5, '0')
$$;

CREATE OR REPLACE FUNCTION next_numero_presupuesto()
  RETURNS TEXT LANGUAGE SQL AS $$
  SELECT 'PRS-' || LPAD(nextval('seq_numero_presupuesto')::TEXT, 5, '0')
$$;

CREATE OR REPLACE FUNCTION next_numero_sepa()
  RETURNS TEXT LANGUAGE SQL AS $$
  SELECT 'SEP-' || LPAD(nextval('seq_numero_sepa')::TEXT, 5, '0')
$$;

CREATE OR REPLACE FUNCTION next_numero_demanda()
  RETURNS TEXT LANGUAGE SQL AS $$
  SELECT 'DNS-' || LPAD(nextval('seq_numero_demanda')::TEXT, 5, '0')
$$;

CREATE OR REPLACE FUNCTION next_numero_ppago()
  RETURNS TEXT LANGUAGE SQL AS $$
  SELECT 'PP-' || LPAD(nextval('seq_numero_ppago')::TEXT, 5, '0')
$$;

-- Trigger que auto-puebla numero_venta al insertar:
CREATE OR REPLACE FUNCTION trigger_set_numero_venta()
  RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.numero_venta IS NULL OR NEW.numero_venta = '' THEN
    NEW.numero_venta := next_numero_venta();
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER set_numero_venta
  BEFORE INSERT ON ventas
  FOR EACH ROW EXECUTE FUNCTION trigger_set_numero_venta();

-- Triggers para TODOS los documentos numerados:
CREATE OR REPLACE FUNCTION trigger_set_numero_presupuesto()
  RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.numero_presupuesto IS NULL OR NEW.numero_presupuesto = '' THEN
    NEW.numero_presupuesto := next_numero_presupuesto();
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER set_numero_presupuesto
  BEFORE INSERT ON presupuestos
  FOR EACH ROW EXECUTE FUNCTION trigger_set_numero_presupuesto();

CREATE OR REPLACE FUNCTION trigger_set_numero_sepa()
  RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.numero_sepa IS NULL OR NEW.numero_sepa = '' THEN
    NEW.numero_sepa := next_numero_sepa();
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER set_numero_sepa
  BEFORE INSERT ON separas
  FOR EACH ROW EXECUTE FUNCTION trigger_set_numero_sepa();

CREATE OR REPLACE FUNCTION trigger_set_numero_demanda()
  RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.numero_demanda IS NULL OR NEW.numero_demanda = '' THEN
    NEW.numero_demanda := next_numero_demanda();
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER set_numero_demanda
  BEFORE INSERT ON demandas_no_satisfechas
  FOR EACH ROW EXECUTE FUNCTION trigger_set_numero_demanda();

CREATE OR REPLACE FUNCTION trigger_set_numero_ppago()
  RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.numero_ppago IS NULL OR NEW.numero_ppago = '' THEN
    NEW.numero_ppago := next_numero_ppago();
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER set_numero_ppago
  BEFORE INSERT ON partes_de_pago
  FOR EACH ROW EXECUTE FUNCTION trigger_set_numero_ppago();

TRIGGER Auth → usuarios (crítico — sin esto el sistema no funciona):
-- Cuando alguien se registra en auth.users, crear automáticamente su fila en usuarios.
-- Esto evita el estado roto de "usuario en Auth sin fila en usuarios".
CREATE OR REPLACE FUNCTION public.handle_new_user()
  RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.usuarios (id, nombre, apellido, email, rol, activo)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nombre', 'Sin nombre'),
    COALESCE(NEW.raw_user_meta_data->>'apellido', ''),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'rol', 'vendedor'),
    true
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

ÍNDICES:
CREATE INDEX idx_unidades_imei ON unidades_serializadas (imei) WHERE imei IS NOT NULL;
CREATE INDEX idx_unidades_estado ON unidades_serializadas (estado, deposito_id);
CREATE INDEX idx_unidades_variante ON unidades_serializadas (variante_id, estado);
CREATE INDEX idx_stock_deposito ON stock (deposito_id);
CREATE INDEX idx_movimientos_variante ON movimientos_stock (variante_id, created_at DESC);
CREATE INDEX idx_log_tabla ON log_actividad (tabla_afectada, created_at DESC);
CREATE INDEX idx_proveedores_tipo ON proveedores (tipo_proveedor, activo);

Ejecutar las migraciones y verificar que todas las tablas se crearon correctamente.
```

**Criterio de avance:** tablas core creadas en Supabase + índices aplicados + sin errores en la consola.

---

### Paso 2b — Schema de negocio + RLS
**Acción manual:** Ejecutar en SQL Editor de Supabase.
**Skills:** [postgres-patterns] | [security-review]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, postgres-patterns, security-review]

Genera el SQL para la SEGUNDA MITAD del schema. Guardar en
migrations/001b_schema_negocio.sql.
(Las tablas del Paso 2a ya deben existir antes de ejecutar este archivo.)

TABLAS DE NEGOCIO:

-- 7. Clientes
CREATE TABLE clientes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo TEXT NOT NULL CHECK (tipo IN ('persona','empresa')),
  nombre TEXT NOT NULL,
  apellido TEXT,
  razon_social TEXT,
  dni TEXT,
  cuit TEXT,
  email TEXT,
  telefono TEXT NOT NULL,
  whatsapp TEXT,
  direccion TEXT,
  ciudad TEXT,
  provincia TEXT,
  fecha_nacimiento DATE,
  lista_precio_id UUID REFERENCES listas_precio,
  moneda_preferida TEXT DEFAULT 'ARS' CHECK (moneda_preferida IN ('ARS','USD')),
  origen TEXT CHECK (origen IN ('mostrador','instagram','mercadolibre','referido','web')),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE garantias_cliente (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id UUID NOT NULL REFERENCES clientes,
  venta_id UUID,
  unidad_serializada_id UUID REFERENCES unidades_serializadas,
  imei TEXT,
  numero_serie TEXT,
  producto_nombre TEXT NOT NULL,
  fecha_compra DATE NOT NULL,
  fecha_vencimiento_garantia DATE NOT NULL,
  estado TEXT NOT NULL DEFAULT 'vigente' CHECK (estado IN ('vigente','vencida','reclamada'))
);

CREATE TABLE cuentas_corriente_cliente (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id UUID NOT NULL UNIQUE REFERENCES clientes ON DELETE CASCADE,
  saldo_deudor_ars NUMERIC(14,2) DEFAULT 0,
  saldo_deudor_usd NUMERIC(14,2) DEFAULT 0,
  limite_credito_ars NUMERIC(14,2) DEFAULT 0,
  limite_credito_usd NUMERIC(14,2) DEFAULT 0,
  activa BOOLEAN DEFAULT true
);

CREATE TABLE movimientos_cuenta_corriente (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id UUID NOT NULL REFERENCES clientes,
  tipo TEXT NOT NULL CHECK (tipo IN ('cargo','pago','ajuste')),
  moneda TEXT NOT NULL CHECK (moneda IN ('ARS','USD')),
  monto NUMERIC(14,2) NOT NULL,
  tipo_cambio_id UUID REFERENCES tipos_cambio_dolar,
  referencia_venta_id UUID,
  descripcion TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 8. Ventas y pagos
CREATE TABLE metodos_pago (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL UNIQUE,
  acepta_usd BOOLEAN DEFAULT false,
  genera_recargo BOOLEAN DEFAULT false,
  porcentaje_recargo NUMERIC(5,2) DEFAULT 0,
  activo BOOLEAN DEFAULT true
);

CREATE TABLE ventas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero_venta TEXT UNIQUE NOT NULL,
  cliente_id UUID REFERENCES clientes,
  deposito_id UUID NOT NULL REFERENCES depositos,
  usuario_vendedor_id UUID NOT NULL REFERENCES auth.users,
  estado TEXT NOT NULL DEFAULT 'presupuesto'
    CHECK (estado IN ('presupuesto','confirmada','entregada','cancelada','con_cambio')),
  canal TEXT NOT NULL DEFAULT 'mostrador'
    CHECK (canal IN ('mostrador','whatsapp','mercadolibre','web','servicio_tecnico')),
  tipo_cambio_id UUID REFERENCES tipos_cambio_dolar,
  tipo_cambio_valor_ars NUMERIC(12,4),
  moneda_base TEXT NOT NULL DEFAULT 'USD' CHECK (moneda_base IN ('ARS','USD')),
  subtotal_usd NUMERIC(14,2) NOT NULL DEFAULT 0,
  subtotal_ars NUMERIC(14,2) NOT NULL DEFAULT 0,
  descuento_global_monto_usd NUMERIC(14,2) DEFAULT 0,
  descuento_global_monto_ars NUMERIC(14,2) DEFAULT 0,
  total_usd NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_ars NUMERIC(14,2) NOT NULL DEFAULT 0,
  lista_precio_id UUID REFERENCES listas_precio,
  notas TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  fecha_confirmacion TIMESTAMPTZ
);

CREATE TABLE items_venta (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venta_id UUID NOT NULL REFERENCES ventas ON DELETE CASCADE,
  variante_id UUID NOT NULL REFERENCES variantes_producto,
  unidad_serializada_id UUID REFERENCES unidades_serializadas,
  cantidad INT NOT NULL DEFAULT 1,
  precio_lista_usd NUMERIC(12,2) NOT NULL,
  precio_lista_ars NUMERIC(12,2) NOT NULL,
  descuento_porcentaje NUMERIC(5,2) DEFAULT 0,
  precio_final_usd NUMERIC(12,2) NOT NULL,
  precio_final_ars NUMERIC(12,2) NOT NULL,
  precio_costo_usd NUMERIC(12,2),
  precio_costo_ars NUMERIC(12,2),
  margen_porcentaje NUMERIC(5,2)
);

CREATE TABLE pagos_venta (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venta_id UUID NOT NULL REFERENCES ventas ON DELETE CASCADE,
  metodo_pago_id UUID NOT NULL REFERENCES metodos_pago,
  monto_ars NUMERIC(14,2),
  monto_usd NUMERIC(14,2),
  cuotas INT,
  referencia_externa TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE aprobaciones_descuento (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venta_id UUID REFERENCES ventas,
  presupuesto_id UUID,
  usuario_solicitante_id UUID NOT NULL REFERENCES auth.users,
  usuario_aprobador_id UUID REFERENCES auth.users,
  variante_id UUID NOT NULL REFERENCES variantes_producto,
  descuento_solicitado_pct NUMERIC(5,2) NOT NULL,
  descuento_maximo_rol_pct NUMERIC(5,2) NOT NULL,
  motivo_solicitud TEXT NOT NULL,
  estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente','aprobado','rechazado')),
  motivo_rechazo TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  resuelta_at TIMESTAMPTZ
);

-- 9. Presupuestos
CREATE TABLE presupuestos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero_presupuesto TEXT UNIQUE NOT NULL,
  cliente_id UUID REFERENCES clientes,
  nombre_cliente_libre TEXT,
  telefono_libre TEXT,
  usuario_vendedor_id UUID NOT NULL REFERENCES auth.users,
  tipo_cambio_id UUID REFERENCES tipos_cambio_dolar,
  subtotal_usd NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_usd NUMERIC(14,2) NOT NULL DEFAULT 0,
  subtotal_ars NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_ars NUMERIC(14,2) NOT NULL DEFAULT 0,
  estado TEXT NOT NULL DEFAULT 'borrador'
    CHECK (estado IN ('borrador','enviado','visto','en_negociacion','aceptado','rechazado','vencido','convertido')),
  vigencia_hasta DATE,
  venta_id UUID REFERENCES ventas,
  canal_envio TEXT CHECK (canal_envio IN ('whatsapp','email','mostrador','mercadolibre')),
  motivo_rechazo TEXT CHECK (motivo_rechazo IN
    ('precio','encontro_mas_barato','no_tenia_lo_que_buscaba','demoro_en_responder','sin_presupuesto','otro')),
  competidor_id UUID,
  precio_competencia_usd NUMERIC(12,2),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE items_presupuesto (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  presupuesto_id UUID NOT NULL REFERENCES presupuestos ON DELETE CASCADE,
  variante_id UUID NOT NULL REFERENCES variantes_producto,
  unidad_serializada_id UUID REFERENCES unidades_serializadas,
  cantidad INT NOT NULL DEFAULT 1,
  precio_lista_usd NUMERIC(12,2) NOT NULL,
  precio_lista_ars NUMERIC(12,2) NOT NULL,
  descuento_porcentaje NUMERIC(5,2) DEFAULT 0,
  precio_final_usd NUMERIC(12,2) NOT NULL,
  precio_final_ars NUMERIC(12,2) NOT NULL
);

-- 10. Caja
CREATE TABLE cajas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  deposito_id UUID NOT NULL REFERENCES depositos,
  tipo TEXT NOT NULL CHECK (tipo IN ('efectivo','electronica')),
  activa BOOLEAN DEFAULT true
);

CREATE TABLE sesiones_caja (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  caja_id UUID NOT NULL REFERENCES cajas,
  usuario_id UUID NOT NULL REFERENCES auth.users,
  monto_apertura_ars NUMERIC(14,2) DEFAULT 0,
  monto_apertura_usd NUMERIC(14,2) DEFAULT 0,
  monto_cierre_declarado_ars NUMERIC(14,2),
  monto_cierre_declarado_usd NUMERIC(14,2),
  monto_cierre_sistema_ars NUMERIC(14,2),
  monto_cierre_sistema_usd NUMERIC(14,2),
  diferencia_ars NUMERIC(14,2),
  diferencia_usd NUMERIC(14,2),
  estado TEXT NOT NULL DEFAULT 'abierta' CHECK (estado IN ('abierta','cerrada')),
  abierta_at TIMESTAMPTZ DEFAULT now(),
  cerrada_at TIMESTAMPTZ
);

CREATE TABLE movimientos_caja (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sesion_caja_id UUID NOT NULL REFERENCES sesiones_caja,
  tipo TEXT NOT NULL CHECK (tipo IN ('ingreso','egreso','venta','devolucion','gasto')),
  moneda TEXT NOT NULL CHECK (moneda IN ('ARS','USD')),
  monto NUMERIC(14,2) NOT NULL,
  tipo_cambio_id UUID REFERENCES tipos_cambio_dolar,
  descripcion TEXT NOT NULL,
  referencia_id UUID,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE categorias_gasto (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL UNIQUE,
  descripcion TEXT,
  activo BOOLEAN DEFAULT true
);

CREATE TABLE gastos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deposito_id UUID NOT NULL REFERENCES depositos,
  categoria_gasto_id UUID NOT NULL REFERENCES categorias_gasto,
  descripcion TEXT NOT NULL,
  moneda TEXT NOT NULL CHECK (moneda IN ('ARS','USD')),
  monto NUMERIC(14,2) NOT NULL,
  tipo_cambio_id UUID REFERENCES tipos_cambio_dolar,
  proveedor_id UUID REFERENCES proveedores,
  comprobante_url TEXT,
  usuario_id UUID REFERENCES auth.users,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 11. Usados y parte de pago
CREATE TABLE catalogo_detalles_usados (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  categoria_detalle TEXT NOT NULL
    CHECK (categoria_detalle IN ('pantalla','carcasa','bateria','camara','audio','biometria','conectividad','accesorios','software','otro')),
  severidad TEXT NOT NULL
    CHECK (severidad IN ('informativo','leve','moderado','grave','bloqueante')),
  reduce_precio_sugerido_usd NUMERIC(10,2) DEFAULT 0,
  requiere_alerta_venta BOOLEAN DEFAULT false,
  activo BOOLEAN DEFAULT true
);

CREATE TABLE detalles_unidad_usada (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unidad_serializada_id UUID NOT NULL REFERENCES unidades_serializadas ON DELETE CASCADE,
  detalle_id UUID NOT NULL REFERENCES catalogo_detalles_usados,
  severidad_real TEXT NOT NULL
    CHECK (severidad_real IN ('informativo','leve','moderado','grave','bloqueante')),
  descripcion_adicional TEXT,
  foto_url TEXT[],
  registrado_por_usuario_id UUID REFERENCES auth.users,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE partes_de_pago (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero_ppago TEXT UNIQUE NOT NULL,
  venta_id UUID REFERENCES ventas,
  cliente_id UUID NOT NULL REFERENCES clientes,
  usuario_evaluador_id UUID NOT NULL REFERENCES auth.users,
  imei_recibido TEXT,
  descripcion_equipo TEXT NOT NULL,
  variante_id UUID REFERENCES variantes_producto,
  condicion_evaluada TEXT NOT NULL
    CHECK (condicion_evaluada IN ('nuevo','excelente','muy_bueno','bueno','regular','para_reparar')),
  valor_ofrecido_usd NUMERIC(12,2) NOT NULL,
  valor_ofrecido_ars NUMERIC(12,2) NOT NULL,
  tipo_cambio_id UUID NOT NULL REFERENCES tipos_cambio_dolar,
  estado TEXT NOT NULL DEFAULT 'en_evaluacion'
    CHECK (estado IN ('en_evaluacion','aceptado','rechazado_cliente','rechazado_tienda')),
  unidad_serializada_id UUID REFERENCES unidades_serializadas,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 12. Demanda, separas y novedades
CREATE TABLE demandas_no_satisfechas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero_demanda TEXT UNIQUE NOT NULL,
  usuario_vendedor_id UUID NOT NULL REFERENCES auth.users,
  deposito_id UUID NOT NULL REFERENCES depositos,
  cliente_id UUID REFERENCES clientes,
  nombre_cliente_libre TEXT,
  telefono_cliente_libre TEXT,
  variante_id UUID REFERENCES variantes_producto,
  descripcion_libre TEXT NOT NULL,
  marca_id UUID REFERENCES marcas,
  categoria_id UUID REFERENCES categorias,
  cantidad_solicitada INT DEFAULT 1,
  condicion_buscada TEXT DEFAULT 'cualquiera' CHECK (condicion_buscada IN ('nuevo','usado','cualquiera')),
  presupuesto_cliente_usd NUMERIC(12,2),
  estado TEXT NOT NULL DEFAULT 'sin_stock'
    CHECK (estado IN ('sin_stock','no_catalogado','precio_no_acordado','en_espera','contactado','vendido','perdido')),
  motivo_perdida TEXT
    CHECK (motivo_perdida IN ('compro_competencia','precio','demoro_mucho','desistio','otro')),
  venta_id UUID REFERENCES ventas,
  competidor_id UUID,
  canal_contacto_preferido TEXT DEFAULT 'whatsapp'
    CHECK (canal_contacto_preferido IN ('whatsapp','llamada','cualquiera')),
  created_at TIMESTAMPTZ DEFAULT now(),
  contactado_at TIMESTAMPTZ,
  cerrado_at TIMESTAMPTZ
);

CREATE TABLE separas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero_sepa TEXT UNIQUE NOT NULL,
  cliente_id UUID NOT NULL REFERENCES clientes,
  usuario_vendedor_id UUID NOT NULL REFERENCES auth.users,
  deposito_id UUID NOT NULL REFERENCES depositos,
  variante_id UUID NOT NULL REFERENCES variantes_producto,
  unidad_serializada_id UUID REFERENCES unidades_serializadas,
  descripcion_producto TEXT NOT NULL,
  precio_acordado_usd NUMERIC(12,2) NOT NULL,
  precio_acordado_ars NUMERIC(12,2) NOT NULL,
  tipo_cambio_id UUID NOT NULL REFERENCES tipos_cambio_dolar,
  tipo_cambio_concrecion_id UUID REFERENCES tipos_cambio_dolar,
  monto_seña_usd NUMERIC(12,2) NOT NULL,
  monto_seña_ars NUMERIC(12,2) NOT NULL,
  saldo_pendiente_usd NUMERIC(12,2) NOT NULL,
  saldo_pendiente_ars NUMERIC(12,2) NOT NULL,
  estado TEXT NOT NULL DEFAULT 'activa'
    CHECK (estado IN ('activa','concretada','vencida','cancelada_cliente','cancelada_tienda')),
  fecha_vencimiento DATE NOT NULL,
  politica_seña_vencida TEXT NOT NULL DEFAULT 'reintegrar'
    CHECK (politica_seña_vencida IN ('reintegrar','retener','credito_cuenta')),
  venta_id UUID REFERENCES ventas,
  created_at TIMESTAMPTZ DEFAULT now(),
  concretada_at TIMESTAMPTZ,
  vencida_at TIMESTAMPTZ
);

CREATE TABLE pagos_sepa (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sepa_id UUID NOT NULL REFERENCES separas ON DELETE CASCADE,
  metodo_pago_id UUID NOT NULL REFERENCES metodos_pago,
  monto_ars NUMERIC(14,2),
  monto_usd NUMERIC(14,2),
  tipo_cambio_id UUID NOT NULL REFERENCES tipos_cambio_dolar,
  sesion_caja_id UUID REFERENCES sesiones_caja,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE novedades_turno (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deposito_id UUID NOT NULL REFERENCES depositos,
  tipo TEXT NOT NULL
    CHECK (tipo IN ('cliente_viene','equipo_listo','llamar_cliente','mercaderia',
                    'sepa_vence_hoy','precio_actualizado','tarea_admin','otro')),
  prioridad TEXT NOT NULL DEFAULT 'normal' CHECK (prioridad IN ('urgente','normal','informativa')),
  titulo TEXT NOT NULL,
  descripcion TEXT,
  cliente_id UUID REFERENCES clientes,
  sepa_id UUID REFERENCES separas,
  venta_id UUID REFERENCES ventas,
  estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente','vista','resuelta','escalada')),
  generada_por TEXT NOT NULL DEFAULT 'usuario' CHECK (generada_por IN ('sistema','usuario')),
  usuario_creador_id UUID REFERENCES auth.users,
  usuario_resolutor_id UUID REFERENCES auth.users,
  created_at TIMESTAMPTZ DEFAULT now(),
  vista_at TIMESTAMPTZ,
  resuelta_at TIMESTAMPTZ,
  vence_at TIMESTAMPTZ
);

CREATE TABLE objetivos_vendedor (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES auth.users,
  periodo DATE NOT NULL,
  meta_monto_usd NUMERIC(12,2) NOT NULL,
  meta_cantidad_ventas INT NOT NULL,
  comision_porcentaje NUMERIC(5,2),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (usuario_id, periodo)
);

ÍNDICES adicionales:
CREATE INDEX idx_ventas_deposito_fecha ON ventas (deposito_id, created_at DESC);
CREATE INDEX idx_ventas_vendedor ON ventas (usuario_vendedor_id, created_at DESC);
CREATE INDEX idx_ventas_estado ON ventas (estado, deposito_id);
CREATE INDEX idx_ventas_cliente ON ventas (cliente_id);
CREATE INDEX idx_clientes_nombre ON clientes (nombre, apellido);
CREATE INDEX idx_clientes_dni ON clientes (dni) WHERE dni IS NOT NULL;
CREATE INDEX idx_separas_estado ON separas (estado, fecha_vencimiento);
CREATE INDEX idx_separas_cliente ON separas (cliente_id);
CREATE INDEX idx_novedades_deposito ON novedades_turno (deposito_id, estado, prioridad);
CREATE INDEX idx_demandas_estado ON demandas_no_satisfechas (estado, variante_id);
CREATE INDEX idx_sesiones_caja ON sesiones_caja (caja_id, estado);
CREATE INDEX idx_movimientos_caja ON movimientos_caja (sesion_caja_id, created_at DESC);

FUNCIÓN RPC — confirmar venta en transacción atómica:
-- Con el cliente JS de Supabase no es posible hacer transacciones reales
-- desde una Server Action. La única forma correcta es una función PostgreSQL
-- que ejecute todas las operaciones en un único bloque de transacción.

CREATE OR REPLACE FUNCTION confirmar_venta(p_datos JSONB)
  RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_venta_id UUID;
  v_numero   TEXT;
  v_item     JSONB;
  v_pago     JSONB;
  v_parte    JSONB;
  v_sesion   UUID;
BEGIN
  -- 1. Generar número de venta
  v_numero := next_numero_venta();

  -- 2. Insertar venta principal
  INSERT INTO ventas (
    numero_venta, cliente_id, deposito_id, usuario_vendedor_id,
    estado, canal, tipo_cambio_id, tipo_cambio_valor_ars, moneda_base,
    subtotal_usd, subtotal_ars, total_usd, total_ars, lista_precio_id, notas,
    fecha_confirmacion
  ) VALUES (
    v_numero,
    (p_datos->>'cliente_id')::UUID,
    (p_datos->>'deposito_id')::UUID,
    (p_datos->>'usuario_vendedor_id')::UUID,
    'confirmada',
    COALESCE(p_datos->>'canal', 'mostrador'),
    (p_datos->>'tipo_cambio_id')::UUID,
    (p_datos->>'tipo_cambio_valor_ars')::NUMERIC,
    COALESCE(p_datos->>'moneda_base', 'USD'),
    (p_datos->>'subtotal_usd')::NUMERIC,
    (p_datos->>'subtotal_ars')::NUMERIC,
    (p_datos->>'total_usd')::NUMERIC,
    (p_datos->>'total_ars')::NUMERIC,
    (p_datos->>'lista_precio_id')::UUID,
    p_datos->>'notas',
    now()
  ) RETURNING id INTO v_venta_id;

  -- 3. Items: insertar + descontar stock
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_datos->'items') LOOP
    INSERT INTO items_venta (
      venta_id, variante_id, unidad_serializada_id, cantidad,
      precio_lista_usd, precio_lista_ars, descuento_porcentaje,
      precio_final_usd, precio_final_ars, precio_costo_usd
    ) VALUES (
      v_venta_id,
      (v_item->>'variante_id')::UUID,
      (v_item->>'unidad_serializada_id')::UUID,
      (v_item->>'cantidad')::INT,
      (v_item->>'precio_lista_usd')::NUMERIC,
      (v_item->>'precio_lista_ars')::NUMERIC,
      COALESCE((v_item->>'descuento_porcentaje')::NUMERIC, 0),
      (v_item->>'precio_final_usd')::NUMERIC,
      (v_item->>'precio_final_ars')::NUMERIC,
      (v_item->>'precio_costo_usd')::NUMERIC
    );

    -- Si es serializado: marcar IMEI como vendido
    IF v_item->>'unidad_serializada_id' IS NOT NULL THEN
      UPDATE unidades_serializadas
      SET estado = 'vendido', updated_at = now()
      WHERE id = (v_item->>'unidad_serializada_id')::UUID;
    ELSE
      -- Genérico: decrementar stock
      UPDATE stock
      SET cantidad_disponible = cantidad_disponible - (v_item->>'cantidad')::INT
      WHERE variante_id = (v_item->>'variante_id')::UUID
        AND deposito_id = (p_datos->>'deposito_id')::UUID;
    END IF;

    -- Movimiento de stock
    INSERT INTO movimientos_stock (tipo, variante_id, deposito_origen_id,
      cantidad, motivo, referencia_tipo, referencia_id, usuario_id)
    VALUES ('egreso', (v_item->>'variante_id')::UUID,
      (p_datos->>'deposito_id')::UUID,
      (v_item->>'cantidad')::INT, 'Venta confirmada',
      'venta', v_venta_id,
      (p_datos->>'usuario_vendedor_id')::UUID);
  END LOOP;

  -- 4. Pagos
  FOR v_pago IN SELECT * FROM jsonb_array_elements(p_datos->'pagos') LOOP
    INSERT INTO pagos_venta (venta_id, metodo_pago_id, monto_ars, monto_usd)
    VALUES (
      v_venta_id,
      (v_pago->>'metodo_pago_id')::UUID,
      (v_pago->>'monto_ars')::NUMERIC,
      (v_pago->>'monto_usd')::NUMERIC
    );
  END LOOP;

  -- 5. Movimiento de caja (si hay sesión abierta)
  SELECT id INTO v_sesion FROM sesiones_caja
  WHERE estado = 'abierta'
    AND caja_id IN (SELECT id FROM cajas WHERE deposito_id = (p_datos->>'deposito_id')::UUID)
  LIMIT 1;

  IF v_sesion IS NOT NULL THEN
    INSERT INTO movimientos_caja (sesion_caja_id, tipo, moneda, monto, descripcion, referencia_id)
    VALUES (v_sesion, 'venta', 'ARS', (p_datos->>'total_ars')::NUMERIC,
      'Venta ' || v_numero, v_venta_id);
  END IF;

  -- 6. Log
  INSERT INTO log_actividad (usuario_id, accion, tabla_afectada, registro_id, descripcion)
  VALUES ((p_datos->>'usuario_vendedor_id')::UUID, 'crear', 'ventas', v_venta_id,
    'Venta confirmada: ' || v_numero);

  RETURN jsonb_build_object('success', true, 'id', v_venta_id, 'numero', v_numero);

EXCEPTION WHEN OTHERS THEN
  -- La transacción hace ROLLBACK automático ante cualquier error
  RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- En la Server Action de Next.js usar:
-- const { data } = await supabase.rpc('confirmar_venta', { p_datos: datosJson })
-- if (!data.success) throw new Error(data.error)

RLS REAL (aplicar a TODAS las tablas):
- Crear función helper en SQL:
  CREATE OR REPLACE FUNCTION get_user_rol()
  RETURNS TEXT AS $$
    SELECT rol FROM usuarios WHERE id = auth.uid()
  $$ LANGUAGE SQL SECURITY DEFINER STABLE;

  CREATE OR REPLACE FUNCTION get_user_deposito_id()
  RETURNS UUID AS $$
    SELECT deposito_id FROM usuarios WHERE id = auth.uid()
  $$ LANGUAGE SQL SECURITY DEFINER STABLE;

  CREATE OR REPLACE FUNCTION is_admin()
  RETURNS BOOLEAN AS $$
    SELECT get_user_rol() IN ('admin','superadmin')
  $$ LANGUAGE SQL SECURITY DEFINER STABLE;

- Políticas:
  * Tablas de catálogo (categorias, marcas, productos, variantes, imagenes):
    SELECT: autenticados / INSERT/UPDATE/DELETE: admin+
  * ventas, presupuestos, separas:
    SELECT: autenticados ven las de su deposito_id | admin ve todas
    INSERT: cualquier autenticado
    DELETE: solo admin
  * precios_variante, historial_precios: SELECT todos auth / escritura solo admin
  * configuracion_sistema: SELECT todos auth / escritura solo superadmin
  * log_actividad: SELECT solo admin+ / INSERT server-side only
  * novedades_turno: cada usuario ve las de su deposito_id
  * usuarios: cada usuario ve/edita su propia fila / admin ve todas
```

**Criterio de avance:** todas las tablas creadas + RLS activo + índices aplicados + sin errores.

---

### Paso 2c — Datos semilla
**Acción manual:** Ejecutar en SQL Editor de Supabase.
**Skills:** [postgres-patterns]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, postgres-patterns]

Genera el SQL con los datos semilla iniciales del sistema.
Guardar en migrations/002_seed_data.sql.

1. MÉTODOS DE PAGO (8 métodos):
   INSERT INTO metodos_pago (nombre, acepta_usd, genera_recargo, porcentaje_recargo) VALUES
   ('efectivo_ars',    false, false, 0),
   ('efectivo_usd',    true,  false, 0),
   ('transferencia',   false, false, 0),
   ('debito',          false, true,  0.8),
   ('credito',         false, true,  5.0),
   ('mercadopago',     false, true,  3.5),
   ('cuenta_corriente',false, false, 0),
   ('parte_de_pago',   false, false, 0);

2. CATEGORÍAS DE GASTO (8 categorías):
   INSERT INTO categorias_gasto (nombre, descripcion) VALUES
   ('alquiler',       'Alquiler del local o depósito'),
   ('servicios',      'Luz, agua, internet, teléfono'),
   ('sueldos',        'Sueldos y cargas sociales'),
   ('publicidad',     'Publicidad online y offline'),
   ('logistica',      'Envíos, fletes y transportes'),
   ('mantenimiento',  'Reparaciones y mantenimiento del local'),
   ('impuestos',      'Impuestos y tasas municipales'),
   ('otros',          'Otros gastos no categorizados');

3. CONFIGURACIÓN DEL SISTEMA (10 parámetros):
   INSERT INTO configuracion_sistema (clave, valor, tipo_valor, descripcion, modulo) VALUES
   ('sepa_dias_vencimiento',                 '15',   'integer', 'Días hasta vencimiento de una sepa',                        'separas'),
   ('sepa_dias_alerta_previo',               '3',    'integer', 'Días antes del vencimiento para alertar',                   'separas'),
   ('postventa_dias_recordatorio',           '7',    'integer', 'Días post-venta para recordatorio automático',              'crm'),
   ('descuento_maximo_vendedor_pct',         '10',   'integer', 'Descuento máximo sin aprobación para vendedores',           'ventas'),
   ('margen_minimo_alerta_pct',              '15',   'integer', 'Margen mínimo antes de alertar',                            'usados'),
   ('tc_variacion_reimprimir_etiquetas_pct', '3',    'integer', 'Variación TC para marcar etiquetas desactualizadas',        'precios'),
   ('elasticidad_ventana_dias',              '30',   'integer', 'Días para análisis de elasticidad precio-demanda',          'reportes'),
   ('stock_muerto_dias',                     '60',   'integer', 'Días sin movimiento para considerar stock muerto',          'inventario'),
   ('ciclo_upgrade_margen_tolerancia_pct',   '20',   'integer', 'Tolerancia sobre ciclo promedio de recompra del cliente',   'crm'),
   ('presupuesto_dias_seguimiento',          '3',    'integer', 'Días sin respuesta para recordatorio de presupuesto',       'ventas');

4. DEPÓSITOS INICIALES (2 depósitos):
   INSERT INTO depositos (nombre, tipo, direccion) VALUES
   ('Tienda Principal',  'tienda',   'Dirección de la tienda — actualizar'),
   ('Depósito Central',  'deposito', 'Dirección del depósito — actualizar');

5. CAJAS INICIALES (1 caja efectivo por depósito):
   INSERT INTO cajas (nombre, deposito_id, tipo)
   SELECT 'Caja Efectivo', id, 'efectivo' FROM depositos WHERE tipo = 'tienda';

6. LISTAS DE PRECIO INICIALES:
   INSERT INTO listas_precio (nombre, tipo, moneda_base) VALUES
   ('Minorista',    'minorista',    'USD'),
   ('Mayorista',    'mayorista',    'USD'),
   ('Distribuidor', 'distribuidor', 'USD'),
   ('Empleado',     'empleado',     'USD');

6b. USUARIO SUPERADMIN DE PRUEBA (CRÍTICO):
-- Sin este usuario no podés testear nada después del Paso 2.
-- Instrucción manual: ir a Supabase → Authentication → Users → Add user
-- Email: admin@sistema.test | Password: Admin1234!
-- Tildar "Auto Confirm User"
-- Luego ejecutar este SQL con el UUID que Supabase le asignó:

-- REEMPLAZAR 'PEGAR-UUID-DEL-USUARIO-AQUI' con el UUID real:
DO $$
DECLARE
  v_user_id UUID := 'PEGAR-UUID-DEL-USUARIO-AQUI';
  v_tienda_id UUID;
BEGIN
  SELECT id INTO v_tienda_id FROM depositos WHERE tipo = 'tienda' LIMIT 1;

  UPDATE usuarios
  SET nombre    = 'Admin',
      apellido  = 'Sistema',
      rol       = 'superadmin',
      deposito_id = v_tienda_id
  WHERE id = v_user_id;

  -- Si el trigger no lo creó automáticamente:
  INSERT INTO usuarios (id, nombre, apellido, email, rol, deposito_id, activo)
  VALUES (v_user_id, 'Admin', 'Sistema', 'admin@sistema.test', 'superadmin', v_tienda_id, true)
  ON CONFLICT (id) DO UPDATE
  SET rol = 'superadmin', deposito_id = v_tienda_id;
END $$;

-- Verificar con: SELECT * FROM usuarios WHERE email = 'admin@sistema.test';
-- Debería mostrar rol = 'superadmin' y deposito_id poblado.

7. CATÁLOGO BASE DE DEFECTOS PARA USADOS (15 defectos comunes):
   INSERT INTO catalogo_detalles_usados
   (nombre, categoria_detalle, severidad, reduce_precio_sugerido_usd, requiere_alerta_venta) VALUES
   ('Pantalla con marca de agua leve',   'pantalla',   'leve',        5,  false),
   ('Pantalla con marca de agua notoria','pantalla',   'moderado',   15,  true),
   ('Pantalla rota o fisurada',          'pantalla',   'grave',       40, true),
   ('Carcasa trasera rayada',            'carcasa',    'leve',         3, false),
   ('Carcasa con golpe o abolladura',    'carcasa',    'moderado',    10, true),
   ('Batería degradada (menos de 80%)',  'bateria',    'moderado',    15, true),
   ('Batería degradada (menos de 60%)',  'bateria',    'grave',       30, true),
   ('Cámara con mancha interna',         'camara',     'moderado',    15, true),
   ('Face ID o lector huella sin funcionar','biometria','grave',      20, true),
   ('Altavoz con falla parcial',         'audio',      'moderado',    10, true),
   ('Sin cargador original',             'accesorios', 'informativo',  5, false),
   ('Sin caja original',                 'accesorios', 'informativo',  3, false),
   ('iCloud activo (bloqueado)',          'software',   'bloqueante',   0, true),
   ('Cuenta Google activa',              'software',   'bloqueante',   0, true),
   ('SIM tray faltante',                 'conectividad','leve',         5, false);
```

**Criterio de avance:** datos semilla insertados + verificar en Supabase que existen todos los registros.

---

### Paso 2d — Supabase Storage
**Acción manual:** Configurar en el panel de Supabase → Storage.
**Skills:** [security-review]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, security-review]

Configurar Supabase Storage para el sistema. Genera el SQL de políticas
y las instrucciones para crear los buckets.

INSTRUCCIONES MANUALES EN SUPABASE DASHBOARD:
Ir a Storage → Create bucket (repetir para cada uno):

1. Bucket: "productos-imagenes"
   - Public: SÍ (las imágenes del catálogo son públicas)
   - File size limit: 5MB
   - Allowed MIME types: image/jpeg, image/png, image/webp

2. Bucket: "usados-fotos"
   - Public: SÍ (fotos de defectos visibles en la ficha del equipo)
   - File size limit: 10MB
   - Allowed MIME types: image/jpeg, image/png, image/webp

3. Bucket: "comprobantes"
   - Public: NO (facturas y comprobantes internos)
   - File size limit: 10MB
   - Allowed MIME types: image/jpeg, image/png, application/pdf

POLÍTICAS RLS para Storage (ejecutar en SQL Editor):

-- Imágenes de productos: cualquier autenticado puede leer, solo admin puede subir/borrar
CREATE POLICY "productos_imagenes_select" ON storage.objects
  FOR SELECT TO authenticated USING (bucket_id = 'productos-imagenes');

CREATE POLICY "productos_imagenes_insert" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (
    bucket_id = 'productos-imagenes' AND is_admin()
  );

CREATE POLICY "productos_imagenes_delete" ON storage.objects
  FOR DELETE TO authenticated USING (
    bucket_id = 'productos-imagenes' AND is_admin()
  );

-- Fotos de usados: cualquier autenticado puede leer y subir
CREATE POLICY "usados_fotos_select" ON storage.objects
  FOR SELECT TO authenticated USING (bucket_id = 'usados-fotos');

CREATE POLICY "usados_fotos_insert" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'usados-fotos');

-- Comprobantes: solo autenticados pueden leer y subir
CREATE POLICY "comprobantes_select" ON storage.objects
  FOR SELECT TO authenticated USING (bucket_id = 'comprobantes');

CREATE POLICY "comprobantes_insert" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'comprobantes');

Crear en el proyecto:
lib/supabase/storage.ts — helpers de upload:
  - uploadProductImage(file, productoId): Promise<string | null>
  - uploadUsadoFoto(file, imei): Promise<string | null>
  - uploadComprobante(file, referencia): Promise<string | null>
  - deleteFile(bucket, path): Promise<void>
  - getPublicUrl(bucket, path): string

Validación de archivos antes de subir (Zod):
  const imageSchema = z.object({
    size: z.number().max(5 * 1024 * 1024, 'Máximo 5MB'),
    type: z.enum(['image/jpeg', 'image/png', 'image/webp']),
  })

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** buckets creados + políticas activas + helpers de upload funcionando.

---

### Paso 3a — Tipos TypeScript y enums
**Acción manual:** Ejecutar:
```
npx supabase gen types typescript --project-id TU_PROJECT_ID > lib/types/database.types.ts
```
**Skills:** [postgres-patterns] | [typescript-advanced]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, postgres-patterns, typescript-advanced]

Tomar lib/types/database.types.ts generado por Supabase CLI y crear:

lib/types/enums.ts — todos los enums del dominio de negocio:
  export const RolUsuario = { SUPERADMIN: 'superadmin', ADMIN: 'admin',
    VENDEDOR: 'vendedor', TECNICO: 'tecnico', DEPOSITO: 'deposito' } as const
  export type RolUsuario = typeof RolUsuario[keyof typeof RolUsuario]

  (Repetir el patrón para:)
  - TipoDeposito: tienda | deposito | servicio_tecnico
  - EstadoUnidad: disponible | vendido | reservado | en_reparacion | en_garantia_proveedor | baja
  - CondicionProducto: nuevo | excelente | muy_bueno | bueno | regular | para_reparar
  - TipoProducto: serializado | generico | servicio
  - EstadoVenta: presupuesto | confirmada | entregada | cancelada | con_cambio
  - CanalVenta: mostrador | whatsapp | mercadolibre | web | servicio_tecnico
  - MonedaBase: ARS | USD
  - EstadoPresupuesto: borrador | enviado | visto | en_negociacion | aceptado | rechazado | vencido | convertido
  - EstadoSepa: activa | concretada | vencida | cancelada_cliente | cancelada_tienda
  - PoliticaSeña: reintegrar | retener | credito_cuenta
  - TipoMovimientoStock: ingreso | egreso | transferencia | ajuste | devolucion
  - EstadoNovedad: pendiente | vista | resuelta | escalada
  - TipoNovedad: cliente_viene | equipo_listo | llamar_cliente | mercaderia | sepa_vence_hoy | precio_actualizado | tarea_admin | otro
  - PrioridadNovedad: urgente | normal | informativa
  - SeveridadDefecto: informativo | leve | moderado | grave | bloqueante
  - EstadoDemanda: sin_stock | no_catalogado | precio_no_acordado | en_espera | contactado | vendido | perdido

lib/types/index.ts — tipos derivados de database.types.ts:
  export type TipoCambio = Tables<'tipos_cambio_dolar'>
  export type Deposito = Tables<'depositos'>
  export type Usuario = Tables<'usuarios'>
  export type Configuracion = Tables<'configuracion_sistema'>
  export type Categoria = Tables<'categorias'>
  export type Marca = Tables<'marcas'>
  export type Producto = Tables<'productos'>
  export type VarianteProducto = Tables<'variantes_producto'>
  export type Stock = Tables<'stock'>
  export type UnidadSerializada = Tables<'unidades_serializadas'>
  export type Proveedor = Tables<'proveedores'>
  export type Cliente = Tables<'clientes'>
  export type CuentaCorriente = Tables<'cuentas_corriente_cliente'>
  export type Venta = Tables<'ventas'>
  export type ItemVenta = Tables<'items_venta'>
  export type MetodoPago = Tables<'metodos_pago'>
  export type PagoVenta = Tables<'pagos_venta'>
  export type Presupuesto = Tables<'presupuestos'>
  export type Sepa = Tables<'separas'>
  export type PagoSepa = Tables<'pagos_sepa'>
  export type SesionCaja = Tables<'sesiones_caja'>
  export type MovimientoCaja = Tables<'movimientos_caja'>
  export type Gasto = Tables<'gastos'>
  export type NovedadTurno = Tables<'novedades_turno'>
  export type LogActividad = Tables<'log_actividad'>
  export type CatalogoDetalle = Tables<'catalogo_detalles_usados'>
  export type DetalleUnidad = Tables<'detalles_unidad_usada'>
  export type ParteDePago = Tables<'partes_de_pago'>
  export type DemandaNoSatisfecha = Tables<'demandas_no_satisfechas'>
  export type ObjetivoVendedor = Tables<'objetivos_vendedor'>

  (Agregar también tipos compuestos útiles:)
  export type VentaConDetalle = Venta & { items: ItemVenta[]; pagos: PagoVenta[]; cliente: Cliente | null }
  export type UnidadConDetalles = UnidadSerializada & { detalles: DetalleUnidad[]; variante: VarianteProducto }
  export type SepaConCliente = Sepa & { cliente: Cliente; variante: VarianteProducto }

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** tipos disponibles + enums como const objects + TypeScript limpio.

---

### Paso 3b — Clientes Supabase + queries + hooks
**Skills:** [security-review] | [postgres-patterns] | [error-handling]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, security-review, postgres-patterns, error-handling]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

1. Configurar clientes Supabase:
   lib/supabase/client.ts — createBrowserClient (para Client Components)
   lib/supabase/server.ts — createServerClient (para Server Components y Actions)
   lib/supabase/proxy.ts  — función proxy() requerida por Next.js 14

2. Configurar proxy.ts en la RAÍZ:
   Proteger /dashboard y rutas anidadas.
   Redirigir a /login si no hay sesión activa.
   Redirigir a /dashboard si hay sesión y se accede a /login.

3. Crear lib/supabase/queries/ con helpers server-side:
   tipo-cambio.ts:
     getTipoCambioHoy(): Promise<TipoCambio | null>
     getTipoCambioById(id: string): Promise<TipoCambio | null>
     getHistorialTC(limit?: number): Promise<TipoCambio[]>

     // Helper OBLIGATORIO — importar y usar en TODA Action que dependa del TC:
     async function requireTCDelDia(supabase: SupabaseClient): Promise<TipoCambio> {
       const tc = await getTipoCambioHoy()
       if (!tc) throw new Error('SIN_TC_DEL_DIA')
       return tc
     }
     // En cada Server Action:
     // try {
     //   const tc = await requireTCDelDia(supabase)
     //   ... usar tc.id y tc.valor_ars
     // } catch (e) {
     //   if ((e as Error).message === 'SIN_TC_DEL_DIA')
     //     return { error: 'Cargá el tipo de cambio del día antes de continuar' }
     //   throw e
     // }

   usuarios.ts:
     getUsuarioActual(): Usuario & { deposito: Deposito }
     getUsuarios(): Usuario[]

   configuracion.ts:
     getConfiguracion(): Record<string, string>
     getParametro(clave: string): string | null

   // PATRÓN CURSOR-BASED para TODOS los listados (nunca usar OFFSET):
   // Ejemplo canónico a seguir en todos los módulos:
   //
   // async function getItems(cursor?: string): Promise<{ data: T[]; nextCursor: string | null }> {
   //   let q = supabase.from('tabla').select('*').order('id').limit(20)
   //   if (cursor) q = q.gt('id', cursor)
   //   const { data } = await q
   //   return {
   //     data: data ?? [],
   //     nextCursor: data?.length === 20 ? data[19].id : null
   //   }
   // }
   //
   // En el componente: searchParams.cursor como prop del Server Component
   // Link "Siguiente": href="?cursor={nextCursor}"

   productos.ts:
     getProductos(filtros?: { categoria?: string; busqueda?: string; cursor?: string }): Promise<{ data: Producto[]; nextCursor: string | null }>
     getVarianteById(id: string): VarianteProducto | null
     buscarVariantes(query: string, depositoId: string): VarianteProducto[]

   stock.ts:
     getStockPorDeposito(depositoId: string): (Stock & { variante: VarianteProducto })[]
     getUnidadByImei(imei: string): UnidadSerializada | null
     getUnidadesDisponibles(varianteId: string, depositoId: string): UnidadSerializada[]

   clientes.ts:
     getClientes(cursor?: string): { data: Cliente[]; nextCursor: string | null }
     getClienteById(id: string): Cliente | null
     buscarCliente(query: string): Cliente[]

   ventas.ts:
     getVentasDelDia(depositoId: string): Venta[]
     getVentas(filtros?: { estado?: string; cursor?: string }): { data: Venta[]; nextCursor: string | null }
     getVentaById(id: string): VentaConDetalle | null

   novedades.ts:
     getNovedadesPendientes(depositoId: string): NovedadTurno[]

   log.ts:
     crearLog(datos: Omit<LogActividad, 'id' | 'created_at'>): Promise<void>

4. Crear lib/hooks/ para Client Components:
   useTipoCambio.ts:
     Retorna { bloqueado: boolean; tc: TipoCambio | null; loading: boolean }
     Si bloqueado = true, el componente debe mostrar mensaje de alerta

   useConfiguracion.ts:
     getParametro(clave: string): string
     (carga la configuración una vez y cachea)

   useToast.ts:
     Helper sobre sonner: toast.success(), toast.error(), toast.loading()

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** clientes configurados + queries disponibles + proxy protege el dashboard.

---

## FASE 1 — Core Operativo (MVP)

### Paso 4 — Login y layout base
**Skills:** [frontend-design] | [security-review] | [accessibility]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, security-review, accessibility]

ANTES de hacer cualquier cosa, verificar archivos inmutables del CLAUDE.md sección 6.

1. Página de login en app/(auth)/login/page.tsx:
   - Server Component con Client Component hijo LoginForm
   - Login email + password via signInWithPassword
   - Al autenticarse → redirigir a /dashboard
   - Si hay sesión → redirigir automáticamente a /dashboard
   DISEÑO (azul marino y blanco predominante):
   - Fondo: blanco #FFFFFF
   - Card centrado con borde sutil y sombra suave
   - Header del card: azul marino #1E3A5F con logo del sistema en blanco
   - Botón login: azul marino #1E3A5F, texto blanco
   - Errores: texto rojo debajo del campo
   - Mobile-first: funciona en 375px
   - Sin librerías de formularios, useTransition + Server Action

2. Layout en app/(dashboard)/layout.tsx:
   - Server Component: leer usuario actual + verificar TC del día
   - Pasar { usuario, tcHoy } al Sidebar

3. Sidebar en components/layout/Sidebar.tsx:
   DISEÑO azul marino:
   - Fondo: azul marino #1E3A5F, texto blanco
   - Item activo: fondo #2D5F8A, borde izquierdo blanco 3px
   - Item hover: fondo rgba(255,255,255,0.1)
   - Logo arriba: nombre del sistema en blanco
   - Separador entre secciones: línea rgba(255,255,255,0.2)
   Links con íconos lucide-react:
     📊 Dashboard | 💱 Tipo de Cambio | 📦 Catálogo | 🏭 Inventario
     🚚 Proveedores | 👥 Clientes | 🛍️ Ventas | 📋 Presupuestos
     🤝 Separas | 📱 Usados | 💰 Caja | 🏆 Vendedores
     Solo admin+: 💲 Precios | 📈 Reportes | ⚙️ Configuración
   Badge rojo si no hay TC del día cargado
   Botón logout abajo
   Colapsable en mobile (hamburger menu)

4. Header en components/layout/Header.tsx:
   DISEÑO:
   - Fondo blanco, borde inferior azul marino claro
   - Nombre del módulo activo (bold, azul marino)
   - Chip del depósito activo
   - Nombre y rol del usuario
   - Indicador TC del día: verde si cargado, ⚠️ amarillo si falta

5. Dashboard base en app/(dashboard)/dashboard/page.tsx:
   - Estructura con Suspense por sección
   - Banner azul marino si no hay TC: "⚠️ Sin tipo de cambio hoy"

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** login funciona + dashboard carga + sidebar azul marino + header blanco.

---

### Paso 5 — Tipo de cambio diario
**Skills:** [frontend-design] | [postgres-patterns] | [error-handling]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, error-handling]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Crear app/(dashboard)/tipo-cambio/page.tsx.

DISEÑO: página blanca, card de TC actual con borde azul marino.

1. Card "TC del día":
   Si existe:
   - Valor en grande: "$1.215,00 ARS / USD" en azul marino
   - Metadata: tipo, fuente, quién lo cargó, a qué hora
   - Badge verde "Cargado"
   Si NO existe:
   - Banner rojo prominente: "⚠️ Sin tipo de cambio — ventas bloqueadas"
   - Formulario de carga inmediato (no oculto)

2. Formulario de carga (solo admin+):
   Campos con validación Zod:
   const tcSchema = z.object({
     valor_ars: z.number().positive('El valor debe ser mayor a 0').max(99999),
     tipo: z.enum(['oficial','blue','personalizado']),
     fuente: z.enum(['manual','api_bcra','api_bluelytics']),
   })
   Server Action: cargarTipoCambio(formData)
   - Validar con Zod
   - Verificar rol admin+
   - Verificar que no exista TC del día (no duplicar)
   - Insertar en tipos_cambio_dolar
   - Crear log_actividad
   - Crear novedad_turno tipo 'precio_actualizado' (informativa)
   - revalidatePath('/tipo-cambio') y revalidatePath('/dashboard')
   - Retornar { success: true } | { error: string }
   Loading: useTransition + botón deshabilitado + toast.loading()
   Éxito: toast.success('Tipo de cambio cargado') + limpiar form
   Error: toast.error(result.error)

3. Tabla histórica:
   Últimos 30 registros con cursor-based pagination
   Columnas: fecha, valor ARS, tipo, fuente, usuario
   Usar componente Table.tsx

4. Lógica de bloqueo global en app/(dashboard)/layout.tsx:
   Si no hay TC del día → agregar BannerSinTC en la parte superior
   El banner tiene link directo a /tipo-cambio

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** se puede cargar TC + toast de éxito + bloqueo visible en todo el dashboard.

---

### Paso 6 — Configuración del sistema y usuarios
**Skills:** [frontend-design] | [postgres-patterns] | [security-review]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, security-review, accessibility, error-handling]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Crear app/(dashboard)/configuracion/ con tabs: Sistema | Usuarios | Depósitos
Solo accesible con rol admin+. Redirigir a /dashboard si no tiene permiso.

Tab Sistema (solo superadmin):
- Tabla con parámetros de configuracion_sistema
- Edición inline por fila
- Validación Zod según tipo_valor:
  integer → z.coerce.number().int().positive()
  decimal → z.coerce.number().positive()
  boolean → z.enum(['true','false'])
  text    → z.string().min(1)
- Server Action: actualizarParametro(clave, valor)
  Validar superadmin → actualizar → log_actividad → revalidate
  toast.success('Parámetro actualizado') | toast.error(...)

Tab Usuarios (admin+):
- Listado paginado cursor-based: nombre, email, rol (badge), depósito, estado
- Formulario crear usuario (modal):
  const usuarioSchema = z.object({
    nombre: z.string().min(2),
    apellido: z.string().min(2),
    email: z.string().email(),
    password: z.string().min(8, 'Mínimo 8 caracteres'),
    rol: z.enum(['superadmin','admin','vendedor','tecnico','deposito']),
    deposito_id: z.string().uuid(),
    comision_porcentaje: z.number().min(0).max(100).optional(),
  })
  Server Action: crearUsuario → crear en Supabase Auth + insertar en usuarios
- Editar: modal con mismo schema (sin password)
- Activar/desactivar: toggle con confirmación
- Validación: no puede cambiar su propio rol

Tab Depósitos (admin+):
- Listado: nombre, tipo (badge), dirección, activo
- ABM con validación Zod
- No eliminar depósito con stock activo (verificar antes)

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** crear usuarios funciona + parámetros editables + depósitos gestionados.

---

### Paso 7 — Catálogo de productos
**Skills:** [frontend-design] | [postgres-patterns]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, accessibility, error-handling]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Crear app/(dashboard)/catalogo/ con tabs: Productos | Marcas | Categorías

Tab Productos:
- SearchInput con debounce + filtros: categoría, tipo (badge), activo
- Listado paginado cursor-based usando componente Table.tsx
  Columnas: SKU, nombre, marca, categoría, tipo (badge), variantes (#), activo
- Click en producto → Drawer.tsx lateral con:
  * Datos del producto editables
  * Sección de variantes: listado con specs (color/cap/RAM) y SKU
  * Botón "Nueva variante" → Modal.tsx
  * Imágenes: grid con upload a Supabase Storage bucket 'productos-imagenes'
    Usar uploadProductImage() de lib/supabase/storage.ts
    Preview inmediato, eliminar con confirmación

Validaciones Zod:
  const productoSchema = z.object({
    sku: z.string().min(1).max(50),
    nombre: z.string().min(2).max(200),
    tipo: z.enum(['serializado','generico','servicio']),
    categoria_id: z.string().uuid(),
    marca_id: z.string().uuid(),
    garantia_meses: z.number().int().min(0).max(120),
  })

  const varianteSchema = z.object({
    color: z.string().optional(),
    capacidad_gb: z.number().int().positive().optional(),
    ram_gb: z.number().int().positive().optional(),
    version: z.string().optional(),
    modelo: z.string().optional(),
    sku_variante: z.string().min(1).max(50),
  })

Server Actions en lib/actions/catalogo.ts:
- crearProducto, actualizarProducto, toggleActivo
- crearVariante, actualizarVariante
- uploadImagenProducto(file, productoId)
- Todos: validar Zod → operación → log_actividad → revalidate → return ActionResult

Tab Marcas:
- ABM simple con Modal.tsx, validación Zod
- No eliminar si tiene productos asociados (verificar count antes)

Tab Categorías:
- Árbol visual: nivel 1 (Celulares) → nivel 2 (iPhone) → nivel 3 (iPhone 15)
- ABM con selector de categoría padre (nullable)

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** crear producto con variantes funciona + imagen uploadable + árbol de categorías.

---

### Paso 8 — Precios y listas de precio
**Skills:** [frontend-design] | [postgres-patterns] | [security-review]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, security-review, accessibility, error-handling, performance]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Crear app/(dashboard)/precios/.
Solo admin+. Redirigir a /dashboard si no tiene permiso.

Tabs: Listas de Precio | Historial | Reglas de Descuento

Tab Listas de Precio:
- Selector de lista activa (tabs o dropdown)
- SearchInput para filtrar variantes
- Tabla paginada cursor-based:
  Columnas: producto, variante (color/cap/RAM), precio USD, margen%,
  precio ARS calculado (USD × TC hoy), precio ARS fijo (si aplica)
- Edición inline por fila:
  * precio_usd: input numérico → al cambiar, recalcular ARS en tiempo real (no requiere guardar)
  * margen_porcentaje: input numérico
  * usar_precio_ars_fijo: toggle → si activo, mostrar campo precio_ars_override
  * Botón "Guardar" por fila

  const precioSchema = z.object({
    precio_usd: z.number().positive('Debe ser mayor a 0'),
    margen_porcentaje: z.number().min(0).max(100),
    usar_precio_ars_fijo: z.boolean(),
    precio_ars_override: z.number().positive().optional(),
  })

  Server Action: actualizarPrecio(varianteId, listaPrecioId, datos)
  - Validar admin+ y Zod
  - Insertar automáticamente en historial_precios con precio anterior
  - log_actividad
  - toast.success con precio nuevo

- Actualización masiva por categoría:
  Select de categoría + nuevo margen% → botón "Aplicar a toda la categoría"
  Modal de confirmación: "¿Actualizar N productos?"

Tab Historial:
- Tabla con filtros: variante (búsqueda), lista, usuario, rango de fechas
- Columnas: fecha, producto, variante, lista, precio anterior, precio nuevo, usuario, motivo

Tab Reglas de Descuento:
- ABM de reglas con validación Zod
- Mostrar descuento máximo por rol según configuracion_sistema

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** precios editables + historial auto-registrado + ARS recalcula en tiempo real.

---

### Paso 9 — Inventario y stock
**Skills:** [frontend-design] | [postgres-patterns] | [performance] | [error-handling]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, performance, error-handling]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Crear app/(dashboard)/inventario/ con tabs: Stock | Serializados | Recepciones | Ajustes

Tab Stock (productos genéricos):
- Tabla paginada cursor-based
  Columnas: producto, variante, depósito, disponible, reservado, en_tránsito, mínimo
  Color semántico usando StatusBadge:
  - disponible = 0 → rojo CRÍTICO
  - disponible ≤ stock_minimo → amarillo BAJO
  - disponible > stock_minimo → verde OK
- Filtros: depósito, categoría
- Exportar CSV de la vista actual

Tab Serializados (productos con IMEI):
- SearchInput por IMEI o número de serie
- Tabla paginada cursor-based:
  Columnas: IMEI, variante, depósito, estado (StatusBadge), condición, es_usado
- Filtros: estado, depósito, condición, es_usado (toggle)
- Click en IMEI → Drawer con ficha completa:
  * Datos básicos: variante, IMEI, condición, origen, fechas
  * Costos: costo adquisición, costos reparación preventa, costo total
  * Precio sugerido en USD y ARS al TC de hoy
  * Para usados: listado de detalles/defectos con fotos
  * Historial de movimientos de esta unidad

Tab Recepciones:
- Formulario nueva recepción con validación Zod completa:
  const recepcionSchema = z.object({
    proveedor_id: z.string().uuid().optional(),
    deposito_id: z.string().uuid(),
    numero_factura: z.string().optional(),
    fecha_factura: z.string().optional(),
    items: z.array(z.object({
      variante_id: z.string().uuid(),
      cantidad: z.number().int().positive(),
      precio_costo_usd: z.number().positive(),
      imeis: z.array(z.string()).optional(),
    })).min(1, 'Debe agregar al menos un producto'),
  })

  Para productos serializados: textarea de IMEIs (uno por línea)
  Validar que cantidad de IMEIs = cantidad pedida

  Server Action: recibirMercaderia(datos)
  - Validar Zod
  - Por cada ítem: actualizar stock (INSERT/UPDATE en tabla stock)
  - Por cada IMEI: crear unidad_serializada
  - Crear movimientos_stock tipo 'ingreso'
  - Si stock llega a mínimo luego: crear novedad_turno 'mercaderia' urgente
  - log_actividad → revalidate → toast

- Historial paginado cursor-based con filtros

Tab Ajustes:
- Formulario con validación Zod:
  const ajusteSchema = z.object({
    variante_id: z.string().uuid(),
    deposito_id: z.string().uuid(),
    tipo_ajuste: z.enum(['entrada','salida']),
    cantidad: z.number().int().positive(),
    motivo: z.enum(['defecto_origen','rotura_interna','robo','error_conteo','vencimiento','muestra','otro']),
    descripcion: z.string().min(10, 'Describí el motivo con al menos 10 caracteres'),
  })

  Si rol = vendedor: crear ajuste con estado pendiente_aprobacion + novedad urgente al admin
  Si rol = admin+: aplicar directo + log

  Historial de ajustes con filtros: pendientes vs aprobados

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** recepción con IMEIs actualiza stock + serializados visibles en ficha.

---

### Paso 10a — Proveedores
**Skills:** [frontend-design] | [postgres-patterns]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, accessibility, error-handling]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Crear app/(dashboard)/proveedores/.

page.tsx — Listado:
- SearchInput + filtros: tipo_proveedor, vende_usado, vende_nuevo, activo
- Tabla paginada cursor-based usando Table.tsx:
  Columnas: nombre, tipo (Badge), riesgo legal (Badge coloreado), score/10, activo
  Badge riesgo: bajo=verde, medio=amarillo, alto=rojo
- Botón "Nuevo proveedor" → Modal con formulario

Formulario (Modal o página /nueva):
  const proveedorSchema = z.object({
    razon_social: z.string().min(2),
    nombre_fantasia: z.string().optional(),
    cuit: z.string().optional(),
    email: z.string().email().optional().or(z.literal('')),
    telefono: z.string().optional(),
    whatsapp: z.string().optional(),
    condicion_pago: z.enum(['contado','15_dias','30_dias','60_dias']),
    moneda_preferida: z.enum(['ARS','USD']),
    tipo_proveedor: z.enum(['distribuidor_nuevo','recuperadora_usados','particular','empresa_renovacion','otro']),
    vende_usado: z.boolean(),
    vende_nuevo: z.boolean(),
    requiere_factura: z.boolean(),
    riesgo_legal: z.enum(['bajo','medio','alto']),
    notas_internas: z.string().optional(),
  })

Ficha de proveedor (app/(dashboard)/proveedores/[id]/page.tsx o Drawer):
- Todos los datos editables
- Score de performance (si tiene datos): lead_time, defectos %, cumplimiento %
  Mostrar como barras de progreso
- Historial de recepciones asociadas (paginado)
- Notas internas (campo de texto libre con guardado automático)

Server Actions en lib/actions/proveedores.ts:
- crearProveedor, actualizarProveedor, toggleActivo
- Todos: Zod → operación → log_actividad → revalidate → ActionResult

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** CRUD de proveedores funciona + ficha con historial de recepciones.

---

### Paso 10b — Clientes
**Skills:** [frontend-design] | [postgres-patterns]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, accessibility, error-handling]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Crear app/(dashboard)/clientes/.

page.tsx — Listado:
- SearchInput (mínimo 3 caracteres, busca nombre+DNI+teléfono)
- Filtros: tipo (persona/empresa), origen, activo
- Tabla paginada cursor-based: nombre, DNI/CUIT, teléfono, origen (Badge), última compra
- Botón "Nuevo cliente" → Modal con formulario

Formulario con validación Zod:
  const clienteSchema = z.object({
    tipo: z.enum(['persona','empresa']),
    nombre: z.string().min(2),
    apellido: z.string().optional(),
    razon_social: z.string().optional(),
    dni: z.string().optional(),
    cuit: z.string().optional(),
    email: z.string().email().optional().or(z.literal('')),
    telefono: z.string().min(6),
    whatsapp: z.string().optional(),
    ciudad: z.string().optional(),
    origen: z.enum(['mostrador','instagram','mercadolibre','referido','web']),
    lista_precio_id: z.string().uuid().optional(),
    moneda_preferida: z.enum(['ARS','USD']),
  }).refine(data => {
    if (data.tipo === 'persona') return !!data.nombre
    if (data.tipo === 'empresa') return !!data.razon_social
    return true
  }, 'Nombre o razón social requerido')

Ficha del cliente (app/(dashboard)/clientes/[id]/page.tsx):
Tabs: Datos | Cuenta Corriente | Historial de Compras | Garantías

Tab Datos: formulario editable con todos los campos
Tab Cuenta Corriente:
  - Card: saldo ARS, saldo USD, límite de crédito
  - Tabla de movimientos paginada: tipo, monto, moneda, descripción, fecha
Tab Historial de Compras:
  - Lista de ventas confirmadas del cliente (paginada cursor-based)
  - Cada ítem: fecha, número, total USD, total ARS, estado (Badge)
Tab Garantías:
  - Lista de garantías activas, vencidas, reclamadas (Badge por estado)
  - Días restantes para las vigentes

Server Actions en lib/actions/clientes.ts:
- crearCliente: crear cliente + crear cuentas_corriente_cliente automáticamente
- actualizarCliente, toggleActivo
- Todos: Zod → operación → log_actividad → revalidate → ActionResult

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** crear cliente funciona + cuenta corriente creada automáticamente + ficha completa.

---

### Paso 11 — Caja diaria
**Skills:** [frontend-design] | [postgres-patterns] | [error-handling]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, error-handling]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Crear app/(dashboard)/caja/.

DISEÑO: cards blancos con borde azul marino, montos en azul marino grande.

page.tsx — Sesión actual:
Estado: sin sesión abierta:
  - Card: "Sin caja abierta"
  - Botón "Abrir caja" con campos monto inicial ARS y USD
  - Schema: z.object({ monto_ars: z.number().min(0), monto_usd: z.number().min(0) })

Estado: sesión abierta:
  - Card de resumen en tiempo real:
    * Ingresos del día: desglose por tipo (ventas, cobros de separas, otros)
    * Egresos del día (gastos)
    * Saldo actual ARS (en grande, azul marino)
    * Saldo actual USD (en grande, azul marino)
  - Listado de movimientos (más reciente primero), paginado cursor-based
    Cada movimiento: tipo (Badge), monto, moneda, descripción, hora
  - Formulario registro de gasto manual:
    const gastoSchema = z.object({
      categoria_gasto_id: z.string().uuid(),
      descripcion: z.string().min(5),
      moneda: z.enum(['ARS','USD']),
      monto: z.number().positive(),
      comprobante_url: z.string().url().optional(),
    })
  - Botón "Cerrar caja" (solo admin):
    * Modal con campos: declarado_ars, declarado_usd
    * Mostrar: sistema dice X, declarás Y, diferencia Z
    * Diferencia: verde si ≤ $100 ARS, rojo si mayor
    * Confirmar → cerrar sesión + log_actividad
    * Al cerrar: novedades_turno urgentes sin resolver → estado 'escalada'

Historial de sesiones:
  - Selector de fecha → ver sesión de ese día
  - Resumen de esa sesión: apertura, cierre, diferencias, movimientos

Server Actions en lib/actions/caja.ts:
- abrirCaja, cerrarCaja, registrarGasto
- Todos: Zod → operación → movimiento_caja → log → revalidate → ActionResult

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** abrir/cerrar caja funciona + gastos registrados + diferencias visibles.

---

### Paso 12a — Ventas: Listado
**Skills:** [frontend-design] | [postgres-patterns] | [performance]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, performance, error-handling]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Crear app/(dashboard)/ventas/page.tsx — Módulo de listado de ventas.

DISEÑO: página blanca, tabla con header azul marino claro.

Listado principal:
- PageHeader.tsx: título "Ventas", botón "Nueva venta" → link a /ventas/nueva
- Filtros en fila: fecha (date picker), estado (select), vendedor (select), depósito (select), canal (select)
- SearchInput: buscar por número de venta o nombre de cliente
- Tabla paginada cursor-based usando Table.tsx:
  Columnas: N° venta, fecha/hora, cliente, vendedor, depósito,
  total USD (CurrencyDisplay), estado (StatusBadge), canal (Badge)
  Click en fila → /ventas/[id]

- Estadísticas de la vista actual (cards resumen sobre la tabla):
  * Total facturado en USD y ARS
  * Cantidad de ventas
  * Ticket promedio USD

Estados de venta y colores:
  presupuesto   → azul claro (Badge info)
  confirmada    → azul marino (Badge primary)
  entregada     → verde (Badge success)
  cancelada     → rojo (Badge danger)
  con_cambio    → naranja (Badge warning)

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** listado con filtros funciona + paginación cursor-based + estadísticas visibles.

---

### Paso 12b — Ventas: Nueva venta (UI del POS)
**Skills:** [frontend-design] | [postgres-patterns] | [security-review] | [accessibility] | [typescript-advanced]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, security-review, accessibility, typescript-advanced]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Crear app/(dashboard)/ventas/nueva/page.tsx — Formulario del POS.
Es un Client Component principal que maneja el estado del carrito localmente.

SECCIÓN 1 — Encabezado:
- Cliente: SearchInput que busca en tiempo real (mínimo 3 chars)
  Resultado: dropdown con nombre, DNI, teléfono
  Si no encuentra: botón "Crear cliente nuevo" → Modal con formulario básico
  Si se crea: auto-seleccionar
- Datos de la venta (no editables por el vendedor):
  * Depósito: el del usuario actual
  * Vendedor: el usuario actual (nombre en texto, no input)
  * TC del día: mostrar "USD 1 = ARS $1.215,00"
  * Si no hay TC: bloquear todo el formulario con mensaje rojo

SECCIÓN 2 — Carrito de productos:
- SearchInput para buscar variante (nombre, SKU, IMEI)
  Al tipear IMEI: buscar directamente la unidad serializada
  Al tipear texto: buscar variantes disponibles en el depósito actual

- Al seleccionar una variante genérica:
  * Mostrar precio USD y ARS (calculado al TC del día, en tiempo real)
  * Input de cantidad (default 1)
  * Input descuento % (default 0, validar vs descuento_maximo_vendedor_pct)
    Si supera el máximo: input se pone rojo + tooltip "Requiere aprobación del admin"
  * Subtotal USD y ARS (calculado en tiempo real)
  * Botón agregar al carrito

- Al seleccionar un producto serializado:
  * Mostrar dropdown de IMEIs disponibles en el depósito
  * Si es usado: mostrar condición + badge de detalles/defectos
  * Si tiene defecto bloqueante: NO mostrar en el dropdown
  * Precio es el de la unidad (precio_venta_sugerido_usd o de la lista)

- Tabla del carrito:
  Columnas: producto/variante, IMEI (si aplica), qty, precio lista, descuento, total USD, total ARS
  Botón eliminar por ítem
  Totales al pie: subtotal, descuento total, TOTAL en grande

- Parte de pago:
  Toggle "El cliente entrega un equipo"
  Si activo: campos IMEI equipo recibido, descripción, condición, valor ofrecido USD
  El valor se muestra como descuento del total

SECCIÓN 3 — Métodos de pago:
- Lista de métodos con checkbox + input de monto
- Validar en tiempo real: suma de pagos = total de la venta
  Si suma < total: badge rojo "Falta ARS $X.XXX"
  Si suma > total: badge verde "Vuelto ARS $X.XXX"
- Si hay parte de pago: se muestra automáticamente como método aplicado

SECCIÓN 4 — Botones de acción:
- "Guardar presupuesto" (secondary): solo guarda, sin descontar stock
- "Confirmar venta" (primary, azul marino): guarda + descuenta stock
  Ambos: disabled durante la acción + spinner

Estado del componente (useState/useReducer):
  type CartItem = { varianteId, unidadId?, descripcion, qty, precioUsd, precioArs, descPct, subtotalUsd, subtotalArs }
  type PagoItem = { metodoPagoId, montoArs, montoUsd }
  type CartState = { cliente: Cliente | null; items: CartItem[]; pagos: PagoItem[]; parteDePago?: ParteDePagoData }

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** UI del POS completa + carrito funciona en cliente + cálculos en tiempo real.

---

### Paso 12c — Ventas: Server Actions + Ticket + Detalle
**Skills:** [postgres-patterns] | [security-review] | [pdf] | [error-handling] | [print-styles]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, postgres-patterns, security-review, pdf, error-handling, print-styles]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Conectar el POS del Paso 12b con las Server Actions y crear las páginas de soporte.

1. Server Actions en lib/actions/ventas.ts:

const itemVentaSchema = z.object({
  variante_id: z.string().uuid(),
  unidad_serializada_id: z.string().uuid().optional(),
  cantidad: z.number().int().positive(),
  precio_lista_usd: z.number().positive(),
  precio_lista_ars: z.number().positive(),
  descuento_porcentaje: z.number().min(0).max(100),
  precio_final_usd: z.number().positive(),
  precio_final_ars: z.number().positive(),
  precio_costo_usd: z.number().optional(),
})

const pagoVentaSchema = z.object({
  metodo_pago_id: z.string().uuid(),
  monto_ars: z.number().optional(),
  monto_usd: z.number().optional(),
})

const ventaSchema = z.object({
  cliente_id: z.string().uuid().optional(),
  deposito_id: z.string().uuid(),
  tipo_cambio_id: z.string().uuid(),
  moneda_base: z.enum(['ARS','USD']),
  total_usd: z.number().positive(),
  total_ars: z.number().positive(),
  lista_precio_id: z.string().uuid().optional(),
  notas: z.string().optional(),
  items: z.array(itemVentaSchema).min(1),
  pagos: z.array(pagoVentaSchema).min(1),
  parte_de_pago: z.object({
    imei: z.string().optional(),
    descripcion: z.string(),
    condicion: z.enum(['nuevo','excelente','muy_bueno','bueno','regular','para_reparar']),
    valor_usd: z.number().positive(),
    cliente_id: z.string().uuid(),
  }).optional(),
})

guardarPresupuesto(datos: z.infer<typeof ventaSchema>):
- Validar Zod
- Generar numero_presupuesto (PRS-XXXXX, auto-incremental)
- Insertar presupuestos + items_presupuesto
- NO descontar stock
- log_actividad → revalidate → ActionResult<{ id: string }>

confirmarVenta(datos):
- Validar Zod
- Verificar que existe TC del día (si no → error)
- Para cada ítem serializado: verificar estado = 'disponible'
- Para cada ítem: verificar stock suficiente
- Verificar descuentos vs máximos del rol
  Si algún ítem supera el máximo → crear aprobacion_descuento pendiente → error especial
- USAR LA FUNCIÓN RPC del Paso 2b (confirmar_venta) para la transacción atómica:
  // Con el cliente JS de Supabase, las transacciones reales solo son posibles via RPC.
  // Llamar así desde la Server Action:
  const { data, error } = await supabase.rpc('confirmar_venta', {
    p_datos: {
      cliente_id: datos.clienteId,
      deposito_id: datos.depositoId,
      usuario_vendedor_id: usuarioActual.id,
      tipo_cambio_id: tc.id,
      tipo_cambio_valor_ars: tc.valor_ars,
      moneda_base: 'USD',
      subtotal_usd: datos.subtotalUsd,
      subtotal_ars: datos.subtotalArs,
      total_usd: datos.totalUsd,
      total_ars: datos.totalArs,
      items: datos.items,
      pagos: datos.pagos,
    }
  })
  if (error || !data?.success) return { error: data?.error ?? error?.message ?? 'Error al confirmar' }
  // La RPC maneja internamente: ventas + items + stock + movimientos + caja + log
  // Todo en una transacción atómica: si falla cualquier paso → rollback completo

- DESPUÉS de la RPC (estas operaciones pueden ir en la Action, no en la RPC):
  * Si items tienen garantia_meses > 0: INSERT garantias_cliente
  * Si hay parte de pago: INSERT partes_de_pago + nueva unidad_serializada
- revalidatePath('/ventas', '/inventario', '/caja', '/dashboard')
- ActionResult<{ id: string; numero: string }>

2. Ticket de venta (componente imprimible):
Crear app/(dashboard)/ventas/[id]/ticket/page.tsx:
- HTML/CSS puro, sin librerías externas
- Optimizado para impresión: @media print oculta sidebar/header
- Diseño:
  * Header: nombre del negocio, depósito, dirección
  * Subheader: N° venta, fecha/hora, vendedor
  * Cliente: nombre, DNI (si tiene)
  * Tabla de ítems: descripción, IMEI (si aplica), qty, precio, descuento, total
  * Sección de pagos: método y monto
  * Totales: subtotal, descuento, TOTAL USD, TOTAL ARS, TC usado
  * Footer: "Gracias por su compra"
- Botón "Imprimir" (window.print) visible solo en pantalla
- Botón "WhatsApp" que genera link wa.me con el número del cliente

3. Detalle de venta (app/(dashboard)/ventas/[id]/page.tsx):
- PageHeader con número de venta + StatusBadge del estado
- Cards: datos generales, cliente, items, pagos, garantías generadas
- Acciones:
  * Presupuesto → "Confirmar venta" (si el TC cambió: aviso con diferencia ARS)
  * Confirmada → "Marcar como entregada"
  * No entregada → "Cancelar" (solo admin, con confirmación y motivo)
- Link al ticket imprimible

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** venta end-to-end funciona + stock actualizado + ticket imprimible + garantías creadas.

---

### Paso 13 — Presupuestos
**Skills:** [frontend-design] | [postgres-patterns] | [pdf] | [print-styles]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, pdf, accessibility, print-styles, error-handling, performance]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Crear app/(dashboard)/presupuestos/.
Reutilizar componentes del carrito del Paso 12b.

page.tsx — Listado:
- Tabla paginada cursor-based: N°, cliente/nombre libre, vendedor, total USD, estado, vigencia, días restantes
- Filtros: estado, vendedor, rango de fechas
- Estadísticas del mes:
  * Total enviados | Convertidos (%) | Rechazados (%) | Tasa de conversión
- Botón "Nuevo presupuesto" → /presupuestos/nueva

nueva/page.tsx:
- Reutilizar el carrito de Paso 12b adaptado:
  * Cliente puede ser anónimo (campo nombre libre + teléfono)
  * Agregar: vigencia_hasta (date picker) + canal_envio
  * NO mostrar sección de pagos (un presupuesto no tiene pagos)
  * NO mostrar sección de parte de pago
- Botón "Generar presupuesto" → guardarPresupuesto() del Paso 12c

[id]/page.tsx — Detalle y seguimiento:
- Datos del presupuesto + items (sin editar)
- Sección de seguimiento:
  * Timeline visual de estados
  * Cambiar estado con botones contextuales:
    enviado → visto → en_negociacion
  * Si rechazado: Modal con campos:
    motivo_rechazo (select) + competidor (búsqueda opcional) + precio_competencia_usd
    Al guardar: también crear observacion_competencia básica (para Fase 2)

- Botón "Convertir a venta" (si aceptado o en_negociacion):
  * Verificar stock de todos los ítems
  * Si TC cambió: card informativo "El TC cambió de $X a $Y — el total ARS varió de $A a $B"
  * Modal de confirmación → invocar confirmarVenta() del Paso 12c
  * Marcar presupuesto como 'convertido'

- Generar PDF usando skill pdf:
  * Encabezado con datos del negocio
  * Cliente (o nombre libre)
  * Tabla de ítems con precios USD y ARS
  * TC utilizado, vigencia
  * Nota de pie: "Precios válidos hasta [vigencia]"
  * Descarga directa

- Botón "Enviar por WhatsApp":
  * Generar link: wa.me/{telefono}?text=Hola {nombre}, te comparto el presupuesto...
  * Incluir en el texto el total USD y la vigencia

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** presupuesto → PDF → conversión a venta con aviso de TC funciona.

---

### Paso 14 — Productos usados
**Skills:** [frontend-design] | [postgres-patterns]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, accessibility, error-handling]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Crear app/(dashboard)/usados/ con tabs: Catálogo de Defectos | Equipos en Stock | Compras

Tab Catálogo de Defectos:
- Tabla: nombre, categoría (Badge), severidad (Badge coloreado), reduce USD, alerta
  Severidades: informativo=gris, leve=verde, moderado=amarillo, grave=naranja, bloqueante=rojo
- ABM con Modal + validación Zod:
  const defectoSchema = z.object({
    nombre: z.string().min(3),
    categoria_detalle: z.enum(['pantalla','carcasa','bateria','camara','audio','biometria','conectividad','accesorios','software','otro']),
    severidad: z.enum(['informativo','leve','moderado','grave','bloqueante']),
    reduce_precio_sugerido_usd: z.number().min(0),
    requiere_alerta_venta: z.boolean(),
  })

Tab Equipos en Stock:
- SearchInput por IMEI
- Filtros: condición, depósito
- Tabla paginada cursor-based: IMEI, variante, condición (Badge), costo total USD, precio sugerido USD, margen estimado %
- Click en IMEI → Drawer completo:
  * Header: IMEI + condición + StatusBadge
  * Precios: costo adquisición + Σ costos reparación = COSTO TOTAL
    Precio sugerido: input editable (con botón "Calcular automático")
    Margen actual: calculado en tiempo real
    Si margen < margen_minimo_alerta_pct: badge ⚠️ "Margen bajo"
  * Lista de defectos con foto:
    Cada defecto: nombre, severidad (Badge), descripción adicional
    Si hay bloqueante: banner rojo "NO VENDIBLE — Resolver primero"
  * Botón "Agregar defecto":
    Select del catálogo → severidad real → descripción → upload foto (Supabase Storage 'usados-fotos')
  * Historial de movimientos

Función calcularPrecioSugerido(unidad):
  base = precio_lista_minorista_usd del modelo (si existe)
  factores = { excelente: 0.70, muy_bueno: 0.60, bueno: 0.50, regular: 0.35 }
  descuento_defectos = Σ(defecto.reduce_precio_sugerido_usd)
  sugerido = (base * factores[condicion]) - descuento_defectos
  return max(sugerido, costo_total * 1.10)  // mínimo 10% de margen

Tab Compras de Usados:
- Formulario con checklist legal obligatorio (5 checkboxes):
  Si alguno sin marcar: los campos avanzan igual pero se registra la excepción
  const compraUsadaSchema = z.object({
    proveedor_id: z.string().uuid().optional(),
    nombre_vendedor: z.string().optional(),
    dni_vendedor: z.string().optional(),
    telefono_vendedor: z.string().optional(),
    tipo_cambio_id: z.string().uuid(),
    metodo_pago_id: z.string().uuid(),
    equipos: z.array(z.object({
      descripcion: z.string().min(3),
      variante_id: z.string().uuid().optional(),
      imei: z.string().min(10),
      precio_usd: z.number().positive(),
      condicion: z.enum(['excelente','muy_bueno','bueno','regular','para_reparar']),
    })).min(1),
  })

Server Actions lib/actions/usados.ts:
- agregarDefecto(unidadId, datos): Zod → insertar → calcular nuevo precio sugerido → revalidate
- registrarCompraUsados(datos): crear unidades_serializadas por cada equipo → actualizar stock → log
- calcularPrecioSugeridoAction(unidadId): ActionResult<{ sugerido: number }>

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** defectos registrables + precio sugerido automático + compras de usados con checklist.

---

### Paso 15 — Separas y reservas con seña
**Skills:** [frontend-design] | [postgres-patterns] | [error-handling] | [accessibility]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, error-handling, accessibility]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Crear app/(dashboard)/separas/.

page.tsx — Listado:
- Cards resumen arriba: activas, vencen hoy (rojo), vencen en ≤3 días (amarillo)
- SearchInput + filtros: estado, depósito, rango de fechas
- Tabla paginada cursor-based: N°, cliente, producto (+ IMEI si aplica),
  precio USD acordado, seña USD, saldo USD, vencimiento, días restantes, estado (StatusBadge)
- Alertas visuales en la fila:
  * vence hoy: fondo rojo suave + badge rojo
  * vence ≤3 días: fondo amarillo suave + badge amarillo
- Botón "Nueva sepa" → /separas/nueva

nueva/page.tsx — Crear sepa:
const sepaSchema = z.object({
  cliente_id: z.string().uuid(),
  deposito_id: z.string().uuid(),
  variante_id: z.string().uuid(),
  unidad_serializada_id: z.string().uuid().optional(),
  precio_acordado_usd: z.number().positive(),
  monto_seña_usd: z.number().positive(),
  metodo_pago_id: z.string().uuid(),
  fecha_vencimiento: z.string().refine(d => new Date(d) > new Date(), 'La fecha debe ser futura'),
  politica_seña_vencida: z.enum(['reintegrar','retener','credito_cuenta']),
})

UI:
- Selector de cliente (SearchInput igual al POS)
- SearchInput de variante → si serializado: select de IMEI disponible
  Al seleccionar IMEI: mostrar info del equipo + precio sugerido
- Precio acordado USD: input con recalculador ARS en tiempo real (TC del día)
  Nota informativa: "El precio ARS al retirar se calculará con el TC de ese día"
- Monto de seña USD + equivalente ARS referencial
- Saldo pendiente calculado: precio_acordado - monto_seña
- Vencimiento: datepicker con fecha sugerida (hoy + sepa_dias_vencimiento)
- Política de seña vencida: radio buttons con explicación de cada opción
- Método de pago de la seña (select de metodos_pago)

Server Action crearSepa(datos):
- Validar Zod
- Verificar stock disponible / IMEI disponible
- Calcular precio_acordado_ars = precio_usd × TC_hoy
- Calcular monto_seña_ars y saldo_pendiente_*
- Generar numero_sepa (SEP-XXXXX)
- INSERT separas + pagos_sepa
- UPDATE unidades_serializadas SET estado='reservado', sepa_id=id
- UPDATE stock SET cantidad_reservada += 1
- INSERT movimientos_caja si hay sesión abierta
- Crear novedades_turno:
  * Si días_hasta_vencimiento ≤ sepa_dias_alerta_previo: tipo 'sepa_vence_hoy', urgente
- log_actividad → revalidate → ActionResult<{ id, numero }>

[id]/page.tsx — Detalle y acciones:
Sección "Concretar venta":
- Saldo pendiente USD
- TC del día actual vs TC de la seña → diferencia ARS informativa
- Precio ARS recalculado al TC de hoy
- Botón "Concretar" → confirmarVenta() adaptado:
  * Los pagos_sepa cuentan como pago parcial de la venta
  * La venta se genera con tipo_cambio del día de concreción
  * UPDATE separas SET estado='concretada', tipo_cambio_concrecion_id=tc_hoy
  * UPDATE unidades_serializadas SET estado='vendido', sepa_id=null

Sección "Cancelar sepa" (solo admin):
- Confirmación con motivo
- Según política:
  * reintegrar: nota informativa de devolución (no automático)
  * retener: log de retención
  * credito_cuenta: INSERT movimientos_cuenta_corriente
- UPDATE separas SET estado='cancelada_*'
- UPDATE unidades_serializadas SET estado='disponible', sepa_id=null
- UPDATE stock SET cantidad_reservada -= 1
- log_actividad

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** sepa completa + IMEI bloqueado + concreción con TC del día + cancelación con política.

---

### Paso 16 — Demanda no satisfecha
**Skills:** [frontend-design] | [postgres-patterns]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, error-handling]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

1. REGISTRO RÁPIDO en el POS (app/(dashboard)/ventas/nueva/):
   En la sección de búsqueda de productos, agregar botón discreto:
   "¿No encontraste lo que buscabas? → Registrar pedido sin stock"
   Abre un Modal simple:
   const demandaRapidaSchema = z.object({
     descripcion_libre: z.string().min(3),
     variante_id: z.string().uuid().optional(),
     estado: z.enum(['sin_stock','no_catalogado','precio_no_acordado']),
     presupuesto_cliente_usd: z.number().positive().optional(),
     nombre_cliente_libre: z.string().optional(),
     telefono_cliente_libre: z.string().optional(),
     condicion_buscada: z.enum(['nuevo','usado','cualquiera']),
     canal_contacto_preferido: z.enum(['whatsapp','llamada','cualquiera']),
   })
   Server Action: crearDemanda(datos) — 1 click, no interrumpe la venta

2. MÓDULO COMPLETO en app/(dashboard)/demanda/:

page.tsx:
- Panel de estadísticas (cards azul marino):
  * Top 5 productos más pedidos sin stock (con cantidad)
  * Tasa de recuperación del mes (en_espera → vendido %)
  * Monto potencial perdido (Σ presupuesto_cliente × cantidad)
  * Motivo de pérdida más frecuente

- SearchInput + filtros: estado, marca, categoría, condición buscada, rango de fechas
- Tabla paginada cursor-based: fecha, producto, estado (StatusBadge), cliente, presupuesto USD, canal
- Click en fila → Drawer:
  * Datos completos de la demanda
  * Cambiar estado: select + motivo (si perdido)
  * Si perdido con competidor: campo competidor_id (para inteligencia competitiva)
  * Si vendido: vincular a venta real (búsqueda por número de venta)

Trigger automático en lib/actions/inventario.ts (dentro de recibirMercaderia):
- Después de actualizar stock, buscar demandas con:
  variante_id = el recibido AND estado = 'en_espera'
- Por cada demanda encontrada:
  → INSERT novedades_turno tipo 'llamar_cliente', prioridad urgente
     titulo: "Llegó stock — llamar a {nombre_cliente}"
     descripcion: "Pedía {descripcion} | Tel: {telefono} | Canal: {canal}"

Server Actions lib/actions/demanda.ts:
- crearDemanda(datos): Zod → generar numero_demanda → INSERT → ActionResult
- actualizarEstadoDemanda(id, estado, extras)

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** registro rápido en POS + módulo con estadísticas + trigger automático al recibir stock.

---

### Paso 17 — Novedades entre turnos
**Skills:** [frontend-design] | [postgres-patterns]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, accessibility, error-handling]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

DISEÑO: prioridades con colores semánticos: urgente=rojo, normal=azul, informativa=gris.

1. BRIEFING AL INICIAR SESIÓN:
   En app/(dashboard)/layout.tsx: después de cargar usuario, verificar novedades pendientes
   Si hay al menos 1 urgente → mostrar modal/overlay de briefing antes del dashboard
   Si solo normales/informativas → mostrar badge en el sidebar

   BriefingModal (components/modules/novedades/BriefingModal.tsx):
   - Overlay semi-transparente, modal azul marino claro
   - Lista ordenada: urgentes primero
   - Cada novedad: ícono + tipo + título + descripción + link al objeto relacionado
   - Botones: "Marcar vista" (individual) y "Marcar todas como vistas"
   - Las urgentes: solo admin puede marcarlas como resueltas (no solo vistas)

2. BADGE EN SIDEBAR:
   Junto al link "Novedades": count de urgentes (rojo) + normales (azul)

3. MÓDULO COMPLETO en app/(dashboard)/novedades/:
   - Filtros: prioridad, tipo, estado, fecha
   - Tabla: prioridad (Badge), tipo, título, descripción, objeto relacionado (link), estado, quién la creó
   - Botón "Nueva novedad manual":
     const novedadSchema = z.object({
       tipo: z.enum(['cliente_viene','equipo_listo','llamar_cliente','mercaderia','tarea_admin','otro']),
       prioridad: z.enum(['urgente','normal','informativa']),
       titulo: z.string().min(3).max(100),
       descripcion: z.string().optional(),
       sepa_id: z.string().uuid().optional(),
       venta_id: z.string().uuid().optional(),
     })
   - Admin puede crear tipo 'tarea_admin' para todo el equipo del depósito

4. NOVEDADES AUTOMÁTICAS — agregar a Server Actions existentes:

   En cargarTipoCambio():
   → crearNovedad({ tipo:'precio_actualizado', prioridad:'informativa',
       titulo:'TC actualizado: $X ARS/USD', deposito_id: todos })

   En recibirMercaderia() si stock queda <= stock_minimo:
   → crearNovedad({ tipo:'mercaderia', prioridad:'urgente',
       titulo:'Stock bajo: [variante]', deposito_id })

   En crearSepa() si vencimiento_dias <= sepa_dias_alerta_previo:
   → crearNovedad({ tipo:'sepa_vence_hoy', prioridad:'urgente',
       titulo:'Sepa [SEP-XXXXX] vence en X días', sepa_id, deposito_id })

   En solicitarAjuste() si requiere aprobación:
   → crearNovedad({ tipo:'tarea_admin', prioridad:'urgente',
       titulo:'Ajuste de stock pendiente de aprobación', deposito_id })

5. ESCALADO AL CERRAR CAJA (agregar en cerrarCaja()):
   UPDATE novedades_turno SET estado='escalada'
   WHERE deposito_id = ? AND estado IN ('pendiente','vista') AND prioridad = 'urgente'

lib/actions/novedades.ts:
- crearNovedad(datos): función utilitaria llamada desde todos los módulos
- marcarVista(id), marcarResuelta(id, usuarioId)

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** briefing aparece al login con urgentes + novedades automáticas funcionan + escalado al cerrar caja.

---

### Paso 18 — Módulo de vendedores
**Skills:** [frontend-design] | [postgres-patterns]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, accessibility, error-handling, performance]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Crear app/(dashboard)/vendedores/.
Un vendedor ve solo SUS métricas. Admin ve todos.

page.tsx — Vista general (admin):
- Ranking del mes: tabla de vendedores ordenada por total USD
  Columnas: #, nombre, ventas (#), facturación USD, margen prom %, ticket prom USD, avance vs meta (%)
- Período: selector mes/año

Mi perfil (vista del vendedor — /vendedores/mi-perfil):
- Card de avance vs objetivo:
  * Meta del mes: USD X.XXX
  * Facturado: USD Y.YYY
  * Progreso: barra azul marino con porcentaje
  * Cantidad de ventas: N / meta_cantidad_ventas
- Métricas del mes: ticket promedio, descuento promedio %, margen promedio %
- Mis ventas del mes: listado paginado cursor-based

[id]/page.tsx — Perfil de un vendedor (admin):
Tabs: Métricas | Objetivos | Ventas

Tab Métricas:
- Cards: ventas del mes, facturación USD, margen %, ticket promedio
- Gráfico simple de ventas por semana (sin librerías externas, barras CSS puras)
- Comparativo con el mes anterior

Tab Objetivos:
- Historial de objetivos por período
- Formulario nuevo objetivo (Modal):
  const objetivoSchema = z.object({
    periodo: z.string().refine(d => /^\d{4}-\d{2}-01$/.test(d), 'Formato YYYY-MM-01'),
    meta_monto_usd: z.number().positive(),
    meta_cantidad_ventas: z.number().int().positive(),
    comision_porcentaje: z.number().min(0).max(100).optional(),
  })

Tab Ventas:
- Listado paginado cursor-based de ventas del período
- Filtros: estado, canal

Las métricas se calculan desde la tabla ventas en tiempo real (Server Component).
No hay tabla precalculada en Fase 1 — en Fase 2 se agrega metricas_vendedor_diarias.

Queries eficientes con índices ya creados (idx_ventas_vendedor).

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** vendedor ve sus métricas + admin ve el ranking + objetivos cargables.

---

### Paso 18.5 — QA: Checklist de flujos críticos
**Skills:** [fix] | [security-review] | [testing]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, fix, security-review, testing]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Verificar y documentar el estado de los flujos críticos de la Fase 1.
Ejecutar cada flujo manualmente y reportar resultados.

FLUJO 1 — Venta completa:
□ Cargar TC del día si no existe
□ Crear cliente nuevo desde el POS
□ Agregar producto serializado (buscar por IMEI)
□ Aplicar descuento (dentro del límite)
□ Agregar método de pago (efectivo ARS)
□ Confirmar venta → verificar:
  - Número de venta generado (V-XXXXX)
  - Stock decrementado (unidad_serializada → estado 'vendido')
  - Garantía creada en garantias_cliente
  - Movimiento en caja (si sesión abierta)
  - Log en log_actividad
□ Acceder al ticket imprimible

FLUJO 2 — Presupuesto → Venta:
□ Crear presupuesto desde /presupuestos/nueva
□ Generar PDF del presupuesto
□ Cambiar estado a 'aceptado'
□ Convertir a venta (con aviso de TC si cambió)
□ Verificar que el presupuesto queda 'convertido'

FLUJO 3 — Sepa completa:
□ Crear sepa con IMEI específico
□ Verificar que el IMEI queda 'reservado' en el inventario
□ Verificar que la seña entra a caja
□ Concretar sepa: verificar que la venta se genera correctamente
□ Verificar que el IMEI pasa a 'vendido'

FLUJO 4 — Demanda no satisfecha:
□ Registrar demanda rápida desde el POS
□ Ingresar stock de esa variante (recepción)
□ Verificar que se crea novedad_turno 'llamar_cliente'

FLUJO 5 — Parte de pago (trade-in):
□ Iniciar venta con parte de pago desde el POS
□ Evaluar el equipo del cliente: condición, IMEI, defectos
□ Asignar valor al parte de pago en USD
□ Verificar que el saldo restante se descuenta del total de venta
□ Confirmar venta → verificar:
  - El equipo del cliente queda como unidad_serializada nueva (usada)
  - Estado inicial: 'disponible' con condición evaluada
  - El parte_de_pago queda con estado 'aceptado' y venta_id asignado
  - El monto del parte aparece como método de pago en la venta

FLUJO 6 — Seguridad:
□ Vendedor NO puede acceder a /precios
□ Vendedor NO puede acceder a /configuracion
□ Vendedor NO puede aprobar ajuste de stock propio
□ TC del día faltante bloquea el formulario de venta

FLUJO 6 — Datos:
□ npx tsc --noEmit → 0 errores
□ npm run build → compila sin errores
□ Sin secrets hardcodeados en el código
□ proxy.ts existe en raíz y tiene contenido correcto
□ Archivos inmutables del CLAUDE.md sección 6 tienen 20+ líneas

Reportar cada ítem como: ✅ OK | ❌ FALLA: [descripción] | ⚠️ PARCIAL: [descripción]
Corregir los que fallen antes de marcar el paso como completado.
```

**Criterio de avance:** todos los flujos críticos ✅ + TypeScript limpio + build exitoso.

---

### Paso 19 — Dashboard principal completo
**Skills:** [frontend-design] | [postgres-patterns] | [performance] | [animations]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, frontend-design, postgres-patterns, performance, animations]

ANTES de empezar, verificar archivos inmutables del CLAUDE.md sección 6.

Completar app/(dashboard)/dashboard/page.tsx.
Server Component con Suspense por sección. Fetches en paralelo (Promise.all).

DISEÑO: fondo blanco predominante, cards con borde sutil, elementos de marca en azul marino.

Sección 1 — Alertas críticas (siempre visible si aplica):
- Sin TC del día: banner azul marino "⚠️ Sin tipo de cambio — cargar ahora" + botón link
- N novedades urgentes: banner rojo con count + link a /novedades
- N separas vencen hoy: banner naranja con lista rápida + links

Sección 2 — Métricas del día (cards en fila):
Card 1: Ventas del día
  Total en USD (grande, azul marino) | Total en ARS | Cantidad de tickets
Card 2: Caja actual
  Saldo ARS (grande) | Saldo USD | Estado (abierta/cerrada con badge)
Card 3: Pipeline
  Presupuestos activos | Separas activas | Monto total en USD
Card 4: Mi avance (si rol = vendedor)
  Barra de progreso vs meta + porcentaje

Sección 3 — Alertas de inventario (solo admin):
- Productos con stock = 0: lista con links a /inventario
- Productos con stock bajo: ídem
- Si todo OK: card verde "Stock en orden"

Sección 4 — Novedades recientes:
- Últimas 5 novedades pendientes (solo del depósito del usuario)
- Link "Ver todas" → /novedades

Sección 5 — Actividad reciente:
- Últimas 5 ventas confirmadas del día (o últimas 48hs si hoy no hay)
- Cada ítem: cliente, variante, total USD, estado, hace cuánto tiempo

Sección 6 — Accesos rápidos:
- Botones grandes con ícono:
  🛍️ Nueva venta | 📋 Nuevo presupuesto | 🤝 Nueva sepa | 💱 Cargar TC

Cargar en paralelo:
  const [tc, ventas, caja, presupuestos, separas, novedades, stock] =
    await Promise.all([...])

Usar <Suspense fallback={<SkeletonCard />}> por sección.

Ejecutar npx tsc --noEmit al finalizar.
```

**Criterio de avance:** dashboard informativo con datos reales + alertas activas + accesos rápidos.

---

### Paso 20 — Deploy en Vercel
**Skills:** [fix] | [security-review] | [error-handling]

**Prompt para Claude Code:**
```
[Skills activas: proyecto-patterns, fix, security-review, error-handling]

Preparar la Fase 1 para deploy en Vercel.

1. Lint y formato final:
   npx eslint . --fix
   npx prettier --write .
   npx tsc --noEmit   ← debe dar 0 errores
   npm run build      ← debe compilar sin errores

2. Verificación de seguridad:
   □ Sin API keys ni secrets hardcodeados
   □ .env.local en .gitignore
   □ RLS activo en todas las tablas
   □ proxy.ts existe en la raíz
   □ No existe middleware.ts (solo proxy.ts)
   □ Archivos inmutables del CLAUDE.md tienen 20+ líneas

3. Verificar archivos utilitarios creados en Paso 1:
   □ lib/utils/actions.ts — ActionResult, actionSuccess, actionError
   □ lib/utils/errors.ts — ErrorNegocio, ErrorSinTC, manejarError
   □ lib/utils/logger.ts — logger.info/warn/error/accion
   □ lib/utils/money.ts — USD, ARS, ExchangeRate, calcularARS
   □ lib/env.ts — validación de variables de entorno
   □ lib/supabase/queries/tipo-cambio.ts — requireTCDelDia()
   Si alguno falta → crearlo antes de continuar con el deploy.

3. Crear .env.example:
   NEXT_PUBLIC_SUPABASE_URL=
   NEXT_PUBLIC_SUPABASE_ANON_KEY=

4. Crear CHANGELOG.md con lo entregado en Fase 1.

5. README.md completo:
   ## Variables de entorno
   ## Cómo correr localmente
   ## Cómo conectar Supabase
   ## Cómo hacer el deploy en Vercel
   ## Configuración post-deploy (CRÍTICO):
      En Supabase → Authentication → URL Configuration:
      - Agregar URL de Vercel en "Site URL"
      - Agregar URL de Vercel en "Redirect URLs"
      En Supabase → Authentication → Providers:
      - Email: desactivar "Confirm email" para testing inicial
      - Al crear usuarios: tildar "Auto Confirm User"
   ## Estrategia de backup:
      Este sistema requiere plan Supabase Pro para backups automáticos diarios.
      Backup manual semanal recomendado:
        Supabase Dashboard → Settings → Backups → Download
        O via CLI: supabase db dump -f backup_YYYY-MM-DD.sql
      Datos críticos: ventas, clientes, stock, separas, tipos_cambio_dolar
      Frecuencia recomendada: diario automático (Pro) + semanal manual

Reportar cualquier error o warning encontrado.
```

**Criterio de avance:** build limpio + deploy exitoso + login funciona en producción + Supabase configurado.

---

## FASE 2 — Gestión Avanzada
**Estado:** 🔴 No iniciada — iniciar después de validar Fase 1 con usuarios reales en producción.

| Paso | Módulo | Skills |
|---|---|---|
| P21 | Órdenes de compra completas | proyecto-patterns, frontend-design, postgres-patterns, error-handling |
| P22 | Transferencias Depósito ↔ Tienda (3 estados) | proyecto-patterns, frontend-design, postgres-patterns, error-handling |
| P23 | Trazabilidad IMEI end-to-end | proyecto-patterns, postgres-patterns |
| P24 | Costo real del usado (COGS + reparaciones) | proyecto-patterns, frontend-design, postgres-patterns, typescript-advanced |
| P25 | Actas digitales de recepción con PDF | proyecto-patterns, frontend-design, pdf, print-styles |
| P26 | Devoluciones y cambios formalizados | proyecto-patterns, frontend-design, postgres-patterns, error-handling |
| P27 | Servicio técnico completo | proyecto-patterns, frontend-design, postgres-patterns, error-handling |
| P28 | Garantías automáticas (mejorar las del Paso 12c) | proyecto-patterns, postgres-patterns, error-handling |
| P29 | Garantías de proveedor (reclamo al distribuidor) | proyecto-patterns, frontend-design, postgres-patterns |
| P30 | Inteligencia competitiva | proyecto-patterns, frontend-design, postgres-patterns |
| P31 | Score de performance de proveedores | proyecto-patterns, postgres-patterns |
| P32 | Precios de mercado + depreciación en stock | proyecto-patterns, frontend-design, postgres-patterns, performance |
| P33 | Eventos de mercado para estacionalidad | proyecto-patterns, frontend-design, postgres-patterns |
| P34 | Recordatorios de seguimiento CRM | proyecto-patterns, frontend-design, postgres-patterns |
| P35 | Métricas diarias de vendedor (tabla precalculada) | proyecto-patterns, postgres-patterns, performance |
| P36 | Comisiones y liquidación de vendedores | proyecto-patterns, frontend-design, postgres-patterns, typescript-advanced |
| P37 | Reportes ERP core | proyecto-patterns, frontend-design, postgres-patterns, xlsx, performance |
| P38 | Etiquetas de precio para exhibición | proyecto-patterns, frontend-design, pdf, print-styles |

---

## FASE 3 — CRM e Inteligencia Comercial
**Estado:** 🔴 No iniciada — iniciar después de validar Fase 2.

| Paso | Módulo | Skills |
|---|---|---|
| P39 | Segmentación de clientes | proyecto-patterns, frontend-design, postgres-patterns, performance |
| P40 | Historial de interacciones CRM | proyecto-patterns, frontend-design, postgres-patterns |
| P41 | Dashboard de inteligencia comercial | proyecto-patterns, frontend-design, postgres-patterns, performance, animations |
| P42 | Reportes de competencia | proyecto-patterns, frontend-design, postgres-patterns, xlsx |
| P43 | v_rotacion_specs — rotación por specs técnicas | proyecto-patterns, postgres-patterns, typescript-advanced |
| P44 | v_elasticidad_precio — elasticidad precio-demanda | proyecto-patterns, postgres-patterns, typescript-advanced |
| P45 | v_ciclo_compra — upgrade proactivo por cliente | proyecto-patterns, frontend-design, postgres-patterns, performance |
| P46 | Análisis de estacionalidad con eventos de mercado | proyecto-patterns, frontend-design, postgres-patterns |

---

## FASE 4 — Automatización
**Estado:** 🔴 No iniciada — iniciar después de validar Fase 3.

| Paso | Módulo | Skills |
|---|---|---|
| P47 | API tipo de cambio automática (BCRA/Bluelytics) | proyecto-patterns, postgres-patterns, security-review, error-handling |
| P48 | WhatsApp automático (Meta Cloud API) | proyecto-patterns, whatsapp, security-review, error-handling |
| P49 | Alertas automáticas stock mínimo + garantías | proyecto-patterns, postgres-patterns, error-handling |
| P50 | Sincronización MercadoLibre (API) | proyecto-patterns, security-review, postgres-patterns, error-handling |
| P51 | ML scraping para precios_mercado_externo | proyecto-patterns, security-review, postgres-patterns |

---

## REGISTRO DE DECISIONES TÉCNICAS

> Completar a medida que el desarrollo avance. Cada decisión evita que el agente la re-discuta.

| Fecha | Decisión | Motivo |
|---|---|---|
| — | Usar proxy.ts en lugar de middleware.ts | Convención del proyecto Next.js 14 |
| — | TC del día bloquea ventas si no existe | Regla de negocio crítica |
| — | vendedor_id nunca nullable en ventas | Integridad de métricas individuales |
| — | Zod en todas las Server Actions | Validación centralizada y type-safe |
| — | Cursor-based pagination (no OFFSET) | Performance con grandes volúmenes de datos |
| — | ActionResult<T> como tipo estándar de retorno | Manejo de errores consistente |
| — | Sonner para toasts | Ligero, integrado con Next.js App Router |
| — | ERP y CRM unificados en un solo sistema | Los datos son los mismos en tiempo real — duplicarlos sería un error de diseño para este tamaño de negocio |
| — | Branded types USD/ARS para montos de dinero | Evita confundir montos ARS con USD a nivel de compilador — error frecuente en sistemas con moneda dual |
| — | manejarError() centraliza manejo de errores | Un solo punto de control: errores de negocio → mensaje directo, errores de sistema → log + mensaje genérico |
| — | unstable_cache para datos semi-estáticos | Métodos de pago, configuración, catálogo → reducen queries a Supabase dramáticamente |
| — | confirmar_venta como RPC PostgreSQL | Garantía de atomicidad: venta + stock + caja + log en una sola transacción sin posibilidad de estado roto |

---

## ERRORES RECURRENTES DETECTADOS

| Error | Causa | Solución |
|---|---|---|
| middleware.ts creado en lugar de proxy.ts | Agente usa convención antigua | Eliminar middleware.ts, crear proxy.ts con export async function proxy() |
| Dashboard da 404 | Ruta incorrecta | Mover a app/(dashboard)/dashboard/page.tsx |
| Archivos inmutables revertidos | Agente sobreescribe al crear módulos | Verificar 20+ líneas en cada archivo inmutable del CLAUDE.md |
| TC no disponible rompe cálculo ARS | No se validó existencia del TC | Verificar getTipoCambioHoy() antes de cualquier cálculo |
| Duplicados en listas al paginar | Uso de OFFSET en lugar de cursor | Usar cursor-based pagination con campo id o created_at |
| Server Action sin validación Zod | Agente olvida la convención | Cada Action debe comenzar con const data = schema.parse(formData) |
| Toast no aparece | Sonner no configurado en layout | Verificar <Toaster /> en app/layout.tsx |
| lib/utils/errors.ts no existe | Paso 1 no lo creó o fue revertido | Crear con ErrorNegocio, ErrorSinTC, manejarError() |
| Modal sin focus trap | Componente sin useEffect de teclado | Usar Modal.tsx del Paso 1.5 que ya tiene focus trap |
| Precio ARS incorrecto | Número suelto multiplicado sin branded type | Usar calcularARS(usd(precio), exchangeRate(tc)) de lib/utils/money.ts |
| Error silencioso en RPC | No se captura el caso data.success === false | Verificar siempre: if (!data?.success) return actionError(data?.error) |
| lib/env.ts no valida al iniciar | Variables de entorno leídas lazy | Importar lib/env.ts en el cliente Supabase para validar al arrancar |
| npx tsc falla con tipos de Supabase | database.types.ts desactualizado | Regenerar: npx supabase gen types typescript --project-id ID > lib/types/database.types.ts |
