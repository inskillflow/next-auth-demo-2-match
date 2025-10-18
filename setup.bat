@echo off
echo ==================================
echo   Configuration de Next Match
echo ==================================
echo.

REM Vérifier si le fichier .env existe
if not exist ".env" (
    echo [ERREUR] Le fichier .env n'existe pas !
    echo Veuillez créer un fichier .env à la racine du projet.
    echo Voir GUIDE_DEMARRAGE.md pour les instructions.
    pause
    exit /b 1
)

echo [1/4] Génération du client Prisma...
call npx prisma generate
if errorlevel 1 (
    echo [ERREUR] Échec de la génération du client Prisma
    pause
    exit /b 1
)

echo [2/4] Application des migrations de base de données...
call npx prisma migrate deploy
if errorlevel 1 (
    echo [ERREUR] Échec des migrations. Vérifiez que PostgreSQL est démarré.
    echo Pour démarrer PostgreSQL avec Docker : docker compose up -d
    pause
    exit /b 1
)

echo [3/4] Peuplement de la base de données (seed)...
call npx prisma db seed
if errorlevel 1 (
    echo [AVERTISSEMENT] Le seed a échoué, mais ce n'est pas critique.
)

echo [4/4] Installation/vérification des dépendances...
call npm install

echo.
echo ==================================
echo   Configuration terminée !
echo ==================================
echo.
echo Pour démarrer le projet en mode développement :
echo   npm run dev
echo.
echo Pour construire et démarrer en production :
echo   npm run build
echo   npm start
echo.
pause

