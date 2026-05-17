# FoxClean

FoxClean es una app gratuita y de codigo abierto para limpiar y optimizar macOS.
Combina una app nativa en SwiftUI, un nucleo Swift compartido y la CLI `fox`.

## Inicio rapido

```sh
brew bundle
xcodegen generate
script/verify_local.sh --launch
```

## Puntos clave

- La app y la CLI comparten `FoxCleanCore`.
- Las acciones destructivas usan dry-run por defecto y mueven archivos a Trash
  cuando se confirman.
- Los registros de operaciones usan JSONL y permiten rollback.
- Incluye escaneo de apps, basura del sistema, orfanos, analizador de disco,
  estado del sistema, limpieza de instaladores, purge de proyectos, tareas de
  optimizacion, completion de shell y scripts para launchers.
- Sin telemetria, sin suscripcion, licencia MIT.

## Nota de release

La distribucion publica todavia requiere firma Developer ID, notarizacion y
credenciales de publicacion.
