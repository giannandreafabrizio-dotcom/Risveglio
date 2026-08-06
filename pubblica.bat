@echo off
cd /d "%~dp0"
title RISVEGLIO - pubblica
echo.
echo  ===========================================
echo     RISVEGLIO  -  pubblicazione
echo  ===========================================
echo.

if not exist index.html goto noindex

set "VER="
for /f tokens^=2^ delims^=^" %%A in ('findstr /b /c:"const APP_VERSION" index.html') do set "VER=%%A"
if not defined VER goto nover

echo  Versione trovata in index.html : %VER%
>versione.txt echo %VER%
echo  versione.txt aggiornato.
echo.

git add -A
git diff --cached --quiet
if not errorlevel 1 goto nulla

git commit -m "v%VER% pubblicata"
if errorlevel 1 goto errore

git push
if errorlevel 1 goto errore

echo.
echo  -------------------------------------------
echo   FATTO.
echo   Tra circa 30 secondi l'app online sara'
echo   alla versione %VER%.
echo   Apri l'icona sull'iPhone: si aggiorna da sola.
echo  -------------------------------------------
goto fine

:noindex
echo  ERRORE: index.html non e' in questa cartella.
echo  Il file pubblica.bat deve stare dentro Desktop\Routine.
goto fine

:nover
echo  ERRORE: non trovo la riga APP_VERSION dentro index.html.
goto fine

:nulla
echo  Non c'e' niente di nuovo da pubblicare: e' gia' tutto online.
goto fine

:errore
echo.
echo  ERRORE durante commit o push.
echo  Controlla la connessione a internet e le credenziali GitHub.
goto fine

:fine
echo.
pause
