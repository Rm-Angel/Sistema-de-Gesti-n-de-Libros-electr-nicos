$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$base = "http://localhost:8080"
$servidorArrancado = $false

function NombreStatus($code) {
    switch ($code) {
        200 { "200 OK" }
        201 { "201 Created" }
        400 { "400 Bad Request" }
        404 { "404 Not Found" }
        409 { "409 Conflict" }
        500 { "500 Internal Server Error" }
        default { "$code" }
    }
}

function Llamar($nombre, $method, $uri, $body) {
    Write-Host ""
    Write-Host ("=== " + $nombre + " ===") -ForegroundColor Cyan
    $temp = New-TemporaryFile
    $bodyFile = $null
    try {
        $args = @("-s", "-o", $temp.FullName, "-w", "%{http_code}", "-X", $method, "-H", "Content-Type: application/json")
        if ($body -ne $null) {
            $bodyFile = New-TemporaryFile
            [System.IO.File]::WriteAllText($bodyFile.FullName, $body, [System.Text.UTF8Encoding]::new($false))
            $args += @("--data-binary", "@$($bodyFile.FullName)")
        }
        $code = & curl.exe @args "$base$uri"
        $code = [int]($code | Out-String).Trim()
        $contenido = Get-Content -LiteralPath $temp.FullName -Raw
        if ([string]::IsNullOrWhiteSpace($contenido)) { $contenido = "" }

        $color = "Green"
        if ($code -ge 400 -and $code -ne 409) { $color = "Red" }
        elseif ($code -ge 400) { $color = "Yellow" }

        Write-Host ("Status: " + (NombreStatus $code)) -ForegroundColor $color
        if ($contenido -ne "") {
            try { $contenido | ConvertFrom-Json | ConvertTo-Json -Depth 5 } catch { $contenido }
        }
    } finally {
        Remove-Item -LiteralPath $temp.FullName -Force -ErrorAction SilentlyContinue
        if ($bodyFile) { Remove-Item -LiteralPath $bodyFile.FullName -Force -ErrorAction SilentlyContinue }
    }
}

function ServidorActivo {
    try { Invoke-RestMethod "$base/api/libros" | Out-Null; return $true } catch { return $false }
}

# 1. Arrancar el servidor si no está activo
if (-not (ServidorActivo)) {
    Write-Host "Arrancando servidor..." -ForegroundColor Yellow
    $proc = Start-Process -FilePath "go" -ArgumentList "run","main.go" -WorkingDirectory $PWD -PassThru -WindowStyle Hidden
    $servidorArrancado = $true
    $intentos = 0
    while (-not (ServidorActivo) -and $intentos -lt 20) {
        Start-Sleep -Milliseconds 500
        $intentos++
    }
    if (-not (ServidorActivo)) {
        Write-Host "No se pudo arrancar el servidor. Revisa si el puerto 8080 esta ocupado." -ForegroundColor Red
        exit 1
    }
    Write-Host "Servidor activo en $base" -ForegroundColor Green
} else {
    Write-Host "Ya hay un servidor activo en $base (lo usare)" -ForegroundColor Green
}

function MostrarMenu {
    Clear-Host
    Write-Host "=============================================" -ForegroundColor Magenta
    Write-Host "  MENU DEMO - Biblioteca Web (API REST)" -ForegroundColor Magenta
    Write-Host "=============================================" -ForegroundColor Magenta
    Write-Host "  1. Crear usuario" -ForegroundColor White
    Write-Host "  2. Crear libro" -ForegroundColor White
    Write-Host "  3. Listar libros" -ForegroundColor White
    Write-Host "  4. Filtrar por genero" -ForegroundColor White
    Write-Host "  5. Prestar libro" -ForegroundColor White
    Write-Host "  6. Segundo prestamo (409)" -ForegroundColor White
    Write-Host "  7. Historial del usuario" -ForegroundColor White
    Write-Host "  8. Devolver libro" -ForegroundColor White
    Write-Host "  9. Importar 3 libros (concurrencia)" -ForegroundColor White
    Write-Host "  t. Ejecutar pruebas (go test ./... -v -race)" -ForegroundColor White
    Write-Host "  0. Salir" -ForegroundColor White
    Write-Host "=============================================" -ForegroundColor Magenta
    Write-Host ""
}

try {
    do {
        MostrarMenu
        $opcion = Read-Host "Elige una opcion"
        switch ($opcion) {
            "1" { Llamar "Crear usuario" POST "/api/usuarios" '{"nombre":"Angel Ramirez","email":"angel@gmail.com","fecha":""}' }
            "2" { Llamar "Crear libro" POST "/api/libros" '{"año":2026,"titulo":"Programacion en Go","autor":"Google","genero":"Tecnologia","formato":"PDF","tamanoMB":2.5}' }
            "3" { Llamar "Listar libros" GET "/api/libros" $null }
            "4" { Llamar "Filtrar por genero" GET "/api/libros/genero/Tecnologia" $null }
            "5" { Llamar "Prestar libro" POST "/api/prestamos" '{"titulo":"Programacion en Go","usuarioId":1,"fecha":""}' }
            "6" { Llamar "Segundo prestamo (esperado: 409)" POST "/api/prestamos" '{"titulo":"Programacion en Go","usuarioId":1,"fecha":""}' }
            "7" { Llamar "Historial del usuario 1" GET "/api/usuarios/1/historial" $null }
            "8" { Llamar "Devolver prestamo 1" POST "/api/prestamos/1/devolver" '{}' }
            "9" { Llamar "Importar 3 libros (concurrencia)" POST "/api/libros/importar" '{"libros":[{"año":2025,"titulo":"Libro 1","autor":"Autor 1","genero":"Ficcion","formato":"PDF","tamanoMB":1.0},{"año":2025,"titulo":"Libro 2","autor":"Autor 2","genero":"Ciencia","formato":"EPUB","tamanoMB":2.0},{"año":2025,"titulo":"Libro 3","autor":"Autor 3","genero":"Historia","formato":"PDF","tamanoMB":3.0}]}' }
            "t" {
                Write-Host ""
                Write-Host "=== Ejecutando pruebas ===" -ForegroundColor Cyan
                go test ./... -v -race
            }
            "0" { Write-Host "Adios!" -ForegroundColor Magenta; break }
            default { Write-Host "Opcion invalida" -ForegroundColor Red }
        }
        if ($opcion -ne "0") {
            Write-Host ""
            Read-Host "Presiona Enter para volver al menu"
        }
    } while ($opcion -ne "0")
} finally {
    if ($servidorArrancado) {
        Write-Host "Deteniendo servidor..." -ForegroundColor Yellow
        Stop-Process -Name main -Force -ErrorAction SilentlyContinue
    }
}