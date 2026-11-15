# TIRELUS: corre PostgreSQL + API local con Docker. Solo ASCII a proposito (PowerShell 5.1).
#
#   .\tirelus.ps1              levanta base + API y verifica /health          (igual que: up)
#   .\tirelus.ps1 db           solo PostgreSQL (servidor compartido del equipo)
#   .\tirelus.ps1 db -Lan      PostgreSQL visible en la red local (puerto 5432)
#   .\tirelus.ps1 verificar    comprueba que la API lee de la base (data_source = db)
#   .\tirelus.ps1 datos        carga los datasets de referencia desde .\datosdb (opcional)
#   .\tirelus.ps1 logs         sigue los registros
#   .\tirelus.ps1 estado       muestra contenedores
#   .\tirelus.ps1 down         detiene todo (conserva los datos)
#   .\tirelus.ps1 reset        detiene y BORRA los datos de la base (vuelve a cargar los .sql)
#
# La app Flutter no va en Docker:  cd app; flutter run -d windows --dart-define=TIRELUS_DEV_SERVER=true

param(
    [ValidateSet('up', 'db', 'verificar', 'datos', 'logs', 'estado', 'down', 'reset')]
    [string]$Comando = 'up',
    [switch]$Lan
)

# 'Continue' a proposito: docker escribe avances en stderr y en PowerShell 5.1 'Stop' lo trata como error.
# Los fallos se detectan con $LASTEXITCODE.
$ErrorActionPreference = 'Continue'
Set-Location $PSScriptRoot

function Fallar($msg) { Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { Fallar 'Docker no esta instalado o no esta en el PATH.' }
docker info *> $null
if ($LASTEXITCODE -ne 0) { Fallar 'Docker no esta corriendo. Abre Docker Desktop, espera a que diga "Engine running" y vuelve a intentar.' }

# .env con contrasena aleatoria, solo la primera vez. Nunca se sube al repo.
function Leer-Env($clave, $defecto) {
    if (Test-Path .env) {
        $linea = Get-Content .env | Where-Object { $_ -match "^\s*$clave\s*=" } | Select-Object -First 1
        if ($linea) { return ($linea -split '=', 2)[1].Trim() }
    }
    return $defecto
}

if (-not (Test-Path .env)) {
    $chars = [char[]]'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    $pass = -join (1..24 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    (Get-Content .env.example) -replace '^TIRELUS_DB_PASSWORD=.*', "TIRELUS_DB_PASSWORD=$pass" | Set-Content .env -Encoding ascii
    Write-Host 'Se creo .env con una contrasena nueva (no se sube al repo).' -ForegroundColor Yellow
}

$usuario = Leer-Env 'TIRELUS_DB_USER' 'postgres'
$base = Leer-Env 'TIRELUS_DB_NAME' 'tirelus'
$puertoApi = Leer-Env 'TIRELUS_API_PORT' '8765'
$apiUrl = "http://127.0.0.1:$puertoApi"

function Verificar-Api {
    try {
        $h = Invoke-RestMethod "$apiUrl/health" -TimeoutSec 5
    } catch {
        Fallar "La API no responde en $apiUrl. Usa .\tirelus.ps1 logs para ver el motivo."
    }
    Write-Host "API: ok=$($h.ok)  data_source=$($h.data_source)" -ForegroundColor Cyan
    if ($h.data_source -ne 'db') {
        $motivo = if ($h.db_error) { " (error: $($h.db_error))" } else { '' }
        Fallar "La API esta usando datos de ejemplo de data.py, no la base$motivo."
    }
    $t = Invoke-RestMethod "$apiUrl/trend/systolic" -TimeoutSec 5
    Write-Host "Presion sistolica: $($t.series.Count) lecturas, estado = $($t.status)" -ForegroundColor Cyan
    Write-Host 'La API esta leyendo de PostgreSQL.' -ForegroundColor Green
}

switch ($Comando) {
    'up' {
        docker compose up -d --build --wait
        if ($LASTEXITCODE -ne 0) { Fallar 'No se pudo levantar. Revisa: .\tirelus.ps1 logs' }
        Verificar-Api
        Write-Host "Listo. API en $apiUrl  (docs: $apiUrl/docs)" -ForegroundColor Green
        Write-Host 'UI: cd app; flutter run -d windows --dart-define=TIRELUS_DEV_SERVER=true'
    }
    'db' {
        if ($Lan) { $env:TIRELUS_DB_BIND = '0.0.0.0' }
        docker compose up -d --wait db
        if ($LASTEXITCODE -ne 0) { Fallar 'No se pudo levantar la base. Revisa: .\tirelus.ps1 logs' }
        $puerto = Leer-Env 'TIRELUS_DB_PUBLISH_PORT' '5432'
        Write-Host "PostgreSQL arriba en el puerto $puerto." -ForegroundColor Green
        if ($Lan) {
            $ips = Get-NetIPAddress -AddressFamily IPv4 |
                Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
                Select-Object -ExpandProperty IPAddress
            Write-Host "Equipo del equipo: TIRELUS_DB_HOST = $($ips -join ' o ')" -ForegroundColor Cyan
            Write-Host "Si no conecta, abre el puerto $puerto en el Firewall de Windows (solo red privada)."
            Write-Host "Usuario: $usuario   Base: $base   Contrasena: ver TIRELUS_DB_PASSWORD en .env (compartela por un canal privado)."
        }
    }
    'verificar' { Verificar-Api }
    'datos' {
        if (-not (Test-Path datosdb)) { Fallar 'No existe .\datosdb (los datasets no estan en el repo; pidelos al equipo).' }
        docker compose cp ./datosdb db:/carga/datosdb
        if ($LASTEXITCODE -ne 0) { Fallar 'No se pudo copiar datosdb al contenedor (levanta la base primero).' }
        docker compose exec -w /carga db psql -U $usuario -d $base -f load_datos.sql
    }
    'logs' { docker compose logs -f --tail 100 }
    'estado' { docker compose ps }
    'down' { docker compose down }
    'reset' {
        Write-Host 'Esto borra los datos de la base de este equipo.' -ForegroundColor Yellow
        docker compose down -v
    }
}
