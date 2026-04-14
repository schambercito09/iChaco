---
name: diffs
description: Mostrar diferencias entre versiones de código. Usar cuando el usuario pida ver qué cambió entre dos versiones de un archivo, entre el estado anterior y actual, o antes de aplicar un cambio importante.
---

# Skill: `diffs`
> **Activar con:** `[Skills activas: diffs]`
> **Propósito:** Ver diferencias de código entre versiones

---

## git diff — la herramienta principal

```bash
# Ver todos los cambios sin commitear
git diff

# Ver cambios de un archivo específico
git diff lib/actions/ventas.ts

# Ver cambios que ya están en staging (git add)
git diff --cached

# Ver diferencias entre dos commits
git diff HEAD~1 HEAD

# Ver diferencias entre ramas
git diff develop..feature/paso-12b-pos

# Solo nombres de archivos cambiados
git diff --name-only HEAD~1 HEAD

# Estadísticas de cambios (cuántas líneas +/-)
git diff --stat HEAD~1 HEAD
```

## Ver qué hizo el último paso

```bash
# Ver el commit más reciente completo
git show HEAD

# Ver solo los archivos que cambió
git show --name-only HEAD

# Ver cambios de un archivo en el último commit
git show HEAD -- lib/actions/ventas.ts

# Ver historial de los últimos 10 commits
git log --oneline -10
```

## Comparar versiones de un archivo

```bash
# Diferencia entre archivo local y último commit
git diff HEAD lib/actions/ventas.ts

# Diferencia entre dos commits para un archivo
git diff abc1234 def5678 -- lib/actions/ventas.ts

# Ver cómo era un archivo en un commit específico
git show abc1234:lib/actions/ventas.ts
```

## Antes de aplicar un cambio importante

Cuando vayas a modificar un módulo existente, primero ver el estado actual:

```bash
# Ver estado actual del archivo
cat lib/actions/ventas.ts

# Después del cambio, ver qué cambió
git diff lib/actions/ventas.ts

# Si el cambio está bien, agregar al staging
git add lib/actions/ventas.ts
git commit -m "fix: corregir calculo de precio ars en confirmacion de venta"
```

## Deshacer cambios

```bash
# Deshacer cambios en un archivo (antes de git add)
git checkout -- lib/actions/ventas.ts

# Deshacer git add (volver a unstaged)
git restore --staged lib/actions/ventas.ts

# Deshacer el último commit (conserva los cambios)
git reset --soft HEAD~1

# Ver qué haría un reset antes de ejecutarlo
git log --oneline -5
```

## Para este proyecto — por paso del roadmap

Cada paso del roadmap genera un commit. Para revisar un paso:

```bash
# Ver qué archivos se crearon/modificaron en el paso N
git show --name-only feat/paso-N-nombre

# Comparar Fase completa (inicio vs fin)
git diff v0.1.0..v0.2.0 --stat
```