#!/usr/bin/env bash
#
# Smoke test del servidor MCP de Identik / Identik MCP server smoke test.
#
# Uso / Usage:
#   ./smoke-test.sh                                  # descubrimiento público: espera 200
#   IDENTIK_TOKEN=api_xxx ./smoke-test.sh            # con token: lista las herramientas
#   IDENTIK_MCP_URL=https://sandbox-electronica.identik.me/api/mcp ./smoke-test.sh
#
set -euo pipefail

URL="${IDENTIK_MCP_URL:-https://electronica.identik.me/api/mcp}"
TOKEN="${IDENTIK_TOKEN:-}"

AUTH=()
if [[ -n "$TOKEN" ]]; then
  AUTH=(-H "Authorization: Bearer ${TOKEN}")
else
  echo "info: descubrimiento público sin token; las operaciones privadas requieren autenticación." >&2
fi

echo "==> POST ${URL}  (tools/list)"
curl -sS --max-time 30 -X POST "$URL" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  "${AUTH[@]}" \
  -w '\n<-- HTTP %{http_code}\n' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'

# Sin token, tools/list responde 200 con el catálogo público de herramientas.
# Las operaciones de cuenta y documentos siguen requiriendo un token válido.
#
# Este servidor MCP es STATELESS: sólo acepta POST. GET y DELETE devuelven 405.
# This MCP server is STATELESS: POST only. GET and DELETE return 405.
