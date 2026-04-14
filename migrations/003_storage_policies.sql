-- =============================================================================
-- 003_storage_policies.sql — Políticas RLS para Supabase Storage
-- Paso 2d — Ejecutar en Supabase SQL Editor DESPUÉS de crear los buckets
--
-- INSTRUCCIONES MANUALES PREVIAS (hacer en Supabase Dashboard → Storage):
--
-- 1. Bucket: "productos-imagenes"
--    - Public: SÍ
--    - File size limit: 5MB
--    - Allowed MIME types: image/jpeg, image/png, image/webp
--
-- 2. Bucket: "usados-fotos"
--    - Public: SÍ
--    - File size limit: 10MB
--    - Allowed MIME types: image/jpeg, image/png, image/webp
--
-- 3. Bucket: "comprobantes"
--    - Public: NO
--    - File size limit: 10MB
--    - Allowed MIME types: image/jpeg, image/png, application/pdf
--
-- Recién después ejecutar este archivo.
-- =============================================================================

-- Imágenes de productos: cualquier autenticado puede leer, solo admin puede subir/borrar
CREATE POLICY "productos_imagenes_select" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'productos-imagenes');

CREATE POLICY "productos_imagenes_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'productos-imagenes' AND is_admin());

CREATE POLICY "productos_imagenes_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'productos-imagenes' AND is_admin());

-- Fotos de usados: cualquier autenticado puede leer y subir
CREATE POLICY "usados_fotos_select" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'usados-fotos');

CREATE POLICY "usados_fotos_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'usados-fotos');

-- Comprobantes: solo autenticados pueden leer y subir
CREATE POLICY "comprobantes_select" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'comprobantes');

CREATE POLICY "comprobantes_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'comprobantes');
