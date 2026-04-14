# CLAUDE.md — ERP/CRM Pyme de Tecnología

> Este archivo es el contexto permanente del proyecto.
> Claude Code lo lee automáticamente al inicio de cada sesión.
> NO modificar salvo cambios estructurales reales en el proyecto.

---

## 1. DESCRIPCIÓN DEL NEGOCIO

Pyme de venta de tecnología: celulares nuevos y usados, accesorios, hardware de PC.
- **Tienda principal** → vende, tiene caja, atiende clientes
- **Depósito separado** → recibe mercadería, hace transferencias
- Múltiples vendedores con métricas y comisiones individuales
- Parte de pago (trade-in): cliente entrega su equipo al comprar
- Servicio técnico propio

---

## 2. STACK TÉCNICO

- Next.js 14 App Router + TypeScript (strict) + Tailwind CSS
- Supabase (PostgreSQL + Auth + Storage) + Vercel
- Validación: Zod | Toasts: Sonner | Íconos: lucide-react
- **Paleta:** Azul marino `#1E3A5F` (headers/sidebar) + Blanco `#FFFFFF` (fondo)
- Azul claro fondo: `#EFF6FF` | Azul acento: `#3B82F6`

---

## 3. CONVENCIONES — SEGUIR SIEMPRE SIN EXCEPCIÓN

### Archivos y rutas
- Auth: `app/(auth)/login/`
- Dashboard: `app/(dashboard)/[modulo]/`
- Server Actions: `lib/actions/[modulo].ts`
- Queries server-side: `lib/supabase/queries/[modulo].ts`
- Schemas Zod: `lib/validations/[modulo].ts`
- Tipos: `lib/types/index.ts` y `lib/types/enums.ts`
- Componentes UI: importar SIEMPRE desde `@/components/ui` (barrel export)

### Patrón Server Actions (OBLIGATORIO en TODAS las actions)
```typescript
// 1. Validar con Zod
const data = schema.parse(formData)  // lanza si falla

// 2. Verificar permisos
const usuario = await getUsuarioActual()
if (usuario.rol !== 'admin') return actionError('Sin permisos')

// 3. Operar (usar RPC para operaciones multi-tabla)
const { data: result, error } = await supabase.rpc('funcion_rpc', { p_datos: data })
if (!result?.success) return actionError(result?.error ?? 'Error')

// 4. Log + revalidate
await crearLog({ accion: 'crear', tabla: 'ventas', ... })
revalidatePath('/ventas')

// 5. Retornar
return actionSuccess({ id: result.id })
```

### Helper requireTCDelDia (usar en ventas, separas, compras)
```typescript
const tc = await requireTCDelDia()  // lanza 'SIN_TC_DEL_DIA' si no existe
// Capturar en la action:
// } catch (e) {
//   if ((e as Error).message === 'SIN_TC_DEL_DIA')
//     return actionError('Cargá el tipo de cambio del día')
// }
```

### Paginación (NUNCA usar OFFSET)
```typescript
let q = supabase.from('tabla').select('*').order('id').limit(20)
if (cursor) q = q.gt('id', cursor)
const { data } = await q
return { data, nextCursor: data?.length === 20 ? data[19].id : null }
```

### Loading states y toasts
```typescript
const [pending, startTransition] = useTransition()
// botón: disabled={pending}
// feedback: toast.success('OK') | toast.error(result.error)
```

---

## 4. REGLAS DE NEGOCIO CRÍTICAS

| Regla | Detalle |
|---|---|
| TC del día | Si falta → bloquear ventas. Usar `requireTCDelDia()` en toda action de precio |
| Vendedor obligatorio | `usuario_vendedor_id` en `ventas` NUNCA nullable |
| IMEIs | Estado: `disponible\|vendido\|reservado\|en_reparacion\|en_garantia_proveedor\|baja` |
| Sepa | Precio USD inmutable. ARS se recalcula al TC del día de concreción |
| Defecto bloqueante | (iCloud activo, etc.) → NO se puede vender la unidad |
| Descuento > límite | Crea `aprobaciones_descuento` pendiente y bloquea la venta |
| Transacciones | Operaciones multi-tabla → usar RPC (no llamadas JS secuenciales) |
| Numeración | Usar SEQUENCEs PostgreSQL (nunca COUNT(*)+1) |
| Paginación | Cursor-based siempre (nunca OFFSET) |

---

## 5. ARCHIVOS INMUTABLES — NUNCA TOCAR

Si alguno tiene < 20 líneas o solo `return null` → fue revertido → restaurarlo primero.

```
proxy.ts                                    ← raíz del proyecto
lib/supabase/proxy.ts
components/layout/DashboardShell.tsx
components/layout/Sidebar.tsx
components/layout/Header.tsx
app/(auth)/login/page.tsx
app/(auth)/login/_components/LoginForm.tsx
app/(auth)/login/actions.ts
app/(auth)/loading.tsx
app/(dashboard)/layout.tsx
app/(dashboard)/dashboard/page.tsx
```

---

## 6. SKILLS DISPONIBLES

```
.claude/skills/frontend-design      → UI de producción con la paleta del proyecto
.claude/skills/postgres-patterns    → SQL, RLS, índices, RPC, cursor pagination
.claude/skills/security-review      → seguridad, RLS, autenticación
.claude/skills/proyecto-patterns    → patrones específicos de ESTE proyecto
.claude/skills/pdf                  → generación de PDFs
.claude/skills/xlsx                 → exportación a Excel
.claude/skills/fix                  → lint y formato antes de commits
```

Declarar las skills al inicio de cada prompt:
`[Skills activas: frontend-design, postgres-patterns, proyecto-patterns]`

---

## 7. CHECKLIST ANTES DE CADA COMMIT

```bash
npx tsc --noEmit          # 0 errores TypeScript
npx eslint . --max-warnings 0   # 0 warnings
npm run build             # build limpio
```

Verificar que los archivos inmutables tienen > 20 líneas cada uno.
