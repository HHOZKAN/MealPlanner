@echo off
setlocal EnableDelayedExpansion

:: Couleurs pour Windows
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "NC=[0m"

:: Fonction pour afficher les messages
:log
echo %GREEN%[GIT]%NC% %~1
goto :eof

:error
echo %RED%[ERROR]%NC% %~1
goto :eof

:warning
echo %YELLOW%[WARNING]%NC% %~1
goto :eof

:: Vérifier s'il y a des modifications
git status --porcelain > temp.txt
set /p CHANGES=<temp.txt
del temp.txt
if "!CHANGES!"=="" (
    call :warning "Aucune modification detectee."
    exit /b 0
)

:: Afficher le status actuel
call :log "Status actuel des fichiers :"
git status

:: Demander confirmation pour continuer
set /p "choice=%YELLOW%Voulez-vous continuer ? (y/n) %NC%"
if /i "!choice!" neq "y" (
    exit /b 0
)

:: Ajouter tous les fichiers
call :log "Ajout des fichiers modifies et non suivis..."
git add -A

:: Demander le message de commit
set /p "commit_message=%GREEN%Message de commit : %NC%"

:: Vérifier si le message de commit n'est pas vide
if "!commit_message!"=="" (
    call :error "Le message de commit ne peut pas etre vide"
    exit /b 1
)

:: Faire le commit
call :log "Creation du commit..."
git commit -m "!commit_message!"

:: Vérifier les remotes
call :log "Liste des remotes configurees :"
git remote -v

:: Push vers GitHub
call :log "Push vers GitHub..."
git push github
if !errorlevel! equ 0 (
    call :log "Push vers GitHub reussi ✓"
) else (
    call :error "Erreur lors du push vers GitHub ×"
)

:: Push vers GitLab
call :log "Push vers GitLab..."
git push gitlab
if !errorlevel! equ 0 (
    call :log "Push vers GitLab reussi ✓"
) else (
    call :error "Erreur lors du push vers GitLab ×"
)

call :log "Operation terminee avec succes!"

:: Afficher le dernier status
git status

endlocal