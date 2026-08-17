# Identik MCP — firma electrónica y firma digital argentina para agentes de IA

[![MCP Registry](https://img.shields.io/badge/MCP%20Registry-me.identik-blue)](https://registry.modelcontextprotocol.io/v0.1/servers?search=me.identik)

**ES** · Servidores [MCP](https://modelcontextprotocol.io) remotos de **[Identik](https://identik.me)** para firmar documentos con validez legal en Argentina (Ley 25.506) desde un agente de IA: crear un documento a partir de una plantilla, enviarlo a firmar, seguir su estado, descargar el PDF firmado con su constancia y verificar firmas criptográficamente.

**EN** · Remote [MCP](https://modelcontextprotocol.io) servers for **[Identik](https://identik.me)**, an Argentine e-signature platform (Ley 25.506). Let an AI agent create a document from a template, send it out for signature, track status, download the signed PDF with its audit certificate, and cryptographically verify signatures.

> Este repositorio contiene **documentación y manifiestos** para conectarse a los servidores MCP alojados por Identik. No contiene el código del producto (Identik es un servicio comercial alojado).
>
> This repository holds **documentation and manifests** for connecting to Identik's hosted MCP servers. It does not contain the product source (Identik is a commercial hosted service).

---

## Las dos plataformas / The two platforms

Identik expone **dos** servidores MCP, uno por nivel de firma. Las herramientas son las mismas; cambia el valor legal de la firma resultante.

Identik exposes **two** MCP servers, one per signature level. The tool set is identical; what differs is the legal weight of the resulting signature.

| | **Firma electrónica** | **Firma digital** |
|---|---|---|
| Registro MCP / MCP Registry | `me.identik/electronica` | `me.identik/firma` |
| Producción / Production | `https://electronica.identik.me/api/mcp` | `https://firma.identik.me/api/mcp` |
| Sandbox (evaluación / evaluation) | `https://sandbox-electronica.identik.me/api/mcp` | `https://sandbox-firma.identik.me/api/mcp` |
| Marco legal / Legal basis | Ley 25.506, art. 5 | Ley 25.506, arts. 2, 7 y 8 |
| Cómo firma el firmante / How the signer signs | Enlace por email + evidencia (constancia con trazabilidad, sello criptográfico, sello de tiempo RFC-3161) | Certificado propio de **certificador licenciado**: CUIL + PIN + OTP |
| Efecto legal / Legal effect | Firma electrónica con evidencia completa | Presunción legal de autoría e integridad |
| Verificación biométrica opcional (DNI + prueba de vida) / Optional biometric ID check | Sí / Yes | No aplica (la identidad la aporta el certificado) / N/A (identity comes from the certificate) |

Los **sandboxes** sirven para evaluar la integración sin efectos legales ni consumo de créditos de producción. Los documentos que emiten quedan marcados como de PRUEBA.

The **sandboxes** let you evaluate the integration with no legal effect and no production credit consumption. Documents they issue are marked as TEST documents.

---

## Transporte y autenticación / Transport and authentication

- **Transporte / Transport:** Streamable HTTP, **stateless**. Sólo `POST` (`GET` y `DELETE` devuelven `405`). / POST only (`GET` and `DELETE` return `405`).
- **Autenticación / Authentication:** encabezado HTTP `Authorization: Bearer api_...`
- **Sin OAuth.** El token es un token de API por cuenta. / **No OAuth.** The token is a per-account API token.

### Cómo obtener un token / How to get a token

**Requiere un token de API de Identik.** Solicitalo en **contacto@identik.me**, o generalo desde tu cuenta en **Configuración → API Tokens**.

**An Identik API token is required.** Request one at **contacto@identik.me**, or generate it in your account under **Configuración → API Tokens**.

Sin token, el servidor responde `401`:

```console
$ curl -sS -X POST https://electronica.identik.me/api/mcp \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
{"jsonrpc":"2.0","error":{"code":-32001,"message":"Falta el token de API (encabezado Authorization: Bearer api_...)."},"id":null}
```

Ver [`examples/smoke-test.sh`](examples/smoke-test.sh). / See [`examples/smoke-test.sh`](examples/smoke-test.sh).

---

## Herramientas / Tools

Diez herramientas, con nombres en español (la plataforma es de mercado argentino). Idénticas en ambas plataformas, salvo lo indicado.

Ten tools, named in Spanish (the platform targets the Argentine market). Identical across both platforms except where noted.

| Herramienta / Tool | Qué hace / What it does |
|---|---|
| `listar_plantillas` | Lista las plantillas del equipo con sus `id` y firmantes. Las plantillas se arman en la interfaz web; desde acá se usan para generar documentos. |
| `listar_documentos` | Lista los documentos del equipo con su estado (`DRAFT`, `PENDING`, `COMPLETED`, `REJECTED`). |
| `obtener_documento` | Devuelve un documento por su `id` numérico: estado, firmantes (con `signingStatus` y `signingUrl`), campos y `envelopeId`. |
| `crear_documento_desde_plantilla` | Genera un documento a partir de una plantilla. Devuelve el `documentId` y el `signingUrl` de cada firmante. **Queda en borrador y no consume crédito** hasta enviarlo. |
| `enviar_documento` | Envía los emails de invitación y pone el documento en firma. **Acá se consume el crédito.** |
| `reenviar_invitacion` | Reenvía el email de firma a firmantes que todavía no firmaron. |
| `descargar_documento_firmado` | Devuelve una URL firmada de descarga del PDF (con la constancia). Pasado el plazo de resguardo responde `410`. |
| `traza_auditoria` | Traza de auditoría completa del documento en JSON: creación, envío, apertura y firmas, con fecha, IP y dispositivo. |
| `validar_pdf` | Verifica criptográficamente las firmas de un PDF: integridad, cadena, sello de tiempo RFC-3161, y si es un documento de PRUEBA. |
| `estado_cuenta` | Créditos de documentos disponibles y totales de la cuenta. |

**Flujo típico / Typical flow:**

```
listar_plantillas  →  crear_documento_desde_plantilla  →  enviar_documento
                                                            ↓
                        obtener_documento / traza_auditoria (seguimiento)
                                                            ↓
                                            descargar_documento_firmado
```

### Sólo en firma electrónica / Electronic signature only

`crear_documento_desde_plantilla` acepta `requiere_biometria: true` — cada firmante debe aprobar una verificación biométrica (DNI + prueba de vida) antes de firmar. Consume 1 crédito de verificación por verificación aprobada. Recomendado combinarlo con `dni_numero` en cada firmante, para que la verificación se valide **contra** ese dato.

`crear_documento_desde_plantilla` accepts `requiere_biometria: true` — each signer must pass a biometric identity check (ID document + liveness) before signing. Consumes 1 verification credit per passed check. Best combined with each signer's `dni_numero`, so the check is validated **against** that value.

### Sólo en firma digital / Digital signature only

Cada firmante se identifica por `cuil`, que debe corresponder a su certificado de firma digital.

Each signer is identified by `cuil`, which must match their digital-signature certificate.

---

## Configuración por cliente / Client configuration

En todos los ejemplos, reemplazá `api_...` por tu token, y `electronica.identik.me` por `firma.identik.me` si querés firma digital (o por el host `sandbox-*` para evaluar).

In every example, replace `api_...` with your token, and `electronica.identik.me` with `firma.identik.me` for digital signature (or with the `sandbox-*` host to evaluate).

### Claude Code

```bash
claude mcp add identik --transport http https://electronica.identik.me/api/mcp \
  --header "Authorization: Bearer api_..."
```

Forma equivalente en `.mcp.json` (versionable en el proyecto) / equivalent `.mcp.json` project file:

```json
{
  "mcpServers": {
    "identik": {
      "type": "http",
      "url": "https://electronica.identik.me/api/mcp",
      "headers": {
        "Authorization": "Bearer api_..."
      }
    }
  }
}
```

### Cursor

`~/.cursor/mcp.json` (global) o `.cursor/mcp.json` (por proyecto):

```json
{
  "mcpServers": {
    "identik": {
      "url": "https://electronica.identik.me/api/mcp",
      "headers": {
        "Authorization": "Bearer api_..."
      }
    }
  }
}
```

### VS Code (GitHub Copilot, agent mode)

`.mcp.json` en el proyecto, o `mcp.json` del usuario. El bloque `inputs` evita dejar el token en el archivo:

```json
{
  "inputs": [
    {
      "id": "identik-token",
      "type": "promptString",
      "description": "Token de API de Identik (sin el prefijo 'Bearer')",
      "password": true
    }
  ],
  "servers": {
    "identik": {
      "type": "http",
      "url": "https://electronica.identik.me/api/mcp",
      "headers": {
        "Authorization": "Bearer ${input:identik-token}"
      }
    }
  }
}
```

### OpenAI Agents SDK (Python)

```python
import asyncio, os
from agents import Agent, Runner
from agents.mcp import MCPServerStreamableHttp

async def main() -> None:
    async with MCPServerStreamableHttp(
        name="identik",
        params={
            "url": "https://electronica.identik.me/api/mcp",
            "headers": {"Authorization": f"Bearer {os.environ['IDENTIK_TOKEN']}"},
        },
    ) as identik:
        agent = Agent(
            name="Asistente de firmas",
            instructions=(
                "Ayudás a preparar y enviar documentos a firmar con Identik. "
                "Confirmá siempre con la persona antes de llamar a enviar_documento, "
                "porque ese paso consume un crédito y envía emails reales."
            ),
            mcp_servers=[identik],
        )
        result = await Runner.run(agent, "¿Qué plantillas tengo disponibles?")
        print(result.final_output)

asyncio.run(main())
```

### OpenAI Responses API (hosted MCP tool)

```bash
curl https://api.openai.com/v1/responses \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-5",
    "tools": [{
      "type": "mcp",
      "server_label": "identik",
      "server_url": "https://electronica.identik.me/api/mcp",
      "headers": { "Authorization": "Bearer api_..." },
      "require_approval": "always"
    }],
    "input": "Listá mis plantillas de Identik."
  }'
```

> `require_approval` en `"always"` es lo recomendado: `enviar_documento` manda emails reales y consume crédito.
>
> Keep `require_approval` at `"always"`: `enviar_documento` sends real emails and consumes credit.

### Gemini CLI

Este repositorio es instalable directamente como **extensión de Gemini CLI**:

```bash
gemini extensions install pbullian/identik-mcp
```

La extensión registra las dos plataformas (`identik-electronica` y `identik-firma`) y pide los tokens durante la instalación, guardándolos en el keychain del sistema. Completá sólo el de la plataforma que usés y dejá el otro vacío.

The extension registers both platforms (`identik-electronica` and `identik-firma`) and prompts for the tokens at install time, storing them in the OS keychain. Fill in only the platform you use and leave the other blank.

También podés pasarlos por entorno / you can also supply them via the environment:

```bash
export IDENTIK_ELECTRONICA_TOKEN="api_..."
export IDENTIK_FIRMA_TOKEN="api_..."
```

Ver [`gemini-extension.json`](gemini-extension.json) y [`GEMINI.md`](GEMINI.md) (guía de uso que la extensión carga en el contexto del agente, incluida la regla de pedir confirmación antes de `enviar_documento`).

See [`gemini-extension.json`](gemini-extension.json) and [`GEMINI.md`](GEMINI.md) — usage guidance the extension loads into the agent's context, including the rule to confirm with a human before `enviar_documento`.

### Claude Desktop

Claude Desktop no acepta encabezados HTTP estáticos en sus conectores remotos, así que el servidor se conecta a través del puente [`mcp-remote`](https://www.npmjs.com/package/mcp-remote). En `claude_desktop_config.json`:

Claude Desktop does not accept static HTTP headers on remote connectors, so the server is bridged through [`mcp-remote`](https://www.npmjs.com/package/mcp-remote). In `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "identik": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "https://electronica.identik.me/api/mcp",
        "--header",
        "Authorization:${IDENTIK_AUTH}"
      ],
      "env": {
        "IDENTIK_AUTH": "Bearer api_..."
      }
    }
  }
}
```

> El valor va como `Authorization:${IDENTIK_AUTH}` **sin espacio** después de los dos puntos: `mcp-remote` parte el argumento en el primer `:`, y algunos runtimes de Claude Desktop cortan los argumentos que contienen espacios. El espacio real viaja dentro de la variable de entorno.
>
> Note the `Authorization:${IDENTIK_AUTH}` form with **no space** after the colon: `mcp-remote` splits on the first `:`, and some Claude Desktop runtimes split arguments containing spaces. The real space travels inside the env var.

---

## Descubrimiento / Discovery

Cada instancia publica su propia metadata, sin autenticación:

Each instance serves its own metadata, unauthenticated:

| Recurso / Resource | URL |
|---|---|
| Manifiesto MCP / MCP manifest | `https://electronica.identik.me/.well-known/mcp.json` |
| Guía para LLMs / LLM guide | `https://electronica.identik.me/llms.txt` |
| Documentación interactiva de la API / Interactive API docs | `https://electronica.identik.me/api/docs` |
| Especificación OpenAPI / OpenAPI spec | `https://electronica.identik.me/api/v1/openapi.json` |
| Colección Postman / Postman collection | `https://electronica.identik.me/api/docs/postman.json` |
| Validador público de PDF / Public PDF validator | `https://electronica.identik.me/validar` |

Lo mismo en `firma.identik.me` y en los hosts `sandbox-*`. La sección **"Agentes de IA (servidor MCP)"** de `/api/docs` documenta el servidor MCP junto a la API REST.

Same paths on `firma.identik.me` and on the `sandbox-*` hosts. The **"Agentes de IA (servidor MCP)"** section of `/api/docs` documents the MCP server alongside the REST API.

### Registro MCP oficial / Official MCP Registry

Ambos servidores están publicados en el [MCP Registry oficial](https://registry.modelcontextprotocol.io) bajo el namespace `me.identik`, verificado por DNS sobre `identik.me`:

Both servers are published in the [official MCP Registry](https://registry.modelcontextprotocol.io) under the `me.identik` namespace, DNS-verified over `identik.me`:

```bash
curl "https://registry.modelcontextprotocol.io/v0.1/servers?search=me.identik"
```

Los manifiestos publicados están en [`servers/`](servers/). / The published manifests live in [`servers/`](servers/).

---

## Notas operativas / Operational notes

- **`enviar_documento` tiene efectos reales.** Manda emails a los firmantes y consume un crédito de documento. Un agente debería pedir confirmación humana antes de llamarlo. Usá los sandboxes mientras desarrollás. / **`enviar_documento` has real side effects.** It emails signers and consumes a document credit. Agents should ask for human confirmation before calling it. Use the sandboxes while developing.
- **Las plantillas se arman en la web.** El MCP consume plantillas existentes; no crea ni edita el diseño de campos. / **Templates are built in the web UI.** The MCP layer consumes existing templates; it does not create or edit field layouts.
- **Créditos.** `estado_cuenta` informa los créditos disponibles. La verificación biométrica usa un pool de créditos separado. / **Credits.** `estado_cuenta` reports available credits. Biometric verification draws on a separate credit pool.
- **Resguardo.** `descargar_documento_firmado` responde `410` pasado el plazo de resguardo del documento. / **Retention.** `descargar_documento_firmado` returns `410` past the document's retention window.

---

## Soporte / Support

- **Token, precios, cuentas / tokens, pricing, accounts:** contacto@identik.me
- **Web:** https://identik.me
- **Problemas con estos manifiestos / issues with these manifests:** [issues de este repositorio](https://github.com/pbullian/identik-mcp/issues)

## Licencia / License

Los manifiestos y ejemplos de este repositorio se publican bajo [MIT](LICENSE). El servicio Identik es un producto comercial alojado, con sus propios términos.

The manifests and examples in this repository are released under [MIT](LICENSE). The Identik service itself is a commercial hosted product with its own terms.
