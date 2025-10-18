# Script de configuration pour Next Match
# Ce script initialise le projet Next.js avec Prisma

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "  Configuration de Next Match" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier si le fichier .env existe
if (-Not (Test-Path ".env")) {
    Write-Host "[ERREUR] Le fichier .env n'existe pas !" -ForegroundColor Red
    Write-Host "Veuillez créer un fichier .env à la racine du projet." -ForegroundColor Yellow
    Write-Host "Voir les instructions dans le README." -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/4] Génération du client Prisma..." -ForegroundColor Green
npx prisma generate
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERREUR] Échec de la génération du client Prisma" -ForegroundColor Red
    exit 1
}

Write-Host "[2/4] Application des migrations de base de données..." -ForegroundColor Green
npx prisma migrate deploy
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERREUR] Échec des migrations. Vérifiez que PostgreSQL est démarré." -ForegroundColor Red
    Write-Host "Pour démarrer PostgreSQL avec Docker : docker compose up -d" -ForegroundColor Yellow
    exit 1
}

Write-Host "[3/4] Peuplement de la base de données (seed)..." -ForegroundColor Green
npx prisma db seed
if ($LASTEXITCODE -ne 0) {
    Write-Host "[AVERTISSEMENT] Le seed a échoué, mais ce n'est pas critique." -ForegroundColor Yellow
}

Write-Host "[4/4] Installation/vérification des dépendances..." -ForegroundColor Green
npm install

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "  Configuration terminée !" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pour démarrer le projet en mode développement :" -ForegroundColor Yellow
Write-Host "  npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "Pour construire et démarrer en production :" -ForegroundColor Yellow
Write-Host "  npm run build" -ForegroundColor White
Write-Host "  npm start" -ForegroundColor White
Write-Host ""

