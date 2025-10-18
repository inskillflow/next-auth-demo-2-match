# Guide de Démarrage - Next Match

## Problème : "Could not find a production build"

**Vous avez essayé `npm start` mais ça ne fonctionne pas ?**

C'est normal ! `npm start` lance le serveur de **production**, mais vous n'avez pas encore construit l'application.

Pour le **développement**, utilisez : `npm run dev`

---

## Prérequis

1. **Node.js** (version 18 ou supérieure)
2. **PostgreSQL** (via Docker ou installation directe)
3. **Comptes externes** (optionnel) :
   - [Cloudinary](https://cloudinary.com) - Pour le stockage d'images
   - [Pusher](https://pusher.com) - Pour la messagerie en temps réel
   - [Resend](https://resend.com) - Pour l'envoi d'emails
   - [Google Cloud Console](https://console.cloud.google.com) - Pour OAuth Google (optionnel)
   - [GitHub](https://github.com/settings/developers) - Pour OAuth GitHub (optionnel)

---

## Installation

### Étape 1 : Créer le fichier `.env`

Créez un fichier `.env` à la racine du projet avec le contenu suivant :

```env
# Database
DATABASE_URL="postgresql://postgres:postgrespw@localhost:5432/nextmatch"

# NextAuth
# Générez avec: node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
AUTH_SECRET="votre-cle-secrete-generee-ici"
NEXT_PUBLIC_BASE_URL="http://localhost:3000"

# Google OAuth (optionnel)
GOOGLE_CLIENT_ID=""
GOOGLE_CLIENT_SECRET=""

# GitHub OAuth (optionnel)
GITHUB_CLIENT_ID=""
GITHUB_CLIENT_SECRET=""

# Resend Email API
RESEND_API_KEY=""

# Cloudinary (pour les images)
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=""
NEXT_PUBLIC_CLOUDINARY_API_KEY=""
CLOUDINARY_API_SECRET=""

# Pusher (pour la messagerie)
PUSHER_APP_ID=""
NEXT_PUBLIC_PUSHER_APP_KEY=""
PUSHER_SECRET=""
```

**Pour générer `AUTH_SECRET`**, exécutez dans PowerShell :
```powershell
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

### Étape 2 : Démarrer PostgreSQL

#### Option A : Avec Docker (recommandé)
```powershell
docker compose up -d
```

#### Option B : Installation directe
1. Téléchargez [PostgreSQL](https://www.postgresql.org/download/windows/)
2. Installez avec le mot de passe `postgrespw`
3. Port : 5432

#### Option C : Base de données en ligne
Utilisez [Supabase](https://supabase.com) ou [Neon](https://neon.tech) (gratuit) et modifiez `DATABASE_URL`.

### Étape 3 : Initialiser le projet

#### Méthode automatique (recommandé)
Exécutez le script PowerShell :
```powershell
.\setup.ps1
```

#### Méthode manuelle
```powershell
# 1. Générer le client Prisma
npx prisma generate

# 2. Appliquer les migrations
npx prisma migrate deploy

# 3. Peupler la base de données (optionnel)
npx prisma db seed

# 4. Installer les dépendances (si nécessaire)
npm install
```

---

## Démarrage

### Mode Développement (recommandé)
```powershell
npm run dev
```
Puis ouvrez : http://localhost:3000

### Mode Production
```powershell
# 1. Construire l'application
npm run build

# 2. Démarrer le serveur
npm start
```

---

## Vérification de la base de données

Pour ouvrir l'interface Prisma Studio :
```powershell
npx prisma studio
```
Cela ouvrira une interface graphique sur http://localhost:5555

---

## Scripts disponibles

- `npm run dev` - Démarrage en mode développement
- `npm run build` - Construction pour la production
- `npm start` - Démarrage du serveur de production
- `npm run lint` - Vérification du code
- `npx prisma studio` - Interface graphique pour la base de données
- `npx prisma migrate dev` - Créer une nouvelle migration

---

## Problèmes courants

### "Could not find a production build"
**Solution** : Utilisez `npm run dev` pour le développement ou `npm run build` avant `npm start`

### "Error: P1001: Can't reach database server"
**Solution** : Vérifiez que PostgreSQL est démarré avec `docker compose up -d`

### "AUTH_SECRET is not set"
**Solution** : Générez une clé avec la commande dans l'Étape 1

### Erreurs liées aux images/messages
**Solution** : Configurez les variables Cloudinary et Pusher dans `.env`

---

## Structure du projet

```
01-next-match-main-1/
├── src/
│   ├── app/              # Pages et routes Next.js
│   ├── components/       # Composants React réutilisables
│   ├── lib/              # Utilitaires et configurations
│   └── hooks/            # Hooks React personnalisés
├── prisma/
│   ├── schema.prisma     # Schéma de base de données
│   └── seed.ts           # Données de test
├── public/               # Fichiers statiques
└── documentation/        # Documentation du projet
```

---

## Fonctionnalités

- **Authentification** : NextAuth avec Google, GitHub et email/password
- **Profils utilisateurs** : Création et édition de profils
- **Photos** : Upload et gestion d'images via Cloudinary
- **Likes** : Système de likes entre utilisateurs
- **Messages** : Messagerie en temps réel avec Pusher
- **Administration** : Panel de modération
- **Emails** : Vérification d'email et réinitialisation de mot de passe

---

## Besoin d'aide ?

1. Vérifiez que toutes les variables d'environnement sont configurées
2. Assurez-vous que PostgreSQL est démarré
3. Consultez les logs d'erreur dans la console
4. Vérifiez la documentation Next.js : https://nextjs.org/docs

---

**Bon développement !**
