-- =============================================================================
-- 002_fix_usuarios.sql
-- Adapta la tabla usuarios al schema esperado por el código.
-- Agrega columnas faltantes sin borrar las existentes.
-- Seguro para ejecutar múltiples veces (IF NOT EXISTS).
-- =============================================================================

-- 1. Apellido (el código espera nombre + apellido separados)
ALTER TABLE usuarios
  ADD COLUMN IF NOT EXISTS apellido TEXT NOT NULL DEFAULT '';

-- 2. Rol tipado (reemplaza el booleano es_admin)
ALTER TABLE usuarios
  ADD COLUMN IF NOT EXISTS rol TEXT NOT NULL DEFAULT 'vendedor'
  CHECK (rol IN ('superadmin','admin','vendedor','tecnico','deposito'));

-- 3. FK al depósito asignado
ALTER TABLE usuarios
  ADD COLUMN IF NOT EXISTS deposito_id UUID REFERENCES depositos(id);

-- 4. Métricas comerciales opcionales
ALTER TABLE usuarios
  ADD COLUMN IF NOT EXISTS comision_porcentaje NUMERIC(5,2);

ALTER TABLE usuarios
  ADD COLUMN IF NOT EXISTS meta_mensual_usd NUMERIC(12,2);

-- =============================================================================
-- Migración de datos: poblar las nuevas columnas con los valores existentes
-- =============================================================================

-- Derivar rol desde es_admin (si la columna existe)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'usuarios' AND column_name = 'es_admin'
  ) THEN
    UPDATE usuarios
    SET rol = CASE WHEN es_admin = true THEN 'admin' ELSE 'vendedor' END
    WHERE rol = 'vendedor';  -- solo las que tienen el default, no sobrescribir asignaciones manuales
  END IF;
END $$;

-- Derivar deposito_id desde sucursal_id (si la columna existe)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'usuarios' AND column_name = 'sucursal_id'
  ) THEN
    UPDATE usuarios
    SET deposito_id = sucursal_id::uuid
    WHERE deposito_id IS NULL
      AND sucursal_id IS NOT NULL;
  END IF;
END $$;

-- =============================================================================
-- Índice para búsquedas por depósito
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_usuarios_deposito_id ON usuarios(deposito_id);
