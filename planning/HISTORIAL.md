# Historial · TIRELUS

Lo que ya se hizo y lo que se descartó durante el hackathon (NASA Space Apps 2026). Lo pendiente está en [`pendientes.md`](../pendientes.md) y lo que se dejó para después de la demo, en [`FUTURO.md`](FUTURO.md).

Prioridad: **P0** = sin esto no hay demo · **P1** = importante para el MVP · **P2** = pulido si sobra tiempo.

## Hecho

| Prioridad | Qué | Resultado |
|---|---|---|
| ~~P1~~ ✅ | ~~Decidir la dirección de la alerta (`above` o `both`)~~ | Decidido el 15 nov: `heart_rate`, `temperature`, `rnfl_thickness`, `intraocular_pressure` y `cup_to_disc_ratio` deben alertar en ambos sentidos, igual que en `db/schema.sql`. **La implementación no está en `main`:** queda como deuda técnica en la rama `feat/alerta-ambos-sentidos`. Ver [`planning/FUTURO.md`](FUTURO.md) §3. |
| ~~P1~~ ✅ | ~~Decidir sistema de usuarios~~ | Decidido el 15 nov: la API se queda con el tripulante fijo para la demo (`TIRELUS_ASTRONAUT_ID` o el primero de la base). La deuda técnica (roles, privacidad en API y base) está en [`planning/FUTURO.md`](FUTURO.md) §2. |
| ~~P1~~ ✅ | ~~Citar el repo de datos sintéticos~~ | Citado en [Datos sintéticos](../README.md#datos-sintéticos) del README. |
| ~~P1~~ ✅ | ~~Fusionar `frontend/jen-trabajo` en `main`~~ | Fusionado el 15 nov (`707c4c6`), sin conflictos: ES/EN con `flutter_localizations`, navegación adaptable, teclado numérico propio, tendencia con puntos tocables, aviso al CMO con deshacer, modo Autónomo con protocolo guiado, SANS localizado, texto mínimo de 13 px y áreas táctiles de 44 px, avisos cuando el motor no responde. `flutter test`: 88 pruebas pasan. |
| ~~P1~~ ✅ | ~~Panel calculado por el motor de reglas (los cinco sistemas)~~ | **Ojos** lleva el azulejo de SANS con los umbrales publicados (+20 / 55 µm, regla propia `evaluate_sans`) más los cinco indicadores de `002_ojos.sql`; **hueso** la masa corporal; **mente** sueño, ánimo y PVT; **inmune** la temperatura. `data.SYSTEMS` se quedó solo con el texto educativo y `_ind` desapareció. |
| ~~P1~~ ✅ | ~~Módulo cardio del panel~~ | `python_app/panel.py` arma cada bloque desde `catalog.snapshot()` con `evaluate_trend`: estado del sistema, valor, variación frente a la línea base y conteo de días ("1 de 3 días", "4 días seguidos"). `data.py` perdió las cifras de cardio; las métricas ganaron `system` y se agregaron diastólica y SpO₂ con los rangos de `db/schema.sql`. Pruebas en `tests_py/test_panel.py` y `test/dashboard_screen_test.dart`. |
| ~~P1~~ ✅ | ~~El panel se refresca solo~~ | `DashboardScreen` vuelve a preguntar cada `TIRELUS_REFRESH_SECONDS` (5 s por defecto), conserva el último dato bueno si el refresco falla ("Sin conexión · último dato HH:MM:SS") y muestra "Actualizado HH:MM:SS". |
| ~~P1~~ ✅ | ~~Cada cuánto se relee la base~~ | `TIRELUS_DB_TTL` (30 s por defecto, 2 s para la demo); un valor inválido no desactiva la base. |
| ~~P2~~ ✅ | ~~Puerto de la API configurable~~ | `--dart-define=TIRELUS_PORT`, como ya pedía `CLAUDE.md`; antes estaba escrito a mano en Dart. |
| ~~P1~~ ✅ | ~~Datos vitales de la tripulación~~ | `tools/sim_sinteticos.py` carga los CSV del generador del equipo a PostgreSQL: tripulación, línea base personal prevuelo y lecturas, con mapeo probado contra los indicadores reales del esquema. Verificado con 4 tripulantes × 90 días. |
| ~~P2~~ ✅ | ~~`--records` exacto en el generador~~ | En el repo del generador: `--records` ahora es el número exacto de filas (decide cuántos pacientes, nunca su duración) y `--patients` manda sobre él; antes `--records 100` producía 6000 filas. 13 pruebas nuevas. |
| ~~P1~~ ✅ | ~~Validar rangos en la API~~ | `POST /evaluate/{metric}` y `/evaluate/sans` responden 422 fuera de `valid_range` (o con NaN/inf), y el catálogo descarta lecturas de la base fuera de rango. Pruebas en `tests_py/test_ranges.py` y `test/api_range_test.dart` (la app muestra "Sin dato" en vez de lanzar). |
| ~~P0~~ ✅ | ~~Levantar el servidor externo con PostgreSQL~~ | PostgreSQL 18.7 en la red local con un usuario de equipo sin permisos de DDL. Host y contraseña se comparten por un canal privado (no en el repo). Solo datos sintéticos. |
| ~~P0~~ ✅ | ~~Probar la capa de PostgreSQL contra un servidor real~~ | El 14 nov las consultas de `db.py` se ejecutaron contra el servidor y `/health` dijo `data_source: db`. Prueba de estabilidad, inyección y concurrencia en [`db/README.md`](../db/README.md#prueba-de-estabilidad-14-nov-servidor-del-equipo). |
| ~~P0~~ ✅ | ~~Exportar el resumen médico~~ | `GET /summary/export` devuelve Markdown con fecha, día de misión y "Datos de ejemplo" (`tests_py/test_export.py`). Botón "Exportar resumen médico" en la pantalla de tendencia: copia al portapapeles. Compartir con `share_plus` y PDF quedan para después. |
| ~~P1~~ ✅ | ~~Guardar el resumen entre reinicios~~ | Se guarda en `summary.json`. |
| ~~P1~~ ✅ | ~~Pasar la carpeta de datos desde Flutter~~ | `path_provider` manda `TIRELUS_DATA_DIR` con `getApplicationSupportDirectory()` (`lib/python_env.dart`, probado en `test/python_env_test.dart`). Si falla, Python usa su respaldo. |
| ~~P1~~ ✅ | ~~Alertar tendencias a la baja~~ | `evaluate_trend` recibe `direction` ("above"/"below") y `absolute_low`; la API usa `alert_when` del catálogo y devuelve `consecutive_below` y `delta_from_low`. Pruebas en `test_rules.py` y `test_p1.py`. |
| ~~P2~~ ✅ | ~~Botón "Marte" cortado en pantallas angostas~~ | `lib/widgets/env_selector.dart` usa botones segmentados en pantallas anchas y menú desplegable por debajo de 640 px. Probado a 360 px sin desbordes. |
| ~~P2~~ ✅ | ~~Pruebas de widgets en Flutter~~ | `app/test/` con pruebas del semáforo (color + forma + palabra + lector de pantalla), del selector de entorno con un `TirelusApi` falso y de contraste de la paleta. |
| ~~P2~~ ✅ | ~~Revisar accesibilidad~~ | Todo el texto ≥ 4.5:1 sobre todos los fondos; bordes de controles ≥ 3:1 (`borderStrong` #5B6F9E); selector de entorno ≥ 44 px. `test/contrast_test.dart` lo verifica en cada corrida. |

## Descartado

| Qué | Motivo |
|---|---|
| ~~Activar TLS en el servidor PostgreSQL~~ | Descartado para la demo el 15 nov: solo hay datos sintéticos en la red local. El cliente ya soporta `TIRELUS_DB_SSL`. Ver [`planning/FUTURO.md`](FUTURO.md) §4. |
| ~~Rotar la contraseña del servidor~~ | Descartado para la demo el 15 nov por la misma razón. Conviene hacerlo si el servidor sigue encendido después del hackathon. |
| ~~PostgreSQL interno de la nave (concepto)~~ | No se documenta para la demo; queda como concepto de la versión final en [`planning/FUTURO.md`](FUTURO.md) §4. |
| ~~Umbrales de respaldo que faltan~~ | Pasan a planeación a futuro: [`planning/FUTURO.md`](FUTURO.md) §1. No se inventan; los decide la persona de ciencia como supuestos de diseño. |
| ~~Probar la app empaquetada en Windows~~ | Descartado el 14 nov. La demo corre en modo desarrollo: `python python_app/main.py` y `flutter run -d windows --dart-define=TIRELUS_DEV_SERVER=true`. Si se retoma: `dart run serious_python:main package python_app -p Windows -r -r -r python_app/requirements.txt --cleanup`, Visual Studio con C++ y `pg8000` en el empaquetado. |
| ~~Probar Docker (`tirelus.ps1`, imagen y compose)~~ | Descartado el 14 nov. Los archivos siguen en el repo, nunca se ejecutaron. |
