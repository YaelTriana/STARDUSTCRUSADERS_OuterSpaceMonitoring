# Origen de las skills de `.claude/skills/` (TIRELUS)

Copiadas el 2026-11-14 (clon superficial de cada repo). Para actualizar, vuelve a copiar la carpeta desde el repo de origen.

| Skills | Repo de origen | Commit | Licencia |
|---|---|---|---|
| **tirelus-serious-python** (propia) | Este repo. Basada en https://pub.dev/packages/serious_python v6.1.3 | — | Del proyecto |
| flutter-add-integration-test, flutter-add-widget-preview, flutter-add-widget-test, flutter-apply-architecture-best-practices, flutter-build-responsive-layout, flutter-fix-layout-issues, flutter-implement-json-serialization, flutter-setup-declarative-routing, flutter-setup-localization, flutter-use-http-package, dart-add-unit-test, dart-fix-runtime-errors, dart-run-static-analysis, dart-resolve-package-conflicts, dart-generate-test-mocks | https://github.com/flutter/agent-plugins | e5a88d2 (2026-11-11) | BSD-3-Clause (The Flutter Authors) |
| fastapi-templates, openapi-spec-generation, python-code-style, python-configuration, python-error-handling, python-testing-patterns, python-type-safety | https://github.com/wshobson/agents | 9c61ab2 (2026-11-08) | MIT |
| neurokit2, statistical-analysis | https://github.com/K-Dense-AI/scientific-agent-skills | 2d2065f (2026-11-09) | MIT |
| brainstorming, writing-plans, systematic-debugging, test-driven-development | https://github.com/obra/superpowers | 22f0b46 (2026-11-03) | MIT |
| frontend-design | https://github.com/anthropics/skills | 1780c5e (2026-11-14) | Ver `frontend-design/LICENSE.txt` |
| accessibility-review | https://github.com/anthropics/knowledge-work-plugins | e91a134 (2026-11-13) | Ver el repo de origen |

## Cambios por serious_python
- **Quitada `statsmodels`:** statsmodels no tiene binarios para Android/iOS en https://pypi.flet.dev, así que no puede ir dentro de la app.
- **`neurokit2`:** solo para generar datos sintéticos en desarrollo, no dentro de la app.
- **`fastapi-templates` y `openapi-spec-generation`:** siguen vigentes, porque la API ahora corre en `127.0.0.1` dentro de la app.
- **Skills de Dart:** son para la UI. La lógica no se porta a Dart.

## Notas
- `neurokit2` declara `allowed-tools: Read Write Edit Bash Glob`. Revísala antes de usarla.
- `accessibility-review` está pensada para web: aplícala sobre capturas o un build de Flutter Web.
- Pendiente de decidir: un paquete de buenas prácticas de Flutter según la gestión de estado (evanca/flutter-ai-rules si Riverpod, VeryGoodOpenSource/very_good_ai_flutter_plugin si Bloc). No instalar ambos.
- Pendiente de escribir (skills propias): `tirelus-motor-reglas`, `tirelus-datos-sinteticos`, `tirelus-contrato-api`, `tirelus-ui-cabina`.
- Las skills de `.claude/skills/` no cargan en sesiones de Claude en la nube.
