# Architecture du Projet

## Structure des dossiers

```
01-next-match-main-1/
│
├── 📂 src/                          # Code source principal
│   ├── 📂 app/                      # App Router Next.js 14
│   │   ├── 📂 (auth)/               # Groupe de routes authentification
│   │   │   ├── login/               # Page de connexion
│   │   │   ├── register/            # Page d'inscription
│   │   │   ├── verify-email/        # Vérification email
│   │   │   ├── forgot-password/     # Mot de passe oublié
│   │   │   ├── reset-password/      # Réinitialisation mot de passe
│   │   │   └── complete-profile/    # Complétion du profil
│   │   │
│   │   ├── 📂 actions/              # Server Actions
│   │   │   ├── authActions.ts       # Actions d'authentification
│   │   │   ├── memberActions.ts     # Actions membres
│   │   │   ├── likeActions.ts       # Actions likes
│   │   │   ├── messageActions.ts    # Actions messages
│   │   │   ├── userActions.ts       # Actions utilisateurs
│   │   │   └── adminActions.ts      # Actions admin
│   │   │
│   │   ├── 📂 api/                  # API Routes
│   │   │   ├── auth/[...nextauth]/  # NextAuth endpoint
│   │   │   ├── pusher-auth/         # Auth Pusher
│   │   │   └── sign-image/          # Signature Cloudinary
│   │   │
│   │   ├── 📂 members/              # Pages membres
│   │   │   ├── [userId]/            # Profil utilisateur dynamique
│   │   │   │   ├── chat/            # Messagerie
│   │   │   │   ├── photos/          # Photos du membre
│   │   │   │   └── page.tsx         # Page profil
│   │   │   ├── edit/                # Édition profil
│   │   │   └── page.tsx             # Liste des membres
│   │   │
│   │   ├── 📂 messages/             # Messagerie
│   │   ├── 📂 lists/                # Listes (likes, matched)
│   │   ├── 📂 admin/                # Administration
│   │   │   └── moderation/          # Modération photos
│   │   │
│   │   ├── layout.tsx               # Layout principal
│   │   ├── page.tsx                 # Page d'accueil
│   │   ├── globals.css              # Styles globaux
│   │   ├── loading.tsx              # Composant de chargement
│   │   └── error.tsx                # Gestion des erreurs
│   │
│   ├── 📂 components/               # Composants réutilisables
│   │   ├── 📂 navbar/               # Composants navigation
│   │   │   ├── TopNav.tsx
│   │   │   ├── UserMenu.tsx
│   │   │   ├── Filters.tsx
│   │   │   └── FiltersWrapper.tsx
│   │   │
│   │   ├── CardWrapper.tsx
│   │   ├── LikeButton.tsx
│   │   ├── MemberImage.tsx
│   │   ├── PresenceAvatar.tsx
│   │   └── ...
│   │
│   ├── 📂 hooks/                    # Hooks personnalisés
│   │   ├── useMessages.tsx          # Hook messages
│   │   ├── useMessageStore.ts       # Store messages (Zustand)
│   │   ├── usePresenceChannel.ts    # Hook présence Pusher
│   │   ├── usePresenceStore.ts      # Store présence
│   │   ├── useFilters.ts            # Hook filtres
│   │   └── useRole.ts               # Hook rôle utilisateur
│   │
│   ├── 📂 lib/                      # Bibliothèques et utilitaires
│   │   ├── 📂 schemas/              # Schémas de validation Zod
│   │   │   ├── loginSchema.ts
│   │   │   ├── registerSchema.ts
│   │   │   ├── messageSchema.ts
│   │   │   └── ...
│   │   │
│   │   ├── prisma.ts                # Client Prisma
│   │   ├── cloudinary.ts            # Configuration Cloudinary
│   │   ├── pusher.ts                # Configuration Pusher
│   │   ├── mail.ts                  # Service email (Resend)
│   │   ├── tokens.ts                # Gestion tokens
│   │   ├── mappings.ts              # Transformations données
│   │   └── util.ts                  # Fonctions utilitaires
│   │
│   ├── 📂 types/                    # Définitions TypeScript
│   │   ├── index.d.ts               # Types globaux
│   │   └── next-auth.d.ts           # Extension types NextAuth
│   │
│   ├── auth.ts                      # Configuration NextAuth
│   ├── auth.config.ts               # Config providers NextAuth
│   ├── middleware.ts                # Middleware Next.js
│   └── routes.ts                    # Définition des routes
│
├── 📂 prisma/                       # Prisma ORM
│   ├── schema.prisma                # Schéma de base de données
│   ├── seed.ts                      # Données de test
│   ├── membersData.ts               # Données membres test
│   └── 📂 migrations/               # Historique migrations
│
├── 📂 public/                       # Fichiers statiques
│   ├── 📂 images/                   # Images (avatars test)
│   ├── next.svg
│   └── vercel.svg
│
├── 📂 documentation/                # Documentation projet
│   ├── 01-guide-demarrage.md
│   ├── 02-configuration-environnement.md
│   ├── 03-scripts-automatisation.md
│   └── 04-architecture-projet.md
│
├── 📄 .env                          # Variables d'environnement (à créer)
├── 📄 .gitignore                    # Fichiers ignorés par Git
├── 📄 docker-compose.yml            # Configuration Docker
├── 📄 next.config.mjs               # Configuration Next.js
├── 📄 tailwind.config.ts            # Configuration Tailwind CSS
├── 📄 tsconfig.json                 # Configuration TypeScript
├── 📄 package.json                  # Dépendances et scripts
├── 📄 setup.ps1                     # Script installation (PowerShell)
├── 📄 setup.bat                     # Script installation (Batch)
└── 📄 start-dev.bat                 # Script démarrage rapide
```

---

## Flux de données

### 1. Authentification

```
User Input
    ↓
LoginForm/RegisterForm (Client Component)
    ↓
Server Action (authActions.ts)
    ↓
NextAuth (auth.ts)
    ↓
Prisma → PostgreSQL
    ↓
Session JWT
    ↓
Protected Routes (middleware.ts)
```

### 2. Actions CRUD

```
User Interaction
    ↓
Client Component (Button, Form, etc.)
    ↓
Server Action (actions/*.ts)
    ↓
Validation (Zod schema)
    ↓
Prisma Client
    ↓
PostgreSQL
    ↓
Revalidation/Redirect
    ↓
UI Update
```

### 3. Temps réel (Messages)

```
User sends message
    ↓
Server Action (messageActions.ts)
    ↓
Save to DB (Prisma)
    ↓
Trigger Pusher event
    ↓
Pusher Server
    ↓
All connected clients (usePresenceChannel)
    ↓
Update UI (useMessageStore)
```

---

## Schéma de base de données

### Tables principales

#### **User**
- Authentification et informations de base
- Lien avec `Member` pour le profil public

#### **Member**
- Profil public de l'utilisateur
- Informations affichées (bio, photos, etc.)

#### **Photo**
- Photos uploadées par les membres
- Système d'approbation (`isApproved`)

#### **Like**
- Relations "like" entre membres
- Table de jointure (source → target)

#### **Message**
- Messages entre membres
- Soft delete (sender/recipient deleted flags)

#### **Token**
- Tokens de vérification email
- Tokens de réinitialisation mot de passe

#### **Account**
- Comptes OAuth liés (Google, GitHub)

### Relations

```
User (1) ←→ (1) Member
Member (1) ←→ (N) Photo
Member (N) ←→ (N) Like
Member (N) ←→ (N) Message
User (1) ←→ (N) Account
```

---

## Stack technique

### Frontend
- **Next.js 14** - Framework React avec App Router
- **React 18** - Bibliothèque UI
- **TypeScript** - Typage statique
- **Tailwind CSS** - Styles utilitaires
- **NextUI** - Composants UI (boutons, modals, etc.)
- **Framer Motion** - Animations
- **React Hook Form** - Gestion de formulaires
- **Zod** - Validation de schémas

### Backend
- **Next.js API Routes** - Endpoints API
- **Server Actions** - Actions serveur
- **NextAuth v5** - Authentification
- **Prisma** - ORM
- **PostgreSQL** - Base de données

### Services externes
- **Cloudinary** - Stockage et transformation d'images
- **Pusher** - WebSockets temps réel
- **Resend** - Envoi d'emails

### Outils
- **Docker** - Conteneurisation (PostgreSQL)
- **ESLint** - Linter
- **Prisma Studio** - Interface BDD

---

## Sécurité

### Authentification
- **NextAuth JWT** - Sessions sécurisées
- **bcryptjs** - Hash des mots de passe
- **Tokens** - Vérification email et reset password

### Protection des routes
- **Middleware** - Protection routes (middleware.ts)
- **Server Actions** - Vérification session serveur
- **Roles** - ADMIN / MEMBER

### API
- **CSRF Protection** - NextAuth automatique
- **Rate limiting** - À implémenter (recommandé)
- **Input validation** - Zod sur toutes les entrées

---

## Performance

### Optimisations Next.js
- **Static Generation** - Pages pré-rendues
- **Incremental Static Regeneration** - Revalidation
- **Image Optimization** - next/image
- **Code Splitting** - Chargement lazy

### Base de données
- **Indexes** - Sur les clés étrangères
- **Connection Pooling** - Prisma
- **Queries optimisées** - Select uniquement les champs nécessaires

### Caching
- **Next.js cache** - fetch() et Server Actions
- **Revalidation** - revalidatePath/revalidateTag

---

## Dépendances principales

### Production
```json
{
  "@nextui-org/react": "2.3.6",       // Composants UI
  "@prisma/client": "^5.11.0",        // Client BDD
  "next": "14.2.1",                   // Framework
  "next-auth": "^5.0.0-beta.15",      // Auth
  "next-cloudinary": "^6.3.0",        // Cloudinary
  "pusher": "^5.2.0",                 // WebSockets serveur
  "pusher-js": "^8.4.0-rc2",          // WebSockets client
  "react-hook-form": "^7.51.1",       // Formulaires
  "zod": "^3.22.4",                   // Validation
  "zustand": "^4.5.2"                 // State management
}
```

### Développement
```json
{
  "prisma": "^5.11.0",                // CLI Prisma
  "typescript": "^5",                 // TypeScript
  "tailwindcss": "^3.3.0",            // Styles
  "@types/*": "...",                  // Types TypeScript
  "eslint": "^8"                      // Linter
}
```

---

## Patterns utilisés

### Server Components vs Client Components
- **Server Components** (défaut) - Fetching data, layout
- **Client Components** (`"use client"`) - Interactivité, hooks

### Server Actions
- Fonctions serveur directement appelables depuis le client
- Remplacement des API routes pour les mutations

### State Management
- **Zustand** - Global state (messages, filters, presence)
- **React Hook Form** - State formulaires
- **NextAuth** - State authentification

### Validation
- **Zod schemas** - Validation côté serveur et client
- **Type-safe** - Types TypeScript générés automatiquement

---

## Ressources

- [Next.js Documentation](https://nextjs.org/docs)
- [Prisma Documentation](https://www.prisma.io/docs)
- [NextAuth Documentation](https://next-auth.js.org)
- [NextUI Documentation](https://nextui.org)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)

