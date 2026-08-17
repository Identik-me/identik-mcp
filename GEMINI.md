# Identik — guía para el agente / agent guidance

Estás conectado a **Identik**, una plataforma argentina de firma de documentos con validez legal (Ley 25.506). Hay dos servidores, según el nivel de firma:

- `identik-electronica` — **firma electrónica** (Ley 25.506, art. 5). Enlace por email + evidencia completa (constancia con trazabilidad, sello criptográfico, sello de tiempo RFC-3161). Admite verificación biométrica opcional del firmante.
- `identik-firma` — **firma digital** (Ley 25.506, arts. 2, 7 y 8). Cada firmante firma con su propio certificado de certificador licenciado (CUIL + PIN + OTP). Tiene presunción legal de autoría e integridad.

Si la persona no aclara cuál usar y el documento necesita el máximo valor probatorio, preguntá antes de elegir.

## Reglas de uso / usage rules

1. **`enviar_documento` tiene efectos reales e irreversibles.** Manda emails a los firmantes y consume un crédito de la cuenta. **Pedí confirmación explícita** antes de llamarlo, y mostrá primero el título del documento y la lista de firmantes con sus emails.
2. **`crear_documento_desde_plantilla` no consume crédito**: el documento queda en borrador. Es el paso seguro para armar y revisar.
3. **Verificá los emails de los firmantes** con la persona antes de crear el documento. Un email equivocado manda un documento legal a un tercero.
4. **Las plantillas se arman en la interfaz web.** No podés crear ni editar plantillas desde acá; sólo usarlas. Si no hay una plantilla adecuada, decilo en vez de improvisar.
5. **No inventes datos de firmantes** (nombre, email, CUIL, número de DNI). Si falta un dato, pedilo.
6. **Consultá `estado_cuenta`** antes de un envío grande, para confirmar que hay créditos.

## Flujo típico / typical flow

```
listar_plantillas  →  crear_documento_desde_plantilla  →  [confirmación humana]  →  enviar_documento
                                                                                      ↓
                                                    obtener_documento / traza_auditoria
                                                                                      ↓
                                                            descargar_documento_firmado
```

## Notas por plataforma / platform notes

- **Firma electrónica:** `crear_documento_desde_plantilla` acepta `requiere_biometria: true` (DNI + prueba de vida antes de firmar; consume 1 crédito de verificación por verificación aprobada). Si la activás, pasá también el `dni_numero` de cada firmante para que la verificación se valide contra ese dato.
- **Firma digital:** cada firmante necesita un `cuil` que corresponda a su certificado. Sin certificado previo, la persona no puede firmar por esta vía.

## Diagnóstico / troubleshooting

- `401` → falta el token o es inválido. El token va en `Authorization: Bearer api_...` (variables `IDENTIK_ELECTRONICA_TOKEN` / `IDENTIK_FIRMA_TOKEN`).
- `410` en `descargar_documento_firmado` → venció el plazo de resguardo del documento.
- Para probar sin efectos legales ni consumo de créditos de producción, usá los entornos sandbox: `sandbox-electronica.identik.me` y `sandbox-firma.identik.me`.
