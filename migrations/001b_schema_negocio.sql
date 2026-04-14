-- =============================================================================
-- 001b_schema_negocio.sql — Schema de NEGOCIO del ERP/CRM
-- Paso 2b — Ejecutar en Supabase SQL Editor
-- REQUISITO: 001a_schema_core.sql debe estar ejecutado primero
-- Contiene: clientes, ventas, caja, usados, separas, novedades
--           + triggers de numeración, RPC confirmar_venta, RLS completo
-- =============================================================================

-- =============================================================================
-- 7. CLIENTES
-- =============================================================================

CREATE TABLE clientes (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo              TEXT NOT NULL CHECK (tipo IN ('persona','empresa')),
  nombre            TEXT NOT NULL,
  apellido          TEXT,
  razon_social      TEXT,
  dni               TEXT,
  cuit              TEXT,
  email             TEXT,
  telefono          TEXT NOT NULL,
  whatsapp          TEXT,
  direccion         TEXT,
  ciudad            TEXT,
  provincia         TEXT,
  fecha_nacimiento  DATE,
  lista_precio_id   UUID REFERENCES listas_precio,
  moneda_preferida  TEXT DEFAULT 'ARS' CHECK (moneda_preferida IN ('ARS','USD')),
  origen            TEXT CHECK (origen IN ('mostrador','instagram','mercadolibre','referido','web')),
  activo            BOOLEAN DEFAULT true,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE garantias_cliente (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id                  UUID NOT NULL REFERENCES clientes,
  venta_id                    UUID,
  unidad_serializada_id       UUID REFERENCES unidades_serializadas,
  imei                        TEXT,
  numero_serie                TEXT,
  producto_nombre             TEXT NOT NULL,
  fecha_compra                DATE NOT NULL,
  fecha_vencimiento_garantia  DATE NOT NULL,
  estado                      TEXT NOT NULL DEFAULT 'vigente'
    CHECK (estado IN ('vigente','vencida','reclamada'))
);

CREATE TABLE cuentas_corriente_cliente (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id          UUID NOT NULL UNIQUE REFERENCES clientes ON DELETE CASCADE,
  saldo_deudor_ars    NUMERIC(14,2) DEFAULT 0,
  saldo_deudor_usd    NUMERIC(14,2) DEFAULT 0,
  limite_credito_ars  NUMERIC(14,2) DEFAULT 0,
  limite_credito_usd  NUMERIC(14,2) DEFAULT 0,
  activa              BOOLEAN DEFAULT true
);

CREATE TABLE movimientos_cuenta_corriente (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id          UUID NOT NULL REFERENCES clientes,
  tipo                TEXT NOT NULL CHECK (tipo IN ('cargo','pago','ajuste')),
  moneda              TEXT NOT NULL CHECK (moneda IN ('ARS','USD')),
  monto               NUMERIC(14,2) NOT NULL,
  tipo_cambio_id      UUID REFERENCES tipos_cambio_dolar,
  referencia_venta_id UUID,
  descripcion         TEXT NOT NULL,
  created_at          TIMESTAMPTZ DEFAULT now()
);

-- =============================================================================
-- 8. VENTAS Y PAGOS
-- =============================================================================

CREATE TABLE metodos_pago (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre             TEXT NOT NULL UNIQUE,
  acepta_usd         BOOLEAN DEFAULT false,
  genera_recargo     BOOLEAN DEFAULT false,
  porcentaje_recargo NUMERIC(5,2) DEFAULT 0,
  activo             BOOLEAN DEFAULT true
);

CREATE TABLE ventas (
  id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero_venta               TEXT UNIQUE NOT NULL,
  cliente_id                 UUID REFERENCES clientes,
  deposito_id                UUID NOT NULL REFERENCES depositos,
  usuario_vendedor_id        UUID NOT NULL REFERENCES auth.users,
  estado                     TEXT NOT NULL DEFAULT 'presupuesto'
    CHECK (estado IN ('presupuesto','confirmada','entregada','cancelada','con_cambio')),
  canal                      TEXT NOT NULL DEFAULT 'mostrador'
    CHECK (canal IN ('mostrador','whatsapp','mercadolibre','web','servicio_tecnico')),
  tipo_cambio_id             UUID REFERENCES tipos_cambio_dolar,
  tipo_cambio_valor_ars      NUMERIC(12,4),
  moneda_base                TEXT NOT NULL DEFAULT 'USD' CHECK (moneda_base IN ('ARS','USD')),
  subtotal_usd               NUMERIC(14,2) NOT NULL DEFAULT 0,
  subtotal_ars               NUMERIC(14,2) NOT NULL DEFAULT 0,
  descuento_global_monto_usd NUMERIC(14,2) DEFAULT 0,
  descuento_global_monto_ars NUMERIC(14,2) DEFAULT 0,
  total_usd                  NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_ars                  NUMERIC(14,2) NOT NULL DEFAULT 0,
  lista_precio_id            UUID REFERENCES listas_precio,
  notas                      TEXT,
  created_at                 TIMESTAMPTZ DEFAULT now(),
  fecha_confirmacion         TIMESTAMPTZ
);

CREATE TABLE items_venta (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venta_id              UUID NOT NULL REFERENCES ventas ON DELETE CASCADE,
  variante_id           UUID NOT NULL REFERENCES variantes_producto,
  unidad_serializada_id UUID REFERENCES unidades_serializadas,
  cantidad              INT NOT NULL DEFAULT 1,
  precio_lista_usd      NUMERIC(12,2) NOT NULL,
  precio_lista_ars      NUMERIC(12,2) NOT NULL,
  descuento_porcentaje  NUMERIC(5,2) DEFAULT 0,
  precio_final_usd      NUMERIC(12,2) NOT NULL,
  precio_final_ars      NUMERIC(12,2) NOT NULL,
  precio_costo_usd      NUMERIC(12,2),
  precio_costo_ars      NUMERIC(12,2),
  margen_porcentaje     NUMERIC(5,2)
);

CREATE TABLE pagos_venta (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venta_id           UUID NOT NULL REFERENCES ventas ON DELETE CASCADE,
  metodo_pago_id     UUID NOT NULL REFERENCES metodos_pago,
  monto_ars          NUMERIC(14,2),
  monto_usd          NUMERIC(14,2),
  cuotas             INT,
  referencia_externa TEXT,
  created_at         TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE aprobaciones_descuento (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venta_id                 UUID REFERENCES ventas,
  presupuesto_id           UUID,
  usuario_solicitante_id   UUID NOT NULL REFERENCES auth.users,
  usuario_aprobador_id     UUID REFERENCES auth.users,
  variante_id              UUID NOT NULL REFERENCES variantes_producto,
  descuento_solicitado_pct NUMERIC(5,2) NOT NULL,
  descuento_maximo_rol_pct NUMERIC(5,2) NOT NULL,
  motivo_solicitud         TEXT NOT NULL,
  estado                   TEXT NOT NULL DEFAULT 'pendiente'
    CHECK (estado IN ('pendiente','aprobado','rechazado')),
  motivo_rechazo           TEXT,
  created_at               TIMESTAMPTZ DEFAULT now(),
  resuelta_at              TIMESTAMPTZ
);

-- =============================================================================
-- 9. PRESUPUESTOS
-- =============================================================================

CREATE TABLE presupuestos (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero_presupuesto   TEXT UNIQUE NOT NULL,
  cliente_id           UUID REFERENCES clientes,
  nombre_cliente_libre TEXT,
  telefono_libre       TEXT,
  usuario_vendedor_id  UUID NOT NULL REFERENCES auth.users,
  tipo_cambio_id       UUID REFERENCES tipos_cambio_dolar,
  subtotal_usd         NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_usd            NUMERIC(14,2) NOT NULL DEFAULT 0,
  subtotal_ars         NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_ars            NUMERIC(14,2) NOT NULL DEFAULT 0,
  estado               TEXT NOT NULL DEFAULT 'borrador'
    CHECK (estado IN ('borrador','enviado','visto','en_negociacion','aceptado','rechazado','vencido','convertido')),
  vigencia_hasta       DATE,
  venta_id             UUID REFERENCES ventas,
  canal_envio          TEXT CHECK (canal_envio IN ('whatsapp','email','mostrador','mercadolibre')),
  motivo_rechazo       TEXT CHECK (motivo_rechazo IN
    ('precio','encontro_mas_barato','no_tenia_lo_que_buscaba','demoro_en_responder','sin_presupuesto','otro')),
  competidor_id        UUID,
  precio_competencia_usd NUMERIC(12,2),
  created_at           TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE items_presupuesto (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  presupuesto_id        UUID NOT NULL REFERENCES presupuestos ON DELETE CASCADE,
  variante_id           UUID NOT NULL REFERENCES variantes_producto,
  unidad_serializada_id UUID REFERENCES unidades_serializadas,
  cantidad              INT NOT NULL DEFAULT 1,
  precio_lista_usd      NUMERIC(12,2) NOT NULL,
  precio_lista_ars      NUMERIC(12,2) NOT NULL,
  descuento_porcentaje  NUMERIC(5,2) DEFAULT 0,
  precio_final_usd      NUMERIC(12,2) NOT NULL,
  precio_final_ars      NUMERIC(12,2) NOT NULL
);

-- =============================================================================
-- 10. CAJA
-- =============================================================================

CREATE TABLE cajas (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre      TEXT NOT NULL,
  deposito_id UUID NOT NULL REFERENCES depositos,
  tipo        TEXT NOT NULL CHECK (tipo IN ('efectivo','electronica')),
  activa      BOOLEAN DEFAULT true
);

CREATE TABLE sesiones_caja (
  id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  caja_id                    UUID NOT NULL REFERENCES cajas,
  usuario_id                 UUID NOT NULL REFERENCES auth.users,
  monto_apertura_ars         NUMERIC(14,2) DEFAULT 0,
  monto_apertura_usd         NUMERIC(14,2) DEFAULT 0,
  monto_cierre_declarado_ars NUMERIC(14,2),
  monto_cierre_declarado_usd NUMERIC(14,2),
  monto_cierre_sistema_ars   NUMERIC(14,2),
  monto_cierre_sistema_usd   NUMERIC(14,2),
  diferencia_ars             NUMERIC(14,2),
  diferencia_usd             NUMERIC(14,2),
  estado                     TEXT NOT NULL DEFAULT 'abierta'
    CHECK (estado IN ('abierta','cerrada')),
  abierta_at                 TIMESTAMPTZ DEFAULT now(),
  cerrada_at                 TIMESTAMPTZ
);

CREATE TABLE movimientos_caja (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sesion_caja_id UUID NOT NULL REFERENCES sesiones_caja,
  tipo           TEXT NOT NULL CHECK (tipo IN ('ingreso','egreso','venta','devolucion','gasto')),
  moneda         TEXT NOT NULL CHECK (moneda IN ('ARS','USD')),
  monto          NUMERIC(14,2) NOT NULL,
  tipo_cambio_id UUID REFERENCES tipos_cambio_dolar,
  descripcion    TEXT NOT NULL,
  referencia_id  UUID,
  created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE categorias_gasto (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre      TEXT NOT NULL UNIQUE,
  descripcion TEXT,
  activo      BOOLEAN DEFAULT true
);

CREATE TABLE gastos (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deposito_id        UUID NOT NULL REFERENCES depositos,
  categoria_gasto_id UUID NOT NULL REFERENCES categorias_gasto,
  descripcion        TEXT NOT NULL,
  moneda             TEXT NOT NULL CHECK (moneda IN ('ARS','USD')),
  monto              NUMERIC(14,2) NOT NULL,
  tipo_cambio_id     UUID REFERENCES tipos_cambio_dolar,
  proveedor_id       UUID REFERENCES proveedores,
  comprobante_url    TEXT,
  usuario_id         UUID REFERENCES auth.users,
  created_at         TIMESTAMPTZ DEFAULT now()
);

-- =============================================================================
-- 11. USADOS Y PARTE DE PAGO
-- =============================================================================

CREATE TABLE catalogo_detalles_usados (
  id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre                     TEXT NOT NULL,
  categoria_detalle          TEXT NOT NULL
    CHECK (categoria_detalle IN
      ('pantalla','carcasa','bateria','camara','audio','biometria','conectividad','accesorios','software','otro')),
  severidad                  TEXT NOT NULL
    CHECK (severidad IN ('informativo','leve','moderado','grave','bloqueante')),
  reduce_precio_sugerido_usd NUMERIC(10,2) DEFAULT 0,
  requiere_alerta_venta      BOOLEAN DEFAULT false,
  activo                     BOOLEAN DEFAULT true
);

CREATE TABLE detalles_unidad_usada (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unidad_serializada_id     UUID NOT NULL REFERENCES unidades_serializadas ON DELETE CASCADE,
  detalle_id                UUID NOT NULL REFERENCES catalogo_detalles_usados,
  severidad_real            TEXT NOT NULL
    CHECK (severidad_real IN ('informativo','leve','moderado','grave','bloqueante')),
  descripcion_adicional     TEXT,
  foto_url                  TEXT[],
  registrado_por_usuario_id UUID REFERENCES auth.users,
  created_at                TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE partes_de_pago (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero_ppago          TEXT UNIQUE NOT NULL,
  venta_id              UUID REFERENCES ventas,
  cliente_id            UUID NOT NULL REFERENCES clientes,
  usuario_evaluador_id  UUID NOT NULL REFERENCES auth.users,
  imei_recibido         TEXT,
  descripcion_equipo    TEXT NOT NULL,
  variante_id           UUID REFERENCES variantes_producto,
  condicion_evaluada    TEXT NOT NULL
    CHECK (condicion_evaluada IN ('nuevo','excelente','muy_bueno','bueno','regular','para_reparar')),
  valor_ofrecido_usd    NUMERIC(12,2) NOT NULL,
  valor_ofrecido_ars    NUMERIC(12,2) NOT NULL,
  tipo_cambio_id        UUID NOT NULL REFERENCES tipos_cambio_dolar,
  estado                TEXT NOT NULL DEFAULT 'en_evaluacion'
    CHECK (estado IN ('en_evaluacion','aceptado','rechazado_cliente','rechazado_tienda')),
  unidad_serializada_id UUID REFERENCES unidades_serializadas,
  created_at            TIMESTAMPTZ DEFAULT now()
);

-- =============================================================================
-- 12. DEMANDA, SEPARAS Y NOVEDADES
-- =============================================================================

CREATE TABLE demandas_no_satisfechas (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero_demanda           TEXT UNIQUE NOT NULL,
  usuario_vendedor_id      UUID NOT NULL REFERENCES auth.users,
  deposito_id              UUID NOT NULL REFERENCES depositos,
  cliente_id               UUID REFERENCES clientes,
  nombre_cliente_libre     TEXT,
  telefono_cliente_libre   TEXT,
  variante_id              UUID REFERENCES variantes_producto,
  descripcion_libre        TEXT NOT NULL,
  marca_id                 UUID REFERENCES marcas,
  categoria_id             UUID REFERENCES categorias,
  cantidad_solicitada      INT DEFAULT 1,
  condicion_buscada        TEXT DEFAULT 'cualquiera'
    CHECK (condicion_buscada IN ('nuevo','usado','cualquiera')),
  presupuesto_cliente_usd  NUMERIC(12,2),
  estado                   TEXT NOT NULL DEFAULT 'sin_stock'
    CHECK (estado IN ('sin_stock','no_catalogado','precio_no_acordado','en_espera','contactado','vendido','perdido')),
  motivo_perdida           TEXT
    CHECK (motivo_perdida IN ('compro_competencia','precio','demoro_mucho','desistio','otro')),
  venta_id                 UUID REFERENCES ventas,
  competidor_id            UUID,
  canal_contacto_preferido TEXT DEFAULT 'whatsapp'
    CHECK (canal_contacto_preferido IN ('whatsapp','llamada','cualquiera')),
  created_at               TIMESTAMPTZ DEFAULT now(),
  contactado_at            TIMESTAMPTZ,
  cerrado_at               TIMESTAMPTZ
);

CREATE TABLE separas (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero_sepa               TEXT UNIQUE NOT NULL,
  cliente_id                UUID NOT NULL REFERENCES clientes,
  usuario_vendedor_id       UUID NOT NULL REFERENCES auth.users,
  deposito_id               UUID NOT NULL REFERENCES depositos,
  variante_id               UUID NOT NULL REFERENCES variantes_producto,
  unidad_serializada_id     UUID REFERENCES unidades_serializadas,
  descripcion_producto      TEXT NOT NULL,
  precio_acordado_usd       NUMERIC(12,2) NOT NULL,
  precio_acordado_ars       NUMERIC(12,2) NOT NULL,
  tipo_cambio_id            UUID NOT NULL REFERENCES tipos_cambio_dolar,
  tipo_cambio_concrecion_id UUID REFERENCES tipos_cambio_dolar,
  monto_seña_usd            NUMERIC(12,2) NOT NULL,
  monto_seña_ars            NUMERIC(12,2) NOT NULL,
  saldo_pendiente_usd       NUMERIC(12,2) NOT NULL,
  saldo_pendiente_ars       NUMERIC(12,2) NOT NULL,
  estado                    TEXT NOT NULL DEFAULT 'activa'
    CHECK (estado IN ('activa','concretada','vencida','cancelada_cliente','cancelada_tienda')),
  fecha_vencimiento         DATE NOT NULL,
  politica_seña_vencida     TEXT NOT NULL DEFAULT 'reintegrar'
    CHECK (politica_seña_vencida IN ('reintegrar','retener','credito_cuenta')),
  venta_id                  UUID REFERENCES ventas,
  created_at                TIMESTAMPTZ DEFAULT now(),
  concretada_at             TIMESTAMPTZ,
  vencida_at                TIMESTAMPTZ
);

CREATE TABLE pagos_sepa (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sepa_id        UUID NOT NULL REFERENCES separas ON DELETE CASCADE,
  metodo_pago_id UUID NOT NULL REFERENCES metodos_pago,
  monto_ars      NUMERIC(14,2),
  monto_usd      NUMERIC(14,2),
  tipo_cambio_id UUID NOT NULL REFERENCES tipos_cambio_dolar,
  sesion_caja_id UUID REFERENCES sesiones_caja,
  created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE novedades_turno (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deposito_id          UUID NOT NULL REFERENCES depositos,
  tipo                 TEXT NOT NULL
    CHECK (tipo IN ('cliente_viene','equipo_listo','llamar_cliente','mercaderia',
                    'sepa_vence_hoy','precio_actualizado','tarea_admin','otro')),
  prioridad            TEXT NOT NULL DEFAULT 'normal'
    CHECK (prioridad IN ('urgente','normal','informativa')),
  titulo               TEXT NOT NULL,
  descripcion          TEXT,
  cliente_id           UUID REFERENCES clientes,
  sepa_id              UUID REFERENCES separas,
  venta_id             UUID REFERENCES ventas,
  estado               TEXT NOT NULL DEFAULT 'pendiente'
    CHECK (estado IN ('pendiente','vista','resuelta','escalada')),
  generada_por         TEXT NOT NULL DEFAULT 'usuario'
    CHECK (generada_por IN ('sistema','usuario')),
  usuario_creador_id   UUID REFERENCES auth.users,
  usuario_resolutor_id UUID REFERENCES auth.users,
  created_at           TIMESTAMPTZ DEFAULT now(),
  vista_at             TIMESTAMPTZ,
  resuelta_at          TIMESTAMPTZ,
  vence_at             TIMESTAMPTZ
);

CREATE TABLE objetivos_vendedor (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id           UUID NOT NULL REFERENCES auth.users,
  periodo              DATE NOT NULL,
  meta_monto_usd       NUMERIC(12,2) NOT NULL,
  meta_cantidad_ventas INT NOT NULL,
  comision_porcentaje  NUMERIC(5,2),
  created_at           TIMESTAMPTZ DEFAULT now(),
  UNIQUE (usuario_id, periodo)
);

-- =============================================================================
-- TRIGGERS — updated_at para clientes
-- =============================================================================

CREATE TRIGGER set_updated_at_clientes
  BEFORE UPDATE ON clientes
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

-- =============================================================================
-- TRIGGERS — numeración automática (deferred from 001a, tablas ya existen)
-- =============================================================================

CREATE TRIGGER set_numero_venta
  BEFORE INSERT ON ventas
  FOR EACH ROW EXECUTE FUNCTION trigger_set_numero_venta();

CREATE TRIGGER set_numero_presupuesto
  BEFORE INSERT ON presupuestos
  FOR EACH ROW EXECUTE FUNCTION trigger_set_numero_presupuesto();

CREATE TRIGGER set_numero_sepa
  BEFORE INSERT ON separas
  FOR EACH ROW EXECUTE FUNCTION trigger_set_numero_sepa();

CREATE TRIGGER set_numero_demanda
  BEFORE INSERT ON demandas_no_satisfechas
  FOR EACH ROW EXECUTE FUNCTION trigger_set_numero_demanda();

CREATE TRIGGER set_numero_ppago
  BEFORE INSERT ON partes_de_pago
  FOR EACH ROW EXECUTE FUNCTION trigger_set_numero_ppago();

-- =============================================================================
-- ÍNDICES
-- =============================================================================

CREATE INDEX idx_ventas_deposito_fecha ON ventas (deposito_id, created_at DESC);
CREATE INDEX idx_ventas_vendedor       ON ventas (usuario_vendedor_id, created_at DESC);
CREATE INDEX idx_ventas_estado         ON ventas (estado, deposito_id);
CREATE INDEX idx_ventas_cliente        ON ventas (cliente_id);
CREATE INDEX idx_clientes_nombre       ON clientes (nombre, apellido);
CREATE INDEX idx_clientes_dni          ON clientes (dni) WHERE dni IS NOT NULL;
CREATE INDEX idx_separas_estado        ON separas (estado, fecha_vencimiento);
CREATE INDEX idx_separas_cliente       ON separas (cliente_id);
CREATE INDEX idx_novedades_deposito    ON novedades_turno (deposito_id, estado, prioridad);
CREATE INDEX idx_demandas_estado       ON demandas_no_satisfechas (estado, variante_id);
CREATE INDEX idx_sesiones_caja         ON sesiones_caja (caja_id, estado);
CREATE INDEX idx_movimientos_caja      ON movimientos_caja (sesion_caja_id, created_at DESC);

-- =============================================================================
-- FUNCIÓN RPC — confirmar_venta (transacción atómica)
-- Con el cliente JS de Supabase no es posible hacer transacciones reales
-- desde una Server Action. La única forma correcta es una función PostgreSQL.
-- Uso: const { data } = await supabase.rpc('confirmar_venta', { p_datos: datosJson })
-- =============================================================================

CREATE OR REPLACE FUNCTION confirmar_venta(p_datos JSONB)
  RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_venta_id UUID;
  v_numero   TEXT;
  v_item     JSONB;
  v_pago     JSONB;
  v_sesion   UUID;
BEGIN
  -- 1. Generar número de venta
  v_numero := next_numero_venta();

  -- 2. Insertar venta principal
  INSERT INTO ventas (
    numero_venta, cliente_id, deposito_id, usuario_vendedor_id,
    estado, canal, tipo_cambio_id, tipo_cambio_valor_ars, moneda_base,
    subtotal_usd, subtotal_ars, total_usd, total_ars, lista_precio_id, notas,
    fecha_confirmacion
  ) VALUES (
    v_numero,
    (p_datos->>'cliente_id')::UUID,
    (p_datos->>'deposito_id')::UUID,
    (p_datos->>'usuario_vendedor_id')::UUID,
    'confirmada',
    COALESCE(p_datos->>'canal', 'mostrador'),
    (p_datos->>'tipo_cambio_id')::UUID,
    (p_datos->>'tipo_cambio_valor_ars')::NUMERIC,
    COALESCE(p_datos->>'moneda_base', 'USD'),
    (p_datos->>'subtotal_usd')::NUMERIC,
    (p_datos->>'subtotal_ars')::NUMERIC,
    (p_datos->>'total_usd')::NUMERIC,
    (p_datos->>'total_ars')::NUMERIC,
    (p_datos->>'lista_precio_id')::UUID,
    p_datos->>'notas',
    now()
  ) RETURNING id INTO v_venta_id;

  -- 3. Items: insertar + descontar stock
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_datos->'items') LOOP
    INSERT INTO items_venta (
      venta_id, variante_id, unidad_serializada_id, cantidad,
      precio_lista_usd, precio_lista_ars, descuento_porcentaje,
      precio_final_usd, precio_final_ars, precio_costo_usd
    ) VALUES (
      v_venta_id,
      (v_item->>'variante_id')::UUID,
      (v_item->>'unidad_serializada_id')::UUID,
      (v_item->>'cantidad')::INT,
      (v_item->>'precio_lista_usd')::NUMERIC,
      (v_item->>'precio_lista_ars')::NUMERIC,
      COALESCE((v_item->>'descuento_porcentaje')::NUMERIC, 0),
      (v_item->>'precio_final_usd')::NUMERIC,
      (v_item->>'precio_final_ars')::NUMERIC,
      (v_item->>'precio_costo_usd')::NUMERIC
    );

    -- Si es serializado: marcar IMEI como vendido
    IF v_item->>'unidad_serializada_id' IS NOT NULL THEN
      UPDATE unidades_serializadas
      SET estado = 'vendido', updated_at = now()
      WHERE id = (v_item->>'unidad_serializada_id')::UUID;
    ELSE
      -- Genérico: decrementar stock
      UPDATE stock
      SET cantidad_disponible = cantidad_disponible - (v_item->>'cantidad')::INT
      WHERE variante_id = (v_item->>'variante_id')::UUID
        AND deposito_id  = (p_datos->>'deposito_id')::UUID;
    END IF;

    -- Movimiento de stock
    INSERT INTO movimientos_stock (
      tipo, variante_id, deposito_origen_id,
      cantidad, motivo, referencia_tipo, referencia_id, usuario_id
    ) VALUES (
      'egreso',
      (v_item->>'variante_id')::UUID,
      (p_datos->>'deposito_id')::UUID,
      (v_item->>'cantidad')::INT,
      'Venta confirmada',
      'venta',
      v_venta_id,
      (p_datos->>'usuario_vendedor_id')::UUID
    );
  END LOOP;

  -- 4. Pagos
  FOR v_pago IN SELECT * FROM jsonb_array_elements(p_datos->'pagos') LOOP
    INSERT INTO pagos_venta (venta_id, metodo_pago_id, monto_ars, monto_usd)
    VALUES (
      v_venta_id,
      (v_pago->>'metodo_pago_id')::UUID,
      (v_pago->>'monto_ars')::NUMERIC,
      (v_pago->>'monto_usd')::NUMERIC
    );
  END LOOP;

  -- 5. Movimiento de caja (si hay sesión abierta en ese depósito)
  SELECT id INTO v_sesion
  FROM sesiones_caja
  WHERE estado = 'abierta'
    AND caja_id IN (
      SELECT id FROM cajas
      WHERE deposito_id = (p_datos->>'deposito_id')::UUID
    )
  LIMIT 1;

  IF v_sesion IS NOT NULL THEN
    INSERT INTO movimientos_caja (sesion_caja_id, tipo, moneda, monto, descripcion, referencia_id)
    VALUES (
      v_sesion, 'venta', 'ARS',
      (p_datos->>'total_ars')::NUMERIC,
      'Venta ' || v_numero,
      v_venta_id
    );
  END IF;

  -- 6. Log
  INSERT INTO log_actividad (usuario_id, accion, tabla_afectada, registro_id, descripcion)
  VALUES (
    (p_datos->>'usuario_vendedor_id')::UUID,
    'crear', 'ventas', v_venta_id,
    'Venta confirmada: ' || v_numero
  );

  RETURN jsonb_build_object('success', true, 'id', v_venta_id, 'numero', v_numero);

EXCEPTION WHEN OTHERS THEN
  -- La transacción hace ROLLBACK automático ante cualquier error
  RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- =============================================================================
-- RLS — Funciones helper
-- =============================================================================

CREATE OR REPLACE FUNCTION get_user_rol()
  RETURNS TEXT AS $$
    SELECT rol FROM usuarios WHERE id = auth.uid()
  $$ LANGUAGE SQL SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_user_deposito_id()
  RETURNS UUID AS $$
    SELECT deposito_id FROM usuarios WHERE id = auth.uid()
  $$ LANGUAGE SQL SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_admin()
  RETURNS BOOLEAN AS $$
    SELECT get_user_rol() IN ('admin','superadmin')
  $$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- =============================================================================
-- RLS — Habilitar en TODAS las tablas (001a + 001b)
-- =============================================================================

-- 001a
ALTER TABLE tipos_cambio_dolar       ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracion_sistema    ENABLE ROW LEVEL SECURITY;
ALTER TABLE depositos                ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE categorias               ENABLE ROW LEVEL SECURITY;
ALTER TABLE marcas                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos                ENABLE ROW LEVEL SECURITY;
ALTER TABLE variantes_producto       ENABLE ROW LEVEL SECURITY;
ALTER TABLE imagenes_producto        ENABLE ROW LEVEL SECURITY;
ALTER TABLE listas_precio            ENABLE ROW LEVEL SECURITY;
ALTER TABLE precios_variante         ENABLE ROW LEVEL SECURITY;
ALTER TABLE historial_precios        ENABLE ROW LEVEL SECURITY;
ALTER TABLE reglas_descuento         ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE unidades_serializadas    ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimientos_stock        ENABLE ROW LEVEL SECURITY;
ALTER TABLE ajustes_stock            ENABLE ROW LEVEL SECURITY;
ALTER TABLE proveedores              ENABLE ROW LEVEL SECURITY;
ALTER TABLE recepciones_mercaderia   ENABLE ROW LEVEL SECURITY;
ALTER TABLE detalle_recepciones      ENABLE ROW LEVEL SECURITY;
ALTER TABLE log_actividad            ENABLE ROW LEVEL SECURITY;

-- 001b
ALTER TABLE clientes                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE garantias_cliente               ENABLE ROW LEVEL SECURITY;
ALTER TABLE cuentas_corriente_cliente       ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimientos_cuenta_corriente    ENABLE ROW LEVEL SECURITY;
ALTER TABLE metodos_pago                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE ventas                          ENABLE ROW LEVEL SECURITY;
ALTER TABLE items_venta                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos_venta                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE aprobaciones_descuento          ENABLE ROW LEVEL SECURITY;
ALTER TABLE presupuestos                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE items_presupuesto               ENABLE ROW LEVEL SECURITY;
ALTER TABLE cajas                           ENABLE ROW LEVEL SECURITY;
ALTER TABLE sesiones_caja                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimientos_caja                ENABLE ROW LEVEL SECURITY;
ALTER TABLE categorias_gasto                ENABLE ROW LEVEL SECURITY;
ALTER TABLE gastos                          ENABLE ROW LEVEL SECURITY;
ALTER TABLE catalogo_detalles_usados        ENABLE ROW LEVEL SECURITY;
ALTER TABLE detalles_unidad_usada           ENABLE ROW LEVEL SECURITY;
ALTER TABLE partes_de_pago                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE demandas_no_satisfechas         ENABLE ROW LEVEL SECURITY;
ALTER TABLE separas                         ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos_sepa                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE novedades_turno                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE objetivos_vendedor              ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- RLS — Políticas
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Catálogo: SELECT autenticados / escritura solo admin+
-- (categorias, marcas, productos, variantes_producto, imagenes_producto)
-- -----------------------------------------------------------------------------

CREATE POLICY "catalogos_select" ON categorias
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "catalogos_insert" ON categorias
  FOR INSERT TO authenticated WITH CHECK (is_admin());
CREATE POLICY "catalogos_update" ON categorias
  FOR UPDATE TO authenticated USING (is_admin());
CREATE POLICY "catalogos_delete" ON categorias
  FOR DELETE TO authenticated USING (is_admin());

CREATE POLICY "marcas_select" ON marcas
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "marcas_insert" ON marcas
  FOR INSERT TO authenticated WITH CHECK (is_admin());
CREATE POLICY "marcas_update" ON marcas
  FOR UPDATE TO authenticated USING (is_admin());
CREATE POLICY "marcas_delete" ON marcas
  FOR DELETE TO authenticated USING (is_admin());

CREATE POLICY "productos_select" ON productos
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "productos_insert" ON productos
  FOR INSERT TO authenticated WITH CHECK (is_admin());
CREATE POLICY "productos_update" ON productos
  FOR UPDATE TO authenticated USING (is_admin());
CREATE POLICY "productos_delete" ON productos
  FOR DELETE TO authenticated USING (is_admin());

CREATE POLICY "variantes_select" ON variantes_producto
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "variantes_insert" ON variantes_producto
  FOR INSERT TO authenticated WITH CHECK (is_admin());
CREATE POLICY "variantes_update" ON variantes_producto
  FOR UPDATE TO authenticated USING (is_admin());
CREATE POLICY "variantes_delete" ON variantes_producto
  FOR DELETE TO authenticated USING (is_admin());

CREATE POLICY "imagenes_select" ON imagenes_producto
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "imagenes_insert" ON imagenes_producto
  FOR INSERT TO authenticated WITH CHECK (is_admin());
CREATE POLICY "imagenes_delete" ON imagenes_producto
  FOR DELETE TO authenticated USING (is_admin());

-- -----------------------------------------------------------------------------
-- Precios: SELECT autenticados / escritura solo admin+
-- -----------------------------------------------------------------------------

CREATE POLICY "listas_precio_select" ON listas_precio
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "listas_precio_write" ON listas_precio
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "precios_variante_select" ON precios_variante
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "precios_variante_write" ON precios_variante
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "historial_precios_select" ON historial_precios
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "historial_precios_insert" ON historial_precios
  FOR INSERT TO authenticated WITH CHECK (is_admin());

CREATE POLICY "reglas_descuento_select" ON reglas_descuento
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "reglas_descuento_write" ON reglas_descuento
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- -----------------------------------------------------------------------------
-- Configuracion sistema: SELECT autenticados / escritura solo superadmin
-- -----------------------------------------------------------------------------

CREATE POLICY "config_select" ON configuracion_sistema
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "config_write" ON configuracion_sistema
  FOR ALL TO authenticated
  USING (get_user_rol() = 'superadmin')
  WITH CHECK (get_user_rol() = 'superadmin');

-- -----------------------------------------------------------------------------
-- Depositos: SELECT autenticados / escritura solo admin+
-- -----------------------------------------------------------------------------

CREATE POLICY "depositos_select" ON depositos
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "depositos_write" ON depositos
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- -----------------------------------------------------------------------------
-- Usuarios: cada uno ve/edita su fila / admin ve todas
-- -----------------------------------------------------------------------------

CREATE POLICY "usuarios_select" ON usuarios
  FOR SELECT TO authenticated
  USING (id = auth.uid() OR is_admin());
CREATE POLICY "usuarios_update" ON usuarios
  FOR UPDATE TO authenticated
  USING (id = auth.uid() OR is_admin());
CREATE POLICY "usuarios_insert" ON usuarios
  FOR INSERT TO authenticated
  WITH CHECK (is_admin());
CREATE POLICY "usuarios_delete" ON usuarios
  FOR DELETE TO authenticated
  USING (is_admin());

-- -----------------------------------------------------------------------------
-- Tipos de cambio: SELECT autenticados / escritura admin+
-- -----------------------------------------------------------------------------

CREATE POLICY "tc_select" ON tipos_cambio_dolar
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "tc_insert" ON tipos_cambio_dolar
  FOR INSERT TO authenticated WITH CHECK (is_admin());
CREATE POLICY "tc_update" ON tipos_cambio_dolar
  FOR UPDATE TO authenticated USING (is_admin());

-- -----------------------------------------------------------------------------
-- Inventario: SELECT/INSERT autenticados / DELETE admin
-- -----------------------------------------------------------------------------

CREATE POLICY "stock_select" ON stock
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "stock_write" ON stock
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "unidades_select" ON unidades_serializadas
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "unidades_write" ON unidades_serializadas
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "movimientos_stock_select" ON movimientos_stock
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "movimientos_stock_insert" ON movimientos_stock
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "ajustes_select" ON ajustes_stock
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "ajustes_insert" ON ajustes_stock
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "ajustes_delete" ON ajustes_stock
  FOR DELETE TO authenticated USING (is_admin());

-- -----------------------------------------------------------------------------
-- Proveedores: SELECT/INSERT/UPDATE autenticados / DELETE admin
-- -----------------------------------------------------------------------------

CREATE POLICY "proveedores_select" ON proveedores
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "proveedores_insert" ON proveedores
  FOR INSERT TO authenticated WITH CHECK (is_admin());
CREATE POLICY "proveedores_update" ON proveedores
  FOR UPDATE TO authenticated USING (is_admin());
CREATE POLICY "proveedores_delete" ON proveedores
  FOR DELETE TO authenticated USING (is_admin());

CREATE POLICY "recepciones_select" ON recepciones_mercaderia
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "recepciones_write" ON recepciones_mercaderia
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "detalle_recepciones_select" ON detalle_recepciones
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "detalle_recepciones_write" ON detalle_recepciones
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- -----------------------------------------------------------------------------
-- Log actividad: SELECT solo admin+ / INSERT desde server (SECURITY DEFINER)
-- -----------------------------------------------------------------------------

CREATE POLICY "log_select" ON log_actividad
  FOR SELECT TO authenticated USING (is_admin());
CREATE POLICY "log_insert" ON log_actividad
  FOR INSERT TO authenticated WITH CHECK (true);

-- -----------------------------------------------------------------------------
-- Clientes: SELECT/INSERT/UPDATE autenticados / DELETE admin
-- -----------------------------------------------------------------------------

CREATE POLICY "clientes_select" ON clientes
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "clientes_insert" ON clientes
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "clientes_update" ON clientes
  FOR UPDATE TO authenticated USING (true);
CREATE POLICY "clientes_delete" ON clientes
  FOR DELETE TO authenticated USING (is_admin());

CREATE POLICY "garantias_select" ON garantias_cliente
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "garantias_write" ON garantias_cliente
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "cta_cte_select" ON cuentas_corriente_cliente
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "cta_cte_write" ON cuentas_corriente_cliente
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "mov_cta_cte_select" ON movimientos_cuenta_corriente
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "mov_cta_cte_insert" ON movimientos_cuenta_corriente
  FOR INSERT TO authenticated WITH CHECK (true);

-- -----------------------------------------------------------------------------
-- Métodos de pago: SELECT autenticados / escritura admin
-- -----------------------------------------------------------------------------

CREATE POLICY "metodos_pago_select" ON metodos_pago
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "metodos_pago_write" ON metodos_pago
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- -----------------------------------------------------------------------------
-- Ventas: SELECT filtrado por depósito (admin ve todo) / INSERT auth / DELETE admin
-- -----------------------------------------------------------------------------

CREATE POLICY "ventas_select" ON ventas
  FOR SELECT TO authenticated
  USING (deposito_id = get_user_deposito_id() OR is_admin());
CREATE POLICY "ventas_insert" ON ventas
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "ventas_update" ON ventas
  FOR UPDATE TO authenticated
  USING (deposito_id = get_user_deposito_id() OR is_admin());
CREATE POLICY "ventas_delete" ON ventas
  FOR DELETE TO authenticated USING (is_admin());

CREATE POLICY "items_venta_select" ON items_venta
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "items_venta_write" ON items_venta
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "pagos_venta_select" ON pagos_venta
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "pagos_venta_write" ON pagos_venta
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "aprobaciones_select" ON aprobaciones_descuento
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "aprobaciones_insert" ON aprobaciones_descuento
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "aprobaciones_update" ON aprobaciones_descuento
  FOR UPDATE TO authenticated USING (is_admin());

-- -----------------------------------------------------------------------------
-- Presupuestos: SELECT por vendedor (admin ve todos) / INSERT auth / DELETE admin
-- -----------------------------------------------------------------------------

CREATE POLICY "presupuestos_select" ON presupuestos
  FOR SELECT TO authenticated
  USING (usuario_vendedor_id = auth.uid() OR is_admin());
CREATE POLICY "presupuestos_insert" ON presupuestos
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "presupuestos_update" ON presupuestos
  FOR UPDATE TO authenticated
  USING (usuario_vendedor_id = auth.uid() OR is_admin());
CREATE POLICY "presupuestos_delete" ON presupuestos
  FOR DELETE TO authenticated USING (is_admin());

CREATE POLICY "items_presupuesto_select" ON items_presupuesto
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "items_presupuesto_write" ON items_presupuesto
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- -----------------------------------------------------------------------------
-- Caja: SELECT/INSERT autenticados / DELETE admin
-- -----------------------------------------------------------------------------

CREATE POLICY "cajas_select" ON cajas
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "cajas_write" ON cajas
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "sesiones_caja_select" ON sesiones_caja
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "sesiones_caja_write" ON sesiones_caja
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "mov_caja_select" ON movimientos_caja
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "mov_caja_insert" ON movimientos_caja
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "mov_caja_delete" ON movimientos_caja
  FOR DELETE TO authenticated USING (is_admin());

CREATE POLICY "cat_gasto_select" ON categorias_gasto
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "cat_gasto_write" ON categorias_gasto
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "gastos_select" ON gastos
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "gastos_insert" ON gastos
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "gastos_update" ON gastos
  FOR UPDATE TO authenticated USING (is_admin());
CREATE POLICY "gastos_delete" ON gastos
  FOR DELETE TO authenticated USING (is_admin());

-- -----------------------------------------------------------------------------
-- Usados y parte de pago
-- -----------------------------------------------------------------------------

CREATE POLICY "cat_usados_select" ON catalogo_detalles_usados
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "cat_usados_write" ON catalogo_detalles_usados
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "detalles_usada_select" ON detalles_unidad_usada
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "detalles_usada_write" ON detalles_unidad_usada
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "ppago_select" ON partes_de_pago
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "ppago_insert" ON partes_de_pago
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "ppago_update" ON partes_de_pago
  FOR UPDATE TO authenticated USING (true);
CREATE POLICY "ppago_delete" ON partes_de_pago
  FOR DELETE TO authenticated USING (is_admin());

-- -----------------------------------------------------------------------------
-- Demandas: SELECT filtrado por depósito (admin ve todo)
-- -----------------------------------------------------------------------------

CREATE POLICY "demandas_select" ON demandas_no_satisfechas
  FOR SELECT TO authenticated
  USING (deposito_id = get_user_deposito_id() OR is_admin());
CREATE POLICY "demandas_insert" ON demandas_no_satisfechas
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "demandas_update" ON demandas_no_satisfechas
  FOR UPDATE TO authenticated USING (true);
CREATE POLICY "demandas_delete" ON demandas_no_satisfechas
  FOR DELETE TO authenticated USING (is_admin());

-- -----------------------------------------------------------------------------
-- Separas: SELECT filtrado por depósito (admin ve todo)
-- -----------------------------------------------------------------------------

CREATE POLICY "separas_select" ON separas
  FOR SELECT TO authenticated
  USING (deposito_id = get_user_deposito_id() OR is_admin());
CREATE POLICY "separas_insert" ON separas
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "separas_update" ON separas
  FOR UPDATE TO authenticated
  USING (deposito_id = get_user_deposito_id() OR is_admin());
CREATE POLICY "separas_delete" ON separas
  FOR DELETE TO authenticated USING (is_admin());

CREATE POLICY "pagos_sepa_select" ON pagos_sepa
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "pagos_sepa_write" ON pagos_sepa
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- -----------------------------------------------------------------------------
-- Novedades: cada usuario ve las de su depósito (admin ve todas)
-- -----------------------------------------------------------------------------

CREATE POLICY "novedades_select" ON novedades_turno
  FOR SELECT TO authenticated
  USING (deposito_id = get_user_deposito_id() OR is_admin());
CREATE POLICY "novedades_insert" ON novedades_turno
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "novedades_update" ON novedades_turno
  FOR UPDATE TO authenticated
  USING (deposito_id = get_user_deposito_id() OR is_admin());
CREATE POLICY "novedades_delete" ON novedades_turno
  FOR DELETE TO authenticated USING (is_admin());

-- -----------------------------------------------------------------------------
-- Objetivos vendedor: cada uno ve los suyos (admin ve todos)
-- -----------------------------------------------------------------------------

CREATE POLICY "objetivos_select" ON objetivos_vendedor
  FOR SELECT TO authenticated
  USING (usuario_id = auth.uid() OR is_admin());
CREATE POLICY "objetivos_write" ON objetivos_vendedor
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());
