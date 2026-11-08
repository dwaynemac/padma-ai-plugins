# Contribuir a PADMA Tools

Buscamos integraciones pequeñas, claras y útiles para usuarios reales de PADMA.

## Agregar un plugin

1. Creá el plugin en `plugins/<nombre>/`.
2. Incluí manifiestos válidos en `.codex-plugin/plugin.json` y
   `.claude-plugin/plugin.json`, con el mismo nombre y versión.
3. Agregá únicamente los componentes necesarios: skills, MCP, apps, scripts o assets.
4. Registrá el plugin en ambos catálogos:
   `.agents/plugins/marketplace.json` para Codex y
   `.claude-plugin/marketplace.json` para Claude Code.
5. Documentá autenticación, casos de uso, límites y efectos de escritura.
6. Verificá que no haya tokens, credenciales, datos personales ni IDs internos hardcodeados.

Preferimos plugins delgados: el servidor o la aplicación PADMA conserva permisos, validaciones e invariantes; el plugin aporta descubrimiento, contexto y workflows.

No enlaces los dos `marketplace.json`: sus esquemas no son iguales. El catálogo
de Codex usa una fuente local estructurada; Claude Code usa rutas relativas
como `"./plugins/<nombre>"`. Los dos deben apuntar al mismo directorio de
plugin.

## Agregar una skill independiente

Usá `skills/<nombre>/SKILL.md` cuando el workflow no necesite MCP, apps, hooks ni otros componentes de un plugin. La descripción debe indicar con claridad cuándo debe activarse y las instrucciones deben enlazar solo las referencias necesarias.

## Checklist

- Los nombres usan minúsculas y guiones.
- No quedan placeholders ni instrucciones de desarrollo local.
- Los ejemplos representan capacidades disponibles hoy.
- Las escrituras sensibles requieren una propuesta clara y autorización del usuario.
- La documentación explica cómo verificar el resultado.
- El plugin y sus skills pasan sus validadores antes de publicarse.

## Validación

Ejecutá la prueba de compatibilidad y las verificaciones de formato antes de
publicar:

```bash
rbenv exec ruby test/marketplace_compatibility_test.rb

find .agents .claude-plugin plugins -name '*.json' -print0 |
  xargs -0 -n1 jq empty

rbenv exec ruby -rpsych -e \
  'ARGV.each { |path| Psych.safe_load_file(path, aliases: false) }' \
  plugins/*/skills/*/agents/openai.yaml

git diff --check
git status --short
```

Cuando Claude Code esté disponible localmente, completá también la validación
oficial:

```bash
claude plugin validate .
claude plugin validate ./plugins/crm
claude plugin validate ./plugins/money
claude plugin validate ./plugins/learn
claude plugin validate ./plugins/padma
```
