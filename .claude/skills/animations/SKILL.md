---
name: animations
description: Micro-interacciones y animaciones para el ERP/CRM. Usar en el polish final después de que el core funciona. Cubre loading skeletons, transiciones de estado, y feedback visual con Framer Motion y CSS.
---

# Skill: `animations`
> **Activar con:** `[Skills activas: animations]`
> **Propósito:** Micro-interacciones que hacen el sistema sentir rápido y pulido

---

## Cuándo usar esta skill

Solo después de que el módulo funciona correctamente.
Las animaciones son el último 5% que hace la diferencia visual.
Nunca sacrificar funcionalidad por animación.

```bash
npm install framer-motion
```

---

## 1. Transiciones de estado en el POS

```tsx
'use client'
import { motion, AnimatePresence } from 'framer-motion'

// Ítems del carrito — entrada y salida animada
export function CarritoAnimado({ items }: { items: CartItem[] }) {
  return (
    <div className="space-y-2">
      <AnimatePresence mode="popLayout">
        {items.map(item => (
          <motion.div
            key={item.varianteId}
            initial={{ opacity: 0, height: 0, y: -10 }}
            animate={{ opacity: 1, height: 'auto', y: 0 }}
            exit={{ opacity: 0, height: 0, scale: 0.95 }}
            transition={{ duration: 0.2, ease: 'easeOut' }}
            className="overflow-hidden"
          >
            <div className="bg-white border border-gray-200 rounded-lg p-3">
              {/* contenido del ítem */}
            </div>
          </motion.div>
        ))}
      </AnimatePresence>

      {/* Total — animar cuando cambia */}
      <motion.div
        key={items.reduce((acc, i) => acc + i.subtotalUsd, 0)} // re-animar al cambiar
        initial={{ scale: 1.05, color: '#1E3A5F' }}
        animate={{ scale: 1, color: '#374151' }}
        transition={{ duration: 0.3 }}
        className="text-right font-bold text-lg"
      >
        USD {items.reduce((acc, i) => acc + i.subtotalUsd, 0)}
      </motion.div>
    </div>
  )
}
```

---

## 2. Notificación de novedad — entrada desde arriba

```tsx
// Novedades urgentes que aparecen en el briefing
export function NovedadCard({ novedad, onMarcarVista }: NovedadCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, x: -20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: 20 }}
      transition={{ duration: 0.25 }}
      className={`
        p-4 rounded-lg border-l-4
        ${novedad.prioridad === 'urgente' ? 'border-red-500 bg-red-50' : 'border-navy bg-blue-light'}
      `}
    >
      <div className="flex justify-between items-start">
        <div>
          <p className="font-semibold text-sm">{novedad.titulo}</p>
          {novedad.descripcion && (
            <p className="text-xs text-gray-600 mt-0.5">{novedad.descripcion}</p>
          )}
        </div>
        <button onClick={() => onMarcarVista(novedad.id)} className="text-gray-400 hover:text-gray-600">
          ✓
        </button>
      </div>
    </motion.div>
  )
}
```

---

## 3. Dashboard cards — entrada escalonada

```tsx
// Cargar los cards del dashboard con delay escalonado
const CARDS = ['ventas', 'caja', 'separas', 'novedades']

export function DashboardCards({ data }: { data: DashboardData }) {
  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
      {CARDS.map((card, i) => (
        <motion.div
          key={card}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: i * 0.08, duration: 0.3, ease: 'easeOut' }}
        >
          <MetricCard type={card} data={data} />
        </motion.div>
      ))}
    </div>
  )
}
```

---

## 4. Badge de alerta — pulso cuando hay urgentes

```tsx
// Badge que pulsa cuando hay novedades urgentes
export function BadgeUrgente({ count }: { count: number }) {
  if (count === 0) return null
  return (
    <span className="relative flex">
      <motion.span
        animate={{ scale: [1, 1.3, 1] }}
        transition={{ duration: 1.5, repeat: Infinity, repeatDelay: 3 }}
        className="absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"
      />
      <span className="relative inline-flex rounded-full h-5 w-5 bg-red-500 text-white text-xs items-center justify-center font-bold">
        {count > 9 ? '9+' : count}
      </span>
    </span>
  )
}
```

---

## 5. Transición de página — entre módulos

```tsx
// components/layout/PageTransition.tsx
'use client'
import { motion } from 'framer-motion'

export function PageTransition({ children }: { children: React.ReactNode }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.2, ease: 'easeOut' }}
    >
      {children}
    </motion.div>
  )
}

// Usar en app/(dashboard)/layout.tsx:
// <PageTransition>{children}</PageTransition>
```

---

## 6. Loading skeleton animado — con Tailwind

```tsx
// Sin Framer Motion — solo CSS, más liviano para skeletons simples
function SkeletonPulse({ className }: { className?: string }) {
  return (
    <div className={`animate-pulse bg-gradient-to-r from-gray-200 via-gray-100 to-gray-200 bg-[length:200%_100%] rounded ${className}`}
      style={{ animation: 'shimmer 1.5s infinite' }}
    />
  )
}

// En globals.css:
// @keyframes shimmer {
//   0% { background-position: 200% 0; }
//   100% { background-position: -200% 0; }
// }
```

---

## 7. Reglas para usar animaciones en este ERP

```
✅ Sí usar:
- Entrada de items al carrito (POS)
- Aparición de novedades urgentes (briefing)
- Transición suave entre páginas del dashboard
- Badge pulsando cuando hay alertas críticas
- Toast de confirmación de venta (ya lo hace Sonner)

❌ No usar:
- Animaciones en tablas de datos (ralentizan la navegación)
- Animaciones en formularios del POS (distrae durante la venta)
- Animaciones de hover en filas de tabla
- Cualquier animación con duration > 400ms
- Infinite loops en elementos no urgentes

Duración recomendada:
- Entrada de elementos:  150–250ms
- Salida de elementos:   100–200ms
- Transición de página:  200ms
- Badge de alerta:       300ms con repeat
```
