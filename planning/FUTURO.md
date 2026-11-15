# Planeación a futuro · TIRELUS

Lo que se deja **fuera de la demo del hackathon** a propósito (decisiones del 15 nov 2026) y qué haría falta para retomarlo. Lo pendiente para la demo vive en [`pendientes.md`](../pendientes.md).

La demo usa solo datos sintéticos ("Datos de ejemplo") del generador del equipo, [`SyntheticData_STARDUSTCRUSADERS_OuterSpaceMonitoring`](https://github.com/MerelyMeredith/SyntheticData_STARDUSTCRUSADERS_OuterSpaceMonitoring). Casi todo lo de este documento se vuelve obligatorio el día que haya datos reales.

## 1. Umbrales de respaldo que faltan

Seis indicadores no tienen límite de respaldo ni en la base (`thresholds`) ni en `app/python_app/data.py`:

| Indicador | Sistema | Qué falta definir |
|---|---|---|
| `body_mass` | hueso y músculo | Pérdida máxima aceptable frente a la base personal |
| `hrv` | corazón | Mínimo de respaldo |
| `macular_thickness` | ojos | Máximo de respaldo |
| `rnfl_thickness` | ojos | Máximo y mínimo (alerta en ambos sentidos) |
| `cup_to_disc_ratio` | ojos | Máximo y mínimo (alerta en ambos sentidos) |
| `near_vision_logmar` | ojos | Máximo de respaldo |

Sin ese límite, estos indicadores solo pueden marcar "atención" por desviación sostenida frente a la base personal; nunca "crítico".

Reglas para definirlos:

- **No se inventan.** NASA no publica umbrales de alerta en vuelo para estos indicadores (no hay fuente). Cada cifra entra como **supuesto de diseño** etiquetado, con el rango clínico terrestre del que sale y su cita.
- La única excepción con cifra publicada sigue siendo SANS: +20 µm primer signo y 55 µm o Frisén 1 como preocupación clínica. Ese umbral aplica al **cambio** de grosor retiniano peripapilar (`retinal_delta`), no a `rnfl_thickness` ni a `macular_thickness` en valor absoluto.
- Los decide la persona de ciencia. Se cargan en `thresholds` (`critico_low`, `critico_high`) y, para el camino sin base, en `abs_low`/`abs_high` de `data.METRICS`.
- Cada umbral nuevo lleva su prueba en `app/tests_py/` antes de entrar (TDD).

Referencia: [`db/AUDITORIA.md`](../db/AUDITORIA.md) §5.1.

## 2. Deuda técnica: sistema de usuarios

**Decisión para la demo:** la API se queda con un tripulante fijo (`TIRELUS_ASTRONAUT_ID`, o el primero de la tabla `astronauts`). No hay inicio de sesión ni selección de perfil.

Qué queda debiendo:

- **Identidad y roles.** Tres roles: astronauta, CMO y flight surgeon. El esquema ya tiene `crew_role`, pero nada lo usa.
- **Privacidad en la API.** Regla del proyecto: los datos médicos de cada tripulante solo los ven él mismo, el CMO y el flight surgeon, y nunca en pantallas compartidas. Hoy se cumple solo porque la app muestra a un tripulante; no hay control de acceso.
- **Privacidad en la base.** Sin roles de PostgreSQL ni RLS (`db/AUDITORIA.md` §5.3). Obligatorio antes de guardar datos reales.
- **Consola de base y vistas compartidas.** Deben seguir sin datos clínicos cuando exista más de un perfil.

Camino sugerido, de menor a mayor esfuerzo:

1. Selección de perfil con rol al abrir la app (sin contraseña), con la API filtrando por tripulante y rol.
2. Autenticación real en la API local y políticas RLS en PostgreSQL por `astronaut_id` y rol.
3. Escalamiento astronauta → CMO → flight surgeon con registro de quién vio qué.

## 3. Deuda técnica: alerta en ambos sentidos

**Decisión (15 nov):** `heart_rate`, `temperature`, `rnfl_thickness`, `intraocular_pressure` y `cup_to_disc_ratio` deben alertar si suben **o** si bajan (`both`), igual que en `db/schema.sql` y `db/002_ojos.sql`.

**Estado:** no está en `main`. En `main` el motor solo acepta `above` o `below` (`evaluate_trend` lanza `ValueError` con `both`) y esos cinco indicadores alertan solo hacia arriba. No falla porque `db.py` no lee `alert_when` de la base: la dirección sale siempre de `data.py`.

**Dónde está el trabajo:** rama `feat/alerta-ambos-sentidos` (sale de `main` en `dc1f504`). Cambios, con pruebas pasando (175 de Python, 99 de Flutter):

| Archivo | Cambio |
|---|---|
| `app/python_app/rules.py` | `evaluate_trend` acepta `direction="both"`; cada racha se cuenta por separado (cruzar de un lado al otro no las suma) |
| `app/python_app/data.py` | Los cinco indicadores pasan a `alert_when: "both"` y su regla dice "por arriba o por abajo" |
| `app/lib/data/models.dart` | Con `both`, la pantalla de tendencia muestra el lado donde está la racha |
| `app/tests_py/test_rules.py`, `test_catalog.py`, `app/test/trend_model_test.dart` | Pruebas nuevas y una actualizada |

Para cerrarla: revisar la rama, fusionarla en `main` y actualizar `db/AUDITORIA.md` §5.2. Queda aparte `respiratory_rate` y `fasting_glucose`, que la base marca `both` y no existen en `data.METRICS`.

## 4. Servidor de base de datos

Descartado para la demo porque el servidor compartido solo guarda datos sintéticos en la red local:

- **TLS hacia PostgreSQL.** El cliente ya lo soporta (`TIRELUS_DB_SSL=require|verify`, `tests_py/test_db_tls.py`); el servidor responde `ssl = off`. Requiere certificado, `ssl = on` y regla `hostssl` en `pg_hba.conf`.
- **Rotar la contraseña** de `tirelus_equipo`, que se compartió por chat. Sin datos reales no es un riesgo; conviene hacerlo de todos modos si el servidor sigue encendido después del hackathon.
- **PostgreSQL interno de la nave.** Es el concepto de la versión final: una base local a bordo, sin depender de Internet ni del retraso de comunicación con la Tierra. El código ya funciona igual contra un servidor externo o interno cambiando solo las variables `TIRELUS_DB_*`; falta documentar el despliegue.

## 5. Otros pendientes de largo plazo

- **Android:** empaquetar con `-p Android`, decidir cómo llega el Python embebido a la base y si hay caché local sin conexión.
- **Empaquetado con serious_python:** retomado el 15 nov para la versión repartible. La simulación embebida ya está hecha y probada; faltan los binarios, que necesitan una máquina Windows (con Visual Studio) y una Mac. Pasos en [`EMPAQUETADO.md`](EMPAQUETADO.md).
- **Docker:** descartado el 14 nov; los archivos siguen en el repo sin probar.
- **Capa de juego y escalamiento:** las tablas `alerts`, `tasks`, `badges`, `astronaut_badges` y `point_events` existen y están vacías; la app todavía no las escribe.
