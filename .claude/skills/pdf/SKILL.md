---
name: pdf
description: Usar cuando se necesite generar o procesar archivos PDF. Incluye los PDFs específicos del ERP/CRM: ticket de venta, presupuesto para cliente, acta de recepción de usados. También cubre operaciones generales con PDFs.
---

# Skill: `pdf`
> **Activar con:** `[Skills activas: pdf]`
> **Propósito:** Generación y procesamiento de PDFs del proyecto

---

## PDFs del proyecto — estructura específica

### 1. Ticket de venta (imprimible desde el browser)

```tsx
// app/(dashboard)/ventas/[id]/ticket/page.tsx
// HTML/CSS puro — se imprime con window.print()

export default async function TicketPage({ params }: { params: { id: string } }) {
  const venta = await getVentaById(params.id)

  return (
    <>
      {/* Botones visibles solo en pantalla, ocultos al imprimir */}
      <div className="print:hidden flex gap-3 p-4">
        <button onClick={() => window.print()}>🖨️ Imprimir</button>
        {venta.cliente?.whatsapp && (
          <a href={generarLinkWhatsApp(venta)} target="_blank">
            📱 Enviar por WhatsApp
          </a>
        )}
      </div>

      {/* Ticket — visible en pantalla y en impresión */}
      <div className="ticket max-w-sm mx-auto p-6 font-mono text-sm">
        <h1 className="text-center font-bold text-lg">NOMBRE DEL NEGOCIO</h1>
        <p className="text-center text-xs">{venta.deposito.nombre} — {venta.deposito.direccion}</p>
        <hr className="my-2" />

        <div className="grid grid-cols-2 gap-1 text-xs">
          <span>N° Venta:</span>     <span className="font-bold">{venta.numero_venta}</span>
          <span>Fecha:</span>        <span>{formatFecha(venta.fecha_confirmacion)}</span>
          <span>Vendedor:</span>     <span>{venta.vendedor.nombre}</span>
          {venta.cliente && (
            <><span>Cliente:</span> <span>{venta.cliente.nombre}</span></>
          )}
        </div>

        <hr className="my-2" />

        {/* Ítems */}
        <table className="w-full text-xs">
          <thead>
            <tr><th>Producto</th><th>Cant</th><th>Total USD</th></tr>
          </thead>
          <tbody>
            {venta.items.map(item => (
              <tr key={item.id}>
                <td>{item.variante.nombre}{item.unidad?.imei ? ` (${item.unidad.imei})` : ''}</td>
                <td className="text-center">{item.cantidad}</td>
                <td className="text-right">USD {item.precio_final_usd}</td>
              </tr>
            ))}
          </tbody>
        </table>

        <hr className="my-2" />

        {/* Totales */}
        <div className="text-xs space-y-1">
          <div className="flex justify-between font-bold">
            <span>TOTAL USD:</span>
            <span>USD {venta.total_usd}</span>
          </div>
          <div className="flex justify-between">
            <span>TOTAL ARS (TC ${venta.tipo_cambio_valor_ars}):</span>
            <span>ARS {formatMonto(venta.total_ars)}</span>
          </div>
        </div>

        <hr className="my-2" />

        {/* Pagos */}
        {venta.pagos.map(pago => (
          <div key={pago.id} className="flex justify-between text-xs">
            <span>{pago.metodo_pago.nombre}:</span>
            <span>ARS {formatMonto(pago.monto_ars)}</span>
          </div>
        ))}

        <p className="text-center text-xs mt-4 text-gray-500">Gracias por su compra</p>
      </div>

      <style>{`
        @media print {
          body { margin: 0; }
          .ticket { max-width: 100%; }
        }
      `}</style>
    </>
  )
}

function generarLinkWhatsApp(venta: VentaConDetalle): string {
  const tel = venta.cliente?.whatsapp?.replace(/\D/g, '')
  const msg = encodeURIComponent(
    `Hola ${venta.cliente?.nombre ?? ''}! Te comparto el comprobante de tu compra.\n` +
    `N° ${venta.numero_venta} — Total: USD ${venta.total_usd}\n` +
    `Gracias por elegirnos! 🙏`
  )
  return `https://wa.me/${tel}?text=${msg}`
}
```

### 2. Presupuesto PDF (descargable)

```typescript
// Usar la skill pdf con reportlab/pdflib para generar el PDF en el servidor
// lib/pdf/presupuesto.ts

import { PDFDocument, StandardFonts, rgb } from 'pdf-lib'

export async function generarPDFPresupuesto(presupuesto: PresupuestoConDetalle): Promise<Buffer> {
  const doc = await PDFDocument.create()
  const page = doc.addPage([595, 842]) // A4
  const font = await doc.embedFont(StandardFonts.Helvetica)
  const fontBold = await doc.embedFont(StandardFonts.HelveticaBold)

  const NAVY = rgb(0.118, 0.227, 0.373) // #1E3A5F
  const GRAY = rgb(0.42, 0.42, 0.42)

  // Header
  page.drawRectangle({ x: 0, y: 782, width: 595, height: 60, color: NAVY })
  page.drawText('PRESUPUESTO', { x: 40, y: 802, size: 20, font: fontBold, color: rgb(1,1,1) })
  page.drawText(`N° ${presupuesto.numero_presupuesto}`, { x: 400, y: 802, size: 14, font, color: rgb(1,1,1) })

  // Datos del presupuesto
  let y = 750
  const line = (label: string, value: string) => {
    page.drawText(label, { x: 40, y, size: 9, font, color: GRAY })
    page.drawText(value, { x: 150, y, size: 9, font })
    y -= 16
  }

  line('Cliente:', presupuesto.nombre_cliente_libre ?? presupuesto.cliente?.nombre ?? 'Sin nombre')
  line('Fecha:', new Date(presupuesto.created_at).toLocaleDateString('es-AR'))
  line('Válido hasta:', presupuesto.vigencia_hasta ? new Date(presupuesto.vigencia_hasta).toLocaleDateString('es-AR') : 'A confirmar')
  line('TC utilizado:', `ARS ${presupuesto.tipo_cambio?.valor_ars ?? 'N/D'} por USD`)

  // ... items, totales, footer
  // Ver implementación completa en docs/pdf-templates.md

  const bytes = await doc.save()
  return Buffer.from(bytes)
}
```

### 3. Enlace WhatsApp para presupuesto

```typescript
export function generarMensajePresupuesto(pres: Presupuesto, telefono: string): string {
  const nombre = pres.nombre_cliente_libre ?? 'cliente'
  const vigencia = pres.vigencia_hasta
    ? new Date(pres.vigencia_hasta).toLocaleDateString('es-AR')
    : 'a confirmar'

  const mensaje = [
    `Hola ${nombre}! 👋`,
    `Te comparto tu presupuesto N° ${pres.numero_presupuesto}`,
    ``,
    `💵 Total: USD ${pres.total_usd}`,
    `📅 Válido hasta: ${vigencia}`,
    ``,
    `Ante cualquier consulta, estamos a tu disposición.`,
  ].join('\n')

  const tel = telefono.replace(/\D/g, '')
  return `https://wa.me/${tel}?text=${encodeURIComponent(mensaje)}`
}
```

---

## Operaciones generales con PDF

### Instalar librería

```bash
npm install pdf-lib
# O para generación server-side más compleja:
npm install @react-pdf/renderer
```

### Leer y extraer texto (Python — para scripts de migración)

```python
import pdfplumber

with pdfplumber.open("documento.pdf") as pdf:
    for page in pdf.pages:
        text = page.extract_text()
        print(text)

# Extraer tablas:
with pdfplumber.open("factura.pdf") as pdf:
    tables = pdf.pages[0].extract_tables()
```

### Fusionar PDFs

```python
from pypdf import PdfWriter, PdfReader

writer = PdfWriter()
for pdf_file in ["doc1.pdf", "doc2.pdf"]:
    reader = PdfReader(pdf_file)
    for page in reader.pages:
        writer.add_page(page)

with open("fusionado.pdf", "wb") as output:
    writer.write(output)
```

### Crear PDF con reportlab (Python)

```python
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib import colors

c = canvas.Canvas("reporte.pdf", pagesize=A4)
width, height = A4

# Header azul marino
c.setFillColorRGB(0.118, 0.227, 0.373)  # #1E3A5F
c.rect(0, height - 60, width, 60, fill=1)

# Texto blanco en el header
c.setFillColorRGB(1, 1, 1)
c.setFont("Helvetica-Bold", 16)
c.drawString(40, height - 35, "Reporte de Ventas")

c.save()
```

**Nota sobre subíndices/superíndices en reportlab:**
Nunca usar caracteres Unicode ₀₁₂ — usar etiquetas XML `<sub>` y `<super>` en objetos `Paragraph`.