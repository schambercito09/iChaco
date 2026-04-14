---
name: accessibility
description: Accesibilidad y usabilidad para el ERP/CRM. Usar al construir modales, drawers, tablas, formularios del POS y cualquier componente interactivo. Foco en navegación por teclado para vendedores que usan el sistema todo el día.
---

# Skill: `accessibility`
> **Activar con:** `[Skills activas: accessibility]`
> **Propósito:** Navegación por teclado, ARIA correcto y UX profesional para uso diario intensivo

---

## Por qué importa en este ERP

Los vendedores usan el sistema **muchas veces por hora** en el mostrador.
Con navegación por teclado correcta, registrar una venta es 3x más rápido que con el mouse.
Un modal sin focus trap rompe la experiencia en tablet y mobile.

---

## 1. Modales — focus trap obligatorio

```tsx
// components/ui/Modal.tsx
'use client'
import { useEffect, useRef } from 'react'

export function Modal({ open, onClose, title, children }: ModalProps) {
  const modalRef = useRef<HTMLDivElement>(null)
  const previousFocus = useRef<Element | null>(null)

  useEffect(() => {
    if (open) {
      // Guardar el foco anterior para restaurarlo al cerrar
      previousFocus.current = document.activeElement

      // Mover el foco al modal
      modalRef.current?.focus()
    } else {
      // Restaurar el foco al elemento que abrió el modal
      if (previousFocus.current instanceof HTMLElement) {
        previousFocus.current.focus()
      }
    }
  }, [open])

  // Cerrar con Escape
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && open) onClose()

      // Focus trap: Tab dentro del modal
      if (e.key === 'Tab' && open && modalRef.current) {
        const focusables = modalRef.current.querySelectorAll<HTMLElement>(
          'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        )
        const first = focusables[0]
        const last = focusables[focusables.length - 1]

        if (e.shiftKey && document.activeElement === first) {
          e.preventDefault()
          last.focus()
        } else if (!e.shiftKey && document.activeElement === last) {
          e.preventDefault()
          first.focus()
        }
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [open, onClose])

  if (!open) return null

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
      className="fixed inset-0 z-50 flex items-center justify-center"
    >
      {/* Overlay */}
      <div
        className="absolute inset-0 bg-black/50"
        onClick={onClose}
        aria-hidden="true"
      />

      {/* Contenido */}
      <div
        ref={modalRef}
        tabIndex={-1}          // necesario para que el div reciba el foco
        className="relative bg-white rounded-lg shadow-xl max-w-lg w-full mx-4 outline-none"
      >
        <div className="bg-navy text-white px-6 py-4 rounded-t-lg flex justify-between items-center">
          <h2 id="modal-title" className="text-lg font-semibold">{title}</h2>
          <button
            onClick={onClose}
            aria-label="Cerrar"
            className="text-white/80 hover:text-white"
          >
            ✕
          </button>
        </div>
        <div className="p-6">{children}</div>
      </div>
    </div>
  )
}
```

---

## 2. Tablas — ARIA para listados de datos

```tsx
// components/ui/Table.tsx
export function Table<T>({ data, columns, onRowClick, caption }: TableProps<T>) {
  return (
    <div role="region" aria-label={caption} className="overflow-x-auto">
      <table className="w-full" aria-label={caption}>
        <caption className="sr-only">{caption}</caption>
        <thead className="bg-blue-light">
          <tr>
            {columns.map(col => (
              <th
                key={col.key}
                scope="col"
                className="px-4 py-3 text-left text-xs font-semibold text-navy uppercase"
              >
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.length === 0 ? (
            <tr>
              <td colSpan={columns.length} className="text-center py-12 text-gray-500">
                Sin resultados
              </td>
            </tr>
          ) : data.map((row, i) => (
            <tr
              key={(row as any).id ?? i}
              onClick={() => onRowClick?.(row)}
              onKeyDown={e => e.key === 'Enter' && onRowClick?.(row)}
              tabIndex={onRowClick ? 0 : undefined}
              role={onRowClick ? 'button' : undefined}
              aria-label={onRowClick ? `Ver detalle` : undefined}
              className={`
                border-t border-gray-100
                ${onRowClick ? 'cursor-pointer hover:bg-blue-light focus:bg-blue-light focus:outline-none focus:ring-2 focus:ring-inset focus:ring-navy' : ''}
                ${i % 2 === 1 ? 'bg-gray-50' : 'bg-white'}
              `}
            >
              {columns.map(col => (
                <td key={col.key} className="px-4 py-3 text-sm">
                  {col.render ? col.render(row) : (row as any)[col.key]}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
```

---

## 3. Formularios — labels y errores correctos

```tsx
// components/ui/Input.tsx
export function Input({ name, label, error, helperText, required, ...props }: InputProps) {
  const id = `input-${name}`
  const errorId = `error-${name}`
  const helpId = `help-${name}`

  return (
    <div className="space-y-1">
      <label
        htmlFor={id}
        className="block text-sm font-medium text-gray-700"
      >
        {label}
        {required && <span aria-hidden="true" className="text-red-500 ml-1">*</span>}
        {required && <span className="sr-only"> (requerido)</span>}
      </label>

      <input
        id={id}
        name={name}
        aria-describedby={[error ? errorId : null, helperText ? helpId : null].filter(Boolean).join(' ')}
        aria-invalid={error ? 'true' : undefined}
        aria-required={required}
        className={`
          w-full px-3 py-2 border rounded-lg text-sm
          focus:outline-none focus:ring-2 focus:ring-navy focus:border-transparent
          ${error ? 'border-red-500 bg-red-50' : 'border-gray-300'}
        `}
        {...props}
      />

      {helperText && (
        <p id={helpId} className="text-xs text-gray-500">{helperText}</p>
      )}

      {error && (
        <p id={errorId} role="alert" className="text-xs text-red-600 flex items-center gap-1">
          <span aria-hidden="true">⚠</span> {error}
        </p>
      )}
    </div>
  )
}
```

---

## 4. Badges de estado — texto para lectores de pantalla

```tsx
// components/ui/StatusBadge.tsx
const STATUS_CONFIG = {
  confirmada:   { label: 'Confirmada',   color: 'bg-green-100 text-green-800' },
  pendiente:    { label: 'Pendiente',    color: 'bg-yellow-100 text-yellow-800' },
  cancelada:    { label: 'Cancelada',    color: 'bg-red-100 text-red-800' },
  reservado:    { label: 'Reservado',    color: 'bg-blue-100 text-blue-800' },
  disponible:   { label: 'Disponible',   color: 'bg-green-100 text-green-800' },
  vencida:      { label: 'Vencida',      color: 'bg-red-100 text-red-800' },
  en_reparacion:{ label: 'En reparación',color: 'bg-orange-100 text-orange-800' },
} as const

export function StatusBadge({ status }: { status: keyof typeof STATUS_CONFIG }) {
  const config = STATUS_CONFIG[status]
  return (
    // aria-label para que los lectores digan el texto, no el color
    <span
      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${config.color}`}
      aria-label={`Estado: ${config.label}`}
    >
      {config.label}
    </span>
  )
}
```

---

## 5. CurrencyDisplay — legible para lectores de pantalla

```tsx
export function CurrencyDisplay({ amountUsd, amountArs, exchangeRate }: CurrencyProps) {
  // El visual muestra "USD 800 / ARS 972.000"
  // El lector de pantalla dice "800 dólares, equivalente a 972.000 pesos"
  return (
    <span aria-label={`${amountUsd} dólares${amountArs ? `, equivalente a ${amountArs.toLocaleString('es-AR')} pesos` : ''}`}>
      <span aria-hidden="true">
        USD {amountUsd.toLocaleString('en-US')}
        {amountArs && ` / ARS ${amountArs.toLocaleString('es-AR')}`}
      </span>
    </span>
  )
}
```

---

## 6. Atajos de teclado — POS y navegación

```tsx
// Para el POS — acciones frecuentes con teclado
'use client'
import { useEffect } from 'react'
import { useRouter } from 'next/navigation'

export function AtajosTeclado() {
  const router = useRouter()

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      // Solo si no hay un input/textarea enfocado
      if (['INPUT','TEXTAREA','SELECT'].includes((e.target as Element).tagName)) return

      // Alt + N → Nueva venta
      if (e.altKey && e.key === 'n') {
        e.preventDefault()
        router.push('/ventas/nueva')
      }
      // Alt + P → Nuevo presupuesto
      if (e.altKey && e.key === 'p') {
        e.preventDefault()
        router.push('/presupuestos/nueva')
      }
      // Alt + S → Nueva sepa
      if (e.altKey && e.key === 's') {
        e.preventDefault()
        router.push('/separas/nueva')
      }
      // Alt + B → Buscador de productos (focus)
      if (e.altKey && e.key === 'b') {
        e.preventDefault()
        document.querySelector<HTMLInputElement>('[data-search="productos"]')?.focus()
      }
    }

    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [router])

  return null // componente sin UI, solo efectos
}

// En app/(dashboard)/layout.tsx:
// <AtajosTeclado />

// En el POS agregar data-search al SearchInput de productos:
// <SearchInput data-search="productos" ... />
```

---

## 7. Focus visible — nunca ocultar el outline

```css
/* En globals.css — NUNCA hacer esto: */
/* * { outline: none; }  ← rompe la accesibilidad */

/* ✅ Estilo de focus consistente con la paleta del proyecto */
:focus-visible {
  outline: 2px solid #1E3A5F;
  outline-offset: 2px;
  border-radius: 4px;
}

/* Para botones con fondo oscuro */
.bg-navy:focus-visible,
.bg-navy-dark:focus-visible {
  outline-color: #BFDBFE;
}
```

---

## 8. Mensajes de estado — Live Regions

```tsx
// Para anunciar cambios dinámicos (stock actualizado, venta confirmada)
export function AnuncioLiveRegion({ mensaje }: { mensaje: string }) {
  return (
    <div
      role="status"           // aria-live="polite" implícito
      aria-live="polite"
      aria-atomic="true"
      className="sr-only"     // visualmente oculto, pero legible por lectores
    >
      {mensaje}
    </div>
  )
}

// Para errores críticos:
<div role="alert" aria-live="assertive" className="sr-only">
  {errorCritico}
</div>
```

---

## 9. Checklist de accesibilidad por módulo

```
Estructura:
- [ ] Todos los inputs tienen <label> con htmlFor
- [ ] Errores de validación tienen role="alert"
- [ ] Imágenes decorativas tienen alt="" (string vacío)
- [ ] Imágenes informativas tienen alt descriptivo

Interacción:
- [ ] Modales tienen focus trap y se cierran con Escape
- [ ] Al cerrar modal, el foco vuelve al elemento que lo abrió
- [ ] Filas clickeables de tabla tienen tabIndex={0} y onKeyDown Enter
- [ ] Botones de ícono tienen aria-label descriptivo

Visual:
- [ ] Contraste de texto mínimo 4.5:1 (blanco sobre navy-#1E3A5F ✅)
- [ ] Focus visible en todos los elementos interactivos
- [ ] Sin outline: none global en el CSS

POS específico:
- [ ] SearchInput de productos tiene autofocus al entrar al POS
- [ ] Atajos de teclado documentados en tooltip del header
- [ ] Tab order lógico: cliente → productos → descuento → pagos → confirmar
```
