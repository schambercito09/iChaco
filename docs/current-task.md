# current-task.md — ERP/CRM Pyme de Tecnología

> Este archivo se actualiza al inicio de CADA sesión de trabajo.
> Define el foco de la sesión actual y nada más.
> Al terminar el paso: marcar [x], anotar resultado, actualizar "Próxima sesión".

---

## SESIÓN ACTUAL

**Fecha:** 2026-04-05
**Paso activo:** Paso 2a — Schema core de Supabase
**Estado:** [ ] En progreso

### Objetivo de esta sesión
Crear el archivo CLAUDE.md en la raíz del proyecto con el contexto
completo y permanente antes de escribir cualquier línea de código.

### Prompt a ejecutar
Copiar el prompt del **Paso 0** del roadmap.md y pegarlo en Claude Code.

### Criterio de avance
CLAUDE.md creado en la raíz con todo el contenido correcto.

### Resultado (completar al terminar)
- [ ] CLAUDE.md creado
- [ ] Revisado que contiene las 6 secciones
- [ ] Notas: _______________

---

## ESTADO GENERAL DEL PROYECTO

| Fase | Estado | Paso actual |
|---|---|---|
| Fase 0 — Fundación | 🔴 No iniciada | Paso 0 |
| Fase 1 — Core MVP | 🔴 No iniciada | — |
| Fase 2 — Gestión Avanzada | 🔴 No iniciada | — |
| Fase 3 — CRM e Inteligencia | 🔴 No iniciada | — |
| Fase 4 — Automatización | 🔴 No iniciada | — |

---

## CHECKLIST FASE 0

- [✅] **P0**   CLAUDE.md del proyecto
- [✅] **P1**   Crear proyecto Next.js 14
- [✅] **P1.5** Componentes UI compartidos
- [ ] **P2a**  Schema core de Supabase
- [ ] **P2b**  Schema de negocio + RLS
- [ ] **P2c**  Datos semilla
- [ ] **P2d**  Supabase Storage
- [ ] **P3a**  Tipos TypeScript y enums
- [ ] **P3b**  Clientes Supabase + queries + hooks

---

## CHECKLIST FASE 1

- [ ] **P4**    Login y layout base
- [ ] **P5**    Tipo de cambio diario
- [ ] **P6**    Configuración del sistema y usuarios
- [ ] **P7**    Catálogo de productos
- [ ] **P8**    Precios y listas de precio
- [ ] **P9**    Inventario y stock
- [ ] **P10a**  Proveedores
- [ ] **P10b**  Clientes
- [ ] **P11**   Caja diaria
- [ ] **P12a**  Ventas: Listado
- [ ] **P12b**  Ventas: Nueva venta (UI del POS)
- [ ] **P12c**  Ventas: Server Actions + Ticket + Detalle
- [ ] **P13**   Presupuestos
- [ ] **P14**   Productos usados
- [ ] **P15**   Separas y reservas con seña
- [ ] **P16**   Demanda no satisfecha
- [ ] **P17**   Novedades entre turnos
- [ ] **P18**   Módulo de vendedores
- [ ] **P18.5** QA: Checklist de flujos críticos
- [ ] **P19**   Dashboard principal completo
- [ ] **P20**   Deploy en Vercel

---

## INVENTARIO DE SKILLS — .claude/skills/

> Todas las skills deben estar instaladas antes de arrancar el Paso 0.
> Carpeta exacta: .claude/skills/[nombre]/SKILL.md

### Skills core — usar en múltiples pasos

| Skill | Activar con | Cuándo |
|---|---|---|
| `proyecto-patterns` | `[Skills activas: proyecto-patterns]` | En TODOS los pasos |
| `postgres-patterns` | `[Skills activas: postgres-patterns]` | SQL, RLS, índices, RPC |
| `frontend-design` | `[Skills activas: frontend-design]` | Cualquier módulo con UI |
| `ui-components-reference` | `[Skills activas: ui-components-reference]` | Al usar Button, Modal, Drawer |
| `security-review` | `[Skills activas: security-review]` | Auth, RLS, secrets, deploy |
| `error-handling` | `[Skills activas: error-handling]` | Server Actions críticas |
| `fix` | `[Skills activas: fix]` | Antes de cada commit |

### Skills por módulo

| Skill | Activar con | Pasos |
|---|---|---|
| `accessibility` | `[Skills activas: accessibility]` | P1.5, P4, P12b, P15 |
| `performance` | `[Skills activas: performance]` | P9, P12a, P19 |
| `typescript-advanced` | `[Skills activas: typescript-advanced]` | P3a, P12b |
| `print-styles` | `[Skills activas: print-styles]` | P12c, P13, P38 |
| `pdf` | `[Skills activas: pdf]` | P12c, P13 |
| `xlsx` | `[Skills activas: xlsx]` | P19, P35, P37 |
| `diffs` | `[Skills activas: diffs]` | Ver cambios entre versiones |

### Skills para fases posteriores

| Skill | Activar con | Cuándo |
|---|---|---|
| `testing` | `[Skills activas: testing]` | P18.5 — QA |
| `animations` | `[Skills activas: animations]` | P19 — polish final |
| `whatsapp` | `[Skills activas: whatsapp]` | Fase 4 — Paso 48 |
| `content-creator` | `[Skills activas: content-creator]` | Marketing, fuera del ERP |

---

## REGISTRO DE SESIONES

| # | Fecha | Paso completado | Resultado | Próximo paso |
|---|---|---|---|---|
| 1 | 2026-04-05 | P0 + P1 + P1.5 | Next.js configurado + 12 componentes UI | P2a |

---

## PROBLEMAS CONOCIDOS / BLOQUEANTES

| Problema | Paso afectado | Estado | Solución aplicada |
|---|---|---|---|
| — | — | — | — |

---

## DECISIONES TOMADAS EN ESTA SESIÓN

| Decisión | Motivo |
|---|---|
| — | — |

---

## CÓMO USAR ESTE ARCHIVO

### Al iniciar una sesión
1. Actualizar la fecha
2. Confirmar el paso activo (verificar que el anterior está [x])
3. Pegar el Contexto Base del roadmap.md en Claude Code
4. Pegar el prompt del paso activo del roadmap.md en Claude Code
5. Agregar registro en la tabla de sesiones

### Al terminar una sesión
1. Marcar [x] el paso completado en los checklists
2. Anotar el resultado
3. Registrar la sesión en la tabla
4. Actualizar "Paso activo" al siguiente
5. Si tomaste decisiones técnicas → anotarlas aquí y en roadmap.md
6. Commit: `git commit -m "feat: paso N - descripción"`

### Si hay un error
1. Anotar en "Problemas conocidos"
2. Consultar "Errores recurrentes detectados" del roadmap.md
3. NO avanzar al siguiente paso hasta resolver

### Señal de alerta — archivos revertidos
Verificar que tienen más de 20 líneas:
  proxy.ts
  lib/supabase/proxy.ts
  components/layout/Sidebar.tsx
  app/(auth)/login/page.tsx
  app/(dashboard)/layout.tsx
  app/(dashboard)/dashboard/page.tsx

---

## TEMPLATE PARA PRÓXIMAS SESIONES

Copiar y completar al inicio de cada sesión nueva:

  ## SESIÓN ACTUAL

  **Fecha:** DD/MM/AAAA
  **Paso activo:** Paso N — [nombre del paso]
  **Estado:** [ ] En progreso

  ### Objetivo de esta sesión
  [descripción del objetivo]

  ### Prompt a ejecutar
  Copiar el prompt del Paso N del roadmap.md.

  ### Criterio de avance
  [criterio del paso en el roadmap]

  ### Resultado (completar al terminar)
  - [ ] [criterio 1]
  - [ ] [criterio 2]
  - [ ] npx tsc --noEmit sin errores
  - [ ] Notas: _______________
