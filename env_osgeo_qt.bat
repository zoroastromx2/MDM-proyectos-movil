@echo off
setlocal enabledelayedexpansion

echo === Entorno limpio OSGeo4W + Qt ===
set OSGEO4W_ROOT=E:\OSGeo4w
set QGIS_PREFIX_PATH=%OSGEO4W_ROOT%\apps\qgis
set QGIS_PLUGINPATH=%QGIS_PREFIX_PATH%\plugins
set GDAL_DATA=%OSGEO4W_ROOT%\share\gdal
set PROJ_LIB=%OSGEO4W_ROOT%\share\proj
set QT_PLUGIN_PATH=D:\QtWin\6.8.3\msvc2022_64\plugins

REM PATH MINIMO (sin %%PATH%% para evitar mezcla con Python/JDK/etc.)
set PATH=%QGIS_PREFIX_PATH%\bin;%OSGEO4W_ROOT%\bin;D:\QtWin\6.8.3\msvc2022_64\bin;C:\Windows\System32;C:\Windows

echo.
echo === Variables clave ===
echo OSGEO4W_ROOT=%OSGEO4W_ROOT%
echo QGIS_PREFIX_PATH=%QGIS_PREFIX_PATH%
echo QGIS_PLUGINPATH=%QGIS_PLUGINPATH%
echo GDAL_DATA=%GDAL_DATA%
echo PROJ_LIB=%PROJ_LIB%
echo QT_PLUGIN_PATH=%QT_PLUGIN_PATH%
echo PATH=%PATH%

echo.
echo === Verificacion de DLLs clave ===
where qgis_core.dll
if errorlevel 1 echo [FALTA] qgis_core.dll

where qgis_gui.dll
if errorlevel 1 echo [FALTA] qgis_gui.dll

where gdal*.dll
if errorlevel 1 echo [FALTA] gdal*.dll

where geos_c.dll
if errorlevel 1 echo [FALTA] geos_c.dll

where proj*.dll
if errorlevel 1 echo [FALTA] proj*.dll

where SFCGAL.dll
if errorlevel 1 echo [FALTA] SFCGAL.dll

where Qt6Core.dll
if errorlevel 1 echo [FALTA] Qt6Core.dll

where Qt6Gui.dll
if errorlevel 1 echo [FALTA] Qt6Gui.dll

where Qt6Qml.dll
if errorlevel 1 echo [FALTA] Qt6Qml.dll

where Qt6Quick.dll
if errorlevel 1 echo [FALTA] Qt6Quick.dll

where vcruntime140.dll
if errorlevel 1 echo [FALTA] vcruntime140.dll

where vcruntime140_1.dll
if errorlevel 1 echo [FALTA] vcruntime140_1.dll

where msvcp140.dll
if errorlevel 1 echo [FALTA] msvcp140.dll

echo.
echo === Ejecutar (D=Debug, R=Release) ===
set /p MODE=Modo [D/R]: 

if /I "%MODE%"=="D" (
    set APP=E:\OSGeo4w\MDM-proyectos-movil\build\Desktop_Qt_6_8_3_MSVC2022_64bit\Debug\MDMProyectosMovil.exe
) else (
    set APP=E:\OSGeo4w\MDM-proyectos-movil\build\Desktop_Qt_6_8_3_MSVC2022_64bit\Release\MDMProyectosMovil.exe
)

echo.
echo APP=%APP%
if not exist "%APP%" (
    echo [ERROR] No existe el ejecutable.
    echo Revisa la ruta/kit de compilacion.
    pause
    exit /b 1
)

echo.
echo === Lanzando app ===
"%APP%"
set EC=%ERRORLEVEL%
echo.
echo ExitCode=%EC%

if "%EC%"=="-1073741515" (
    echo [DIAGNOSTICO] 0xC0000135: falta una DLL en tiempo de ejecucion.
)

pause
endlocal