# Guide Débutant - Configuration Complète Sans Docker

Ce guide est fait pour les débutants qui ne peuvent pas utiliser Docker sur Windows. Nous allons configurer tous les services nécessaires étape par étape.

---

## Vue d'ensemble

Vous allez créer des comptes sur ces services (tous gratuits) :

1. **Neon** - Base de données PostgreSQL en ligne
2. **Cloudinary** - Stockage d'images
3. **Pusher** - Messagerie en temps réel
4. **Resend** - Envoi d'emails
5. **Google** (optionnel) - Connexion avec Google
6. **GitHub** (optionnel) - Connexion avec GitHub

**Temps estimé : 30-45 minutes**

---

## Étape 1 : Créer la base de données avec Neon

### 1.1 - Créer un compte Neon

1. Ouvrez votre navigateur
2. Allez sur : https://neon.tech
3. Cliquez sur **"Sign Up"** (S'inscrire)
4. Choisissez une option :
   - **GitHub** (recommandé si vous avez un compte GitHub)
   - **Google**
   - **Email**
5. Suivez les instructions pour valider votre compte

### 1.2 - Créer votre premier projet

1. Vous arrivez sur le tableau de bord (Dashboard)
2. Cliquez sur **"Create a project"** ou **"New Project"**
3. Remplissez les informations :
   - **Project name** : `nextmatch` (ou le nom de votre choix)
   - **Region** : Choisissez le plus proche de vous (exemple : Europe - Frankfurt)
   - **PostgreSQL version** : Laissez la version par défaut (la plus récente)
4. Cliquez sur **"Create project"**
5. Attendez quelques secondes...

### 1.3 - Récupérer l'URL de connexion

1. Une fois le projet créé, vous voyez votre **Dashboard**
2. Cherchez la section **"Connection Details"** ou **"Connection String"**
3. Vous verrez plusieurs onglets : **Prisma**, **Node.js**, etc.
4. Cliquez sur l'onglet **"Prisma"**
5. Vous verrez une URL qui ressemble à :
   ```
   postgresql://username:password@ep-xxx-xxx.region.aws.neon.tech/neondb?sslmode=require
   ```
6. Cliquez sur l'icône de **copie** (📋) à côté de l'URL
7. **GARDEZ cette URL**, vous en aurez besoin dans l'Étape 7

**IMPORTANT** : Notez cette URL dans un fichier texte temporaire, vous en aurez besoin.

---

## Étape 2 : Créer un compte Cloudinary (Stockage d'images)

### 2.1 - Créer un compte

1. Allez sur : https://cloudinary.com
2. Cliquez sur **"Sign Up for Free"** (Inscription gratuite)
3. Remplissez le formulaire :
   - **Email**
   - **Password** (Mot de passe)
   - **Cloud Name** : Choisissez un nom unique (exemple : nextmatch-votrenom)
     - **IMPORTANT** : Ce nom sera dans vos URLs d'images, gardez-le simple
4. Cochez "I agree to the Terms of Service"
5. Cliquez sur **"Create Account"**
6. Vérifiez votre email et cliquez sur le lien de confirmation

### 2.2 - Récupérer vos identifiants

1. Connectez-vous à Cloudinary
2. Vous arrivez sur le **Dashboard**
3. En haut de la page, vous voyez une section **"Account Details"**
4. Notez ces 3 informations (cliquez sur l'œil pour révéler les valeurs cachées) :
   - **Cloud Name** : (exemple : dxxxxx)
   - **API Key** : (exemple : 123456789012345)
   - **API Secret** : (cliquez sur "reveal" puis copiez)

**Copiez ces 3 valeurs dans un fichier texte.**

---

## Étape 3 : Créer un compte Pusher (Messagerie temps réel)

### 3.1 - Créer un compte

1. Allez sur : https://pusher.com
2. Cliquez sur **"Sign Up"**
3. Créez votre compte avec :
   - **Email**
   - **Password**
   - Ou utilisez GitHub/Google
4. Validez votre email

### 3.2 - Créer une nouvelle App

1. Sur le Dashboard, cliquez sur **"Create app"** ou **"Channels apps"** → **"Create app"**
2. Remplissez le formulaire :
   - **Name** : `nextmatch` (ou votre choix)
   - **Cluster** : Choisissez le plus proche :
     - **ap1** : Asie-Pacifique (Singapour)
     - **eu** : Europe
     - **us-east-1** : USA Est
   - **Tech stack** : Sélectionnez **"React"** pour Frontend et **"Node.js"** pour Backend
3. Cliquez sur **"Create app"**

### 3.3 - Récupérer vos identifiants

1. Vous êtes sur la page de votre app
2. Cliquez sur **"App Keys"** dans le menu de gauche
3. Vous voyez :
   - **app_id** : (exemple : 1234567)
   - **key** : (exemple : abcdef123456)
   - **secret** : (exemple : 7890xyz)
   - **cluster** : (exemple : ap1)
4. **Copiez ces 3 valeurs** (app_id, key, secret) dans votre fichier texte

**IMPORTANT** : Notez aussi le **cluster**, vous en aurez peut-être besoin.

---

## Étape 4 : Créer un compte Resend (Envoi d'emails)

### 4.1 - Créer un compte

1. Allez sur : https://resend.com
2. Cliquez sur **"Get Started"** ou **"Sign Up"**
3. Inscrivez-vous avec :
   - **Email**
   - **Password**
   - Ou GitHub
4. Vérifiez votre email

### 4.2 - Créer une API Key

1. Sur le Dashboard, cliquez sur **"API Keys"** dans le menu
2. Cliquez sur **"Create API Key"** ou **"+ Create"**
3. Remplissez :
   - **Name** : `nextmatch` (pour identifier cette clé)
   - **Permission** : Laissez **"Full Access"** (Accès complet)
4. Cliquez sur **"Create"**
5. **Une clé apparaît qui commence par `re_`**
6. **COPIEZ IMMÉDIATEMENT** cette clé (vous ne pourrez plus la voir après)
7. Collez-la dans votre fichier texte

**Format** : `re_xxxxxxxxxxxxxxxxxxxxxxxxxx`

### 4.3 - Configuration du domaine (optionnel pour le développement)

Pour le développement local, vous n'avez pas besoin de configurer un domaine. La clé API suffit.

---

## Étape 5 : Google OAuth (OPTIONNEL - pour connexion avec Google)

Si vous voulez permettre la connexion avec Google, suivez ces étapes. Sinon, passez à l'Étape 6.

### 5.1 - Créer un projet Google Cloud

1. Allez sur : https://console.cloud.google.com
2. Connectez-vous avec votre compte Google
3. Cliquez sur le **sélecteur de projet** en haut (à côté de "Google Cloud")
4. Cliquez sur **"NEW PROJECT"** (Nouveau projet)
5. Remplissez :
   - **Project name** : `nextmatch` (ou votre choix)
   - **Organization** : Laissez vide si vous n'en avez pas
6. Cliquez sur **"CREATE"** (Créer)
7. Attendez quelques secondes, puis sélectionnez votre nouveau projet

### 5.2 - Configurer l'écran de consentement OAuth

1. Dans le menu de gauche, cherchez **"APIs & Services"** → **"OAuth consent screen"**
2. Choisissez **"External"** (Externe)
3. Cliquez sur **"CREATE"**
4. Remplissez le formulaire :
   - **App name** : `Next Match`
   - **User support email** : Votre email
   - **Developer contact information** : Votre email
5. Cliquez sur **"SAVE AND CONTINUE"**
6. Sur la page "Scopes", cliquez simplement sur **"SAVE AND CONTINUE"** (pas besoin d'ajouter de scopes)
7. Sur la page "Test users", vous pouvez ajouter votre email, puis **"SAVE AND CONTINUE"**
8. Vérifiez le résumé et cliquez sur **"BACK TO DASHBOARD"**

### 5.3 - Créer les identifiants OAuth

1. Dans le menu de gauche, cliquez sur **"Credentials"** (Identifiants)
2. Cliquez sur **"+ CREATE CREDENTIALS"** en haut
3. Sélectionnez **"OAuth client ID"**
4. Configuration :
   - **Application type** : **"Web application"**
   - **Name** : `Next Match Web Client`
   - **Authorized JavaScript origins** : Cliquez sur **"+ ADD URI"**
     - Ajoutez : `http://localhost:3000`
   - **Authorized redirect URIs** : Cliquez sur **"+ ADD URI"**
     - Ajoutez : `http://localhost:3000/api/auth/callback/google`
5. Cliquez sur **"CREATE"**
6. Une popup apparaît avec :
   - **Client ID** : (commence par un long nombre)
   - **Client Secret** : (une chaîne de caractères)
7. **Copiez ces deux valeurs** dans votre fichier texte
8. Cliquez sur **"OK"**

---

## Étape 6 : GitHub OAuth (OPTIONNEL - pour connexion avec GitHub)

Si vous voulez permettre la connexion avec GitHub, suivez ces étapes. Sinon, passez à l'Étape 7.

### 6.1 - Créer une OAuth App GitHub

1. Allez sur : https://github.com/settings/developers
2. Connectez-vous si nécessaire
3. Dans le menu de gauche, cliquez sur **"OAuth Apps"**
4. Cliquez sur **"New OAuth App"** (Nouvelle application OAuth)
5. Remplissez le formulaire :
   - **Application name** : `Next Match` (sera visible par les utilisateurs)
   - **Homepage URL** : `http://localhost:3000`
   - **Application description** : (optionnel) `Application de rencontres`
   - **Authorization callback URL** : `http://localhost:3000/api/auth/callback/github`
6. Cliquez sur **"Register application"**

### 6.2 - Récupérer les identifiants

1. Vous voyez votre application créée
2. Notez le **Client ID** (affiché directement)
3. Cliquez sur **"Generate a new client secret"**
4. Confirmez avec votre mot de passe GitHub si demandé
5. **Un Client Secret apparaît** (vous ne le reverrez plus après)
6. **Copiez immédiatement** le Client ID et le Client Secret dans votre fichier texte

---

## Étape 7 : Créer le fichier .env

Maintenant que vous avez tous vos identifiants, vous allez créer le fichier de configuration.

### 7.1 - Ouvrir le projet dans VS Code (ou votre éditeur)

1. Ouvrez **Visual Studio Code**
2. Allez dans **File** → **Open Folder**
3. Sélectionnez le dossier de votre projet : `C:\projetsnext\01-next-match-main-1`
4. Cliquez sur **"Sélectionner un dossier"**

### 7.2 - Créer le fichier .env

1. Dans VS Code, faites un **clic droit** dans l'explorateur de fichiers (à gauche)
2. Sélectionnez **"New File"** (Nouveau fichier)
3. Nommez-le exactement : `.env` (avec le point au début)
4. Appuyez sur **Entrée**

### 7.3 - Remplir le fichier .env

Copiez ce template et remplacez les valeurs entre guillemets par vos vraies valeurs :

```env
# ============================================
# BASE DE DONNÉES NEON
# ============================================
# Collez ici l'URL complète que vous avez copiée depuis Neon
DATABASE_URL="postgresql://username:password@ep-xxx-xxx.region.aws.neon.tech/neondb?sslmode=require"

# ============================================
# NEXTAUTH (Authentification)
# ============================================
# Pour générer AUTH_SECRET, ouvrez PowerShell et exécutez :
# node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
AUTH_SECRET="COLLEZ_ICI_LA_CLE_GENEREE"
NEXT_PUBLIC_BASE_URL="http://localhost:3000"

# ============================================
# GOOGLE OAUTH (OPTIONNEL)
# ============================================
# Si vous avez configuré Google OAuth (Étape 5) :
GOOGLE_CLIENT_ID="votre-client-id-google.apps.googleusercontent.com"
GOOGLE_CLIENT_SECRET="votre-client-secret-google"

# Si vous ne l'avez PAS configuré, laissez ces lignes vides :
# GOOGLE_CLIENT_ID=""
# GOOGLE_CLIENT_SECRET=""

# ============================================
# GITHUB OAUTH (OPTIONNEL)
# ============================================
# Si vous avez configuré GitHub OAuth (Étape 6) :
GITHUB_CLIENT_ID="votre-client-id-github"
GITHUB_CLIENT_SECRET="votre-client-secret-github"

# Si vous ne l'avez PAS configuré, laissez ces lignes vides :
# GITHUB_CLIENT_ID=""
# GITHUB_CLIENT_SECRET=""

# ============================================
# RESEND (Envoi d'emails)
# ============================================
# Collez la clé API Resend (commence par re_)
RESEND_API_KEY="re_votre_cle_resend"

# ============================================
# CLOUDINARY (Stockage d'images)
# ============================================
# Collez les 3 valeurs depuis votre Dashboard Cloudinary
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="votre-cloud-name"
NEXT_PUBLIC_CLOUDINARY_API_KEY="votre-api-key"
CLOUDINARY_API_SECRET="votre-api-secret"

# ============================================
# PUSHER (Messagerie temps réel)
# ============================================
# Collez les 3 valeurs depuis votre App Pusher
PUSHER_APP_ID="votre-app-id"
NEXT_PUBLIC_PUSHER_APP_KEY="votre-pusher-key"
PUSHER_SECRET="votre-pusher-secret"
```

### 7.4 - Générer AUTH_SECRET

C'est la seule valeur que vous devez générer vous-même :

1. Ouvrez **PowerShell** (recherchez "PowerShell" dans Windows)
2. Copiez-collez cette commande et appuyez sur Entrée :
   ```powershell
   node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
   ```
3. Une longue chaîne de caractères s'affiche (exemple : `xK7/9mPqR3sT5vN2wB8aL4...`)
4. **Copiez cette valeur**
5. Dans votre fichier `.env`, remplacez `COLLEZ_ICI_LA_CLE_GENEREE` par cette valeur

### 7.5 - Vérifier le fichier .env

Votre fichier `.env` doit maintenant ressembler à ceci (avec vos vraies valeurs) :

```env
DATABASE_URL="postgresql://alex:abc123@ep-cool-sound-123456.us-east-1.aws.neon.tech/neondb?sslmode=require"
AUTH_SECRET="xK7/9mPqR3sT5vN2wB8aL4cD6eF1gH9iJ0kL="
NEXT_PUBLIC_BASE_URL="http://localhost:3000"
GOOGLE_CLIENT_ID="123456789-abcdef.apps.googleusercontent.com"
GOOGLE_CLIENT_SECRET="GOCSPX-abc123def456"
GITHUB_CLIENT_ID="Iv1.a1b2c3d4e5f6"
GITHUB_CLIENT_SECRET="abc123def456ghi789jkl012"
RESEND_API_KEY="re_123456789_abcdefghijklmnop"
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="dnextmatch"
NEXT_PUBLIC_CLOUDINARY_API_KEY="123456789012345"
CLOUDINARY_API_SECRET="abcdef123456"
PUSHER_APP_ID="1234567"
NEXT_PUBLIC_PUSHER_APP_KEY="abcdef123456"
PUSHER_SECRET="7890xyz"
```

### 7.6 - IMPORTANT : Vérifier le cluster Pusher

Si lors de la création de votre app Pusher vous avez choisi un cluster différent de `ap1` :

1. Ouvrez le fichier : `src/lib/pusher.ts`
2. Cherchez la ligne : `cluster: 'ap1',`
3. Remplacez `'ap1'` par votre cluster (exemple : `'eu'` ou `'us-east-1'`)
4. Sauvegardez le fichier

### 7.7 - Sauvegarder

1. Dans VS Code, appuyez sur **Ctrl + S** pour sauvegarder
2. Vérifiez que le fichier `.env` est bien à la racine du projet (même niveau que `package.json`)

---

## Étape 8 : Installer les dépendances

### 8.1 - Ouvrir un terminal

1. Dans VS Code, allez dans le menu **Terminal** → **New Terminal**
2. Ou appuyez sur **Ctrl + `** (backtick)
3. Un terminal s'ouvre en bas de l'écran
4. Vérifiez que vous êtes dans le bon dossier (vous devez voir le chemin du projet)

### 8.2 - Installer Node.js (si pas déjà fait)

1. Tapez cette commande pour vérifier :
   ```powershell
   node --version
   ```
2. Si vous voyez une version (exemple : `v18.17.0`), c'est bon, passez à 8.3
3. Sinon, téléchargez et installez Node.js :
   - Allez sur : https://nodejs.org
   - Téléchargez la version **LTS** (Long Term Support)
   - Installez-la (suivez les instructions)
   - **Redémarrez VS Code**
   - Réessayez la commande `node --version`

### 8.3 - Installer les packages npm

Dans le terminal VS Code, tapez :

```powershell
npm install
```

**Attendez...** Cela peut prendre 2-5 minutes. Vous verrez plein de lignes défiler. C'est normal.

**Quand c'est fini**, vous voyez quelque chose comme :
```
added 324 packages in 2m
```

---

## Étape 9 : Configurer la base de données avec Prisma

### 9.1 - Générer le client Prisma

Dans le terminal, tapez :

```powershell
npx prisma generate
```

**Résultat attendu** : Vous voyez "Generated Prisma Client"

### 9.2 - Appliquer les migrations (créer les tables)

Dans le terminal, tapez :

```powershell
npx prisma migrate deploy
```

**Résultat attendu** : Vous voyez des lignes comme :
```
Applying migration...
Database migration completed
```

### 9.3 - Peupler la base avec des données de test

Dans le terminal, tapez :

```powershell
npx prisma db seed
```

**Résultat attendu** : Vous voyez "Database seeded successfully" ou des messages indiquant que des utilisateurs ont été créés.

**Si vous avez une erreur**, ce n'est pas grave. Le seed n'est pas obligatoire pour démarrer.

---

## Étape 10 : Démarrer l'application

### 10.1 - Lancer le serveur de développement

Dans le terminal, tapez :

```powershell
npm run dev
```

**Vous devez voir** :
```
▲ Next.js 14.2.1
- Local:        http://localhost:3000

✓ Ready in 2.5s
```

### 10.2 - Ouvrir l'application

1. Ouvrez votre navigateur (Chrome, Firefox, Edge...)
2. Allez sur : **http://localhost:3000**
3. **Vous devez voir la page d'accueil de Next Match !**

---

## Étape 11 : Tester l'application

### 11.1 - Créer un compte

1. Sur la page d'accueil, cliquez sur **"Register"** ou **"S'inscrire"**
2. Remplissez le formulaire :
   - **Email**
   - **Mot de passe**
   - **Nom**
3. Cliquez sur **"Sign Up"** ou **"S'inscrire"**

### 11.2 - Vérifier l'email (si Resend est configuré)

1. Vérifiez votre boîte email
2. Vous devriez recevoir un email de vérification
3. Cliquez sur le lien dans l'email
4. Vous êtes redirigé et votre email est vérifié

**Si vous n'avez PAS configuré Resend**, vous ne recevrez pas d'email, mais vous pouvez quand même utiliser l'application.

### 11.3 - Compléter votre profil

1. Remplissez les informations de votre profil :
   - **Date de naissance**
   - **Genre**
   - **Description**
   - **Ville et pays**
2. Cliquez sur **"Submit"** ou **"Soumettre"**

### 11.4 - Uploader une photo (si Cloudinary est configuré)

1. Allez dans votre profil
2. Cliquez sur **"Edit Profile"** ou **"Photos"**
3. Cliquez sur **"Upload"**
4. Sélectionnez une image depuis votre ordinateur
5. L'image est uploadée sur Cloudinary et apparaît dans votre profil

### 11.5 - Tester la messagerie (si Pusher est configuré)

Pour tester la messagerie en temps réel :
1. Créez un second compte (utilisez un autre email ou un mode incognito)
2. Envoyez un message entre les deux comptes
3. Le message devrait apparaître en temps réel sans recharger la page

---

## Vérification - Liste de contrôle

Cochez ce que vous avez fait :

- [ ] Compte Neon créé et DATABASE_URL copiée
- [ ] Compte Cloudinary créé et 3 identifiants copiés
- [ ] Compte Pusher créé et 3 identifiants copiés
- [ ] Compte Resend créé et API Key copiée
- [ ] (Optionnel) Google OAuth configuré
- [ ] (Optionnel) GitHub OAuth configuré
- [ ] Fichier `.env` créé à la racine du projet
- [ ] Toutes les valeurs remplies dans `.env`
- [ ] AUTH_SECRET généré
- [ ] `npm install` exécuté avec succès
- [ ] `npx prisma generate` exécuté
- [ ] `npx prisma migrate deploy` exécuté
- [ ] `npx prisma db seed` exécuté (ou essayé)
- [ ] `npm run dev` fonctionne
- [ ] Page http://localhost:3000 s'affiche
- [ ] Compte créé et connexion réussie

---

## Problèmes courants

### "Cannot find module '.env'"

**Solution** : Le fichier `.env` n'est pas au bon endroit
- Il doit être à la **racine** du projet
- Au même niveau que `package.json`

### "AUTH_SECRET is not set"

**Solution** : Vous avez oublié de générer ou copier AUTH_SECRET
- Relisez l'Étape 7.4
- Générez une nouvelle clé
- Collez-la dans `.env`
- Redémarrez avec `npm run dev`

### "Can't reach database server"

**Solution** : Problème avec l'URL Neon
- Vérifiez que vous avez copié l'URL **complète** depuis Neon
- Elle doit contenir `?sslmode=require` à la fin
- Pas d'espace avant ou après

### "Cloudinary upload failed"

**Solutions** :
- Vérifiez que les 3 valeurs Cloudinary sont correctes
- Pas d'espace avant ou après les guillemets
- Le Cloud Name doit correspondre exactement

### "Pusher connection failed"

**Solutions** :
- Vérifiez que le cluster dans `src/lib/pusher.ts` correspond à votre cluster Pusher
- Vérifiez les 3 identifiants Pusher dans `.env`

### Le serveur ne démarre pas

**Solutions** :
1. Fermez le terminal (cliquez sur la poubelle)
2. Ouvrez un nouveau terminal
3. Retapez `npm run dev`

---

## Pour arrêter le serveur

Quand vous voulez arrêter l'application :

1. Dans le terminal où tourne `npm run dev`
2. Appuyez sur **Ctrl + C**
3. Tapez **O** (pour "Oui") si demandé
4. Le serveur s'arrête

---

## Pour redémarrer l'application plus tard

La prochaine fois que vous voulez travailler sur le projet :

1. Ouvrez VS Code
2. Ouvrez le dossier du projet
3. Ouvrez un terminal (**Ctrl + `**)
4. Tapez : `npm run dev`
5. Allez sur http://localhost:3000

**C'est tout !** Vous n'avez pas besoin de refaire toute la configuration.

---

## Ressources et aide

### Vérifier vos services en ligne

- **Neon Dashboard** : https://console.neon.tech
- **Cloudinary Dashboard** : https://cloudinary.com/console
- **Pusher Dashboard** : https://dashboard.pusher.com
- **Resend Dashboard** : https://resend.com/overview

### Documentation

Consultez les autres guides dans le dossier `documentation/` :
- `02-configuration-environnement.md` - Détails sur chaque service
- `05-troubleshooting.md` - Plus de solutions aux problèmes
- `03-scripts-automatisation.md` - Commandes utiles

### Prisma Studio (voir votre base de données)

Pour voir les données dans votre base :

```powershell
npx prisma studio
```

Ouvre une interface sur http://localhost:5555

---

## Récapitulatif des comptes créés

Gardez ces informations en sécurité :

| Service | URL | Ce que ça fait |
|---------|-----|----------------|
| **Neon** | https://neon.tech | Base de données PostgreSQL |
| **Cloudinary** | https://cloudinary.com | Stockage et traitement d'images |
| **Pusher** | https://pusher.com | Messagerie en temps réel |
| **Resend** | https://resend.com | Envoi d'emails |
| **Google Cloud** | https://console.cloud.google.com | OAuth Google (optionnel) |
| **GitHub OAuth** | https://github.com/settings/developers | OAuth GitHub (optionnel) |

---

## Félicitations !

Vous avez configuré avec succès tous les services nécessaires pour Next Match sans Docker !

Votre application est maintenant prête à être utilisée et développée.

**Prochaines étapes :**
- Explorez l'application
- Créez des profils
- Testez les fonctionnalités
- Consultez le code dans `src/`

**Bon développement !**

