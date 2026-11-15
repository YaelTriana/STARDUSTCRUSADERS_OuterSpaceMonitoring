-- TIRELUS · datos de ejemplo de la app (sinteticos). Correr despues de schema.sql y 002_ojos.sql.
--   psql -U postgres -d tirelus -f db/003_demo.sql
-- Re-ejecutable: usa ids fijos y ON CONFLICT DO NOTHING.
--
-- Solo trae lo que ya existe en app/python_app/data.py (presion sistolica D34-D47 y su linea base
-- 110-126 mmHg). Los datos de FC, sueno, animo y SANS (los ">>> DATOS:" de data.py) se agregan
-- aqui cuando la persona de contenido cientifico los entregue. Nada de esto es dato clinico real.

BEGIN;

INSERT INTO astronauts (id, name, role)
VALUES ('00000000-0000-4000-8000-000000000001', 'Tripulante A (Datos de ejemplo)', 'astronauta')
ON CONFLICT (id) DO NOTHING;

INSERT INTO baselines (astronaut_id, indicator_id, body_state, low, high)
VALUES ('00000000-0000-4000-8000-000000000001', 'systolic', 'reposo', 110, 126)
ON CONFLICT DO NOTHING;

-- 14 lecturas diarias de presion sistolica (mmHg). status queda NULL: lo escribe el motor de reglas.
INSERT INTO measurements (client_id, astronaut_id, indicator_id, body_state, value, measured_at,
                          mission_day, environment, note)
SELECT md5('tirelus-demo-systolic-' || t.d)::uuid,
       '00000000-0000-4000-8000-000000000001',
       'systolic', 'reposo', t.v,
       now() - make_interval(days => 47 - t.d),
       t.d, 'iss', 'Datos de ejemplo'
FROM unnest(
        ARRAY[118, 120, 117, 121, 119, 122, 124, 126, 125, 128, 130, 129, 131, 132],
        ARRAY[34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47]
     ) AS t(v, d)
ON CONFLICT (client_id) DO NOTHING;

COMMIT;
