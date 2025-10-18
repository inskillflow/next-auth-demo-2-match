@echo off
echo ==================================
echo   Démarrage rapide - Mode DEV
echo ==================================
echo.

REM Vérifier si .env existe
if not exist ".env" (
    echo [ERREUR] Fichier .env manquant !
    echo.
    echo Créez un fichier .env en copiant ENV_TEMPLATE.txt
    echo Voir GUIDE_DEMARRAGE.md pour les instructions complètes.
    echo.
    pause
    exit /b 1
)

echo Démarrage du serveur de développement...
echo Ouvrez http://localhost:3000 dans votre navigateur
echo.
echo Appuyez sur Ctrl+C pour arrêter le serveur
echo.

call npm run dev

