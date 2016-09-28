@echo off
setlocal enableextensions

if /i "%1"=="/nocheckadmin" goto start
whoami /all /nh |find "SeCreateSymbolicLinkPrivilege" >nul 2>nul
if errorlevel 1 (
	elevate -c -w "%~f0" /nocheckadmin
	goto :eof
)

:start

set BOOST_DIR=%~dp0
set PACKAGES_REL=..\packages

cd /d "%BOOST_DIR%"

call :findlibs

echo Librer¡as encontradas:
for /f "usebackq delims=[]= tokens=2*" %%a in (`set bs_version[`) do (
	echo %%a	%%b
)
echo.

if not defined bs_version[boost] (
	echo No se ha encontrado la librer¡a boost.
	echo Instalando...
	pushd "%BOOST_DIR%\%PACKAGES_REL%"
	nuget install boost
	popd
	call :findlibs
	echo Instalada librer¡a boost versi¢n %bs_version[boost]%
)

echo Limpiando...
rmdir boost >nul 2>nul
rd /s /q lib32 >nul 2>nul
rd /s /q lib64 >nul 2>nul

echo Generando enlaces...
if not exist "%bs_path[boost]%\lib\native\include\boost\" (
	echo Error: no se encuentra "%bs_path[boost]%\lib\native\include\boost\"
	exit /b 1
)
call :makelink /d boost "%bs_path[boost]%\lib\native\include\boost"
mkdir lib32 >nul 2>nul
mkdir lib64 >nul 2>nul
for /f "usebackq delims=[]= tokens=2*" %%a in (`set bs_path[`) do (
	if exist "%%~b\lib\native\address-model-32\lib\*" (
		for %%c in ("%%~b\lib\native\address-model-32\lib\*") do (
			call :makelink "lib32\%%~nxc" "..\%%~c"
		)
	)
	if exist "%%~b\lib\native\address-model-64\lib\*" (
		for %%c in ("%%~b\lib\native\address-model-64\lib\*") do (
			call :makelink "lib64\%%~nxc" "..\%%~c"
		)
	)
)
echo ­Hecho!
goto :eof

:findlibs
::Encontramos todas las librer¡as de Boost y sus £ltimas versiones
for /f "usebackq delims=. tokens=1*" %%a in (`dir /b /a:d "%BOOST_DIR%\%PACKAGES_REL%\boost*" ^|sort`) do (
	set bs_version[%%a]=%%b
	set bs_path[%%a]=%PACKAGES_REL%\%%a.%%b
)
goto :eof

:makelink
setlocal
set _opts=
:_loop
set _1=%~1
if "%_1:~,1%"=="/" (
	if defined _opts (
		set _opts=%_opts% %1
	) else (
		set _opts=%1
	)
	shift
	goto :_loop
)
echo. .\%~1
mklink %_opts% "%~1" "%~2" >nul
endlocal
goto :eof

