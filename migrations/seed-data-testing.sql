-- seed-data-testing.sql
-- Datos realistas para testear el sistema después de completar la Fase 1.
-- Ejecutar DESPUÉS de 002_seed_data.sql en el SQL Editor de Supabase.
-- Usar solo en entornos de desarrollo y testing.

-- ─── MARCAS ────────────────────────────────────────────────────────────────
INSERT INTO marcas (nombre, pais_origen) VALUES
  ('Apple',   'Estados Unidos'),
  ('Samsung', 'Corea del Sur'),
  ('Xiaomi',  'China'),
  ('Motorola','Estados Unidos'),
  ('Lenovo',  'China')
ON CONFLICT DO NOTHING;

-- ─── CATEGORÍAS ────────────────────────────────────────────────────────────
INSERT INTO categorias (nombre) VALUES
  ('Celulares'),
  ('Accesorios'),
  ('Hardware PC'),
  ('Tablets')
ON CONFLICT DO NOTHING;

INSERT INTO categorias (nombre, categoria_padre_id)
SELECT 'iPhone',  id FROM categorias WHERE nombre = 'Celulares'
ON CONFLICT DO NOTHING;

INSERT INTO categorias (nombre, categoria_padre_id)
SELECT 'Samsung Galaxy', id FROM categorias WHERE nombre = 'Celulares'
ON CONFLICT DO NOTHING;

INSERT INTO categorias (nombre, categoria_padre_id)
SELECT 'Cables',  id FROM categorias WHERE nombre = 'Accesorios'
ON CONFLICT DO NOTHING;

INSERT INTO categorias (nombre, categoria_padre_id)
SELECT 'Fundas',  id FROM categorias WHERE nombre = 'Accesorios'
ON CONFLICT DO NOTHING;

-- ─── PRODUCTOS ─────────────────────────────────────────────────────────────
INSERT INTO productos (sku, nombre, categoria_id, marca_id, tipo, requiere_imei, garantia_meses)
SELECT
  'IPH15',
  'iPhone 15',
  (SELECT id FROM categorias WHERE nombre = 'iPhone'),
  (SELECT id FROM marcas WHERE nombre = 'Apple'),
  'serializado', true, 12
ON CONFLICT (sku) DO NOTHING;

INSERT INTO productos (sku, nombre, categoria_id, marca_id, tipo, requiere_imei, garantia_meses)
SELECT
  'SAMA55',
  'Samsung Galaxy A55',
  (SELECT id FROM categorias WHERE nombre = 'Samsung Galaxy'),
  (SELECT id FROM marcas WHERE nombre = 'Samsung'),
  'serializado', true, 12
ON CONFLICT (sku) DO NOTHING;

INSERT INTO productos (sku, nombre, categoria_id, marca_id, tipo, requiere_imei, garantia_meses)
SELECT
  'MOTG84',
  'Motorola Moto G84',
  (SELECT id FROM categorias WHERE nombre = 'Celulares'),
  (SELECT id FROM marcas WHERE nombre = 'Motorola'),
  'serializado', true, 12
ON CONFLICT (sku) DO NOTHING;

INSERT INTO productos (sku, nombre, categoria_id, marca_id, tipo, requiere_imei, garantia_meses)
SELECT
  'CABLEUSBC',
  'Cable USB-C 1m',
  (SELECT id FROM categorias WHERE nombre = 'Cables'),
  (SELECT id FROM marcas WHERE nombre = 'Xiaomi'),
  'generico', false, 0
ON CONFLICT (sku) DO NOTHING;

-- ─── VARIANTES ─────────────────────────────────────────────────────────────
INSERT INTO variantes_producto (producto_id, color, capacidad_gb, ram_gb, sku_variante)
SELECT id, 'Negro',    128, 6, 'IPH15-128-NEG' FROM productos WHERE sku = 'IPH15'
ON CONFLICT (sku_variante) DO NOTHING;

INSERT INTO variantes_producto (producto_id, color, capacidad_gb, ram_gb, sku_variante)
SELECT id, 'Blanco',   128, 6, 'IPH15-128-BLA' FROM productos WHERE sku = 'IPH15'
ON CONFLICT (sku_variante) DO NOTHING;

INSERT INTO variantes_producto (producto_id, color, capacidad_gb, ram_gb, sku_variante)
SELECT id, 'Azul',     256, 6, 'IPH15-256-AZU' FROM productos WHERE sku = 'IPH15'
ON CONFLICT (sku_variante) DO NOTHING;

INSERT INTO variantes_producto (producto_id, color, capacidad_gb, ram_gb, sku_variante)
SELECT id, 'Azul',     128, 8, 'SAMA55-128-AZU' FROM productos WHERE sku = 'SAMA55'
ON CONFLICT (sku_variante) DO NOTHING;

INSERT INTO variantes_producto (producto_id, color, capacidad_gb, ram_gb, sku_variante)
SELECT id, 'Negro',    256, 8, 'SAMA55-256-NEG' FROM productos WHERE sku = 'SAMA55'
ON CONFLICT (sku_variante) DO NOTHING;

INSERT INTO variantes_producto (producto_id, color, capacidad_gb, ram_gb, sku_variante)
SELECT id, 'Grafito',  256, 12, 'MOTG84-256-GRA' FROM productos WHERE sku = 'MOTG84'
ON CONFLICT (sku_variante) DO NOTHING;

INSERT INTO variantes_producto (producto_id, sku_variante)
SELECT id, 'CABLEUSBC-UNI' FROM productos WHERE sku = 'CABLEUSBC'
ON CONFLICT (sku_variante) DO NOTHING;

-- ─── PRECIOS (lista minorista) ──────────────────────────────────────────────
INSERT INTO precios_variante (variante_id, lista_precio_id, precio_usd, margen_porcentaje)
SELECT v.id, l.id, 800, 22
FROM variantes_producto v, listas_precio l
WHERE v.sku_variante = 'IPH15-128-NEG' AND l.tipo = 'minorista'
ON CONFLICT (variante_id, lista_precio_id) DO NOTHING;

INSERT INTO precios_variante (variante_id, lista_precio_id, precio_usd, margen_porcentaje)
SELECT v.id, l.id, 800, 22
FROM variantes_producto v, listas_precio l
WHERE v.sku_variante = 'IPH15-128-BLA' AND l.tipo = 'minorista'
ON CONFLICT (variante_id, lista_precio_id) DO NOTHING;

INSERT INTO precios_variante (variante_id, lista_precio_id, precio_usd, margen_porcentaje)
SELECT v.id, l.id, 950, 22
FROM variantes_producto v, listas_precio l
WHERE v.sku_variante = 'IPH15-256-AZU' AND l.tipo = 'minorista'
ON CONFLICT (variante_id, lista_precio_id) DO NOTHING;

INSERT INTO precios_variante (variante_id, lista_precio_id, precio_usd, margen_porcentaje)
SELECT v.id, l.id, 420, 18
FROM variantes_producto v, listas_precio l
WHERE v.sku_variante = 'SAMA55-128-AZU' AND l.tipo = 'minorista'
ON CONFLICT (variante_id, lista_precio_id) DO NOTHING;

INSERT INTO precios_variante (variante_id, lista_precio_id, precio_usd, margen_porcentaje)
SELECT v.id, l.id, 460, 18
FROM variantes_producto v, listas_precio l
WHERE v.sku_variante = 'SAMA55-256-NEG' AND l.tipo = 'minorista'
ON CONFLICT (variante_id, lista_precio_id) DO NOTHING;

INSERT INTO precios_variante (variante_id, lista_precio_id, precio_usd, margen_porcentaje,
  precio_ars_override, usar_precio_ars_fijo)
SELECT v.id, l.id, 7, 40, 8500, true
FROM variantes_producto v, listas_precio l
WHERE v.sku_variante = 'CABLEUSBC-UNI' AND l.tipo = 'minorista'
ON CONFLICT (variante_id, lista_precio_id) DO NOTHING;

-- ─── TIPO DE CAMBIO HOY ────────────────────────────────────────────────────
INSERT INTO tipos_cambio_dolar (fecha, valor_ars, tipo, fuente)
VALUES (CURRENT_DATE, 1215.00, 'blue', 'manual')
ON CONFLICT (fecha) DO NOTHING;

-- ─── STOCK EN TIENDA ───────────────────────────────────────────────────────
INSERT INTO stock (variante_id, deposito_id, cantidad_disponible, stock_minimo)
SELECT v.id, d.id, 5, 2
FROM variantes_producto v, depositos d
WHERE v.sku_variante IN ('IPH15-128-NEG','IPH15-128-BLA','IPH15-256-AZU')
  AND d.tipo = 'tienda'
ON CONFLICT (variante_id, deposito_id) DO UPDATE SET cantidad_disponible = 5;

INSERT INTO stock (variante_id, deposito_id, cantidad_disponible, stock_minimo)
SELECT v.id, d.id, 8, 3
FROM variantes_producto v, depositos d
WHERE v.sku_variante IN ('SAMA55-128-AZU','SAMA55-256-NEG')
  AND d.tipo = 'tienda'
ON CONFLICT (variante_id, deposito_id) DO UPDATE SET cantidad_disponible = 8;

INSERT INTO stock (variante_id, deposito_id, cantidad_disponible, stock_minimo)
SELECT v.id, d.id, 20, 5
FROM variantes_producto v, depositos d
WHERE v.sku_variante = 'CABLEUSBC-UNI' AND d.tipo = 'tienda'
ON CONFLICT (variante_id, deposito_id) DO UPDATE SET cantidad_disponible = 20;

-- ─── UNIDADES SERIALIZADAS (IMEIs de prueba) ───────────────────────────────
INSERT INTO unidades_serializadas
  (variante_id, deposito_id, imei, estado, condicion, costo_adquisicion_usd, costo_total_usd)
SELECT v.id, d.id, '354123456789001', 'disponible', 'nuevo', 650, 650
FROM variantes_producto v, depositos d
WHERE v.sku_variante = 'IPH15-128-NEG' AND d.tipo = 'tienda'
ON CONFLICT (imei) DO NOTHING;

INSERT INTO unidades_serializadas
  (variante_id, deposito_id, imei, estado, condicion, costo_adquisicion_usd, costo_total_usd)
SELECT v.id, d.id, '354123456789002', 'disponible', 'nuevo', 650, 650
FROM variantes_producto v, depositos d
WHERE v.sku_variante = 'IPH15-128-NEG' AND d.tipo = 'tienda'
ON CONFLICT (imei) DO NOTHING;

INSERT INTO unidades_serializadas
  (variante_id, deposito_id, imei, estado, condicion, costo_adquisicion_usd, costo_total_usd)
SELECT v.id, d.id, '354987654321001', 'disponible', 'nuevo', 340, 340
FROM variantes_producto v, depositos d
WHERE v.sku_variante = 'SAMA55-128-AZU' AND d.tipo = 'tienda'
ON CONFLICT (imei) DO NOTHING;

-- ─── CLIENTES DE PRUEBA ────────────────────────────────────────────────────
INSERT INTO clientes (tipo, nombre, apellido, dni, telefono, whatsapp, ciudad, origen)
VALUES
  ('persona', 'Juan',    'García',   '30123456', '3624551001', '3624551001', 'Resistencia', 'mostrador'),
  ('persona', 'María',   'López',    '28765432', '3624552002', '3624552002', 'Resistencia', 'instagram'),
  ('persona', 'Carlos',  'Rodríguez','35111222', '3624553003', '3624553003', 'Resistencia', 'mostrador'),
  ('empresa', 'TechShop','',         null,       '3624554004', '3624554004', 'Resistencia', 'referido')
ON CONFLICT DO NOTHING;

-- Crear cuentas corrientes para cada cliente
INSERT INTO cuentas_corriente_cliente (cliente_id)
SELECT id FROM clientes
WHERE telefono IN ('3624551001','3624552002','3624553003','3624554004')
ON CONFLICT (cliente_id) DO NOTHING;

-- ─── PROVEEDOR DE PRUEBA ───────────────────────────────────────────────────
INSERT INTO proveedores
  (razon_social, nombre_fantasia, tipo_proveedor, vende_nuevo, vende_usado, requiere_factura, riesgo_legal, moneda_preferida)
VALUES
  ('Distribuidora Sur SA', 'Distrib. Sur', 'distribuidor_nuevo', true, false, true, 'bajo', 'USD')
ON CONFLICT DO NOTHING;

-- ─── VERIFICACIÓN FINAL ────────────────────────────────────────────────────
-- Ejecutar para confirmar que todo se insertó:
/*
SELECT 'marcas' AS tabla, COUNT(*) FROM marcas
UNION ALL SELECT 'categorias', COUNT(*) FROM categorias
UNION ALL SELECT 'productos', COUNT(*) FROM productos
UNION ALL SELECT 'variantes', COUNT(*) FROM variantes_producto
UNION ALL SELECT 'precios', COUNT(*) FROM precios_variante
UNION ALL SELECT 'stock', COUNT(*) FROM stock
UNION ALL SELECT 'imeis', COUNT(*) FROM unidades_serializadas
UNION ALL SELECT 'clientes', COUNT(*) FROM clientes
UNION ALL SELECT 'tc_hoy', COUNT(*) FROM tipos_cambio_dolar WHERE fecha = CURRENT_DATE;
*/
