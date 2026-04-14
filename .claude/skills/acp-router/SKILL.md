---
name: acp-router
description: Enrutá solicitudes en lenguaje natural para Pi, Claude Code, Codex, OpenCode, Gemini CLI o trabajo con el harness ACP hacia sesiones del runtime ACP de OpenClaw o sesiones directas manejadas por acpx (flujo "telephone game"). Para solicitudes de threads con agentes de código, leé esta skill primero y luego usá solo `sessions_spawn` para crear threads.
user-invocable: false
---

# Enrutador del Harness ACP

Cuando la intención del usuario es "ejecutar esto en Pi/Claude Code/Codex/OpenCode/Gemini/Kimi (harness ACP)", no uses el runtime de subagente ni PTY scraping. Enrutá a través de los flujos con soporte ACP.

## Detección de intención

Activá esta skill cuando el usuario le pida a OpenClaw:

- ejecutar algo en Pi / Claude Code / Codex / OpenCode / Gemini
- continuar trabajo existente en el harness
- retransmitir instrucciones a un harness de codificación externo
- mantener una conversación con un harness externo en formato de thread

Preflight obligatorio para solicitudes de threads con agentes de código:

- Antes de crear cualquier thread para trabajo con Pi/Claude/Codex/OpenCode/Gemini, leé esta skill primero en el mismo turno.
- Después de leerla, seguí el `camino del runtime ACP de OpenClaw` que se indica abajo; no uses `message(action="thread-create")` para crear threads del harness ACP.

## Selección de modo

Elegí uno de estos caminos:

1. Camino del runtime ACP de OpenClaw (por defecto): usá `sessions_spawn` / herramientas del runtime ACP.
2. Camino directo `acpx` (telephone game): usá la CLI `acpx` a través de `exec` para manejar la sesión del harness directamente.

Usá `acpx` directo cuando se cumpla alguna de estas condiciones:

- el usuario pide explícitamente el manejo directo con `acpx`
- el runtime ACP / camino del plugin no está disponible o tiene problemas
- la tarea es simplemente "retransmitir prompts al harness" y no se necesitan funciones del ciclo de vida ACP de OpenClaw

No usar:

- runtime `subagents` para controlar el harness
- delegación por comando `/acp` como requisito para el usuario
- PTY scraping de las CLIs pi/claude/codex/opencode/gemini/kimi cuando `acpx` está disponible

## Mapeo de AgentId

Usá estos valores por defecto cuando el usuario nombra un harness directamente:

- "pi" -> `agentId: "pi"`
- "claude" o "claude code" -> `agentId: "claude"`
- "codex" -> `agentId: "codex"`
- "opencode" -> `agentId: "opencode"`
- "gemini" o "gemini cli" -> `agentId: "gemini"`
- "kimi" o "kimi cli" -> `agentId: "kimi"`

Estos valores coinciden con los alias integrados actuales de acpx.

Si la política rechaza el id elegido, reportá el error claramente y solicitá el id de agente ACP permitido.

## Camino del runtime ACP de OpenClaw

Comportamiento requerido:

1. Para solicitudes de creación de threads con harness ACP, leé esta skill primero en el mismo turno antes de llamar herramientas.
2. Usá `sessions_spawn` con:
   - `runtime: "acp"`
   - `thread: true`
   - `mode: "session"` (salvo que el usuario quiera explícitamente one-shot)
3. Para crear threads con harness ACP, no uses `message` con `action=thread-create`; `sessions_spawn` es el único camino para crear threads.
4. Colocá el trabajo solicitado en `task` para que la sesión ACP lo reciba de inmediato.
5. Configurá `agentId` explícitamente salvo que el agente ACP por defecto sea conocido.
6. No le pidas al usuario que ejecute slash commands o CLI cuando este camino funciona directamente.

Ejemplo:

Usuario: "creá una sesión de prueba de codex en un thread y decile que diga hola"

Llamada:

```json
{
  "task": "Decí hola.",
  "runtime": "acp",
  "agentId": "codex",
  "thread": true,
  "mode": "session"
}
```

## Política de recuperación al crear threads

Cuando el usuario pida iniciar un harness de codificación en un thread (por ejemplo "iniciá un thread de codex/claude/pi/kimi"), tratalo como una solicitud de runtime ACP e intentá satisfacerla de principio a fin.

Comportamiento requerido cuando el backend ACP no está disponible:

1. No le pidas de inmediato al usuario que elija un camino alternativo.
2. Primero intentá una reparación local automática:
   - asegurate de que acpx fijado localmente en el plugin esté instalado en `extensions/acpx`
   - verificá `${ACPX_CMD} --version`
3. Después de reinstalar/reparar, reiniciá el gateway y ofrecé explícitamente ejecutar ese reinicio por el usuario.
4. Reintentá el spawn del thread ACP una vez después de la reparación.
5. Solo si la reparación y el reintento fallan, reportá el error concreto y ofrecé opciones de fallback.

Al ofrecer fallback, mantené ACP primero:

- Opción 1: reintentar el spawn ACP mostrando el paso exacto que falla
- Opción 2: flujo telephone game con acpx directo

No uses el runtime de subagente por defecto para estas solicitudes.

## Política de instalación y versión de ACPX (camino directo acpx)

Para este repo, las llamadas directas a `acpx` deben seguir la misma política de versión fijada que la extensión `@openclaw/acpx`.

1. Preferí el binario local del plugin, no el PATH global:
   - `./extensions/acpx/node_modules/.bin/acpx`
2. Resolvé la versión fijada desde la dependencia de la extensión:
   - `node -e "console.log(require('./extensions/acpx/package.json').dependencies.acpx)"`
3. Si el binario falta o la versión no coincide, instalá la versión fijada localmente en el plugin:
   - `cd extensions/acpx && npm install --omit=dev --no-save acpx@<versionFijada>`
4. Verificá antes de usar:
   - `./extensions/acpx/node_modules/.bin/acpx --version`
5. Si la instalación/reparación cambió los artefactos de ACPX, reiniciá el gateway y ofrecé ejecutar el reinicio.
6. No ejecutes `npm install -g acpx` salvo que el usuario lo pida explícitamente.

Configurá y reutilizá:

```bash
ACPX_CMD="./extensions/acpx/node_modules/.bin/acpx"
```

## Camino directo acpx ("telephone game")

Usá este camino para manejar sesiones del harness sin `/acp` ni runtime de subagente.

### Reglas

1. Usá comandos `exec` que llamen a `${ACPX_CMD}`.
2. Reutilizá un nombre de sesión estable por conversación para que los prompts de seguimiento queden en el mismo contexto del harness.
3. Preferí `--format quiet` para obtener texto limpio del asistente para retransmitir al usuario.
4. Usá `exec` (one-shot) solo cuando el usuario quiera comportamiento one-shot.
5. Mantené el directorio de trabajo explícito (`--cwd`) cuando el alcance de la tarea dependa del contexto del repositorio.

### Nombres de sesión

Usá un nombre determinístico, por ejemplo:

- `oc-<harness>-<conversationId>`

Donde `conversationId` es el id del thread cuando está disponible, o el id del canal/conversación en caso contrario.

### Plantillas de comandos

Sesión persistente (crear si no existe, luego enviar prompt):

```bash
${ACPX_CMD} codex sessions show oc-codex-<conversationId> \
  || ${ACPX_CMD} codex sessions new --name oc-codex-<conversationId>

${ACPX_CMD} codex -s oc-codex-<conversationId> --cwd <workspacePath> --format quiet "<prompt>"
```

One-shot:

```bash
${ACPX_CMD} codex exec --cwd <workspacePath> --format quiet "<prompt>"
```

Cancelar un turno en curso:

```bash
${ACPX_CMD} codex cancel -s oc-codex-<conversationId>
```

Cerrar sesión:

```bash
${ACPX_CMD} codex sessions close oc-codex-<conversationId>
```

### Aliases del harness en acpx

- `pi`
- `claude`
- `codex`
- `opencode`
- `gemini`
- `kimi`

### Comandos de adaptadores integrados en acpx

Los valores por defecto son:

- `pi -> npx pi-acp`
- `claude -> npx -y @zed-industries/claude-agent-acp`
- `codex -> npx @zed-industries/codex-acp`
- `opencode -> npx -y opencode-ai acp`
- `gemini -> gemini`
- `kimi -> kimi acp`

Si `~/.acpx/config.json` sobreescribe `agents`, esas sobreescrituras reemplazan los valores por defecto.

### Manejo de errores

- `acpx: command not found`:
  - para solicitudes de spawn de thread ACP, instalá acpx fijado localmente en `extensions/acpx` de inmediato
  - reiniciá el gateway después de la instalación y ofrecé ejecutar el reinicio automáticamente
  - luego reintentá una vez
  - no pidas permiso para instalar salvo que la política lo requiera explícitamente
  - no instalés `acpx` globalmente salvo que se pida explícitamente
- comando del adaptador faltante (por ejemplo `claude-agent-acp` no encontrado):
  - para solicitudes de spawn de thread ACP, primero restaurá los valores por defecto integrados eliminando las sobreescrituras rotas del agente en `~/.acpx/config.json`
  - luego reintentá una vez antes de ofrecer fallback
  - si el usuario quiere sobreescrituras basadas en binarios, instalá exactamente el binario del adaptador configurado
- `NO_SESSION`: ejecutá `${ACPX_CMD} <agente> sessions new --name <nombreSesion>` y luego reintentá el prompt.
- cola ocupada: esperá la finalización (por defecto) o usá `--no-wait` cuando se desee comportamiento asíncrono explícitamente.

### Retransmisión de salida

Al retransmitir al usuario, devolvé el texto final del asistente obtenido del resultado del comando `acpx`. Evitá retransmitir ruido crudo de herramientas locales salvo que el usuario haya pedido logs detallados.
