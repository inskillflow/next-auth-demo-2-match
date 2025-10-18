# Dépannage et Problèmes Courants

## Erreurs fréquentes et solutions

### 1. "Could not find a production build"

**Erreur complète :**
```
Error: Could not find a production build in the '.next' directory.
Try building your app with 'next build' before starting the production server.
```

**Cause :**
Vous essayez d'utiliser `npm start` (production) sans avoir construit l'application.

**Solutions :**

#### Option A : Mode développement (recommandé)
```powershell
npm run dev
```

#### Option B : Mode production
```powershell
npm run build
npm start
```

---

### 2. "Can't reach database server"

**Erreur complète :**
```
Error: P1001: Can't reach database server at localhost:5432
```

**Cause :**
PostgreSQL n'est pas démarré ou n'est pas accessible.

**Solutions :**

#### Avec Docker
```powershell
# Vérifier si Docker est en cours d'exécution
docker ps

# Démarrer PostgreSQL
docker compose up -d

# Voir les logs
docker compose logs -f postgres
```

#### Avec installation locale
```powershell
# Vérifier le service PostgreSQL (Windows)
Get-Service -Name postgresql*

# Démarrer le service
Start-Service postgresql-x64-14  # Adaptez le nom
```

#### Vérifier la connexion
```powershell
# Tester avec psql
psql -h localhost -U postgres -p 5432

# Ou avec Prisma
npx prisma db pull
```

---

### 3. "AUTH_SECRET is not set"

**Erreur :**
```
Error: AUTH_SECRET environment variable is not set
```

**Cause :**
La variable d'environnement `AUTH_SECRET` est manquante dans `.env`.

**Solution :**

```powershell
# 1. Générer une clé secrète
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"

# 2. Ajouter dans .env
AUTH_SECRET="la-cle-generee"
```

---

### 4. "Prisma Client not generated"

**Erreur :**
```
Error: @prisma/client did not initialize yet.
```

**Cause :**
Le client Prisma n'a pas été généré.

**Solution :**
```powershell
npx prisma generate
```

---

### 5. "Migration failed"

**Erreur :**
```
Error: P3005: The database schema is not empty
```

**Cause :**
La base de données existe déjà avec un schéma différent.

**Solutions :**

#### Option A : Reset complet ( Supprime les données)
```powershell
npx prisma migrate reset
```

#### Option B : Force push ( Danger)
```powershell
npx prisma db push --force-reset
```

#### Option C : Nouvelle base de données
Modifiez `DATABASE_URL` dans `.env` avec un nouveau nom de BDD :
```env
DATABASE_URL="postgresql://postgres:postgrespw@localhost:5432/nextmatch_new"
```

---

### 6. "Port 3000 already in use"

**Erreur :**
```
Error: Port 3000 is already in use
```

**Cause :**
Un autre processus utilise le port 3000.

**Solutions :**

#### Option A : Tuer le processus
```powershell
# Trouver le processus
netstat -ano | findstr :3000

# Tuer le processus (remplacez PID)
taskkill /PID <PID> /F
```

#### Option B : Utiliser un autre port
```powershell
# Windows
$env:PORT=3001; npm run dev

# Ou créer un fichier .env.local
PORT=3001
```

---

### 7. "Invalid credentials"

**Problème :**
Impossible de se connecter avec un compte existant.

**Solutions :**

#### Vérifier les données
```powershell
npx prisma studio
```
Vérifiez la table `User` → `passwordHash` est rempli

#### Reset mot de passe
Utilisez la fonction "Forgot Password" dans l'application.

#### Créer un nouveau compte
Utilisez la page `/register`.

---

### 8. "Cloudinary upload failed"

**Erreur :**
```
Error: Invalid cloud_name
```

**Cause :**
Configuration Cloudinary manquante ou incorrecte.

**Solution :**

```env
# Vérifiez dans .env
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="votre-cloud-name"
NEXT_PUBLIC_CLOUDINARY_API_KEY="votre-api-key"
CLOUDINARY_API_SECRET="votre-secret"
```

Obtenez ces valeurs depuis [Cloudinary Dashboard](https://cloudinary.com/console).

---

### 9. "Pusher authentication failed"

**Erreur :**
```
Pusher error: Auth failed
```

**Cause :**
Configuration Pusher manquante ou incorrecte.

**Solution :**

```env
# Vérifiez dans .env
PUSHER_APP_ID="votre-app-id"
NEXT_PUBLIC_PUSHER_APP_KEY="votre-app-key"
PUSHER_SECRET="votre-secret"
```

**Vérifiez aussi le cluster** dans `src/lib/pusher.ts` :
```typescript
cluster: 'ap1',  // Changez selon votre région
```

---

### 10. "Email sending failed"

**Erreur :**
```
Error: Resend API key not configured
```

**Cause :**
Configuration Resend manquante.

**Solution :**

```env
# Ajoutez dans .env
RESEND_API_KEY="re_votre_cle"
```

Obtenez une clé sur [Resend](https://resend.com).

**Note :** Sans cette clé, la vérification email et reset password ne fonctionneront pas.

---

## Problèmes Docker

### "docker: command not found"

**Cause :**
Docker n'est pas installé ou pas dans le PATH.

**Solution :**
1. Téléchargez [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Installez et redémarrez
3. Vérifiez : `docker --version`

---

### "Cannot connect to Docker daemon"

**Cause :**
Docker Desktop n'est pas démarré.

**Solution :**
1. Lancez Docker Desktop
2. Attendez que l'icône soit verte
3. Réessayez la commande

---

### "Port 5432 already allocated"

**Cause :**
PostgreSQL tourne déjà localement ou dans un autre conteneur.

**Solutions :**

#### Option A : Arrêter le service local
```powershell
Stop-Service postgresql-x64-14
```

#### Option B : Changer le port dans docker-compose.yml
```yaml
ports: 
  - 5433:5432  # Port externe différent
```

Puis dans `.env` :
```env
DATABASE_URL="postgresql://postgres:postgrespw@localhost:5433/nextmatch"
```

---

## Commandes de diagnostic

### Vérifier Node.js
```powershell
node --version  # Doit être >= 18
npm --version
```

### Vérifier les variables d'environnement
```powershell
# PowerShell
Get-Content .env

# Ou avec Node
node -r dotenv/config -e "console.log(process.env)"
```

### Vérifier la connexion PostgreSQL
```powershell
# Avec Prisma
npx prisma db pull

# Avec psql
psql -h localhost -U postgres -p 5432 -d nextmatch
```

### Vérifier les migrations
```powershell
npx prisma migrate status
```

### Voir les logs Next.js détaillés
```powershell
# Mode verbose
npm run dev -- --debug
```

---

## Nettoyage et reset

### Nettoyer le cache Next.js
```powershell
# Supprimer .next
rm -r -Force .next

# Redémarrer
npm run dev
```

### Nettoyer node_modules
```powershell
# Supprimer node_modules
rm -r -Force node_modules

# Nettoyer le cache npm
npm cache clean --force

# Réinstaller
npm install
```

### Reset complet de la base de données
```powershell
# Avec Prisma ( Supprime toutes les données)
npx prisma migrate reset

# Ou avec Docker ( Supprime tout le conteneur)
docker compose down -v
docker compose up -d
npx prisma migrate deploy
npx prisma db seed
```

---

## Problèmes d'authentification

### Impossible de se connecter après inscription

**Vérifications :**
1. Email vérifié ? (vérifiez `emailVerified` dans Prisma Studio)
2. Profil complété ? (vérifiez `profileComplete`)
3. Bon mot de passe ? (testez "Forgot Password")

### Session expirée constamment

**Solution :**
Vérifiez que `AUTH_SECRET` est bien défini et **identique** entre les redémarrages.

### OAuth Google/GitHub ne fonctionne pas

**Vérifications :**
1. Redirect URI correct dans la console du provider
2. Client ID et Secret corrects dans `.env`
3. Variables bien préfixées : `GOOGLE_CLIENT_ID` (pas `NEXT_PUBLIC_`)

---

## Monitoring et logs

### Voir les logs Docker
```powershell
docker compose logs -f
```

### Voir les logs Next.js
Les logs s'affichent directement dans le terminal où vous avez lancé `npm run dev`.

### Voir les requêtes Prisma
Ajoutez dans `src/lib/prisma.ts` :
```typescript
const prisma = new PrismaClient({
  log: ['query', 'info', 'warn', 'error'],
});
```

---

## Demander de l'aide

Quand vous demandez de l'aide, incluez :

### Informations système
```powershell
# Versions
node --version
npm --version
docker --version

# OS
systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
```

### Logs d'erreur
Copiez **l'erreur complète** du terminal, pas juste le message.

### Configuration
```powershell
# Vérifiez (sans partager les secrets !)
cat .env | Select-String -Pattern "^[A-Z]" | ForEach-Object { $_.Line -replace '=.*', '=***' }
```

### Étapes pour reproduire
Décrivez précisément ce que vous avez fait avant l'erreur.

---

## Ressources utiles

- [Next.js Troubleshooting](https://nextjs.org/docs/messages)
- [Prisma Error Reference](https://www.prisma.io/docs/reference/api-reference/error-reference)
- [NextAuth Errors](https://next-auth.js.org/errors)
- [Docker Troubleshooting](https://docs.docker.com/engine/install/troubleshoot/)

---

## Conseils généraux

1. **Toujours vérifier `.env` en premier** - 80% des erreurs viennent de là
2. **Redémarrer le serveur** après modification de `.env`
3. **Vérifier PostgreSQL** avant de démarrer l'application
4. **Lire les messages d'erreur** en entier, pas juste le début
5. **Utiliser Prisma Studio** pour inspecter les données
6. **Consulter les logs Docker** si problème de BDD
7. **Nettoyer le cache** si comportement bizarre

---

**Si le problème persiste après avoir essayé ces solutions, n'hésitez pas à demander de l'aide en fournissant les informations ci-dessus ! **

