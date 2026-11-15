import sqlite3
import re
import os

conn = sqlite3.connect(':memory:')
cur = conn.cursor()

cur.execute('''CREATE TABLE astronauts (
    id TEXT PRIMARY KEY, patient_id TEXT, mission_id TEXT, name TEXT,
    role TEXT, age INT, gender TEXT, sex TEXT, height_m REAL
)''')
cur.execute('''CREATE TABLE baselines (
    astronaut_id TEXT, indicator_id TEXT, body_state TEXT, low REAL, high REAL,
    PRIMARY KEY (astronaut_id, indicator_id, body_state)
)''')
cur.execute('''CREATE TABLE thresholds (
    indicator_id TEXT, body_state TEXT, environment TEXT, critico_low REAL, critico_high REAL
)''')
cur.execute('''CREATE TABLE measurements (
    client_id TEXT PRIMARY KEY, astronaut_id TEXT, indicator_id TEXT,
    body_state TEXT, value REAL, measured_at TEXT, mission_day INT, environment TEXT
)''')

with open('db/004_populate.sql', 'r', encoding='utf-8') as f:
    sql = f.read()

for stmt in sql.split(';\n'):
    stmt = stmt.strip()
    # remove leading comment lines
    lines = [l for l in stmt.splitlines() if not l.strip().startswith('--') and not l.strip().startswith('\\')]
    stmt = '\n'.join(lines).strip()
    if not stmt or stmt in ('BEGIN', 'COMMIT'):
        continue
    clean = re.sub(r'ON CONFLICT.*', '', stmt, flags=re.DOTALL).strip()
    clean = clean.replace('+00', '')
    if clean.startswith('INSERT INTO astronauts'):
        cur.execute(clean)
    elif clean.startswith('INSERT INTO baselines'):
        cur.execute(clean)
    elif clean.startswith('INSERT INTO measurements'):
        cur.execute(clean)

print('Astronauts in DB:', cur.execute('SELECT COUNT(*) FROM astronauts').fetchone()[0])
print('Baselines in DB:', cur.execute('SELECT COUNT(*) FROM baselines').fetchone()[0])
print('Measurements in DB:', cur.execute('SELECT COUNT(*) FROM measurements').fetchone()[0])

cur.execute('SELECT id, patient_id, name FROM astronauts ORDER BY id LIMIT 1')
row = cur.fetchone()
astro_id = row[0]
print(f'Selected astronaut: {row[1]} ({row[2]}), id={astro_id}')

cur.execute("SELECT indicator_id, low, high FROM baselines WHERE astronaut_id = ? AND body_state = 'reposo'", (astro_id,))
print('Baseline indicators for SC-00001:', [r[0] for r in cur.fetchall()])

cur.execute('''
SELECT indicator_id, value, mission_day FROM (
  SELECT indicator_id, value, mission_day, measured_at,
         row_number() OVER (PARTITION BY indicator_id ORDER BY measured_at DESC) AS rn
  FROM measurements
  WHERE astronaut_id = ? AND body_state = 'reposo'
) ultimas WHERE rn <= 14 ORDER BY indicator_id, measured_at
''', (astro_id,))
rows = cur.fetchall()
print(f'Latest 14 readings count for SC-00001: {len(rows)}')
by_ind = {}
for ind, val, day in rows:
    by_ind.setdefault(ind, []).append((day, val))
for ind, data in by_ind.items():
    print(f'  {ind}: {len(data)} readings, day range {data[0][0]}..{data[-1][0]}')
