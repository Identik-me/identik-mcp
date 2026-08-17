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

Los **sandboxes** son entornos separados, con sus propias cuentas, datos, créditos y base de datos: sirven para desarrollar y evaluar la integración sin tocar producción. Los documentos que emiten **no tienen validez**, por diseño y de forma verificable: la constancia sale marcada «PRUEBA — FIRMA NO VÁLIDA», el sello se hace con un certificado de prueba distinto al de producción, y el validador público lo reconoce y rechaza el documento como de prueba (`validar_pdf` devuelve `testEnvironment: true` y `ok: false`).

The **sandboxes** are separate environments with their own accounts, data, credits and database — use them to build and evaluate the integration without touching production. Documents they issue are **not valid**, by design and verifiably so: the audit certificate is watermarked «PRUEBA — FIRMA NO VÁLIDA», sealing uses a test certificate distinct from the production one, and the public validator recognises it and rejects the document as a test (`validar_pdf` returns `testEnvironment: true` and `ok: false`).

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

| Cliente / Client | ¿Encabezado estático nativo? / Native static header? | Dónde / Where |
|---|---|---|
| [Claude Code](#claude-code) | Sí / Yes | `claude mcp add`, `.mcp.json` |
| [Cursor](#cursor) | Sí / Yes | `~/.cursor/mcp.json` |
| [VS Code / Copilot](#vs-code-github-copilot-agent-mode) | Sí / Yes | `.vscode/mcp.json` |
| [Codex CLI](#codex-cli) | Sí / Yes | `~/.codex/config.toml` |
| [OpenAI Agents SDK](#openai-agents-sdk-python) | Sí / Yes | código / code |
| [OpenAI Responses API](#openai-responses-api-hosted-mcp-tool) | Sí / Yes | código / code |
| [Gemini CLI](#gemini-cli) | Sí / Yes | extensión / extension |
| [Claude Desktop](#claude-desktop) | **No** — vía `mcp-remote` / via `mcp-remote` | `claude_desktop_config.json` |

### Claude Code

```bash
claude mcp add identik --transport http https://electronica.identik.me/api/mcp \
  --header "Authorization: Bearer api_..."
```

`--header` se puede repetir. Forma equivalente en `.mcp.json` (versionable en el proyecto) / `--header` is repeatable. Equivalent `.mcp.json` project file:

```json
{
  "mcpServers": {
    "identik": {
      "type": "http",
      "url": "https://electronica.identik.me/api/mcp",
      "headers": {
        "Authorization": "Bearer ${IDENTIK_TOKEN}"
      }
    }
  }
}
```

> `type` es **obligatorio** cuando hay `url`: una entrada con `url` y sin `type` se considera un error de configuración y el servidor se omite. Claude Code expande `${VAR}` y `${VAR:-default}` en `url` y en `headers`, así que el token puede quedar fuera del archivo versionado.
>
> `type` is **required** whenever `url` is present — an entry with `url` and no `type` is a configuration error and the server is skipped. Claude Code expands `${VAR}` and `${VAR:-default}` in `url` and `headers`, so the token need not be committed.

### Cursor

`~/.cursor/mcp.json` (global) o `.cursor/mcp.json` (por proyecto):

```json
{
  "mcpServers": {
    "identik": {
      "url": "https://electronica.identik.me/api/mcp",
      "headers": {
        "Authorization": "Bearer ${env:IDENTIK_TOKEN}"
      }
    }
  }
}
```

Cursor infiere que el servidor es remoto por la presencia de `url`: no lleva `type`. Si recibís un `401`, hay builds en los que `${env:...}` no se resuelve dentro de `headers`; en ese caso poné el token literal en `~/.cursor/mcp.json` (el global, **no** el `.cursor/mcp.json` versionado).

Cursor infers a remote server from the presence of `url`, so no `type` field is needed. If you get a `401`, some builds fail to resolve `${env:...}` inside `headers`; put the literal token in `~/.cursor/mcp.json` (the global one, **not** the committed `.cursor/mcp.json`).

### VS Code (GitHub Copilot, agent mode)

`.vscode/mcp.json` en el workspace, o el `mcp.json` del perfil de usuario (paleta de comandos → **MCP: Open User Configuration**). Ojo: la clave de nivel superior es `servers`, no `mcpServers`. El bloque `inputs` evita dejar el token en el archivo:

`.vscode/mcp.json` in the workspace, or the user-profile `mcp.json` (Command Palette → **MCP: Open User Configuration**). Note the top-level key is `servers`, not `mcpServers`. The `inputs` block keeps the token out of the file:

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

VS Code pide el token en la primera conexión y lo guarda de forma segura, así que no queda nada secreto en el repositorio.

VS Code prompts for the token on first connect and stores it securely, so no secret lands in git.

> Con el **Agent Host** de VS Code, los servidores que usan `${input:...}` no se reenvían. Para configuración portable usá un `.mcp.json` del workspace o `~/.copilot/mcp-config.json` (esquema distinto: clave `mcpServers` y campo `tools`).
>
> With VS Code's **Agent Host**, servers using `${input:...}` are not forwarded. For portable configuration use a workspace `.mcp.json` or `~/.copilot/mcp-config.json` (different schema: `mcpServers` key plus a `tools` field).

### Codex CLI

En `~/.codex/config.toml`, con el token fuera del archivo (Codex agrega el prefijo `Bearer`):

In `~/.codex/config.toml`, keeping the token out of the file (Codex adds the `Bearer` prefix itself):

```toml
[mcp_servers.identik]
url = "https://electronica.identik.me/api/mcp"
bearer_token_env_var = "IDENTIK_TOKEN"
```

Se puede generar con / can be generated with:

```bash
codex mcp add identik --url https://electronica.identik.me/api/mcp \
  --bearer-token-env-var IDENTIK_TOKEN
```

Equivalente con el encabezado explícito / equivalent with an explicit header:

```toml
[mcp_servers.identik]
url = "https://electronica.identik.me/api/mcp"
http_headers = { Authorization = "Bearer api_..." }
tool_timeout_sec = 120
```

> `codex mcp add` no tiene flag para encabezados arbitrarios: si necesitás `http_headers`, editá `config.toml` a mano.
>
> `codex mcp add` has no flag for arbitrary headers — hand-edit `config.toml` if you need `http_headers`.

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
    "model": "gpt-5.6",
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

Dos detalles de esta vía / two notes on this path:

- El token va en **`headers`**, no en `authorization`: ese campo es para un access token de OAuth, que este servidor no usa. / The token goes in **`headers`**, not `authorization` — that field is for an OAuth access token, which this server does not use.
- A diferencia de los demás clientes, acá **OpenAI** se conecta al servidor desde su propia infraestructura, no desde tu máquina. / Unlike the other clients, here **OpenAI** connects to the server from its own infrastructure, not from your machine.

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

El archivo de configuración de Claude Desktop admite solamente servidores stdio, y sus **conectores personalizados** piden una URL con OAuth (no aceptan un encabezado estático). Así que el servidor se conecta a través del puente [`mcp-remote`](https://www.npmjs.com/package/mcp-remote).

Claude Desktop's config file takes stdio servers only, and its **custom connectors** dialog asks for a URL with OAuth (no static-header field). So the server is bridged through [`mcp-remote`](https://www.npmjs.com/package/mcp-remote).

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "identik": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "https://electronica.identik.me/api/mcp",
        "--transport", "http-only",
        "--header", "Authorization:${IDENTIK_AUTH}"
      ],
      "env": {
        "IDENTIK_AUTH": "Bearer api_..."
      }
    }
  }
}
```

`--transport http-only` evita que `mcp-remote` pruebe primero SSE, que este servidor no expone. Requiere Node.js instalado.

`--transport http-only` stops `mcp-remote` from probing SSE first, which this server does not expose. Requires Node.js.

> El valor va como `Authorization:${IDENTIK_AUTH}` **sin espacio** después de los dos puntos: `mcp-remote` parte el argumento en el primer `:`, y algunos runtimes de Claude Desktop cortan los argumentos que contienen espacios. El espacio real viaja dentro de la variable de entorno.
>
> Note the `Authorization:${IDENTIK_AUTH}` form with **no space** after the colon: `mcp-remote` splits on the first `:`, and some Claude Desktop runtimes split arguments containing spaces. The real space travels inside the env var.

> La pestaña **Code** de Claude Desktop (Claude Code embebido) sí lee `~/.claude.json` y `.mcp.json`, así que ahí funciona la forma nativa `type: "http"` + `headers` de más arriba. La limitación es sólo de la superficie de chat.
>
> Claude Desktop's **Code** tab (embedded Claude Code) does read `~/.claude.json` and `.mcp.json`, so the native `type: "http"` + `headers` form above works there. The limitation applies only to the chat surface.

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
