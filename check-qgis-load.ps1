$ErrorActionPreference = "Stop"

# --- Rutas ---
$OSGEO4W_ROOT = "E:\OSGeo4w"
$QT_ROOT      = "D:\QtWin\6.8.3\msvc2022_64"

$qgisCore = Join-Path $OSGEO4W_ROOT "apps\qgis\bin\qgis_core.dll"
$qgisGui  = Join-Path $OSGEO4W_ROOT "apps\qgis\bin\qgis_gui.dll"

# --- Entorno limpio ---
$env:QGIS_PREFIX_PATH = "$OSGEO4W_ROOT\apps\qgis"
$env:QGIS_PLUGINPATH  = "$OSGEO4W_ROOT\apps\qgis\plugins"
$env:GDAL_DATA        = "$OSGEO4W_ROOT\share\gdal"
$env:PROJ_LIB         = "$OSGEO4W_ROOT\share\proj"
$env:QT_PLUGIN_PATH   = "$QT_ROOT\plugins"
$env:PATH             = "$OSGEO4W_ROOT\apps\qgis\bin;$OSGEO4W_ROOT\bin;$QT_ROOT\bin;C:\Windows\System32;C:\Windows"

Write-Host "=== Entorno ==="
Write-Host "PATH=$($env:PATH)"
Write-Host "QGIS_PREFIX_PATH=$($env:QGIS_PREFIX_PATH)"
Write-Host ""

# --- WinAPI LoadLibrary ---
Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
    [System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError=true, CharSet=System.Runtime.InteropServices.CharSet.Unicode)]
    public static extern System.IntPtr LoadLibrary(string lpFileName);

    [System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool FreeLibrary(System.IntPtr hModule);
"@

function Test-LoadLibrary($dllPath) {
    Write-Host "Probando LoadLibrary: $dllPath"
    if (-not (Test-Path $dllPath)) {
        Write-Host "  [NO EXISTE] $dllPath" -ForegroundColor Red
        return
    }

    $h = [Win32.NativeMethods]::LoadLibrary($dllPath)
    if ($h -eq [IntPtr]::Zero) {
        $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        $ex  = New-Object ComponentModel.Win32Exception($err)
        Write-Host "  [FALLO] Win32Error=$err -> $($ex.Message)" -ForegroundColor Red
    } else {
        Write-Host "  [OK] Cargó correctamente" -ForegroundColor Green
        [void][Win32.NativeMethods]::FreeLibrary($h)
    }
}

Write-Host "=== Pruebas ==="
Test-LoadLibrary $qgisCore
Test-LoadLibrary $qgisGui

Write-Host ""
Write-Host "=== Extra: localizar SFCGAL.dll ==="
try {
    & where.exe SFCGAL.dll
} catch {
    Write-Host "  [FALTA] SFCGAL.dll (where no encontró resultados)" -ForegroundColor Yellow
}