-- =============================================================================
-- 001a_schema_core.sql — Schema CORE del ERP/CRM
-- Paso 2a — Ejecutar en Supabase SQL Editor
-- Contiene: tipos_cambio_dolar, configuracion_sistema, depositos, usuarios,
--           catálogo, precios, inventario, proveedores, auditoría
--           + triggers, sequences, funciones helper e índices
-- =============================================================================

-- =============================================================================
-- 1. CONFIGURACIÓN BASE
-- =============================================================================

CREATE TABLE tipos_cambio_dolar (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha      DATE NOT NULL UNIQUE,
  valor_ars  NUMERIC(12,4) NOT NULL,
  tipo       TEXT NOT NULL CHECK (tipo IN ('oficial','blue','personalizado')),
  fuente     TEXT NOT NULL CHECK (fuente IN ('manual','api_bcra','api_bluelytics')),
  usuario_id UUID REFERENCES auth.users,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE configuracion_sistema (
  clave                 TEXT PRIMARY KEY,
  valor                 TEXT NOT NULL,
  tipo_valor            TEXT NOT NULL CHECK (tipo_valor IN ('integer','decimal','boolean','text','json')),
  descripcion           TEXT,
  modulo                TEXT,
  updated_at            TIMESTAMPTZ DEFAULT now(),
  updated_by_usuario_id UUID REFERENCES auth.users
);

CREATE TABLE depositos (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre    TEXT NOT NULL,
  tipo      TEXT NOT NULL CHECK (tipo IN ('tienda','deposito','servicio_tecnico')),
  direccion TEXT,
  activo    BOOLEAN DEFAULT true
);

CREATE TABLE usuarios (
  id                    UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  nombre                TEXT NOT NULL,
  apellido              TEXT NOT NULL,
  email                 TEXT NOT NULL,
  rol                   TEXT NOT NULL CHECK (rol IN ('superadmin','admin','vendedor','tecnico','deposito')),
  deposito_id           UUID REFERENCES depositos,
  comision_porcentaje   NUMERIC(5,2),
  meta_mensual_usd      NUMERIC(12,2),
  activo                BOOLEAN DEFAULT true,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

-- =============================================================================
-- 2. CATÁLOGO
-- =============================================================================

CREATE TABLE categorias (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre            TEXT NOT NULL,
  categoria_padre_id UUID REFERENCES categorias,
  activo            BOOLEAN DEFAULT true
);

CREATE TABLE marcas (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre      TEXT NOT NULL,
  pais_origen TEXT,
  logo_url    TEXT
);

CREATE TABLE productos (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku                      TEXT UNIQUE NOT NULL,
  nombre                   TEXT NOT NULL,
  descripcion              TEXT,
  categoria_id             UUID REFERENCES categorias,
  marca_id                 UUID REFERENCES marcas,
  tipo                     TEXT NOT NULL CHECK (tipo IN ('serializado','generico','servicio')),
  requiere_imei            BOOLEAN DEFAULT false,
  requiere_numero_serie    BOOLEAN DEFAULT false,
  garantia_meses           INT DEFAULT 0,
  activo                   BOOLEAN DEFAULT true,
  created_at               TIMESTAMPTZ DEFAULT now(),
  updated_at               TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE variantes_producto (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producto_id UUID NOT NULL REFERENCES productos ON DELETE CASCADE,
  color       TEXT,
  capacidad_gb INT,
  ram_gb      INT,
  version     TEXT,
  modelo      TEXT,
  sku_variante TEXT UNIQUE NOT NULL,
  activo      BOOLEAN DEFAULT true
);

CREATE TABLE imagenes_producto (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producto_id UUID NOT NULL REFERENCES productos ON DELETE CASCADE,
  variante_id UUID REFERENCES variantes_producto,
  url         TEXT NOT NULL,
  orden       INT DEFAULT 0,
  es_principal BOOLEAN DEFAULT false
);

-- =============================================================================
-- 3. PRECIOS
-- =============================================================================

CREATE TABLE listas_precio (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre      TEXT NOT NULL,
  tipo        TEXT NOT NULL CHECK (tipo IN ('minorista','mayorista','distribuidor','empleado')),
  moneda_base TEXT NOT NULL DEFAULT 'USD' CHECK (moneda_base IN ('USD','ARS')),
  activa      BOOLEAN DEFAULT true
);

CREATE TABLE precios_variante (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  variante_id           UUID NOT NULL REFERENCES variantes_producto ON DELETE CASCADE,
  lista_precio_id       UUID NOT NULL REFERENCES listas_precio ON DELETE CASCADE,
  precio_usd            NUMERIC(12,2) NOT NULL,
  precio_ars_override   NUMERIC(12,2),
  usar_precio_ars_fijo  BOOLEAN DEFAULT false,
  margen_porcentaje     NUMERIC(5,2) DEFAULT 0,
  vigente_desde         DATE DEFAULT CURRENT_DATE,
  vigente_hasta         DATE,
  UNIQUE (variante_id, lista_precio_id)
);

CREATE TABLE historial_precios (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  variante_id           UUID NOT NULL REFERENCES variantes_producto,
  lista_precio_id       UUID NOT NULL REFERENCES listas_precio,
  precio_usd_anterior   NUMERIC(12,2),
  precio_usd_nuevo      NUMERIC(12,2) NOT NULL,
  motivo                TEXT,
  usuario_id            UUID REFERENCES auth.users,
  created_at            TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE reglas_descuento (
  id                           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre                       TEXT NOT NULL,
  tipo                         TEXT NOT NULL CHECK (tipo IN ('porcentaje','monto_fijo')),
  valor_descuento              NUMERIC(10,2) NOT NULL,
  descuento_maximo_porcentaje  NUMERIC(5,2) NOT NULL,
  aplica_a                     TEXT NOT NULL CHECK (aplica_a IN ('todo','categoria','marca','producto')),
  referencia_id                UUID,
  activa                       BOOLEAN DEFAULT true,
  vigente_desde                DATE DEFAULT CURRENT_DATE,
  vigente_hasta                DATE
);

-- =============================================================================
-- 4. INVENTARIO
-- =============================================================================

CREATE TABLE stock (
  variante_id           UUID NOT NULL REFERENCES variantes_producto ON DELETE CASCADE,
  deposito_id           UUID NOT NULL REFERENCES depositos ON DELETE CASCADE,
  cantidad_disponible   INT NOT NULL DEFAULT 0,
  cantidad_reservada    INT NOT NULL DEFAULT 0,
  cantidad_en_transito  INT NOT NULL DEFAULT 0,
  stock_minimo          INT NOT NULL DEFAULT 0,
  stock_maximo          INT,
  PRIMARY KEY (variante_id, deposito_id)
);

CREATE TABLE unidades_serializadas (
  id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  variante_id                UUID NOT NULL REFERENCES variantes_producto,
  deposito_id                UUID NOT NULL REFERENCES depositos,
  imei                       TEXT UNIQUE,
  numero_serie               TEXT UNIQUE,
  estado                     TEXT NOT NULL DEFAULT 'disponible'
    CHECK (estado IN ('disponible','vendido','reservado','en_reparacion','en_garantia_proveedor','baja')),
  condicion                  TEXT NOT NULL DEFAULT 'nuevo'
    CHECK (condicion IN ('nuevo','excelente','muy_bueno','bueno','regular','para_reparar')),
  es_usado                   BOOLEAN DEFAULT false,
  origen_usado               TEXT CHECK (origen_usado IN ('compra_directa','parte_de_pago','recepcion_garantia','otro')),
  precio_venta_sugerido_usd  NUMERIC(12,2),
  precio_venta_sugerido_ars  NUMERIC(12,2),
  costo_adquisicion_usd      NUMERIC(12,2),
  costo_total_usd            NUMERIC(12,2),
  fecha_ingreso_stock        DATE DEFAULT CURRENT_DATE,
  sepa_id                    UUID,
  tipo_cambio_id             UUID REFERENCES tipos_cambio_dolar,
  notas_estado               TEXT,
  created_at                 TIMESTAMPTZ DEFAULT now(),
  updated_at                 TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE movimientos_stock (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo                TEXT NOT NULL CHECK (tipo IN ('ingreso','egreso','transferencia','ajuste','devolucion')),
  variante_id         UUID NOT NULL REFERENCES variantes_producto,
  deposito_origen_id  UUID REFERENCES depositos,
  deposito_destino_id UUID REFERENCES depositos,
  cantidad            INT NOT NULL,
  motivo              TEXT,
  referencia_tipo     TEXT CHECK (referencia_tipo IN
    ('venta','compra','compra_usados','transferencia','ajuste','sepa','devolucion','garantia_proveedor')),
  referencia_id       UUID,
  usuario_id          UUID REFERENCES auth.users,
  created_at          TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE ajustes_stock (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  variante_id              UUID NOT NULL REFERENCES variantes_producto,
  deposito_id              UUID NOT NULL REFERENCES depositos,
  unidad_serializada_id    UUID REFERENCES unidades_serializadas,
  tipo_ajuste              TEXT NOT NULL CHECK (tipo_ajuste IN ('entrada','salida')),
  cantidad                 INT NOT NULL,
  motivo                   TEXT NOT NULL CHECK (motivo IN
    ('defecto_origen','rotura_interna','robo','error_conteo','vencimiento','muestra','otro')),
  descripcion              TEXT NOT NULL,
  referencia_tipo          TEXT CHECK (referencia_tipo IN ('recepcion','devolucion','garantia_proveedor','manual')),
  referencia_id            UUID,
  aprobado_por_usuario_id  UUID REFERENCES auth.users,
  usuario_id               UUID REFERENCES auth.users,
  created_at               TIMESTAMPTZ DEFAULT now()
);

-- =============================================================================
-- 5. PROVEEDORES
-- =============================================================================

CREATE TABLE proveedores (
  id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  razon_social                    TEXT NOT NULL,
  nombre_fantasia                 TEXT,
  cuit                            TEXT,
  email                           TEXT,
  telefono                        TEXT,
  whatsapp                        TEXT,
  direccion                       TEXT,
  condicion_pago                  TEXT CHECK (condicion_pago IN ('contado','15_dias','30_dias','60_dias')),
  moneda_preferida                TEXT DEFAULT 'USD' CHECK (moneda_preferida IN ('ARS','USD')),
  tipo_proveedor                  TEXT CHECK (tipo_proveedor IN
    ('distribuidor_nuevo','recuperadora_usados','particular','empresa_renovacion','otro')),
  vende_usado                     BOOLEAN DEFAULT false,
  vende_nuevo                     BOOLEAN DEFAULT true,
  requiere_factura                BOOLEAN DEFAULT true,
  riesgo_legal                    TEXT DEFAULT 'bajo' CHECK (riesgo_legal IN ('bajo','medio','alto')),
  notas_internas                  TEXT,
  lead_time_promedio_dias         NUMERIC(5,1),
  tasa_defectos_porcentaje        NUMERIC(5,2),
  cumplimiento_precio_porcentaje  NUMERIC(5,2),
  score_general                   NUMERIC(3,1),
  score_actualizado_at            TIMESTAMPTZ,
  activo                          BOOLEAN DEFAULT true,
  created_at                      TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE recepciones_mercaderia (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  orden_compra_id          UUID,
  proveedor_id             UUID REFERENCES proveedores,
  deposito_id              UUID NOT NULL REFERENCES depositos,
  numero_factura_proveedor TEXT,
  fecha_factura            DATE,
  tipo_cambio_id           UUID REFERENCES tipos_cambio_dolar,
  usuario_id               UUID REFERENCES auth.users,
  created_at               TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE detalle_recepciones (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recepcion_id       UUID NOT NULL REFERENCES recepciones_mercaderia ON DELETE CASCADE,
  variante_id        UUID NOT NULL REFERENCES variantes_producto,
  cantidad_recibida  INT NOT NULL,
  precio_costo_usd   NUMERIC(12,2) NOT NULL,
  precio_costo_ars   NUMERIC(12,2),
  imeis_ingresados   TEXT[]
);

-- =============================================================================
-- 6. AUDITORÍA
-- =============================================================================

CREATE TABLE log_actividad (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id       UUID REFERENCES auth.users,
  accion           TEXT NOT NULL CHECK (accion IN
    ('crear','editar','eliminar','anular','aprobar','rechazar','login','logout')),
  tabla_afectada   TEXT NOT NULL,
  registro_id      UUID,
  datos_anteriores JSONB,
  datos_nuevos     JSONB,
  ip_address       TEXT,
  descripcion      TEXT NOT NULL,
  created_at       TIMESTAMPTZ DEFAULT now()
);

-- =============================================================================
-- TRIGGERS — updated_at automático
-- =============================================================================

CREATE OR REPLACE FUNCTION trigger_set_updated_at()
  RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_updated_at_usuarios
  BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

CREATE TRIGGER set_updated_at_productos
  BEFORE UPDATE ON productos
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

CREATE TRIGGER set_updated_at_variantes_producto
  BEFORE UPDATE ON variantes_producto
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

CREATE TRIGGER set_updated_at_unidades_serializadas
  BEFORE UPDATE ON unidades_serializadas
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

-- =============================================================================
-- SEQUENCES — numeración de documentos sin race condition
-- =============================================================================

CREATE SEQUENCE seq_numero_venta       START 1;
CREATE SEQUENCE seq_numero_presupuesto START 1;
CREATE SEQUENCE seq_numero_sepa        START 1;
CREATE SEQUENCE seq_numero_demanda     START 1;
CREATE SEQUENCE seq_numero_ppago       START 1;
CREATE SEQUENCE seq_numero_oc          START 1;

-- Funciones helper — generan el número con prefijo
CREATE OR REPLACE FUNCTION next_numero_venta()
  RETURNS TEXT LANGUAGE SQL AS $$
  SELECT 'V-' || LPAD(nextval('seq_numero_venta')::TEXT, 5, '0')
$$;

CREATE OR REPLACE FUNCTION next_numero_presupuesto()
  RETURNS TEXT LANGUAGE SQL AS $$
  SELECT 'PRS-' || LPAD(nextval('seq_numero_presupuesto')::TEXT, 5, '0')
$$;

CREATE OR REPLACE FUNCTION next_numero_sepa()
  RETURNS TEXT LANGUAGE SQL AS $$
  SELECT 'SEP-' || LPAD(nextval('seq_numero_sepa')::TEXT, 5, '0')
$$;

CREATE OR REPLACE FUNCTION next_numero_demanda()
  RETURNS TEXT LANGUAGE SQL AS $$
  SELECT 'DNS-' || LPAD(nextval('seq_numero_demanda')::TEXT, 5, '0')
$$;

CREATE OR REPLACE FUNCTION next_numero_ppago()
  RETURNS TEXT LANGUAGE SQL AS $$
  SELECT 'PP-' || LPAD(nextval('seq_numero_ppago')::TEXT, 5, '0')
$$;

-- =============================================================================
-- TRIGGER Auth → usuarios (CRÍTICO)
-- Cuando alguien se registra en auth.users, crea su fila en public.usuarios
-- Sin esto el sistema queda en estado roto
-- =============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
  RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.usuarios (id, nombre, apellido, email, rol, activo)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nombre', 'Sin nombre'),
    COALESCE(NEW.raw_user_meta_data->>'apellido', ''),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'rol', 'vendedor'),
    true
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- TRIGGERS — numeración automática de documentos
-- (las tablas ventas, presupuestos, etc. se crean en 001b — estos triggers
--  se definen aquí junto a sus funciones pero se aplican en 001b)
-- =============================================================================

CREATE OR REPLACE FUNCTION trigger_set_numero_venta()
  RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.numero_venta IS NULL OR NEW.numero_venta = '' THEN
    NEW.numero_venta := next_numero_venta();
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION trigger_set_numero_presupuesto()
  RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.numero_presupuesto IS NULL OR NEW.numero_presupuesto = '' THEN
    NEW.numero_presupuesto := next_numero_presupuesto();
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION trigger_set_numero_sepa()
  RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.numero_sepa IS NULL OR NEW.numero_sepa = '' THEN
    NEW.numero_sepa := next_numero_sepa();
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION trigger_set_numero_demanda()
  RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.numero_demanda IS NULL OR NEW.numero_demanda = '' THEN
    NEW.numero_demanda := next_numero_demanda();
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION trigger_set_numero_ppago()
  RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.numero_ppago IS NULL OR NEW.numero_ppago = '' THEN
    NEW.numero_ppago := next_numero_ppago();
  END IF;
  RETURN NEW;
END;
$$;

-- =============================================================================
-- ÍNDICES
-- =============================================================================

CREATE INDEX idx_unidades_imei     ON unidades_serializadas (imei) WHERE imei IS NOT NULL;
CREATE INDEX idx_unidades_estado   ON unidades_serializadas (estado, deposito_id);
CREATE INDEX idx_unidades_variante ON unidades_serializadas (variante_id, estado);
CREATE INDEX idx_stock_deposito    ON stock (deposito_id);
CREATE INDEX idx_movimientos_variante ON movimientos_stock (variante_id, created_at DESC);
CREATE INDEX idx_log_tabla         ON log_actividad (tabla_afectada, created_at DESC);
CREATE INDEX idx_proveedores_tipo  ON proveedores (tipo_proveedor, activo);
