$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$base = "http://localhost:8080"

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

Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "  DEMO RUBRICA - Biblioteca Web (API REST)" -ForegroundColor Magenta
Write-Host "=============================================" -ForegroundColor Magenta

# 0. Comprobar que la API responde
try {
    Invoke-RestMethod "$base/api/libros" | Out-Null
    Write-Host "Servidor activo en $base" -ForegroundColor Green
} catch {
    Write-Host "El servidor no responde. Ejecuta primero: go run main.go" -ForegroundColor Yellow
    exit 1
}

# 1. Crear usuario
Llamar "Servicio 1 - Crear usuario" POST "/api/usuarios" '{"nombre":"Angel Ramirez","email":"angel@gmail.com","fecha":""}'

# 2. Crear libro
Llamar "Servicio 2 - Crear libro" POST "/api/libros" '{"año":2026,"titulo":"Programacion en Go","autor":"Google","genero":"Tecnologia","formato":"PDF","tamanoMB":2.5}'

# 3. Listar libros
Llamar "Servicio 3 - Listar libros" GET "/api/libros" $null

# 4. Filtrar por genero
Llamar "Servicio 4 - Filtrar por genero" GET "/api/libros/genero/Tecnologia" $null

# 5. Prestar libro
Llamar "Servicio 5 - Prestar libro" POST "/api/prestamos" '{"titulo":"Programacion en Go","usuarioId":1,"fecha":""}'

# 6. Segundo prestamo -> 409 Conflict (error de negocio)
Llamar "Servicio 6 - Segundo prestamo (esperado: 409)" POST "/api/prestamos" '{"titulo":"Programacion en Go","usuarioId":1,"fecha":""}'

# 7. Historial del usuario
Llamar "Servicio 7 - Historial del usuario" GET "/api/usuarios/1/historial" $null

# 8. Devolver libro
Llamar "Servicio 8 - Devolver prestamo 1" POST "/api/prestamos/1/devolver" '{}'

# 9. Importacion concurrente (goroutines)
Llamar "Servicio 9 - Importar 3 libros (concurrencia)" POST "/api/libros/importar" '{"libros":[{"año":2025,"titulo":"Libro 1","autor":"Autor 1","genero":"Ficcion","formato":"PDF","tamanoMB":1.0},{"año":2025,"titulo":"Libro 2","autor":"Autor 2","genero":"Ciencia","formato":"EPUB","tamanoMB":2.0},{"año":2025,"titulo":"Libro 3","autor":"Autor 3","genero":"Historia","formato":"PDF","tamanoMB":3.0}]}'

Write-Host ""
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "  DEMO FINALIZADA" -ForegroundColor Magenta
Write-Host "=============================================" -ForegroundColor Magenta