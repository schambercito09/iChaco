---
name: xlsx
description: Usar cuando se necesite crear, editar o exportar archivos Excel/CSV. Incluye los reportes específicos del ERP/CRM y operaciones generales con planillas. Activar para: reportes de ventas, stock, comisiones, o cuando el usuario mencione exportar datos a Excel.
---

# Skill: `xlsx`
> **Activar con:** `[Skills activas: xlsx]`
> **Propósito:** Reportes Excel y exportación de datos del ERP

---

## Reportes del proyecto — estructuras específicas

### 1. Reporte de ventas por período

```python
import pandas as pd
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, numbers
from openpyxl.utils import get_column_letter

def generar_reporte_ventas(ventas: list[dict], periodo: str) -> str:
    wb = Workbook()
    ws = wb.active
    ws.title = "Ventas"

    NAVY = "1E3A5F"
    LIGHT_BLUE = "EFF6FF"

    # Header
    headers = ["N° Venta", "Fecha", "Cliente", "Vendedor",
               "Depósito", "Canal", "Total USD", "Total ARS", "Estado"]
    ws.append(headers)

    # Estilos del header
    for col, _ in enumerate(headers, 1):
        cell = ws.cell(row=1, column=col)
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = PatternFill("solid", start_color=NAVY)
        cell.alignment = Alignment(horizontal="center")

    # Datos
    for i, venta in enumerate(ventas, 2):
        ws.append([
            venta["numero_venta"],
            venta["fecha_confirmacion"],
            venta.get("cliente", {}).get("nombre", "Anónimo"),
            venta["vendedor"]["nombre"],
            venta["deposito"]["nombre"],
            venta["canal"],
            venta["total_usd"],
            venta["total_ars"],
            venta["estado"],
        ])
        # Fondo alternado
        if i % 2 == 0:
            for col in range(1, len(headers) + 1):
                ws.cell(row=i, column=col).fill = PatternFill("solid", start_color=LIGHT_BLUE)

        # Formato de moneda en columnas USD y ARS
        ws.cell(row=i, column=7).number_format = '"USD "#,##0.00'
        ws.cell(row=i, column=8).number_format = '"ARS "#,##0.00'

    # Anchos de columna
    col_widths = [12, 12, 25, 20, 18, 14, 14, 16, 12]
    for i, width in enumerate(col_widths, 1):
        ws.column_dimensions[get_column_letter(i)].width = width

    # Fila de totales
    last_row = len(ventas) + 2
    ws.append(["", "", "", "", "", "TOTAL",
               f"=SUM(G2:G{last_row-1})",
               f"=SUM(H2:H{last_row-1})", ""])
    ws.cell(last_row, 6).font = Font(bold=True)
    ws.cell(last_row, 7).font = Font(bold=True)
    ws.cell(last_row, 7).number_format = '"USD "#,##0.00'
    ws.cell(last_row, 8).font = Font(bold=True)
    ws.cell(last_row, 8).number_format = '"ARS "#,##0.00'

    path = f"/tmp/reporte_ventas_{periodo}.xlsx"
    wb.save(path)
    return path
```

### 2. Reporte de stock por depósito

```python
def generar_reporte_stock(stock_data: list[dict]) -> str:
    wb = Workbook()
    ws = wb.active
    ws.title = "Stock"

    headers = ["SKU", "Producto", "Variante", "Depósito",
               "Disponible", "Reservado", "En Tránsito", "Stock Mínimo", "Estado"]
    ws.append(headers)

    # Header azul marino
    for col in range(1, len(headers) + 1):
        cell = ws.cell(row=1, column=col)
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = PatternFill("solid", start_color="1E3A5F")

    ROJO = "FEE2E2"
    AMARILLO = "FEF9C3"
    VERDE = "D1FAE5"

    for i, item in enumerate(stock_data, 2):
        disponible = item["cantidad_disponible"]
        minimo = item["stock_minimo"]

        estado = "CRÍTICO" if disponible == 0 else ("BAJO" if disponible <= minimo else "OK")

        ws.append([
            item["variante"]["sku_variante"],
            item["variante"]["producto"]["nombre"],
            f"{item['variante'].get('color','')} {item['variante'].get('capacidad_gb','')}GB".strip(),
            item["deposito"]["nombre"],
            disponible,
            item["cantidad_reservada"],
            item["cantidad_en_transito"],
            minimo,
            estado,
        ])

        # Color por estado
        color = ROJO if estado == "CRÍTICO" else (AMARILLO if estado == "BAJO" else VERDE)
        for col in range(1, len(headers) + 1):
            ws.cell(row=i, column=col).fill = PatternFill("solid", start_color=color[1:] if color.startswith("#") else color)

    path = "/tmp/reporte_stock.xlsx"
    wb.save(path)
    return path
```

### 3. Reporte de comisiones de vendedores

```python
def generar_reporte_comisiones(vendedores: list[dict], periodo: str) -> str:
    wb = Workbook()
    ws = wb.active
    ws.title = f"Comisiones {periodo}"

    headers = ["Vendedor", "Depósito", "Ventas (#)", "Total Vendido USD",
               "% Comisión", "Comisión USD", "Meta USD", "Avance %"]
    ws.append(headers)

    for col in range(1, len(headers) + 1):
        cell = ws.cell(row=1, column=col)
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = PatternFill("solid", start_color="1E3A5F")

    for i, v in enumerate(vendedores, 2):
        total = v["total_vendido_usd"]
        meta = v["meta_mensual_usd"] or 1
        comision_pct = v["comision_porcentaje"] or 0

        ws.append([
            f"{v['nombre']} {v['apellido']}",
            v["deposito"]["nombre"],
            v["cantidad_ventas"],
            total,
            comision_pct / 100,
            f"=D{i}*E{i}",           # fórmula Excel
            meta,
            f"=D{i}/G{i}",           # fórmula Excel
        ])

        ws.cell(i, 4).number_format = '"USD "#,##0.00'
        ws.cell(i, 5).number_format = '0.0%'
        ws.cell(i, 6).number_format = '"USD "#,##0.00'
        ws.cell(i, 7).number_format = '"USD "#,##0.00'
        ws.cell(i, 8).number_format = '0%'

    path = f"/tmp/comisiones_{periodo}.xlsx"
    wb.save(path)
    return path
```

### 4. Exportar CSV desde Server Action (Next.js)

```typescript
// app/(dashboard)/ventas/export/route.ts
import { NextResponse } from 'next/server'
import { createServerClient } from '@/lib/supabase/server'

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const desde = searchParams.get('desde')
  const hasta = searchParams.get('hasta')

  const supabase = createServerClient()
  const { data: ventas } = await supabase
    .from('ventas')
    .select('numero_venta, created_at, total_usd, total_ars, estado')
    .gte('created_at', desde ?? '')
    .lte('created_at', hasta ?? '')

  // Generar CSV
  const headers = 'N° Venta,Fecha,Total USD,Total ARS,Estado\n'
  const rows = ventas?.map(v =>
    `${v.numero_venta},${v.created_at},${v.total_usd},${v.total_ars},${v.estado}`
  ).join('\n') ?? ''

  return new NextResponse(headers + rows, {
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="ventas-${desde}-${hasta}.csv"`,
    },
  })
}

// En el componente:
// <a href={`/ventas/export?desde=2024-01-01&hasta=2024-01-31`}>
//   Exportar CSV
// </a>
```

---

## Operaciones generales

### Leer y analizar datos existentes

```python
import pandas as pd

# Leer Excel
df = pd.read_excel('archivo.xlsx')
df.info()
df.describe()

# Escribir Excel simple
df.to_excel('output.xlsx', index=False)
```

### Crear Excel con openpyxl (para formato complejo)

```python
from openpyxl import Workbook, load_workbook
from openpyxl.styles import Font, PatternFill, Alignment

# Crear nuevo
wb = Workbook()
ws = wb.active
ws['A1'] = '=SUM(B1:B10)'  # SIEMPRE fórmulas, nunca valores calculados en Python
wb.save('output.xlsx')

# Recalcular fórmulas (requiere LibreOffice)
# python scripts/recalc.py output.xlsx
```

## Buenas prácticas generales

- **Fórmulas vs valores:** SIEMPRE usar fórmulas Excel (`=SUM(...)`) en lugar de calcular en Python y hardcodear
- **Recalcular:** después de crear/modificar con openpyxl, ejecutar `scripts/recalc.py`
- **Índices:** openpyxl es 1-indexed (row=1, column=1 = celda A1)
- **data_only=True:** si se abre con este flag y se guarda, las fórmulas se pierden permanentemente