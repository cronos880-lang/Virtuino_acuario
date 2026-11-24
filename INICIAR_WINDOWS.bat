@echo off
setlocal
cd /d "%~dp0"
rem Acuaris V0.5.1 - lanzador para Windows (codigo fuente + motor Godot portatil)
rem Uso: INICIAR_WINDOWS.bat            -> editor
rem      INICIAR_WINDOWS.bat app        -> app del movil en el PC (simulador)
rem      INICIAR_WINDOWS.bat consola    -> editor mostrando mensajes de error
set "MODO=%~1"
set "VERSION_GODOT=4.7.2"
set "MOTOR=%~dp0motor"
set "GODOT=%MOTOR%\Godot_v4.7.2-stable_win64.exe"
set "GODOT_CONSOLA=%MOTOR%\Godot_v4.7.2-stable_win64_console.exe"
set "URL=https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip"

if exist "%GODOT%" goto PREPARAR
echo.
echo Acuaris funciona con el motor Godot %VERSION_GODOT% - gratuito, licencia MIT.
echo No esta en la carpeta "motor". Se descarga de la web oficial de Godot
echo en GitHub, unos 82 MB, y se guarda SOLO en esta carpeta: no se instala
echo nada en Windows. Para quitarlo basta con borrar la carpeta.
echo.
choice /C SN /N /M "Descargar Godot %VERSION_GODOT% ahora? [S/N]: "
if errorlevel 2 exit /b 1
if not exist "%MOTOR%" mkdir "%MOTOR%"
echo Descargando Godot %VERSION_GODOT%...
curl -L --fail -o "%MOTOR%\godot.zip" "%URL%"
if errorlevel 1 goto ERROR_DESCARGA
tar -xf "%MOTOR%\godot.zip" -C "%MOTOR%"
if errorlevel 1 goto ERROR_DESCARGA
del "%MOTOR%\godot.zip"
rem Modo autocontenido de Godot: sus datos se quedan dentro de "motor"
type nul > "%MOTOR%\_sc_"

:PREPARAR
if exist "%~dp0acuaris\.godot\global_script_class_cache.cfg" goto LANZAR
echo Preparando Acuaris por primera vez, unos segundos...
"%GODOT_CONSOLA%" --headless --path "%~dp0acuaris" --import >nul 2>nul

:LANZAR
if /I "%MODO%"=="consola" (
    "%GODOT_CONSOLA%" --path "%~dp0acuaris"
    pause
    exit /b 0
)
if /I "%MODO%"=="app" (
    start "" "%GODOT%" --path "%~dp0acuaris" -- --app
    exit /b 0
)
start "" "%GODOT%" --path "%~dp0acuaris"
exit /b 0

:ERROR_DESCARGA
echo.
echo No se pudo descargar o descomprimir Godot. Revisa la conexion a Internet.
echo Tambien puedes descargar a mano Godot_v4.7.2-stable_win64.exe.zip de
echo https://godotengine.org y descomprimirlo dentro de la carpeta "motor".
pause
exit /b 1
