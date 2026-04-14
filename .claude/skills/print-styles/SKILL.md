---
name: print-styles
description: Estilos de impresión para el ERP/CRM. Usar al construir el ticket de venta, etiquetas de precio y cualquier componente que se imprima físicamente. Cubre tickets térmicos (58mm/80mm), etiquetas A4 y CSS de impresión.
---

# Skill: `print-styles`
> **Activar con:** `[Skills activas: print-styles]`
> **Propósito:** Tickets de venta y etiquetas que se ven bien en papel real

---

## 1. Ticket de venta — impresora térmica

Las impresoras térmicas más comunes en tiendas son de 58mm o 80mm de ancho.
El ticket debe verse bien en ambas.

```tsx
// app/(dashboard)/ventas/[id]/ticket/page.tsx

export default async function TicketPage({ params }: { params: { id: string } }) {
  const venta = await getVentaById(params.id)
  if (!venta) notFound()

  return (
    <>
      {/* Botones — solo visibles en pantalla, ocultos al imprimir */}
      <div className="print:hidden fixed top-4 right-4 flex gap-2 z-10">
        <button
          onClick={() => window.print()}
          className="px-4 py-2 bg-navy text-white rounded-lg text-sm font-medium"
        >
          🖨️ Imprimir ticket
        </button>
        {venta.cliente?.whatsapp && (
          <a
            href={generarLinkWhatsApp(venta)}
            target="_blank"
            className="px-4 py-2 bg-green-600 text-white rounded-lg text-sm font-medium"
          >
            📱 Enviar WhatsApp
          </a>
        )}
        <a
          href={`/ventas/${params.id}`}
          className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg text-sm font-medium"
        >
          ← Volver
        </a>
      </div>

      {/* Ticket — visible en pantalla como preview y en impresión */}
      <div className="min-h-screen bg-gray-100 print:bg-white flex items-start justify-center pt-16 print:pt-0 print:block">
        <div className="ticket bg-white p-4 font-mono text-xs leading-tight w-[300px] print:w-full print:shadow-none shadow-lg">

          {/* Encabezado */}
          <div className="text-center border-b border-dashed border-gray-400 pb-3 mb-3">
            <p className="font-bold text-base">{venta.deposito.nombre}</p>
            {venta.deposito.direccion && (
              <p className="text-gray-600">{venta.deposito.direccion}</p>
            )}
          </div>

          {/* Datos de la venta */}
          <div className="mb-3 space-y-0.5">
            <div className="flex justify-between">
              <span className="text-gray-500">N° Venta:</span>
              <span className="font-bold">{venta.numero_venta}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">Fecha:</span>
              <span>{new Date(venta.fecha_confirmacion!).toLocaleDateString('es-AR')}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">Hora:</span>
              <span>{new Date(venta.fecha_confirmacion!).toLocaleTimeString('es-AR', { hour: '2-digit', minute: '2-digit' })}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">Vendedor:</span>
              <span>{venta.vendedor.nombre}</span>
            </div>
            {venta.cliente && (
              <div className="flex justify-between">
                <span className="text-gray-500">Cliente:</span>
                <span>{venta.cliente.nombre} {venta.cliente.apellido}</span>
              </div>
            )}
          </div>

          {/* Separador */}
          <div className="border-t border-dashed border-gray-400 my-2" />

          {/* Ítems */}
          <div className="mb-3">
            <p className="font-bold text-center mb-1">DETALLE</p>
            {venta.items.map(item => (
              <div key={item.id} className="mb-1.5">
                <div className="flex justify-between font-medium">
                  <span className="flex-1 pr-2 truncate">{item.variante.producto.nombre}</span>
                  <span>USD {item.precio_final_usd}</span>
                </div>
                {item.unidad?.imei && (
                  <p className="text-gray-500 text-[10px] ml-2">IMEI: {item.unidad.imei}</p>
                )}
                {item.descuento_porcentaje > 0 && (
                  <p className="text-gray-500 text-[10px] ml-2">Desc: {item.descuento_porcentaje}%</p>
                )}
              </div>
            ))}
          </div>

          {/* Separador */}
          <div className="border-t border-dashed border-gray-400 my-2" />

          {/* Totales */}
          <div className="mb-3 space-y-0.5">
            <div className="flex justify-between font-bold text-sm">
              <span>TOTAL USD:</span>
              <span>USD {venta.total_usd}</span>
            </div>
            <div className="flex justify-between text-gray-600">
              <span>TC: ${venta.tipo_cambio_valor_ars}</span>
              <span>ARS {Number(venta.total_ars).toLocaleString('es-AR')}</span>
            </div>
          </div>

          {/* Pagos */}
          <div className="mb-3">
            <p className="font-bold text-[10px] text-gray-500 uppercase mb-1">Forma de pago</p>
            {venta.pagos.map(pago => (
              <div key={pago.id} className="flex justify-between text-[10px]">
                <span>{pago.metodo.nombre.replace(/_/g, ' ')}</span>
                <span>ARS {Number(pago.monto_ars ?? 0).toLocaleString('es-AR')}</span>
              </div>
            ))}
          </div>

          {/* Footer */}
          <div className="border-t border-dashed border-gray-400 pt-2 text-center text-gray-500">
            <p>¡Gracias por su compra!</p>
            <p className="text-[10px] mt-0.5">Conserve este comprobante</p>
          </div>
        </div>
      </div>

      <style>{`
        @media print {
          @page {
            margin: 0;
            size: 80mm auto;   /* Impresora térmica 80mm */
          }
          body {
            margin: 0;
            padding: 0;
          }
          .ticket {
            width: 100%;
            padding: 4mm;
            font-size: 9pt;
            line-height: 1.3;
          }
        }

        /* Para impresora térmica 58mm */
        @media print and (max-width: 60mm) {
          @page { size: 58mm auto; }
          .ticket { font-size: 8pt; }
        }
      `}</style>
    </>
  )
}
```

---

## 2. Etiquetas de precio — formato A4

```tsx
// app/(dashboard)/inventario/etiquetas/page.tsx
// Múltiples etiquetas en una hoja A4

interface EtiquetaPrecioProps {
  nombre: string
  variante: string
  precioUsd: number
  precioArs: number
  sku: string
  condicion?: string
}

function EtiquetaPrecio({ nombre, variante, precioUsd, precioArs, sku, condicion }: EtiquetaPrecioProps) {
  return (
    <div className="etiqueta border border-gray-300 p-2 flex flex-col justify-between bg-white">
      <div>
        <p className="font-bold text-sm leading-tight line-clamp-2">{nombre}</p>
        <p className="text-xs text-gray-600">{variante}</p>
        {condicion && (
          <span className="text-[10px] bg-amber-100 text-amber-800 px-1 rounded">
            {condicion.toUpperCase()}
          </span>
        )}
      </div>
      <div className="mt-1">
        <p className="text-lg font-bold text-navy">USD {precioUsd}</p>
        <p className="text-xs text-gray-600">ARS {precioArs.toLocaleString('es-AR')}</p>
        <p className="text-[9px] text-gray-400 mt-0.5">{sku}</p>
      </div>
    </div>
  )
}

export default function EtiquetasPage() {
  return (
    <>
      {/* Controles — solo en pantalla */}
      <div className="print:hidden p-4 flex gap-3 items-center">
        <h1 className="text-xl font-bold text-navy">Etiquetas de precio</h1>
        <button
          onClick={() => window.print()}
          className="px-4 py-2 bg-navy text-white rounded-lg"
        >
          🖨️ Imprimir etiquetas
        </button>
      </div>

      {/* Grilla de etiquetas */}
      <div className="etiquetas-grid p-4 print:p-0">
        {/* Las etiquetas se distribuyen automáticamente en la hoja A4 */}
      </div>

      <style>{`
        .etiquetas-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 4mm;
        }

        .etiqueta {
          width: auto;
          height: 40mm;
          break-inside: avoid;
        }

        @media print {
          @page {
            size: A4;
            margin: 10mm;
          }

          .etiquetas-grid {
            gap: 3mm;
          }

          .etiqueta {
            border: 0.5pt solid #ccc;
          }
        }
      `}</style>
    </>
  )
}
```

---

## 3. Reglas generales de CSS para impresión

```css
/* En globals.css — agregar estas reglas base */

@media print {
  /* Ocultar siempre al imprimir */
  .print\:hidden,
  nav,
  aside,
  [data-sidebar],
  [data-header] {
    display: none !important;
  }

  /* Reset de colores para impresión en B&N */
  * {
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;   /* Preservar colores de fondo */
  }

  /* Links sin subrayado en impresión */
  a {
    text-decoration: none;
    color: inherit;
  }

  /* Evitar que las tablas corten filas entre páginas */
  tr {
    break-inside: avoid;
  }

  /* Salto de página forzado */
  .print-page-break {
    break-before: page;
  }

  /* Evitar salto de página */
  .print-no-break {
    break-inside: avoid;
  }
}

/* Clases de utilidad Tailwind para impresión (ya incluidas en Tailwind) */
/* print:hidden    → display: none en impresión */
/* print:block     → display: block en impresión */
/* print:text-black → color negro en impresión */
```

---

## 4. Botón imprimir estándar

```tsx
// components/ui/BotonImprimir.tsx
'use client'

interface BotonImprimirProps {
  label?: string
  className?: string
}

export function BotonImprimir({ label = 'Imprimir', className }: BotonImprimirProps) {
  return (
    <button
      onClick={() => window.print()}
      className={`
        print:hidden
        flex items-center gap-2 px-4 py-2
        bg-navy text-white rounded-lg text-sm font-medium
        hover:bg-navy-dark transition-colors
        ${className}
      `}
      aria-label={`Imprimir ${label}`}
    >
      🖨️ {label}
    </button>
  )
}
```

---

## 5. Checklist de impresión

```
Antes de dar por terminado un componente imprimible:

- [ ] print:hidden en todos los botones y controles de navegación
- [ ] @page con size correcto (80mm auto para tickets, A4 para reportes)
- [ ] Testar con Ctrl+P en el browser — el preview debe verse correcto
- [ ] Sin colores de fondo que no se impriman (usar print-color-adjust: exact)
- [ ] Fuente monospace (font-mono) para tickets — mejor legibilidad
- [ ] break-inside: avoid en cada ítem del ticket
- [ ] Probar en Safari también — tiene comportamientos de impresión diferentes
```
