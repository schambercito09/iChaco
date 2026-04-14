# CHANGELOG — ERP/CRM Pyme de Tecnología

> Registro de cambios por versión. Actualizar antes de cada deploy a producción.
> Formato: [Tipo] Descripción — Tipo: Nuevo | Mejora | Fix | Seguridad | Cambio

---

## [Sin publicar] — Próxima versión

### Nuevas funcionalidades
- ...

### Mejoras
- ...

### Fixes
- ...

---

## [v1.0.0] — FECHA_DE_DEPLOY — Fase 1 completa

### Nuevas funcionalidades
- [Nuevo] Sistema de tipo de cambio diario con bloqueo automático de ventas
- [Nuevo] Catálogo de productos con variantes (color, capacidad, RAM)
- [Nuevo] Inventario con stock por depósito y trazabilidad por IMEI
- [Nuevo] POS / Nueva venta con múltiples métodos de pago en ARS y USD
- [Nuevo] Presupuestos con seguimiento, PDF y conversión a venta
- [Nuevo] Separas (reservas con seña) con alertas de vencimiento
- [Nuevo] Módulo de usados: ficha de defectos y precio sugerido automático
- [Nuevo] Clientes con cuenta corriente en ARS y USD
- [Nuevo] Caja diaria con apertura/cierre y diferencias en ARS y USD
- [Nuevo] Demanda no satisfecha con registro rápido desde el POS
- [Nuevo] Novedades entre turnos con briefing al iniciar sesión
- [Nuevo] Dashboard con métricas del día y alertas activas
- [Nuevo] Módulo de vendedores con métricas individuales y objetivos

### Técnico
- Schema de base de datos con RLS activado en todas las tablas
- Numeración de documentos via PostgreSQL SEQUENCE (sin duplicados)
- Transacción atómica de venta via función RPC confirmar_venta()
- Trigger Auth → usuarios para creación automática de perfiles
- Storage con buckets para imágenes de productos y fotos de usados

---

## [v0.1.0] — FECHA — Fundación del proyecto

### Técnico
- Proyecto Next.js 14 configurado con Supabase y Tailwind
- Schema de base de datos Fase 1 creado
- Sistema de autenticación con Supabase Auth
- Componentes UI base (Button, Input, Modal, Drawer, Table, etc.)

---

## Cómo actualizar este archivo

Antes de cada deploy a producción:
1. Mover el contenido de "[Sin publicar]" a una nueva versión `[vX.Y.Z]`
2. Agregar la fecha del deploy
3. Dejar "[Sin publicar]" vacío para el próximo ciclo
4. Hacer commit: `docs: actualizar changelog para vX.Y.Z`
