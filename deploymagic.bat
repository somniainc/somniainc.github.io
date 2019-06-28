@echo off
setlocal enableDelayedExpansion enableextensions

REM Set global variables here
SET _APP=%1
SET _PASS=%2
SET _DEPLOYURL=http://softdeploy.somniainc.com

cd /D "%~dp0"
set _CURPATH=%~dp0
Echo Pre-flight checks.  Ensuring pre-requisites are met.
Echo(

rem check for admin rights
net session 1> nul 2> nul
if not errorlevel 1 goto asadmin
echo Check for Administrator rights.     FAIL.
echo Please run this script as an administrator
exit /b
:asadmin
echo Check for Administrator rights.     PASS.
rem this is the check to see if powershell is installed
for %%i in (powershell.exe) do if "%%~$path:i"=="" (echo Check for Powershell.               FAIL. && echo Please ensure powershell is installed on this system. && exit /b) else echo Check for Powershell.               PASS.
rem Check .net framework version (4.5 minimum required)

set KEY_NAME="HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
set VALUE_NAME=Release

reg query %KEY_NAME% /v %VALUE_NAME% 1> nul 2> nul
if errorlevel 1 goto netisbad
FOR /F "usebackq tokens=3*" %%A IN (`REG QUERY %KEY_NAME% /v %VALUE_NAME%`) DO (
    set /a netver=%%A %%B
    )
if not %netver% LSS 378389 goto netisgood

:netisbad

echo Check for .Net 4.5                  FAIL.
echo Please ensure you have the 4.5 version or higher of the .Net framework installed.
exit /b

:netisgood
echo Check for .Net 4.5                  PASS.

rem DOWNLOAD WGET.EXE BECAUSE THE .NET DOWNLOADER SUCKS!!  This is like using IE to download Chrome. :D
echo(
Echo Downloading WGET [Using .NET]
powershell -ExecutionPolicy unrestricted -command "(New-Object Net.WebClient).DownloadFile(\"%_DEPLOYURL%/bootstrap/wget.exe\", \"wget.exe\")"

rem DOWNLOAD 7zip command line
Echo Downloading 7zip
wget --no-check-certificate -q "%_DEPLOYURL%/bootstrap/7za.exe" -O 7za.exe
wget --no-check-certificate "%_DEPLOYURL%/z/%_APP%.exe" -O %_APP%.exe
7za x %_APP%.exe -aoa -p%_PASS%

for /f "delims=" %%a in (%_APP%\execute) DO call %%a

echo Cleaning up...
rd /s /q %_APP%
del %_APP%.exe
del 7za.exe
del wget.exe
