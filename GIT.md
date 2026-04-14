# GIT.md — Estrategia de Ramas y Commits

## Estructura de ramas

```
main              ← producción (solo deploy estable)
develop           ← integración (pre-producción)
└── feature/paso-N-nombre    ← trabajo activo
```

**Regla:** nunca pushear código roto a `develop` o `main`.

---

## Flujo estándar por paso del roadmap

```bash
# 1. Asegurarse de estar en develop actualizado
git checkout develop
git pull origin develop

# 2. Crear rama para el paso
git checkout -b feature/paso-N-nombre-modulo
# Ejemplos:
# feature/paso-4-login-layout
# feature/paso-12b-pos-nueva-venta
# feature/paso-15-separas

# 3. Desarrollar + verificar
npx tsc --noEmit          # 0 errores TypeScript
npm run build             # build limpio

# 4. Commit al terminar
git add .
git commit -m "feat: paso N - descripcion del modulo"

# 5. Push de la rama
git push -u origin feature/paso-N-nombre-modulo

# 6. Merge a develop
git checkout develop
git merge feature/paso-N-nombre-modulo
git push origin develop
```

---

## Convención de commits (Conventional Commits)

```
<tipo>: <descripcion en minúsculas y español>

Tipos:
  feat:     nueva funcionalidad
  fix:      corrección de bug
  refactor: refactor sin cambio de funcionalidad
  style:    cambios de estilo/formato sin lógica
  docs:     documentación
  chore:    tareas de mantenimiento (deps, config)
  test:     tests

Ejemplos:
  feat: paso 4 - login con supabase auth y layout base
  feat: paso 12b - ui del pos con carrito y calculos en tiempo real
  fix: corregir calculo de precio ars al cambiar tc del dia
  refactor: extraer calcularPrecioSugerido a lib/utils/usados
  docs: actualizar current-task.md con paso 12c completado
  chore: actualizar dependencias supabase a v2.39
```

---

## Deploy a producción

```bash
# Verificar que develop está listo para producción
git checkout develop
npx tsc --noEmit
npm run build

# Crear tag de versión
git tag v1.0.0 -m "Fase 1 completa - MVP operativo"
git push origin v1.0.0

# Merge a main (dispara deploy automático en Vercel)
git checkout main
git merge develop
git push origin main
```

---

## Rollback si algo falla en producción

```bash
# Opción 1: Revertir el último merge
git checkout main
git revert HEAD --no-edit
git push origin main

# Opción 2: Volver a un tag estable
git checkout main
git reset --hard v0.9.0   # la versión estable anterior
git push origin main --force

# En Vercel: también se puede hacer rollback desde el dashboard
# Deployments → elegir una version anterior → Promote to Production
```

---

## Comandos útiles del día a día

```bash
# Ver estado actual
git status
git log --oneline -10

# Ver qué cambió en un archivo
git diff lib/actions/ventas.ts

# Deshacer cambios en un archivo (antes de commit)
git checkout -- lib/actions/ventas.ts

# Guardar cambios temporalmente (para cambiar de rama)
git stash
git stash pop

# Ver todas las ramas
git branch -a

# Eliminar rama local después de merge
git branch -d feature/paso-4-login-layout

# Eliminar rama remota
git push origin --delete feature/paso-4-login-layout
```

---

## .gitignore — verificar que incluye

```
.env.local
.env.*.local
node_modules/
.next/
out/
*.log
.DS_Store
dev.log
```

---

## Historial de versiones

| Versión | Fecha | Descripción |
|---|---|---|
| v0.1.0 | — | Fase 0 completa: schema + tipos |
| v0.2.0 | — | Fase 1 parcial: login + TC + catálogo |
| v1.0.0 | — | Fase 1 completa: MVP operativo |
| v1.x.x | — | Fase 2: gestión avanzada |
| v2.0.0 | — | Fase 3: CRM e inteligencia |
