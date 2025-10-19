# Troubleshooting - Résolution des Problèmes Rencontrés

Ce document détaille tous les problèmes rencontrés lors de la configuration initiale du projet et comment ils ont été résolus, étape par étape.

---

## Table des Matières

1. [Problème 1 : "Could not find a production build"](#problème-1--could-not-find-a-production-build)
2. [Problème 2 : "The table public.User does not exist"](#problème-2--the-table-publicuser-does-not-exist)
3. [Problème 3 : "Upload preset not found" - Cloudinary](#problème-3--upload-preset-not-found---cloudinary)
4. [Problème 4 : Configuration du Cluster Pusher](#problème-4--configuration-du-cluster-pusher)
5. [Problème 5 : Status 400 (Bad Request) - Cloudinary](#problème-5--status-400-bad-request---cloudinary)
6. [Configuration Complète du Preset Cloudinary](#configuration-complète-du-preset-cloudinary)
7. [Vérifications Finales](#vérifications-finales)
8. [Checklist Complète de Démarrage](#checklist-complète-de-démarrage)

---

## Problème 1 : "Could not find a production build"

### Symptômes

```
Error: Could not find a production build in the '.next' directory.
Try building your app with 'next build' before starting the production server.
```

Vous avez essayé de démarrer l'application avec `npm start`.

### Cause

`npm start` lance le serveur en **mode production**, mais il n'y a pas encore de build compilé dans le dossier `.next/`.

### Solution

**Option A : Mode Développement (Recommandé pour débuter)**

Utilisez `npm run dev` au lieu de `npm start` :

```powershell
npm run dev
```

Le mode développement :
- Ne nécessite pas de build préalable
- Recharge automatiquement les changements (hot-reload)
- Affiche des erreurs détaillées
- Idéal pour le développement

**Option B : Mode Production**

Si vous voulez vraiment utiliser le mode production :

```powershell
# 1. Construire l'application
npm run build

# 2. Démarrer le serveur de production
npm start
```

### Explication Détaillée

**Scripts npm disponibles :**

| Commande | Usage | Quand l'utiliser |
|----------|-------|------------------|
| `npm run dev` | Développement avec hot-reload | Pendant le développement quotidien |
| `npm run build` | Compile l'application | Avant le déploiement en production |
| `npm start` | Serveur de production | Après `npm run build`, pour la production |
| `npm run lint` | Vérification du code | Avant de commiter du code |

---

## Problème 2 : "The table public.User does not exist"

### Symptômes

```
PrismaClientKnownRequestError: 
Invalid `prisma.user.findUnique()` invocation:

The table `public.User` does not exist in the current database.
```

L'application se lance mais quand vous essayez de créer un compte, vous obtenez cette erreur.

### Cause

Les tables de la base de données n'ont pas été créées. Prisma a besoin d'appliquer les migrations pour créer la structure de la base de données.

### Solution Complète

#### Étape 1 : Arrêter le serveur

Dans le terminal où tourne `npm run dev` :
- Appuyez sur **Ctrl + C**
- Le serveur s'arrête

#### Étape 2 : Générer le client Prisma

```powershell
npx prisma generate
```

**Résultat attendu :**
```
✔ Generated Prisma Client (5.11.0) to ./node_modules/@prisma/client
```

**Ce que ça fait :**
- Génère le client TypeScript pour accéder à la base de données
- Crée des types TypeScript pour vos modèles
- Nécessaire après chaque modification du fichier `schema.prisma`

#### Étape 3 : Appliquer les migrations

```powershell
npx prisma migrate deploy
```

**Résultat attendu :**
```
The following migration(s) have been applied:

migrations/
  └─ 20240413085447_initial/
    └─ migration.sql
  └─ 20240413100752_added_is_approved/
    └─ migration.sql

✔ All migrations have been successfully applied.
```

**Ce que ça fait :**
- Crée toutes les tables dans la base de données
- Applique les migrations existantes
- Crée les relations entre les tables

**Tables créées :**
- `User` : Authentification et informations de base
- `Member` : Profils publics des utilisateurs
- `Photo` : Photos uploadées par les membres
- `Like` : Système de likes entre utilisateurs
- `Message` : Messages entre membres
- `Token` : Tokens de vérification email et reset password
- `Account` : Comptes OAuth (Google, GitHub)

#### Étape 4 : Peupler la base de données (Optionnel)

```powershell
npx prisma db seed
```

**Résultat attendu :**
```
Running seed command...
🌱 The seed command has been executed.
```

**Ce que ça fait :**
- Crée 10 profils de test (5 hommes, 5 femmes)
- Crée 1 compte administrateur
- Ajoute des photos pour chaque profil
- Génère des descriptions et informations

**Comptes créés :**

| Email | Mot de passe | Genre | Rôle |
|-------|--------------|-------|------|
| lisa@test.com | password | Femme | Membre |
| karen@test.com | password | Femme | Membre |
| margo@test.com | password | Femme | Membre |
| lois@test.com | password | Femme | Membre |
| ruthie@test.com | password | Femme | Membre |
| todd@test.com | password | Homme | Membre |
| porter@test.com | password | Homme | Membre |
| mayo@test.com | password | Homme | Membre |
| skinner@test.com | password | Homme | Membre |
| davis@test.com | password | Homme | Membre |
| admin@test.com | password | - | Admin |

#### Étape 5 : Redémarrer l'application

```powershell
npm run dev
```

### Si le Seed Échoue

**Erreur "Unique constraint failed" :**

Cela signifie que les utilisateurs existent déjà dans la base.

**Solution : Reset complet**

```powershell
npx prisma migrate reset
```

**Confirmation :**
```
? We need to reset the database, do you want to continue? › (y/N)
```

Tapez **y** et appuyez sur Entrée.

**Ce que ça fait :**
1. Supprime toutes les tables
2. Recrée toutes les tables
3. Applique toutes les migrations
4. Exécute automatiquement le seed

---

## Problème 3 : "Upload preset not found" - Cloudinary

### Symptômes

Quand vous essayez d'uploader une photo, vous voyez :

```
Upload preset not found
```

Dans la console du navigateur (F12) :
```
Failed to load api.cloudinary.com/.../upload:1
```

### Cause

Le **Upload Preset** n'existe pas sur votre compte Cloudinary, ou le nom du preset dans le code ne correspond pas à celui créé sur Cloudinary.

### Solution Détaillée

#### Partie 1 : Identifier le preset utilisé dans le code

Le code utilise un preset nommé **`nextmatch`** (modifié depuis `nm-demo`).

**Fichier modifié :** `src/components/ImageUploadButton.tsx`

```typescript
<CldUploadButton
  options={{maxFiles: 1}}
  onSuccess={onUploadImage}
  signatureEndpoint='/api/sign-image'
  uploadPreset='nextmatch'  // ← Ce nom doit exister sur Cloudinary
  className={...}
>
```

#### Partie 2 : Créer le preset sur Cloudinary

**Étape 1 : Accéder à Cloudinary**

1. Ouvrez votre navigateur
2. Allez sur : https://console.cloudinary.com
3. Connectez-vous avec vos identifiants

**Étape 2 : Accéder aux Settings**

1. En haut à droite, cliquez sur l'icône **engrenage** (Settings)
2. Vous arrivez sur la page des paramètres

**Étape 3 : Onglet Upload**

1. En haut de la page, cliquez sur l'onglet **"Upload"**
2. Vous voyez plusieurs sections
3. Descendez jusqu'à la section **"Upload presets"**

**Étape 4 : Créer un nouveau preset**

1. Dans la section "Upload presets", cliquez sur **"Add upload preset"** en haut à droite
2. Une nouvelle page s'ouvre

**Étape 5 : Configuration du preset (TRÈS IMPORTANT)**

Remplissez les champs suivants **EXACTEMENT** comme indiqué :

**Configuration obligatoire :**

| Champ | Valeur | Importance |
|-------|--------|------------|
| **Preset name** | `nextmatch` | CRITIQUE - Doit correspondre au code |
| **Signing mode** | **Unsigned** | CRITIQUE - Doit être "Unsigned" pas "Signed" |

**Configuration optionnelle (recommandée) :**

| Champ | Valeur | Description |
|-------|--------|-------------|
| **Folder** | `nextmatch` | Organise les images dans un dossier |
| **Unique filename** | Coché | Évite les conflits de noms |
| **Overwrite** | Non coché | Préserve les images existantes |
| **Access mode** | `public` | Les images sont accessibles publiquement |

**Étape 6 : Sauvegarder**

1. Descendez en bas de la page
2. Cliquez sur le bouton **"Save"** en haut à droite

**Étape 7 : Vérification**

Vous revenez à la liste des presets. Vous devez voir :

```
Preset name: nextmatch
Type: unsigned ✓
```

**ATTENTION :** Si vous voyez `(signed)` à côté du nom, ce n'est PAS bon :
- Le preset ne fonctionnera pas
- Supprimez-le et recréez-le en choisissant bien **"Unsigned"**

### Explication Détaillée : Signed vs Unsigned

#### Pourquoi ce choix est CRITIQUE ?

Le mode du preset (Signed ou Unsigned) détermine **qui est autorisé** à uploader des images sur votre compte Cloudinary et **comment** l'authentification fonctionne.

---

#### Mode UNSIGNED (Ce que nous utilisons)

**Définition :**
Le mode "Unsigned" permet à **n'importe qui ayant le nom du preset** d'uploader des images directement depuis son navigateur vers votre Cloudinary, **sans vérification serveur**.

**Comment ça fonctionne :**

```
┌─────────────┐                    ┌─────────────────┐
│  Navigateur │                    │   Cloudinary    │
│  (Client)   │                    │    Serveur      │
└──────┬──────┘                    └────────┬────────┘
       │                                    │
       │  1. Clic "Upload image"           │
       │                                    │
       │  2. Sélectionne image.jpg         │
       │                                    │
       │  3. POST /upload                  │
       │     - cloud_name: dgxtwhibj       │
       │     - upload_preset: nextmatch    │
       │     - file: image.jpg             │
       ├───────────────────────────────────>│
       │                                    │
       │  4. Cloudinary vérifie :          │
       │     - Le preset existe ? ✓        │
       │     - Le preset est Unsigned ? ✓  │
       │     - Règles du preset OK ? ✓     │
       │                                    │
       │  5. Retourne l'URL de l'image     │
       │<───────────────────────────────────┤
       │     {url: "https://...", ...}     │
       │                                    │
```

**Avantages :**
✅ Simple à configurer
✅ Upload direct du navigateur → Cloudinary (pas de passage par votre serveur)
✅ Économise la bande passante de votre serveur
✅ Plus rapide (connexion directe)
✅ Idéal pour le développement

**Inconvénients :**
❌ Moins sécurisé : n'importe qui connaissant le nom du preset peut uploader
❌ Pas de validation côté serveur avant l'upload
❌ Dépend uniquement des restrictions du preset (taille, format, etc.)

**Quand l'utiliser :**
- Développement (ce que nous faisons)
- Applications où les uploads sont contrôlés après coup (modération, comme notre système "Awaiting approval")
- Quand la simplicité est prioritaire

---

#### Mode SIGNED (Ce que nous n'utilisons PAS)

**Définition :**
Le mode "Signed" nécessite qu'une **signature cryptographique** soit générée par **votre serveur** pour chaque upload. Sans cette signature, Cloudinary refuse l'upload.

**Comment ça fonctionne :**

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────┐
│  Navigateur │     │    Votre    │     │   Cloudinary    │
│  (Client)   │     │   Serveur   │     │    Serveur      │
└──────┬──────┘     └──────┬──────┘     └────────┬────────┘
       │                   │                     │
       │  1. Clic "Upload" │                     │
       │                   │                     │
       │  2. POST /api/get-signature            │
       ├──────────────────>│                     │
       │                   │                     │
       │  3. Serveur génère signature :         │
       │     - timestamp = now()                 │
       │     - hash = SHA256(params + api_secret)│
       │                   │                     │
       │  4. Retourne      │                     │
       │     {signature,   │                     │
       │      timestamp}   │                     │
       │<──────────────────┤                     │
       │                   │                     │
       │  5. POST /upload avec signature        │
       │     - file: image.jpg                   │
       │     - timestamp: 1234567890            │
       │     - signature: abc123def456...       │
       ├────────────────────────────────────────>│
       │                   │                     │
       │  6. Cloudinary vérifie :               │
       │     - Signature valide ? ✓             │
       │     - Timestamp récent ? ✓             │
       │     - Signature = hash(params) ? ✓     │
       │                   │                     │
       │  7. Si tout OK, accepte l'upload       │
       │<────────────────────────────────────────┤
       │                   │                     │
```

**Avantages :**
✅ Très sécurisé : seul votre serveur peut autoriser les uploads
✅ Contrôle total : vous pouvez valider les images côté serveur avant de signer
✅ Évite les abus : impossible d'uploader sans passer par votre API
✅ Traçabilité : vous savez qui a uploadé quoi

**Inconvénients :**
❌ Plus complexe à configurer
❌ Nécessite un endpoint API sur votre serveur (`/api/sign-image`)
❌ Deux requêtes au lieu d'une (signature + upload)
❌ Plus lent (étape supplémentaire)

**Quand l'utiliser :**
- Production avec haute sécurité
- Applications critiques
- Quand vous voulez valider/transformer les images côté serveur avant upload
- Contrôle strict des utilisateurs

---

#### Pourquoi notre projet utilise UNSIGNED ?

**1. Le code est configuré pour Unsigned**

Dans `src/components/ImageUploadButton.tsx` :

```typescript
<CldUploadButton
  uploadPreset='nextmatch'  // ← Pas de signature
  signatureEndpoint='/api/sign-image'  // ← Endpoint existe mais non utilisé
  onSuccess={onUploadImage}
/>
```

**2. Nous avons un système de modération**

Les photos uploadées ont le statut `isApproved: false` par défaut :
- Elles ne sont pas visibles publiquement
- Un admin doit les approuver manuellement
- Cela compense le manque de sécurité de Unsigned

**3. C'est suffisant pour le développement**

Pour apprendre et développer, Unsigned est largement suffisant et évite la complexité.

---

#### Comment vérifier votre mode ?

**Sur Cloudinary :**

1. Settings → Upload → Upload presets
2. Regardez à côté du nom du preset :

```
✓ CORRECT : nextmatch (unsigned)
✗ INCORRECT : nextmatch (signed)
```

**Dans le code :**

Si vous voyez cette erreur dans la console :
```
Upload preset not found
```
Ou :
```
Status 400 (Bad Request)
```

C'est probablement que le preset est en mode Signed au lieu de Unsigned.

---

#### Tableau Comparatif Complet

| Critère | UNSIGNED (Notre choix) | SIGNED (Alternatif) |
|---------|------------------------|---------------------|
| **Sécurité** | ⚠️ Moyenne | ✅ Élevée |
| **Complexité** | ✅ Simple | ❌ Complexe |
| **Vitesse** | ✅ Rapide (1 requête) | ⚠️ Plus lent (2 requêtes) |
| **Configuration** | ✅ 5 minutes | ⚠️ 30+ minutes |
| **Contrôle serveur** | ❌ Non | ✅ Oui |
| **Validation avant upload** | ❌ Non | ✅ Oui |
| **Bande passante serveur** | ✅ Aucune | ⚠️ Moyenne |
| **Adapté au dev** | ✅ Parfait | ⚠️ Overkill |
| **Adapté à la prod** | ⚠️ Avec modération | ✅ Idéal |
| **Traçabilité** | ⚠️ Limitée | ✅ Complète |
| **Protection contre abus** | ⚠️ Limitée | ✅ Totale |

---

#### Migration vers Signed (si besoin futur)

Si vous voulez migrer vers le mode Signed plus tard :

**Étape 1 : Créer l'endpoint de signature**

Le fichier `src/app/api/sign-image/route.ts` existe déjà dans le projet.

**Étape 2 : Changer le preset sur Cloudinary**

1. Aller sur le preset "nextmatch"
2. Changer **Signing mode** : Unsigned → **Signed**
3. Save

**Étape 3 : Le code n'a rien à changer**

Le composant `ImageUploadButton` est déjà configuré avec :
```typescript
signatureEndpoint='/api/sign-image'
```

Il basculera automatiquement en mode Signed !

---

#### Résumé pour les Débutants

**Mode UNSIGNED = "Ouvert mais surveillé"**
- N'importe qui peut uploader (avec le nom du preset)
- Mais les images sont modérées après
- Comme laisser sa porte ouverte mais avoir des caméras

**Mode SIGNED = "Fermé et contrôlé"**
- Seul votre serveur peut autoriser les uploads
- Vérification avant chaque upload
- Comme avoir une porte avec code d'accès

**Pour ce projet :**
👉 Utilisez **UNSIGNED** : C'est plus simple et suffisant grâce à notre système de modération (Awaiting approval)

### Vérifier la configuration .env

Assurez-vous que votre fichier `.env` contient :

```env
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="votre-cloud-name"
NEXT_PUBLIC_CLOUDINARY_API_KEY="votre-api-key"
CLOUDINARY_API_SECRET="votre-api-secret"
```

**Pour trouver ces valeurs :**

1. Sur la page d'accueil de Cloudinary (Dashboard)
2. Regardez la section **"Product Environment Credentials"** en haut
3. Vous y verrez :
   - **Cloud name** : (exemple : `dgxtwhibj`)
   - **API Key** : (exemple : `123456789012345`)
   - **API Secret** : Cliquez sur l'icône "œil" pour le révéler

**Copiez ces 3 valeurs dans votre `.env`**

### Redémarrer l'application

```powershell
# Arrêter le serveur (Ctrl + C)

# Supprimer le cache Next.js
Remove-Item -Recurse -Force .next

# Redémarrer
npm run dev
```

---

## Problème 4 : Configuration du Cluster Pusher

### Symptômes

La messagerie en temps réel ne fonctionne pas, ou vous voyez des erreurs de connexion Pusher dans la console.

### Cause

Le cluster Pusher dans le code ne correspond pas au cluster de votre application Pusher.

### Identification de votre cluster

Quand vous créez une app Pusher, vous choisissez un cluster :

| Cluster | Région |
|---------|--------|
| `mt1` | USA (Montana) |
| `us-east-1` | USA Est (Virginie) |
| `us-west-1` | USA Ouest (Californie) |
| `eu` | Europe (Irlande) |
| `ap1` | Asie-Pacifique (Singapour) |
| `ap2` | Asie-Pacifique (Mumbai) |

**Le code par défaut utilisait `ap1`, mais votre cluster est `mt1`.**

### Solution

#### Étape 1 : Identifier votre cluster sur Pusher

1. Allez sur https://dashboard.pusher.com
2. Connectez-vous
3. Sélectionnez votre app
4. Dans l'onglet **"App Keys"**, vous voyez votre cluster

**Dans votre cas :**
```
app_id = "131729"
key = "318b4c077abe583f2a04"
secret = "25e4ba58a50a61d46c98"
cluster = "mt1"  ← Votre cluster
```

#### Étape 2 : Ajouter les identifiants dans .env

Ajoutez ces lignes dans votre fichier `.env` :

```env
PUSHER_APP_ID="131729"
NEXT_PUBLIC_PUSHER_APP_KEY="318b4c077abe583f2a04"
PUSHER_SECRET="25e4ba58a50a61d46c98"
```

#### Étape 3 : Modifier le cluster dans le code

**Fichier à modifier :** `src/lib/pusher.ts`

**Changement effectué :**

```typescript
// AVANT (ne fonctionnait pas)
cluster: 'ap1'

// APRÈS (fonctionne avec votre app)
cluster: 'mt1'
```

**Code complet modifié :**

```typescript
if (!global.pusherServerInstance) {
    global.pusherServerInstance = new PusherServer({
        appId: process.env.PUSHER_APP_ID!,
        key: process.env.NEXT_PUBLIC_PUSHER_APP_KEY!,
        secret: process.env.PUSHER_SECRET!,
        cluster: 'mt1',  // ← Changé de 'ap1' à 'mt1'
        useTLS: true
    })
}

if (!global.pusherClientInstance) {
    global.pusherClientInstance = new PusherClient(process.env.NEXT_PUBLIC_PUSHER_APP_KEY!, {
        channelAuthorization: {
            endpoint: '/api/pusher-auth',
            transport: 'ajax'
        },
        cluster: 'mt1'  // ← Changé de 'ap1' à 'mt1'
    })
}
```

#### Étape 4 : Redémarrer

```powershell
# Ctrl + C pour arrêter
npm run dev
```

### Tester la messagerie temps réel

**Test avec 2 navigateurs :**

1. **Navigateur 1** : Connectez-vous avec `todd@test.com` / `password`
2. **Navigateur 2** (mode incognito) : Connectez-vous avec `lisa@test.com` / `password`
3. Dans le navigateur 1, cliquez sur le profil de Lisa → icône message
4. Envoyez un message
5. Dans le navigateur 2, allez dans MESSAGES
6. Le message devrait apparaître **instantanément** sans recharger la page

**Indicateurs de présence :**
- 🟢 Point vert = utilisateur en ligne
- ⚪ Point gris = utilisateur hors ligne

---

## Problème 5 : Status 400 (Bad Request) - Cloudinary

### Symptômes

Dans la console du navigateur (F12) :

```
Failed to load api.cloudinary.com/v../dgxtwhibj/upload:1
resource: the server responded with a status of 400 (Bad Request)
```

L'upload semble démarrer mais échoue immédiatement.

### Causes Possibles

1. Le preset n'existe pas
2. Le preset existe mais en mode "Signed" au lieu de "Unsigned"
3. Le Cloud Name est incorrect
4. Les variables d'environnement ne sont pas chargées

### Solution Complète

#### Vérification 1 : Cloud Name

Dans l'URL d'erreur, vous voyez votre cloud name : `dgxtwhibj`

Vérifiez dans `.env` :

```env
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="dgxtwhibj"
```

**Pas d'espace, pas de guillemets doubles à l'intérieur.**

#### Vérification 2 : Le preset existe et est "Unsigned"

1. Allez sur https://console.cloudinary.com
2. Settings → Upload → Upload presets
3. Vérifiez que vous voyez :

```
nextmatch (unsigned)
```

**Si vous voyez `(signed)` :**
- Supprimez le preset
- Recréez-le en choisissant **Signing mode: Unsigned**

#### Vérification 3 : Variables d'environnement chargées

Dans le terminal PowerShell, testez :

```powershell
# Tester si les variables sont chargées
node -e "console.log('Cloud Name:', process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME || 'NON DEFINI')"
```

**Si vous voyez "NON DEFINI" :**
- Le fichier `.env` n'est pas au bon endroit
- Il doit être à la **racine** du projet (même niveau que `package.json`)

#### Vérification 4 : Contenu complet du .env

Votre `.env` doit contenir au minimum :

```env
# Base de données
DATABASE_URL="votre-url-neon"

# NextAuth
AUTH_SECRET="votre-cle-generee"
NEXT_PUBLIC_BASE_URL="http://localhost:3000"

# Cloudinary
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="dgxtwhibj"
NEXT_PUBLIC_CLOUDINARY_API_KEY="votre-api-key"
CLOUDINARY_API_SECRET="votre-api-secret"

# Pusher
PUSHER_APP_ID="131729"
NEXT_PUBLIC_PUSHER_APP_KEY="318b4c077abe583f2a04"
PUSHER_SECRET="25e4ba58a50a61d46c98"
```

#### Solution finale : Nettoyage complet

```powershell
# 1. Arrêter le serveur (Ctrl + C)

# 2. Supprimer le cache Next.js
Remove-Item -Recurse -Force .next

# 3. Supprimer node_modules (optionnel, si problème persiste)
Remove-Item -Recurse -Force node_modules
npm install

# 4. Redémarrer
npm run dev
```

---

## Configuration Complète du Preset Cloudinary

### Guide Visuel Pas à Pas

#### Étape 1 : Connexion

```
1. Ouvrir https://console.cloudinary.com
2. Se connecter avec email/password ou GitHub
```

#### Étape 2 : Navigation vers Upload Presets

```
Dashboard → Icône engrenage (⚙️ Settings) → Onglet "Upload"
```

#### Étape 3 : Section Upload Presets

Descendez jusqu'à voir :

```
┌─────────────────────────────────────┐
│ Upload presets                       │
│                                      │
│ [Add upload preset]  [Enable...]    │
│                                      │
│ ┌─────────────────────────────────┐ │
│ │ Default preset (signed)         │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

#### Étape 4 : Cliquer sur "Add upload preset"

#### Étape 5 : Configuration du nouveau preset

```
┌────────────────────────────────────────┐
│ Upload Preset Configuration             │
├────────────────────────────────────────┤
│                                         │
│ Preset name*                            │
│ ┌────────────────────────────────────┐ │
│ │ nextmatch                          │ │
│ └────────────────────────────────────┘ │
│                                         │
│ Signing mode*                           │
│ ┌────────────────────────────────────┐ │
│ │ ○ Signed                           │ │
│ │ ● Unsigned  ← CHOISIR CELUI-CI    │ │
│ └────────────────────────────────────┘ │
│                                         │
│ Folder (optional)                       │
│ ┌────────────────────────────────────┐ │
│ │ nextmatch                          │ │
│ └────────────────────────────────────┘ │
│                                         │
│ ☑ Unique filename                      │
│ ☐ Overwrite                            │
│ ☐ Use filename                         │
│                                         │
│ Access mode                             │
│ ┌────────────────────────────────────┐ │
│ │ public                             │ │
│ └────────────────────────────────────┘ │
│                                         │
│               [Save]  [Cancel]          │
└────────────────────────────────────────┘
```

#### Étape 6 : Valeurs exactes à entrer

| Champ | Valeur à entrer | Obligatoire |
|-------|----------------|-------------|
| Preset name | `nextmatch` | OUI |
| Signing mode | **Unsigned** (cliquer sur le bouton radio) | OUI |
| Folder | `nextmatch` | Non (mais recommandé) |
| Unique filename | Coché ☑ | Non (mais recommandé) |
| Overwrite | Non coché ☐ | Recommandé |
| Access mode | `public` | Par défaut |

#### Étape 7 : Sauvegarder

1. Descendez en bas de la page
2. Cliquez sur le bouton **"Save"** (en haut à droite généralement)

#### Étape 8 : Vérification

Vous revenez à la liste. Vous devez voir :

```
┌─────────────────────────────────────┐
│ Upload presets                       │
│                                      │
│ ┌─────────────────────────────────┐ │
│ │ nextmatch (unsigned) ✓          │ │
│ │ Created: Just now                │ │
│ └─────────────────────────────────┘ │
│                                      │
│ ┌─────────────────────────────────┐ │
│ │ Default preset (signed)         │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Vérification critique :** Le mot **(unsigned)** doit apparaître.

### Options Avancées (Optionnelles)

Si vous voulez plus de contrôle, vous pouvez aussi configurer :

**Transformations automatiques :**
```
Width: 800
Height: 800
Crop: fill
Quality: auto
```

**Formats acceptés :**
```
☑ jpg, png, gif, webp
☐ pdf, svg
```

**Taille maximale :**
```
Max file size: 10 MB (par défaut)
```

---

## Vérifications Finales

### Checklist avant de tester

- [ ] Fichier `.env` existe à la racine du projet
- [ ] `DATABASE_URL` rempli avec l'URL Neon
- [ ] `AUTH_SECRET` généré et rempli
- [ ] Les 3 variables Cloudinary remplies
- [ ] Les 3 variables Pusher remplies
- [ ] Preset "nextmatch" créé sur Cloudinary en mode **Unsigned**
- [ ] Cluster Pusher modifié dans `src/lib/pusher.ts` (mt1)
- [ ] `npx prisma generate` exécuté
- [ ] `npx prisma migrate deploy` exécuté
- [ ] `npx prisma db seed` exécuté
- [ ] Application redémarrée avec `npm run dev`

### Test Complet de l'Application

#### Test 1 : Inscription et Profil

```
1. Aller sur http://localhost:3000
2. Cliquer sur "Register"
3. Créer un compte
4. Compléter le profil
5. ✓ Succès si vous arrivez sur la page MATCHES
```

#### Test 2 : Upload de Photo

```
1. Aller sur "Edit Profile" → "Update Photos"
2. Cliquer sur "Upload new image"
3. Sélectionner une image
4. ✓ Succès si l'image apparaît avec "Awaiting approval"
```

#### Test 3 : Modération (Admin)

```
1. Se déconnecter
2. Se connecter avec admin@test.com / password
3. Menu "ADMIN" ou aller sur /admin/moderation
4. Approuver la photo
5. ✓ Succès si la photo change de statut
```

#### Test 4 : Messagerie Temps Réel

```
1. Navigateur 1 : todd@test.com / password
2. Navigateur 2 (incognito) : lisa@test.com / password
3. Nav 1 : Cliquer sur Lisa → Message
4. Nav 1 : Envoyer "Hello"
5. Nav 2 : Aller dans MESSAGES
6. ✓ Succès si le message apparaît instantanément
```

#### Test 5 : Système de Likes

```
1. Page MATCHES
2. Cliquer sur ❤️ sur un profil
3. Aller dans LISTS
4. ✓ Succès si le profil apparaît dans "Members I have liked"
```

### Outils de Diagnostic

#### Prisma Studio

Voir toutes les données de la base :

```powershell
npx prisma studio
```

Ouvre http://localhost:5555

**Tables à vérifier :**
- `User` : Tous les utilisateurs
- `Member` : Les profils
- `Photo` : Photos avec statut `isApproved`
- `Message` : Messages échangés
- `Like` : Likes entre utilisateurs

#### Console du Navigateur

Appuyez sur **F12** pour ouvrir les DevTools.

**Onglet Console :** Voir les erreurs JavaScript
**Onglet Network :** Voir les requêtes HTTP (filtrer par "upload" pour Cloudinary)
**Onglet Application → Local Storage :** Voir les données stockées

#### Logs du Terminal

Le terminal où tourne `npm run dev` affiche :
- Les requêtes HTTP
- Les erreurs serveur
- Les logs Prisma (si activés)

---

## Checklist Complète de Démarrage

### Phase 1 : Préparation (30-45 minutes)

#### Services Externes à Créer

- [ ] **Neon** : Base de données PostgreSQL
  - Créer un compte sur https://neon.tech
  - Créer un projet
  - Copier l'URL de connexion (onglet Prisma)

- [ ] **Cloudinary** : Stockage d'images
  - Créer un compte sur https://cloudinary.com
  - Noter Cloud Name, API Key, API Secret
  - Créer un preset "nextmatch" en mode **Unsigned**

- [ ] **Pusher** : Messagerie temps réel
  - Créer un compte sur https://pusher.com
  - Créer une app
  - Noter App ID, Key, Secret, Cluster

- [ ] **Resend** : Emails (optionnel)
  - Créer un compte sur https://resend.com
  - Créer une API Key

- [ ] **Google OAuth** (optionnel)
  - Google Cloud Console
  - Créer un projet OAuth
  - Noter Client ID et Secret

- [ ] **GitHub OAuth** (optionnel)
  - GitHub Developer Settings
  - Créer une OAuth App
  - Noter Client ID et Secret

### Phase 2 : Configuration Locale

#### Fichier .env

- [ ] Créer le fichier `.env` à la racine
- [ ] Ajouter `DATABASE_URL` (Neon)
- [ ] Générer et ajouter `AUTH_SECRET`
  ```powershell
  node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
  ```
- [ ] Ajouter `NEXT_PUBLIC_BASE_URL="http://localhost:3000"`
- [ ] Ajouter les 3 variables Cloudinary
- [ ] Ajouter les 3 variables Pusher
- [ ] Ajouter `RESEND_API_KEY` (si configuré)
- [ ] Ajouter Google OAuth (si configuré)
- [ ] Ajouter GitHub OAuth (si configuré)

#### Modifications du Code

- [ ] Vérifier `src/components/ImageUploadButton.tsx`
  - Preset doit être `'nextmatch'`
  
- [ ] Vérifier `src/lib/pusher.ts`
  - Cluster doit correspondre à votre cluster Pusher

### Phase 3 : Initialisation

#### Base de Données

- [ ] Ouvrir un terminal dans le projet
- [ ] Exécuter : `npm install`
- [ ] Exécuter : `npx prisma generate`
- [ ] Exécuter : `npx prisma migrate deploy`
- [ ] Exécuter : `npx prisma db seed`

#### Démarrage

- [ ] Exécuter : `npm run dev`
- [ ] Ouvrir : http://localhost:3000
- [ ] Vérifier qu'aucune erreur n'apparaît

### Phase 4 : Tests

#### Test Basique

- [ ] Créer un compte
- [ ] Compléter le profil
- [ ] Voir la page MATCHES

#### Test Upload

- [ ] Aller dans Edit Profile → Photos
- [ ] Uploader une image
- [ ] Vérifier "Awaiting approval"

#### Test Admin

- [ ] Se déconnecter
- [ ] Se connecter avec admin@test.com / password
- [ ] Aller sur /admin/moderation
- [ ] Approuver la photo

#### Test Messagerie

- [ ] 2 navigateurs avec 2 comptes différents
- [ ] Envoyer un message
- [ ] Vérifier réception instantanée

#### Test Likes

- [ ] Liker un profil
- [ ] Vérifier dans LISTS

### Phase 5 : Outils de Développement

- [ ] Tester Prisma Studio : `npx prisma studio`
- [ ] Vérifier les DevTools du navigateur (F12)
- [ ] Lire les logs du terminal

---

## Récapitulatif des Commandes Importantes

### Commandes npm

```powershell
# Développement
npm run dev              # Démarrer en mode développement
npm run build            # Compiler pour la production
npm start                # Serveur de production (après build)
npm run lint             # Vérifier le code

# Installation
npm install              # Installer les dépendances
npm install --force      # Forcer la réinstallation
```

### Commandes Prisma

```powershell
# Client
npx prisma generate           # Générer le client TypeScript

# Migrations
npx prisma migrate dev        # Créer une migration (dev)
npx prisma migrate deploy     # Appliquer les migrations (prod)
npx prisma migrate reset      # Reset complet (supprime tout)

# Base de données
npx prisma db seed            # Peupler avec des données
npx prisma db pull            # Synchroniser depuis la BDD
npx prisma db push            # Pousser le schéma vers la BDD

# Outils
npx prisma studio             # Interface graphique
npx prisma validate           # Valider le schéma
npx prisma format             # Formater schema.prisma
```

### Commandes PowerShell Utiles

```powershell
# Nettoyage
Remove-Item -Recurse -Force .next        # Supprimer le cache Next.js
Remove-Item -Recurse -Force node_modules # Supprimer node_modules

# Variables d'environnement
$env:VARIABLE_NAME                       # Lire une variable
Get-Content .env                         # Voir le contenu de .env

# Processus
Get-Process node                         # Voir les processus Node
Stop-Process -Name node -Force           # Tuer tous les processus Node
```

---

## Ressources et Documentation

### Documentation Officielle

- **Next.js** : https://nextjs.org/docs
- **Prisma** : https://www.prisma.io/docs
- **NextAuth** : https://next-auth.js.org
- **Cloudinary** : https://cloudinary.com/documentation
- **Pusher** : https://pusher.com/docs
- **NextUI** : https://nextui.org

### Services Utilisés

- **Neon** : https://neon.tech/docs
- **Resend** : https://resend.com/docs

### Troubleshooting Officiels

- **Next.js Errors** : https://nextjs.org/docs/messages
- **Prisma Errors** : https://www.prisma.io/docs/reference/api-reference/error-reference
- **NextAuth Errors** : https://next-auth.js.org/errors

---

## Notes Importantes

### Sécurité

1. **Ne jamais commiter le fichier `.env`**
   - Déjà dans `.gitignore`
   - Contient des secrets

2. **Régénérer AUTH_SECRET en production**
   - Utilisez une valeur différente de celle du développement

3. **Utiliser des clés différentes pour chaque environnement**
   - Dev, staging, production

### Performance

1. **Mode développement est plus lent**
   - Normal, il recompile à chaque modification
   - Utilisez le mode production pour les tests de performance

2. **First load peut être long**
   - La première compilation prend du temps
   - Les rechargements suivants sont rapides

### Base de Données

1. **Neon gratuit a des limites**
   - 0.5 GB de stockage
   - 10 branches
   - Suffisant pour le développement

2. **Sauvegarder régulièrement**
   ```powershell
   npx prisma db pull > backup-schema.prisma
   ```

---

**Ce document couvre tous les problèmes rencontrés et leurs solutions détaillées.**

