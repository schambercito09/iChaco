---
name: whatsapp
description: Integración con WhatsApp via Meta Cloud API para el ERP/CRM. Usar en la Fase 4 (Paso 48). Cubre mensajes manuales, templates aprobados, webhooks y el bot de respuesta automática.
---

# Skill: `whatsapp`
> **Activar con:** `[Skills activas: whatsapp]`
> **Propósito:** Mensajes automáticos desde el ERP — recordatorios de sepa, presupuestos, novedades

---

## ⚠️ Esta skill es para la Fase 4 — no implementar antes

Antes de usar esta skill:
- El sistema debe estar en producción con usuarios reales (Fase 1 completa)
- Los módulos de ventas, presupuestos y separas deben estar funcionando
- Se necesita una cuenta de Meta Business verificada

---

## 1. Dos tipos de mensajes WhatsApp

```
MENSAJES DE PLANTILLA (Template Messages):
- Aprobados por Meta antes de enviar
- Se envían a cualquier contacto (esté o no en conversación activa)
- Casos: recordatorio de sepa vencida, presupuesto listo, garantía por vencer
- Formato fijo con variables: "Hola {{1}}, tu sepa {{2}} vence el {{3}}"

MENSAJES DE SESIÓN (Session Messages):
- Solo cuando el cliente escribió primero en las últimas 24hs
- Texto libre, sin aprobación
- Casos: responder consultas, enviar presupuesto PDF por link
```

---

## 2. Setup — Meta Cloud API

```bash
npm install axios
# No hay SDK oficial estable — usar axios directo
```

```typescript
// lib/whatsapp/client.ts
const WHATSAPP_API_URL = 'https://graph.facebook.com/v19.0'
const PHONE_NUMBER_ID = process.env.WHATSAPP_PHONE_NUMBER_ID
const ACCESS_TOKEN = process.env.WHATSAPP_ACCESS_TOKEN

export async function enviarMensaje(payload: object) {
  const response = await fetch(
    `${WHATSAPP_API_URL}/${PHONE_NUMBER_ID}/messages`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    }
  )

  if (!response.ok) {
    const error = await response.json()
    throw new Error(`WhatsApp API error: ${JSON.stringify(error)}`)
  }

  return response.json()
}
```

---

## 3. Templates del ERP

```typescript
// lib/whatsapp/templates.ts

// Template: recordatorio de sepa próxima a vencer
export async function recordatorioSepa(
  telefono: string,
  nombre: string,
  numeroSepa: string,
  producto: string,
  fechaVencimiento: string,
  saldoUsd: number
) {
  return enviarMensaje({
    messaging_product: 'whatsapp',
    to: formatearTelefono(telefono),
    type: 'template',
    template: {
      name: 'recordatorio_sepa',   // nombre aprobado en Meta Business
      language: { code: 'es_AR' },
      components: [{
        type: 'body',
        parameters: [
          { type: 'text', text: nombre },
          { type: 'text', text: numeroSepa },
          { type: 'text', text: producto },
          { type: 'text', text: fechaVencimiento },
          { type: 'text', text: `USD ${saldoUsd}` },
        ]
      }]
    }
  })
}

// Template: presupuesto listo
export async function presupuestoListo(
  telefono: string,
  nombre: string,
  numeroPresupuesto: string,
  totalUsd: number,
  vigencia: string,
  linkPresupuesto?: string
) {
  return enviarMensaje({
    messaging_product: 'whatsapp',
    to: formatearTelefono(telefono),
    type: 'template',
    template: {
      name: 'presupuesto_listo',
      language: { code: 'es_AR' },
      components: [
        {
          type: 'body',
          parameters: [
            { type: 'text', text: nombre },
            { type: 'text', text: numeroPresupuesto },
            { type: 'text', text: `USD ${totalUsd}` },
            { type: 'text', text: vigencia },
          ]
        },
        ...(linkPresupuesto ? [{
          type: 'button',
          sub_type: 'url',
          index: 0,
          parameters: [{ type: 'text', text: linkPresupuesto }]
        }] : [])
      ]
    }
  })
}

// Helper para formatear teléfono argentino
function formatearTelefono(tel: string): string {
  // Eliminar todo lo que no sea número
  const limpio = tel.replace(/\D/g, '')
  // Agregar código de país si no lo tiene
  if (limpio.startsWith('54')) return limpio
  if (limpio.startsWith('0')) return '54' + limpio.substring(1)
  return '54' + limpio
}
```

---

## 4. Server Action para enviar WhatsApp desde el ERP

```typescript
// lib/actions/whatsapp.ts
export async function enviarRecordatorioSepaAction(sepaId: string): Promise<ActionResult> {
  try {
    const supabase = createServerClient()
    const usuario = await getUsuarioActual()
    if (!usuario || !['admin', 'superadmin'].includes(usuario.rol)) {
      return actionError('Sin permisos')
    }

    const { data: sepa } = await supabase
      .from('separas')
      .select('*, cliente:clientes(nombre, whatsapp), variante:variantes_producto(*)')
      .eq('id', sepaId)
      .single()

    if (!sepa?.cliente?.whatsapp) {
      return actionError('El cliente no tiene WhatsApp registrado')
    }

    await recordatorioSepa(
      sepa.cliente.whatsapp,
      sepa.cliente.nombre,
      sepa.numero_sepa,
      sepa.descripcion_producto,
      new Date(sepa.fecha_vencimiento).toLocaleDateString('es-AR'),
      sepa.saldo_pendiente_usd
    )

    // Registrar en log
    await crearLog({
      accion: 'crear',
      tabla_afectada: 'whatsapp_mensajes',
      descripcion: `Recordatorio de sepa ${sepa.numero_sepa} enviado a ${sepa.cliente.nombre}`,
      usuario_id: usuario.id,
    })

    return actionOk()

  } catch (e) {
    return manejarError(e, 'enviarRecordatorioSepaAction')
  }
}
```

---

## 5. Webhook — recibir mensajes entrantes

```typescript
// app/api/whatsapp/webhook/route.ts

// Verificación del webhook (solo primera vez)
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const mode = searchParams.get('hub.mode')
  const token = searchParams.get('hub.verify_token')
  const challenge = searchParams.get('hub.challenge')

  if (mode === 'subscribe' && token === process.env.WHATSAPP_VERIFY_TOKEN) {
    return new Response(challenge, { status: 200 })
  }

  return new Response('Forbidden', { status: 403 })
}

// Recibir mensajes
export async function POST(request: Request) {
  const body = await request.json()

  // Verificar que viene de Meta
  const signature = request.headers.get('x-hub-signature-256')
  if (!verificarFirmaWebhook(body, signature)) {
    return new Response('Unauthorized', { status: 401 })
  }

  const messages = body.entry?.[0]?.changes?.[0]?.value?.messages
  if (!messages) return new Response('OK', { status: 200 })

  for (const message of messages) {
    await procesarMensajeEntrante(message)
  }

  return new Response('OK', { status: 200 })
}

async function procesarMensajeEntrante(message: any) {
  const telefono = message.from
  const texto = message.text?.body?.toLowerCase() ?? ''

  // Buscar cliente por teléfono
  const supabase = createServerClient()
  const { data: cliente } = await supabase
    .from('clientes')
    .select('id, nombre')
    .or(`telefono.eq.${telefono},whatsapp.eq.${telefono}`)
    .single()

  // Crear novedad para que el equipo lo atienda
  await supabase.from('novedades_turno').insert({
    tipo: 'cliente_viene',
    prioridad: 'normal',
    titulo: `WhatsApp de ${cliente?.nombre ?? telefono}`,
    descripcion: texto.substring(0, 200),
    cliente_id: cliente?.id,
    generada_por: 'sistema',
    // deposito_id: el depósito principal
  })
}
```

---

## 6. Variables de entorno necesarias

```env
# .env.local — agregar en Fase 4
WHATSAPP_PHONE_NUMBER_ID=     # ID del número en Meta Business
WHATSAPP_ACCESS_TOKEN=        # Token de acceso permanente
WHATSAPP_VERIFY_TOKEN=        # Token para verificar el webhook (elegir uno)
```

---

## 7. Templates a crear en Meta Business Manager

Antes de implementar, crear y esperar aprobación (~24hs) de estos templates:

```
1. recordatorio_sepa
   Variables: {{nombre}}, {{numero_sepa}}, {{producto}}, {{fecha_vencimiento}}, {{saldo}}
   "Hola {{1}}! Te recordamos que tu sepa {{2}} para {{3}} vence el {{4}}. Saldo pendiente: {{5}}."

2. presupuesto_listo
   Variables: {{nombre}}, {{numero}}, {{total_usd}}, {{vigencia}}
   "Hola {{1}}! Tu presupuesto {{2}} está listo. Total: {{3}}. Válido hasta {{4}}."

3. garantia_por_vencer
   Variables: {{nombre}}, {{producto}}, {{fecha_vencimiento}}
   "Hola {{1}}! La garantía de tu {{2}} vence el {{3}}. Ante cualquier problema, contactanos."
```
