# SUPABASE-CHECKLIST.md — Configuración Manual del Proyecto

> Estos pasos NO pueden automatizarse — hay que hacerlos manualmente en
> el dashboard de Supabase. Marcar cada uno al completarlo.

---

## PARTE 1 — Configuración inicial del proyecto

- [ ] Crear proyecto en Supabase (plan Free para desarrollo, Pro para producción)
  - Región: sa-east-1 (São Paulo) — la más cercana a Argentina
  - Contraseña de la BD: guardar en un gestor de contraseñas

- [ ] Anotar los datos del proyecto:
  - Project ID: `augarbafiwogugmqxcmq`
  - Project URL: `https://augarbafiwogugmqxcmq.supabase.co`
  - Anon Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF1Z2FyYmFmaXdvZ3VnbXF4Y21xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzNTE1NzEsImV4cCI6MjA5MDkyNzU3MX0.XngD_bC-qVveWuR9Zp28JQgBmjHt5DoSxI3WwBqNjhg`

---

## PARTE 2 — Autenticación

### Email/Password
- [ ] Ir a **Authentication → Providers → Email**
- [ ] En desarrollo: desactivar "Confirm email" (para no necesitar confirmar mails)
- [ ] En producción: activar "Confirm email" + configurar template de email

### URL de redirección
- [ ] Ir a **Authentication → URL Configuration**
- [ ] Agregar en "Site URL":
  - Desarrollo: `http://localhost:3000`
  - Producción: `https://tu-app.vercel.app`
- [ ] Agregar en "Redirect URLs":
  - `http://localhost:3000/**`
  - `https://tu-app.vercel.app/**`

### Templates de email (producción)
- [ ] Ir a **Authentication → Email Templates**
- [ ] Personalizar "Confirm signup" con el nombre del sistema
- [ ] Personalizar "Reset password" con el nombre del sistema

---

## PARTE 3 — Base de datos

### Ejecutar migraciones (en orden)
- [ ] Ir a **SQL Editor**
- [ ] Ejecutar `migrations/001a_schema_core.sql`
- [ ] Ejecutar `migrations/001b_schema_negocio.sql`
- [ ] Ejecutar `migrations/002_seed_data.sql`
- [ ] Verificar: **Table Editor** debe mostrar todas las tablas

### Crear usuario superadmin de prueba
- [ ] Ir a **Authentication → Users → Add user**
  - Email: `admin@sistema.test`
  - Password: `Admin1234!`
  - Tildar "Auto Confirm User"
- [ ] Copiar el UUID generado
- [ ] Ir a **SQL Editor** y ejecutar:
  ```sql
  UPDATE usuarios
  SET nombre = 'Admin', apellido = 'Sistema', rol = 'superadmin'
  WHERE id = 'PEGAR-UUID-AQUI';
  ```
- [ ] Verificar: `SELECT * FROM usuarios WHERE email = 'admin@sistema.test';`
  debe mostrar `rol = 'superadmin'`

### Verificar RLS
- [ ] Ir a **Database → Tables**
- [ ] Para cada tabla: verificar que el candado "RLS" aparece activado
- [ ] Si alguna tabla no tiene RLS: ejecutar `ALTER TABLE nombre ENABLE ROW LEVEL SECURITY;`

---

## PARTE 4 — Storage

### Crear buckets
- [ ] Ir a **Storage → New bucket**

  **Bucket 1: productos-imagenes**
  - Name: `productos-imagenes`
  - Public bucket: ✅ SÍ
  - File size limit: 5 MB
  - Allowed MIME types: `image/jpeg, image/png, image/webp`

  **Bucket 2: usados-fotos**
  - Name: `usados-fotos`
  - Public bucket: ✅ SÍ
  - File size limit: 10 MB
  - Allowed MIME types: `image/jpeg, image/png, image/webp`

  **Bucket 3: comprobantes**
  - Name: `comprobantes`
  - Public bucket: ❌ NO
  - File size limit: 10 MB
  - Allowed MIME types: `image/jpeg, image/png, application/pdf`

### Políticas de Storage
- [ ] Ejecutar en SQL Editor el SQL de políticas del Paso 2d del roadmap

---

## PARTE 5 — Índices y performance

- [ ] Ir a **Database → Extensions**
- [ ] Activar `pg_stat_statements` (para monitorear queries lentas)

- [ ] Ejecutar en SQL Editor:
  ```sql
  -- Verificar que los índices están creados
  SELECT indexname, tablename FROM pg_indexes
  WHERE schemaname = 'public'
  ORDER BY tablename, indexname;
  ```
  Debe mostrar los índices definidos en las migraciones.

---

## PARTE 6 — Backup (plan Pro)

- [ ] En plan Pro: ir a **Settings → Backups**
- [ ] Verificar que los backups automáticos diarios están activos
- [ ] Hacer el primer backup manual: **Settings → Backups → Create backup**

---

## PARTE 7 — Post-deploy en Vercel

- [ ] Agregar variables de entorno en Vercel:
  - `NEXT_PUBLIC_SUPABASE_URL`
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- [ ] Agregar la URL de Vercel en Supabase → Authentication → URL Configuration
- [ ] Hacer un login de prueba desde la URL de producción
- [ ] Verificar que las novedades automáticas se crean al cargar el TC del día

---

## PARTE 8 — Monitoring

- [ ] Ir a **Settings → Reports**
- [ ] Revisar weekly report de queries lentas
- [ ] Si alguna query supera 100ms de promedio → agregar índice

---

## Comandos SQL útiles para verificación

```sql
-- Ver todas las tablas del proyecto
SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;

-- Ver todas las políticas RLS activas
SELECT tablename, policyname, cmd FROM pg_policies WHERE schemaname = 'public';

-- Ver todos los triggers
SELECT trigger_name, event_object_table FROM information_schema.triggers
WHERE trigger_schema = 'public';

-- Ver todas las sequences
SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = 'public';

-- Test del usuario superadmin
SELECT id, nombre, rol, deposito_id FROM usuarios WHERE rol = 'superadmin';

-- Test de datos semilla
SELECT nombre FROM categorias_gasto;
SELECT nombre FROM metodos_pago;
SELECT clave, valor FROM configuracion_sistema;
```
