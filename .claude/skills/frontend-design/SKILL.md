---
name: frontend-design
description: Crear interfaces frontend de calidad de producción para el ERP/CRM. Usar cuando se construyan módulos del dashboard, componentes, páginas o cualquier UI del sistema. Incluye la paleta oficial del proyecto y las clases Tailwind específicas.
---

# Skill: `frontend-design`
> **Activar con:** `[Skills activas: frontend-design]`
> **Propósito:** UI de producción con paleta azul marino del proyecto

---

## PALETA OFICIAL DEL PROYECTO — usar siempre estos colores

```
Azul marino principal:  #1E3A5F  →  navy        (sidebar, headers, botones primarios)
Azul marino oscuro:     #142842  →  navy-dark   (hover, badges de número de paso)
Azul marino medio:      #2D5F8A  →  navy-light  (hover en sidebar, items activos)
Azul claro fondo:       #EFF6FF  →  blue-light  (fondo de secciones, acciones manuales)
Azul acento:            #3B82F6  →  blue-accent (links, highlights)
Borde azul:             #BFDBFE  →  blue-border (bordes de cards con fondo azul)
Blanco:                 #FFFFFF  →  white       (fondo predominante de páginas)
Gris texto:             #374151             (texto principal del body)
Gris suave:             #6B7280             (texto secundario, labels)
Gris borde:             #E5E7EB             (bordes de tablas, separadores)
Gris fondo:             #F9FAFB             (filas alternas, fondos sutiles)
Verde éxito:            #065F46 / #D1FAE5   (texto/fondo de criterios de avance)
Rojo error:             #991B1B / #FEE2E2   (texto/fondo de alertas críticas)
```

## Clases Tailwind del proyecto

```typescript
// Estos colores están en tailwind.config.ts — usarlos siempre:
className="bg-navy"           // azul marino #1E3A5F
className="bg-navy-dark"      // azul marino oscuro
className="bg-navy-light"     // azul marino medio (hover)
className="bg-blue-light"     // fondo azul muy claro
className="text-navy"         // texto azul marino
className="border-blue-border" // borde azul claro
className="text-blue-accent"  // texto azul acento

// Para fondos de página — SIEMPRE blanco:
className="bg-white min-h-screen"

// Para cards — blanco con borde sutil:
className="bg-white rounded-lg border border-gray-200 shadow-sm p-6"

// Para headers de sección — azul marino:
className="bg-navy text-white px-4 py-3 rounded-t-lg"
```

## Principios de diseño del sistema

**Fondo predominante: BLANCO** — Las páginas del dashboard son blancas.
El azul marino aparece en: sidebar, headers de módulos, botones primarios, badges de estado importantes.
El azul claro aparece en: fondos de cards informativos, secciones de acción manual.

```
Jerarquía visual:
  Página         → bg-white
  Sidebar        → bg-navy text-white
  Card principal → bg-white border border-gray-200
  Header de card → bg-navy text-white (opcional)
  Botón primario → bg-navy hover:bg-navy-dark text-white
  Botón secundario → border border-navy text-navy hover:bg-blue-light
  Badge urgente  → bg-red-100 text-red-800
  Badge OK       → bg-green-100 text-green-800
  Badge info     → bg-blue-light text-navy border border-blue-border
```

## Layout estándar de módulo

```tsx
// Estructura de cada página del dashboard:
export default function MiModuloPage() {
  return (
    <div className="bg-white min-h-screen">
      {/* Header del módulo */}
      <PageHeader
        title="Nombre del Módulo"
        actions={<Button variant="primary">Acción principal</Button>}
      />

      {/* Alertas si corresponde */}
      {!tcHoy && (
        <div className="mx-6 mb-4 p-4 bg-amber-50 border border-amber-200 rounded-lg">
          <p className="text-amber-800 text-sm font-medium">
            ⚠️ Sin tipo de cambio del día
          </p>
        </div>
      )}

      {/* Contenido */}
      <div className="px-6 pb-6 space-y-6">
        {/* Filtros */}
        <div className="flex gap-3 items-center">
          <SearchInput placeholder="Buscar..." onSearch={setQuery} />
          {/* más filtros */}
        </div>

        {/* Tabla principal */}
        <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
          <Table data={data} columns={columns} />
        </div>

        {/* Paginación */}
        <div className="flex justify-end gap-2">
          {nextCursor && (
            <Link href={`?cursor=${nextCursor}`}>
              <Button variant="ghost" size="sm">Siguiente →</Button>
            </Link>
          )}
        </div>
      </div>
    </div>
  )
}
```

## Sidebar — azul marino

```tsx
// El sidebar ya está construido en components/layout/Sidebar.tsx (INMUTABLE)
// Referencia de estilos para crear items consistentes:

// Item normal:
className="flex items-center gap-3 px-4 py-2.5 text-white/80 hover:bg-navy-light hover:text-white rounded-lg transition-colors"

// Item activo:
className="flex items-center gap-3 px-4 py-2.5 bg-navy-light text-white rounded-lg border-l-4 border-white"

// Badge de alerta en item:
<span className="ml-auto w-2 h-2 rounded-full bg-red-400" />
```

## Formularios — mobile-first desde 375px

```tsx
// Todos los formularios deben funcionar en 375px
<div className="space-y-4 w-full max-w-lg">
  {/* Stack vertical en mobile, grid en desktop */}
  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
    <Input name="nombre" label="Nombre" />
    <Input name="apellido" label="Apellido" />
  </div>

  {/* Botones: full width en mobile */}
  <div className="flex flex-col sm:flex-row gap-3 pt-4">
    <Button type="submit" loading={pending} className="w-full sm:w-auto">
      Guardar
    </Button>
    <Button variant="secondary" className="w-full sm:w-auto">
      Cancelar
    </Button>
  </div>
</div>
```

## Tablas — diseño consistente

```tsx
// Header de tabla: azul marino claro
<thead className="bg-blue-light border-b border-blue-border">
  <tr>
    <th className="px-4 py-3 text-left text-xs font-semibold text-navy uppercase tracking-wider">
      Columna
    </th>
  </tr>
</thead>

// Filas alternas:
<tbody className="divide-y divide-gray-200">
  {data.map((row, i) => (
    <tr
      key={row.id}
      className={`
        ${i % 2 === 0 ? 'bg-white' : 'bg-gray-50'}
        hover:bg-blue-light cursor-pointer transition-colors
      `}
      onClick={() => onRowClick(row)}
    >
```

## Estados de alerta — colores semánticos

```tsx
// Sin TC del día — amarillo prominente
<div className="p-4 bg-amber-50 border-l-4 border-amber-500 rounded-r-lg">
  <p className="font-semibold text-amber-800">⚠️ Sin tipo de cambio hoy</p>
  <p className="text-sm text-amber-700">Las ventas están bloqueadas hasta cargarlo.</p>
</div>

// Error crítico — rojo
<div className="p-4 bg-red-50 border-l-4 border-red-500 rounded-r-lg">
  <p className="font-semibold text-red-800">🔴 {cantidadUrgentes} novedades urgentes</p>
</div>

// Éxito / OK — verde
<div className="p-4 bg-green-50 border border-green-200 rounded-lg">
  <p className="text-green-800">✓ Stock en orden</p>
</div>

// Informativo — azul claro
<div className="p-4 bg-blue-light border border-blue-border rounded-lg">
  <p className="text-navy text-sm">💡 El precio ARS se calculará al TC del día de retiro</p>
</div>
```

---

## Principios de diseño base (para todos los proyectos)

Antes de codear, definir la dirección estética. Para este ERP:
- **Tono:** Profesional, confiable, eficiente. No decorativo.
- **Tipografía:** Inter o sistema — legibilidad máxima en datos densos.
- **Densidad:** Alta — los usuarios manejan tablas con muchos registros.
- **Movimiento:** Mínimo — solo transiciones de estado (hover, focus, loading).
- **Mobile:** Funcional, no idéntico al desktop. Priorizar acciones clave.

### Lo que NUNCA hacer en este sistema
- Gradientes decorativos en fondos de páginas
- Animaciones complejas en tablas o listados
- Colores fuera de la paleta del proyecto
- Fuentes decorativas — solo Inter o sistema
- Cards con sombras pesadas — usar bordes sutiles