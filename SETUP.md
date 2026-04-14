# SETUP.md — Guía de Setup del Entorno de Desarrollo

## Requisitos previos

| Herramienta | Versión mínima | Verificar |
|---|---|---|
| Node.js | 18.17+ | `node --version` |
| npm | 9+ | `npm --version` |
| Git | 2.40+ | `git --version` |
| VS Code | Cualquier reciente | — |

---

## Paso 1 — Clonar el repo e instalar dependencias

```bash
git clone https://github.com/TU_USUARIO/TU_REPO.git
cd TU_REPO
npm install
```

---

## Paso 2 — Variables de entorno

Crear `.env.local` en la raíz (nunca commitear este archivo):

```env
NEXT_PUBLIC_SUPABASE_URL=https://TU_PROJECT_ID.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
```

Obtener desde: **Supabase Dashboard → Settings → API → Legacy API Keys**
- URL: campo "Project URL"
- Anon key: empieza con `eyJ...`

⚠️ Usar las **Legacy** anon keys, no las nuevas "publishable keys" — son más estables.

---

## Paso 3 — Supabase CLI (para generar tipos TypeScript)

```bash
npm install -g supabase

# Login
supabase login

# Generar tipos (ejecutar cada vez que cambia el schema)
npx supabase gen types typescript --project-id TU_PROJECT_ID > lib/types/database.types.ts
```

Obtener TU_PROJECT_ID desde: **Supabase Dashboard → Settings → General → Project ID**

---

## Paso 4 — Extensiones recomendadas de VS Code

Instalar estas extensiones (buscar por el ID en la tienda de VS Code):

| Extensión | ID | Para qué sirve |
|---|---|---|
| Tailwind CSS IntelliSense | `bradlc.vscode-tailwindcss` | Autocompletado de clases Tailwind |
| ESLint | `dbaeumer.vscode-eslint` | Errores de código en tiempo real |
| Prettier | `esbenp.prettier-vscode` | Formateo automático |
| TypeScript Hero | `ms-vscode.vscode-typescript-next` | TypeScript mejorado |
| Supabase | `supabase.supabase` | Autocompletado de queries |
| Error Lens | `usernamehw.errorlens` | Errores inline en el código |

Configurar VS Code para formatear al guardar (`settings.json`):

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "typescript.tsdk": "node_modules/typescript/lib"
}
```

---

## Paso 5 — Verificar que todo funciona

```bash
# TypeScript sin errores
npx tsc --noEmit

# Levantar en desarrollo
npm run dev

# Abrir en el browser
# → http://localhost:3000
```

Si aparece error de Supabase connection → verificar que `.env.local` tiene las variables correctas.

---

## Paso 6 — Configurar Git

```bash
# Configurar nombre y email (si no está hecho)
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"

# Evitar warnings de CRLF en Windows
git config core.autocrlf true

# Ver configuración
git config --list
```

---

## Comandos de uso diario

```bash
# Levantar desarrollo
npm run dev

# Verificar TypeScript antes de hacer commit
npx tsc --noEmit

# Lint y formato
npx eslint . --fix
npx prettier --write .

# Build de producción (verificar antes de deploy)
npm run build

# Regenerar tipos desde Supabase (después de cambiar el schema)
npx supabase gen types typescript --project-id TU_PROJECT_ID > lib/types/database.types.ts

# Ver logs de desarrollo
npm run dev 2>&1 | tee dev.log
```

---

## Solución de problemas comunes

### "Module not found" al levantar
```bash
rm -rf node_modules .next
npm install
npm run dev
```

### "NEXT_PUBLIC_SUPABASE_URL is not defined"
Verificar que `.env.local` existe en la raíz y tiene las variables correctas.
Reiniciar el servidor de desarrollo después de cambiar variables de entorno.

### TypeScript error en database.types.ts
```bash
npx supabase gen types typescript --project-id TU_PROJECT_ID > lib/types/database.types.ts
```

### Build falla con error de Tailwind
```bash
npx tailwindcss -i ./app/globals.css -o ./app/output.css --watch
```

### Error "Too many connections" en Supabase
Usar siempre el cliente correcto:
- Server Components / Actions → `createServerClient` de `lib/supabase/server.ts`
- Client Components → `createBrowserClient` de `lib/supabase/client.ts`
