---
name: fix
description: Ejecutar SIEMPRE antes de hacer un commit. Corrige lint, formato y TypeScript. Usar también cuando aparezcan errores de ESLint, Prettier o TypeScript durante el desarrollo.
---

# Skill: `fix`
> **Activar con:** `[Skills activas: fix]`
> **Propósito:** Lint, formato y TypeScript antes de cada commit

---

## Antes de CADA commit — ejecutar en orden

```bash
# 1. Formato con Prettier
npx prettier --write .

# 2. Lint con ESLint (corregir automático)
npx eslint . --fix

# 3. TypeScript — DEBE dar 0 errores
npx tsc --noEmit

# 4. Build de verificación (antes de push a main/develop)
npm run build
```

Si alguno falla, corregir antes de continuar. NO commitear con errores de TypeScript.

## Errores comunes y solución rápida

### TypeScript — "Property does not exist on type"
```bash
# Regenerar tipos desde Supabase si el schema cambió
npx supabase gen types typescript --project-id TU_PROJECT_ID > lib/types/database.types.ts
npx tsc --noEmit
```

### TypeScript — "Cannot find module '@/components/ui'"
El barrel export no existe o le falta un export. Verificar `components/ui/index.ts`.

### ESLint — "React Hook called conditionally"
Mover el hook al nivel superior del componente. Nunca dentro de if, loop o función anidada.

### ESLint — "exhaustive-deps"
Agregar todas las dependencias al array de useEffect/useCallback.
Si la dependencia es estable (ref, setter), puede omitirse con comentario justificado.

### Prettier — conflicto con ESLint
Verificar que `.eslintrc` tiene `"prettier"` al final del array `extends`.

### "Module not found" después de crear archivos
```bash
rm -rf .next
npm run dev
```

### Build falla con "params is not awaited" (Next.js 15+)
Este proyecto usa Next.js 14. Si aparece este error, verificar que no se actualizó Next.js accidentalmente.

## Checklist pre-commit

```bash
# 1. Verificar archivos inmutables (deben tener > 20 líneas cada uno)
for f in proxy.ts lib/supabase/proxy.ts app/(dashboard)/layout.tsx app/(auth)/login/page.tsx; do
  lines=$(wc -l < "$f" 2>/dev/null || echo 0)
  echo "$lines líneas: $f"
done
# Si alguno da < 20 → fue revertido → restaurar ANTES de commitear

# 2. Verificar que no hay secrets hardcodeados
grep -rn "supabase.co\|eyJ" --include="*.ts" --include="*.tsx" . \
  | grep -v ".env" | grep -v "node_modules" | grep -v ".next"

# 3. Estado final
git status
git diff --stat
npx tsc --noEmit
```

## Convención de commits del proyecto

```
feat:     nueva funcionalidad (nuevo módulo, nueva acción)
fix:      corrección de bug
refactor: refactor sin cambio funcional
style:    solo formato/estilo, sin cambios de lógica
docs:     documentación (roadmap, context, current-task, README)
chore:    dependencias, config, scripts
test:     tests

Formato: <tipo>: paso N - descripción breve en minúsculas

Ejemplos correctos:
  feat: paso 4 - login con supabase auth y layout base
  feat: paso 12b - ui del pos con carrito y calculos en tiempo real
  fix: corregir calculo precio ars cuando tc cambia durante el dia
  refactor: extraer calcularMargen a lib/utils/precios
  docs: actualizar current-task.md con paso 15 completado
  chore: actualizar supabase-js a v2.39
```