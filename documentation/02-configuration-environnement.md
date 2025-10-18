# Configuration de l'Environnement

## Fichier `.env` obligatoire

Ce fichier doit être créé à la **racine du projet** et contient toutes les variables d'environnement nécessaires.

---

## Variables obligatoires (minimum pour démarrer)

```env
# Base de données PostgreSQL
DATABASE_URL="postgresql://postgres:postgrespw@localhost:5432/nextmatch"

# Authentification NextAuth (OBLIGATOIRE)
AUTH_SECRET="votre-cle-secrete-ici"
NEXT_PUBLIC_BASE_URL="http://localhost:3000"
```

### Génération de `AUTH_SECRET`

**PowerShell :**
```powershell
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

**CMD :**
```cmd
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

---

## Variables OAuth (optionnelles)

### Google OAuth

1. Allez sur [Google Cloud Console](https://console.cloud.google.com)
2. Créez un nouveau projet
3. Activez l'API Google+
4. Créez des identifiants OAuth 2.0
5. Ajoutez `http://localhost:3000/api/auth/callback/google` aux URI de redirection

```env
GOOGLE_CLIENT_ID="votre-client-id"
GOOGLE_CLIENT_SECRET="votre-client-secret"
```

### GitHub OAuth

1. Allez sur [GitHub Developer Settings](https://github.com/settings/developers)
2. Créez une nouvelle OAuth App
3. Authorization callback URL : `http://localhost:3000/api/auth/callback/github`

```env
GITHUB_CLIENT_ID="votre-client-id"
GITHUB_CLIENT_SECRET="votre-client-secret"
```

---

## Service Email - Resend (optionnel mais recommandé)

Pour l'envoi d'emails de vérification et de réinitialisation de mot de passe.

1. Inscrivez-vous sur [Resend](https://resend.com)
2. Créez une API Key
3. Ajoutez-la dans `.env` :

```env
RESEND_API_KEY="re_votre_cle_api"
```

**Note :** Sans cette clé, les fonctionnalités d'email ne fonctionneront pas, mais le reste de l'application sera opérationnel.

---

## Cloudinary - Stockage d'images (optionnel mais recommandé)

Pour le téléchargement et la gestion des photos de profil.

1. Inscrivez-vous sur [Cloudinary](https://cloudinary.com)
2. Récupérez vos identifiants depuis le Dashboard
3. Ajoutez-les dans `.env` :

```env
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="votre-cloud-name"
NEXT_PUBLIC_CLOUDINARY_API_KEY="votre-api-key"
CLOUDINARY_API_SECRET="votre-api-secret"
```

**Note :** Sans Cloudinary, le téléchargement de photos ne fonctionnera pas.

---

## Pusher - Messagerie temps réel (optionnel)

Pour la messagerie instantanée entre utilisateurs.

1. Inscrivez-vous sur [Pusher](https://pusher.com)
2. Créez une nouvelle app
3. Choisissez le cluster le plus proche (ex: `ap1` pour l'Asie)
4. Ajoutez les identifiants dans `.env` :

```env
PUSHER_APP_ID="votre-app-id"
NEXT_PUBLIC_PUSHER_APP_KEY="votre-app-key"
PUSHER_SECRET="votre-secret"
```

**Note :** Le cluster est défini dans `src/lib/pusher.ts` (actuellement `ap1`). Modifiez-le si nécessaire.

---

## Configuration PostgreSQL

### Option 1 : Docker (recommandé)

Le fichier `docker-compose.yml` est déjà configuré :

```yaml
services:
  postgres:
    image: postgres
    environment:
      - POSTGRES_PASSWORD=postgrespw
    ports: 
      - 5432:5432
```

**Commandes :**
```powershell
# Démarrer
docker compose up -d

# Arrêter
docker compose down

# Voir les logs
docker compose logs -f
```

### Option 2 : Installation locale

1. Téléchargez [PostgreSQL](https://www.postgresql.org/download/windows/)
2. Installez avec ces paramètres :
   - Port : `5432`
   - Mot de passe : `postgrespw`
   - Utilisateur : `postgres`
3. Créez la base de données :
   ```sql
   CREATE DATABASE nextmatch;
   ```

### Option 3 : Base de données cloud (gratuit)

#### Supabase
1. Créez un compte sur [Supabase](https://supabase.com)
2. Créez un nouveau projet
3. Copiez la "Connection String" (format PostgreSQL)
4. Remplacez `DATABASE_URL` dans `.env`

#### Neon
1. Créez un compte sur [Neon](https://neon.tech)
2. Créez une base de données
3. Copiez la connection string
4. Remplacez `DATABASE_URL` dans `.env`

---

## Template complet du fichier `.env`

```env
# ===================================================
# DATABASE
# ===================================================
DATABASE_URL="postgresql://postgres:postgrespw@localhost:5432/nextmatch"

# ===================================================
# NEXTAUTH (OBLIGATOIRE)
# ===================================================
# Générez avec: node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
AUTH_SECRET=""
NEXT_PUBLIC_BASE_URL="http://localhost:3000"

# ===================================================
# OAUTH (OPTIONNEL)
# ===================================================
# Google OAuth
GOOGLE_CLIENT_ID=""
GOOGLE_CLIENT_SECRET=""

# GitHub OAuth
GITHUB_CLIENT_ID=""
GITHUB_CLIENT_SECRET=""

# ===================================================
# SERVICES EXTERNES (OPTIONNELS)
# ===================================================
# Resend - Service d'envoi d'emails
# https://resend.com
RESEND_API_KEY=""

# Cloudinary - Stockage d'images
# https://cloudinary.com
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=""
NEXT_PUBLIC_CLOUDINARY_API_KEY=""
CLOUDINARY_API_SECRET=""

# Pusher - Messagerie temps réel
# https://pusher.com
PUSHER_APP_ID=""
NEXT_PUBLIC_PUSHER_APP_KEY=""
PUSHER_SECRET=""
```

---

## Vérification de la configuration

### 1. Tester la connexion à PostgreSQL

```powershell
npx prisma db pull
```

Si la connexion fonctionne, vous verrez un message de succès.

### 2. Vérifier les variables d'environnement

Créez un fichier test :

```javascript
// test-env.js
console.log('DATABASE_URL:', process.env.DATABASE_URL ? 'OK - Défini' : 'ERREUR - Manquant');
console.log('AUTH_SECRET:', process.env.AUTH_SECRET ? 'OK - Défini' : 'ERREUR - Manquant');
console.log('CLOUDINARY:', process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME ? 'OK - Défini' : 'INFO - Optionnel');
console.log('PUSHER:', process.env.PUSHER_APP_ID ? 'OK - Défini' : 'INFO - Optionnel');
console.log('RESEND:', process.env.RESEND_API_KEY ? 'OK - Défini' : 'INFO - Optionnel');
```

Exécutez :
```powershell
node -r dotenv/config test-env.js
```

---

## Sécurité

**IMPORTANT :**

1. **Ne jamais commiter le fichier `.env`** (déjà dans `.gitignore`)
2. **Ne pas partager les clés secrètes** sur GitHub, Discord, etc.
3. **Utiliser des clés différentes** pour dev et production
4. **Régénérer les clés** si elles sont compromises

---

## Ressources

- [Next.js Environment Variables](https://nextjs.org/docs/basic-features/environment-variables)
- [Prisma Connection String](https://www.prisma.io/docs/reference/database-reference/connection-urls)
- [NextAuth Configuration](https://next-auth.js.org/configuration/options)
