---
name: testing
description: Tests para el ERP/CRM. Usar al construir el QA del Paso 18.5 y al testear Server Actions críticas. Cubre Vitest para lógica de negocio, Testing Library para componentes, y mocks de Supabase.
---

# Skill: `testing`
> **Activar con:** `[Skills activas: testing]`
> **Propósito:** Tests para las operaciones críticas — venta, stock, caja, separas

---

## Setup inicial

```bash
npm install -D vitest @vitest/ui @testing-library/react @testing-library/user-event
npm install -D jsdom @vitejs/plugin-react
```

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./tests/setup.ts'],
  },
  resolve: {
    alias: { '@': path.resolve(__dirname, '.') },
  },
})
```

```typescript
// tests/setup.ts
import '@testing-library/jest-dom'
```

---

## 1. Tests de lógica de negocio — sin base de datos

```typescript
// tests/lib/utils/money.test.ts
import { describe, it, expect } from 'vitest'
import { calcularARS, calcularMargen, usd, ars, exchangeRate } from '@/lib/utils/money'

describe('calcularARS', () => {
  it('calcula correctamente precio ARS desde USD y TC', () => {
    const precio = usd(800)
    const tc = exchangeRate(1215)
    const resultado = calcularARS(precio, tc)
    expect(resultado).toBe(972000)
  })

  it('retorna 0 si el monto es 0', () => {
    expect(calcularARS(usd(0), exchangeRate(1215))).toBe(0)
  })
})

describe('calcularMargen', () => {
  it('calcula margen correctamente', () => {
    expect(calcularMargen(usd(800), usd(650))).toBeCloseTo(23.07, 1)
  })

  it('retorna 0 si el costo es 0 (evitar division por cero)', () => {
    expect(calcularMargen(usd(800), usd(0))).toBe(0)
  })
})
```

---

## 2. Tests de Server Actions — con mock de Supabase

```typescript
// tests/lib/actions/tipo-cambio.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { cargarTipoCambioAction } from '@/lib/actions/tipo-cambio'

// Mock del cliente Supabase
vi.mock('@/lib/supabase/server', () => ({
  createServerClient: vi.fn(() => ({
    from: vi.fn(() => ({
      insert: vi.fn().mockResolvedValue({ data: null, error: null }),
      select: vi.fn(() => ({
        eq: vi.fn(() => ({
          single: vi.fn().mockResolvedValue({
            data: { id: 'test-id', rol: 'admin' }, error: null
          })
        }))
      }))
    })),
    auth: {
      getUser: vi.fn().mockResolvedValue({
        data: { user: { id: 'user-id' } }, error: null
      })
    }
  }))
}))

vi.mock('next/cache', () => ({
  revalidatePath: vi.fn(),
}))

describe('cargarTipoCambioAction', () => {
  const formDataValida = () => {
    const fd = new FormData()
    fd.set('valor_ars', '1215')
    fd.set('tipo', 'blue')
    fd.set('fuente', 'manual')
    return fd
  }

  it('retorna error si valor_ars es 0', async () => {
    const fd = new FormData()
    fd.set('valor_ars', '0')
    fd.set('tipo', 'blue')
    fd.set('fuente', 'manual')

    const result = await cargarTipoCambioAction(fd)
    expect('error' in result).toBe(true)
  })

  it('retorna success con datos válidos', async () => {
    const result = await cargarTipoCambioAction(formDataValida())
    expect('success' in result).toBe(true)
  })
})
```

---

## 3. Tests de validación Zod

```typescript
// tests/lib/validations/ventas.test.ts
import { describe, it, expect } from 'vitest'
import { ventaSchema } from '@/lib/validations/ventas'

describe('ventaSchema', () => {
  const itemValido = {
    variante_id: '550e8400-e29b-41d4-a716-446655440000',
    cantidad: 1,
    precio_lista_usd: 800,
    precio_lista_ars: 972000,
    descuento_porcentaje: 0,
    precio_final_usd: 800,
    precio_final_ars: 972000,
  }

  const datoValido = {
    deposito_id: '550e8400-e29b-41d4-a716-446655440001',
    tipo_cambio_id: '550e8400-e29b-41d4-a716-446655440002',
    moneda_base: 'USD' as const,
    total_usd: 800,
    total_ars: 972000,
    items: [itemValido],
    pagos: [{ metodo_pago_id: '550e8400-e29b-41d4-a716-446655440003', monto_ars: 972000 }],
  }

  it('valida datos correctos', () => {
    expect(() => ventaSchema.parse(datoValido)).not.toThrow()
  })

  it('falla si no hay items', () => {
    expect(() => ventaSchema.parse({ ...datoValido, items: [] })).toThrow()
  })

  it('falla si no hay pagos', () => {
    expect(() => ventaSchema.parse({ ...datoValido, pagos: [] })).toThrow()
  })

  it('falla si total_usd es negativo', () => {
    expect(() => ventaSchema.parse({ ...datoValido, total_usd: -1 })).toThrow()
  })
})
```

---

## 4. Tests de componentes — POS

```tsx
// tests/components/pos/CarritoVenta.test.tsx
import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { CarritoVenta } from '@/components/modules/ventas/CarritoVenta'

describe('CarritoVenta', () => {
  const itemMock = {
    varianteId: 'uuid-1',
    descripcion: 'iPhone 15 128GB Negro',
    qty: 1,
    precioUsd: 800,
    precioArs: 972000,
    descPct: 0,
    subtotalUsd: 800,
    subtotalArs: 972000,
  }

  it('muestra el ítem en el carrito', () => {
    render(<CarritoVenta items={[itemMock]} onRemove={() => {}} tcHoy={1215} />)
    expect(screen.getByText('iPhone 15 128GB Negro')).toBeInTheDocument()
    expect(screen.getByText('USD 800')).toBeInTheDocument()
  })

  it('calcula el total correctamente con múltiples ítems', () => {
    const items = [itemMock, { ...itemMock, varianteId: 'uuid-2', subtotalUsd: 200 }]
    render(<CarritoVenta items={items} onRemove={() => {}} tcHoy={1215} />)
    expect(screen.getByText('USD 1.000')).toBeInTheDocument()
  })

  it('llama onRemove con el varianteId al eliminar', async () => {
    const onRemove = vi.fn()
    render(<CarritoVenta items={[itemMock]} onRemove={onRemove} tcHoy={1215} />)

    await userEvent.click(screen.getByRole('button', { name: /eliminar/i }))
    expect(onRemove).toHaveBeenCalledWith('uuid-1')
  })
})
```

---

## 5. Comandos de testing

```bash
# Correr todos los tests
npm run test

# Modo watch (durante desarrollo)
npm run test -- --watch

# UI interactivo
npm run test -- --ui

# Coverage
npm run test -- --coverage

# Test de un archivo específico
npm run test -- tests/lib/utils/money.test.ts

# Agregar a package.json:
# "test": "vitest run",
# "test:watch": "vitest",
# "test:ui": "vitest --ui",
# "test:coverage": "vitest run --coverage"
```

---

## 6. Qué testear en este proyecto

```
Alta prioridad (testear siempre):
- [ ] calcularARS(), calcularMargen() — errores de redondeo cuestan dinero
- [ ] schemas Zod de ventas, separas y recepciones
- [ ] requireTCDelDia() lanza correctamente cuando no hay TC

Media prioridad (testear antes de cada deploy):
- [ ] CarritoVenta — totales correctos, eliminar funciona
- [ ] FormularioSepa — precio ARS se recalcula al cambiar precio USD
- [ ] StatusBadge — mapea correctamente estados a colores/labels

Bajo prioridad (testear cuando haya tiempo):
- [ ] Componentes de display puro (CurrencyDisplay, PageHeader)
- [ ] Funciones helper de formateo de fechas y montos
```
