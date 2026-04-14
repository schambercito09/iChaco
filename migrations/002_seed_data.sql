-- =============================================================================
-- 002_seed_data.sql — Datos semilla iniciales del ERP/CRM
-- Paso 2c — Ejecutar en Supabase SQL Editor
-- REQUISITO: 001a y 001b deben estar ejecutados primero
-- =============================================================================

-- =============================================================================
-- 1. MÉTODOS DE PAGO (8 métodos)
-- =============================================================================

INSERT INTO metodos_pago (nombre, acepta_usd, genera_recargo, porcentaje_recargo) VALUES
  ('efectivo_ars',    false, false, 0),
  ('efectivo_usd',    true,  false, 0),
  ('transferencia',   false, false, 0),
  ('debito',          false, true,  0.8),
  ('credito',         false, true,  5.0),
  ('mercadopago',     false, true,  3.5),
  ('cuenta_corriente',false, false, 0),
  ('parte_de_pago',   false, false, 0);

-- =============================================================================
-- 2. CATEGORÍAS DE GASTO (8 categorías)
-- =============================================================================

INSERT INTO categorias_gasto (nombre, descripcion) VALUES
  ('alquiler',      'Alquiler del local o depósito'),
  ('servicios',     'Luz, agua, internet, teléfono'),
  ('sueldos',       'Sueldos y cargas sociales'),
  ('publicidad',    'Publicidad online y offline'),
  ('logistica',     'Envíos, fletes y transportes'),
  ('mantenimiento', 'Reparaciones y mantenimiento del local'),
  ('impuestos',     'Impuestos y tasas municipales'),
  ('otros',         'Otros gastos no categorizados');

-- =============================================================================
-- 3. CONFIGURACIÓN DEL SISTEMA (10 parámetros)
-- =============================================================================

INSERT INTO configuracion_sistema (clave, valor, tipo_valor, descripcion, modulo) VALUES
  ('sepa_dias_vencimiento',                '15', 'integer', 'Días hasta vencimiento de una sepa',                       'separas'),
  ('sepa_dias_alerta_previo',              '3',  'integer', 'Días antes del vencimiento para alertar',                  'separas'),
  ('postventa_dias_recordatorio',          '7',  'integer', 'Días post-venta para recordatorio automático',             'crm'),
  ('descuento_maximo_vendedor_pct',        '10', 'integer', 'Descuento máximo sin aprobación para vendedores',          'ventas'),
  ('margen_minimo_alerta_pct',             '15', 'integer', 'Margen mínimo antes de alertar',                           'usados'),
  ('tc_variacion_reimprimir_etiquetas_pct','3',  'integer', 'Variación TC para marcar etiquetas desactualizadas',       'precios'),
  ('elasticidad_ventana_dias',             '30', 'integer', 'Días para análisis de elasticidad precio-demanda',         'reportes'),
  ('stock_muerto_dias',                    '60', 'integer', 'Días sin movimiento para considerar stock muerto',         'inventario'),
  ('ciclo_upgrade_margen_tolerancia_pct',  '20', 'integer', 'Tolerancia sobre ciclo promedio de recompra del cliente',  'crm'),
  ('presupuesto_dias_seguimiento',         '3',  'integer', 'Días sin respuesta para recordatorio de presupuesto',      'ventas');

-- =============================================================================
-- 4. DEPÓSITOS INICIALES (2 depósitos)
-- =============================================================================

INSERT INTO depositos (nombre, tipo, direccion) VALUES
  ('Tienda Principal', 'tienda',   'Dirección de la tienda — actualizar'),
  ('Depósito Central', 'deposito', 'Dirección del depósito — actualizar');

-- =============================================================================
-- 5. CAJAS INICIALES (1 caja efectivo en la tienda)
-- =============================================================================

INSERT INTO cajas (nombre, deposito_id, tipo)
  SELECT 'Caja Efectivo', id, 'efectivo'
  FROM depositos
  WHERE tipo = 'tienda';

-- =============================================================================
-- 6. LISTAS DE PRECIO INICIALES
-- =============================================================================

INSERT INTO listas_precio (nombre, tipo, moneda_base) VALUES
  ('Minorista',    'minorista',    'USD'),
  ('Mayorista',    'mayorista',    'USD'),
  ('Distribuidor', 'distribuidor', 'USD'),
  ('Empleado',     'empleado',     'USD');

-- =============================================================================
-- 6b. USUARIO SUPERADMIN DE PRUEBA — ACCIÓN MANUAL REQUERIDA
--
-- PASO 1: Ir a Supabase → Authentication → Users → Add user
--         Email:    admin@sistema.test
--         Password: Admin1234!
--         Tildar "Auto Confirm User" → guardar
--
-- PASO 2: Copiar el UUID que Supabase asignó al usuario
--
-- PASO 3: Reemplazar 'PEGAR-UUID-DEL-USUARIO-AQUI' con ese UUID y ejecutar:
-- =============================================================================

DO $$
DECLARE
  v_user_id   UUID := '39246369-2483-4eb4-a76a-deaec9b5cc39';
  v_tienda_id UUID;
BEGIN
  SELECT id INTO v_tienda_id FROM depositos WHERE tipo = 'tienda' LIMIT 1;

  UPDATE usuarios
  SET nombre      = 'Admin',
      apellido    = 'Sistema',
      rol         = 'superadmin',
      deposito_id = v_tienda_id
  WHERE id = v_user_id;

  -- Si el trigger no lo creó automáticamente:
  INSERT INTO usuarios (id, nombre, apellido, email, rol, deposito_id, activo)
  VALUES (v_user_id, 'Admin', 'Sistema', 'admin@sistema.test', 'superadmin', v_tienda_id, true)
  ON CONFLICT (id) DO UPDATE
    SET rol         = 'superadmin',
        deposito_id = v_tienda_id;
END $$;

-- Verificar con:
-- SELECT id, nombre, apellido, email, rol, deposito_id FROM usuarios WHERE email = 'admin@sistema.test';
-- Debe mostrar: rol = 'superadmin' y deposito_id poblado.

-- =============================================================================
-- 7. CATÁLOGO BASE DE DEFECTOS PARA USADOS (15 defectos comunes)
-- =============================================================================

INSERT INTO catalogo_detalles_usados
  (nombre, categoria_detalle, severidad, reduce_precio_sugerido_usd, requiere_alerta_venta)
VALUES
  ('Pantalla con marca de agua leve',      'pantalla',     'leve',        5,  false),
  ('Pantalla con marca de agua notoria',   'pantalla',     'moderado',   15,  true),
  ('Pantalla rota o fisurada',             'pantalla',     'grave',       40, true),
  ('Carcasa trasera rayada',               'carcasa',      'leve',         3, false),
  ('Carcasa con golpe o abolladura',       'carcasa',      'moderado',    10, true),
  ('Batería degradada (menos de 80%)',     'bateria',      'moderado',    15, true),
  ('Batería degradada (menos de 60%)',     'bateria',      'grave',       30, true),
  ('Cámara con mancha interna',            'camara',       'moderado',    15, true),
  ('Face ID o lector huella sin funcionar','biometria',    'grave',       20, true),
  ('Altavoz con falla parcial',            'audio',        'moderado',    10, true),
  ('Sin cargador original',                'accesorios',   'informativo',  5, false),
  ('Sin caja original',                    'accesorios',   'informativo',  3, false),
  ('iCloud activo (bloqueado)',             'software',     'bloqueante',   0, true),
  ('Cuenta Google activa',                 'software',     'bloqueante',   0, true),
  ('SIM tray faltante',                    'conectividad', 'leve',         5, false);
