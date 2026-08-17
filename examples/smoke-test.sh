#!/usr/bin/env bash
#
# Smoke test del servidor MCP de Identik / Identik MCP server smoke test.
#
# Uso / Usage:
#   ./smoke-test.sh                                  # sin token: espera 401
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
  echo "warn: sin IDENTIK_TOKEN — se espera HTTP 401 (el servidor exige token)." >&2
fi

echo "==> POST ${URL}  (tools/list)"
curl -sS --max-time 30 -X POST "$URL" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  "${AUTH[@]}" \
  -w '\n<-- HTTP %{http_code}\n' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'

# Sin token la respuesta es:
#   {"jsonrpc":"2.0","error":{"code":-32001,
#    "message":"Falta el token de API (encabezado Authorization: Bearer api_...)."},"id":null}
#
# Este servidor MCP es STATELESS: sólo acepta POST. GET y DELETE devuelven 405.
# This MCP server is STATELESS: POST only. GET and DELETE return 405.
