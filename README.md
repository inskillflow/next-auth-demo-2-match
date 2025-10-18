# Next Match - Application de Rencontres

Une application de rencontres moderne construite avec **Next.js 14**, **Prisma**, **PostgreSQL** et **NextAuth**.

![Next.js](https://img.shields.io/badge/Next.js-14.2.1-black?logo=next.js)
![React](https://img.shields.io/badge/React-18-blue?logo=react)
![TypeScript](https://img.shields.io/badge/TypeScript-5-blue?logo=typescript)
![Prisma](https://img.shields.io/badge/Prisma-5.11-2D3748?logo=prisma)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-13+-336791?logo=postgresql)

---

## Fonctionnalités

- **Authentification complète** (Email/Password, Google, GitHub)
- **Profils utilisateurs** avec photos et informations personnelles
- **Système de likes** bidirectionnel
- **Messagerie instantanée** en temps réel (Pusher)
- **Présence en ligne** des utilisateurs
- **Upload de photos** via Cloudinary
- **Panel d'administration** avec modération
- **Vérification email** et réinitialisation de mot de passe
- **Interface moderne** avec Tailwind CSS et NextUI

---

## Démarrage Rapide

### Prérequis

- **Node.js** 18+ ([Télécharger](https://nodejs.org/))
- **PostgreSQL** (via [Docker](https://www.docker.com/products/docker-desktop/) ou [installation directe](https://www.postgresql.org/download/windows/))
- **npm** ou **yarn**

### Installation en 3 étapes

#### Étape 1 : Créer le fichier `.env`

Créez un fichier `.env` à la racine :

```env
# Database
DATABASE_URL="postgresql://postgres:postgrespw@localhost:5432/nextmatch"

# NextAuth (générez avec: node -e "console.log(require('crypto').randomBytes(32).toString('base64'))")
AUTH_SECRET="votre-cle-secrete"
NEXT_PUBLIC_BASE_URL="http://localhost:3000"
```

#### Étape 2 : Démarrer PostgreSQL

```bash
# Avec Docker
docker compose up -d
```

#### Étape 3 : Initialiser et lancer

**Windows PowerShell :**
```powershell
.\setup.ps1      # Installation automatique
npm run dev      # Démarrer l'application
```

**Windows CMD :**
```cmd
setup.bat        # Installation automatique
npm run dev      # Démarrer l'application
```

**Ou manuellement :**
```bash
npx prisma generate
npx prisma migrate deploy
npx prisma db seed
npm run dev
```

Ouvrez [http://localhost:3000](http://localhost:3000)

---

## Documentation Complète

La documentation détaillée est disponible dans le dossier [`documentation/`](./documentation/) :

| Document | Description |
|----------|-------------|
| **[Guide de Démarrage](./documentation/01-guide-demarrage.md)** | Installation et configuration complètes |
| **[Configuration Environnement](./documentation/02-configuration-environnement.md)** | Variables d'environnement et services externes |
| **[Scripts d'Automatisation](./documentation/03-scripts-automatisation.md)** | Utilisation des scripts et commandes |
| **[Architecture du Projet](./documentation/04-architecture-projet.md)** | Structure du code et patterns |
| **[Troubleshooting](./documentation/05-troubleshooting.md)** | Résolution des problèmes courants |

---

## Stack Technique

### Frontend
- **Next.js 14** - App Router, Server Components, Server Actions
- **React 18** - Bibliothèque UI
- **TypeScript** - Typage statique
- **Tailwind CSS** - Styles utilitaires
- **NextUI** - Composants UI modernes
- **Framer Motion** - Animations
- **React Hook Form** + **Zod** - Formulaires et validation

### Backend
- **Next.js API Routes** - Endpoints REST
- **NextAuth v5** - Authentification
- **Prisma** - ORM TypeScript
- **PostgreSQL** - Base de données relationnelle

### Services Externes (optionnels)
- **Cloudinary** - Stockage et transformation d'images
- **Pusher** - WebSockets temps réel
- **Resend** - Service d'envoi d'emails

---

## Scripts NPM

```bash
# Développement
npm run dev          # Serveur de développement avec hot-reload

# Production
npm run build        # Compiler l'application
npm start            # Lancer le serveur de production

# Base de données
npx prisma studio           # Interface graphique BDD
npx prisma migrate dev      # Créer une migration
npx prisma migrate deploy   # Appliquer les migrations
npx prisma db seed          # Peupler avec des données test

# Qualité
npm run lint         # Vérifier le code avec ESLint
```

---

## Docker

Le projet inclut une configuration Docker pour PostgreSQL :

```bash
# Démarrer PostgreSQL
docker compose up -d

# Arrêter
docker compose down

# Voir les logs
docker compose logs -f
```

---

## Structure du Projet

```
01-next-match-main-1/
├── src/
│   ├── app/              # Pages et routes (App Router)
│   ├── components/       # Composants React réutilisables
│   ├── lib/              # Utilitaires et configurations
│   ├── hooks/            # Hooks React personnalisés
│   └── types/            # Définitions TypeScript
├── prisma/
│   ├── schema.prisma     # Schéma de base de données
│   └── seed.ts           # Données de test
├── public/               # Fichiers statiques
├── documentation/        # Documentation complète
├── docker-compose.yml    # Configuration Docker
└── package.json          # Dépendances et scripts
```

---

## Configuration

### Variables d'environnement obligatoires

```env
DATABASE_URL="postgresql://..."
AUTH_SECRET="..."
NEXT_PUBLIC_BASE_URL="http://localhost:3000"
```

### Variables optionnelles (pour toutes les fonctionnalités)

```env
# OAuth
GOOGLE_CLIENT_ID=""
GOOGLE_CLIENT_SECRET=""
GITHUB_CLIENT_ID=""
GITHUB_CLIENT_SECRET=""

# Services
RESEND_API_KEY=""
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=""
NEXT_PUBLIC_CLOUDINARY_API_KEY=""
CLOUDINARY_API_SECRET=""
PUSHER_APP_ID=""
NEXT_PUBLIC_PUSHER_APP_KEY=""
PUSHER_SECRET=""
```

Voir la [documentation complète sur la configuration](./documentation/02-configuration-environnement.md).

---

## Problèmes Courants

### "Could not find a production build"
Solution : Utilisez `npm run dev` pour le développement (pas `npm start`)

### "Can't reach database server"
Solution : Démarrez PostgreSQL avec `docker compose up -d`

### "AUTH_SECRET is not set"
Solution : Générez une clé avec `node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"`

Pour plus de solutions, consultez le [Guide de Troubleshooting](./documentation/05-troubleshooting.md).

---

## Captures d'écran

*(À ajouter : captures d'écran de l'application)*

---

## Contribution

Les contributions sont les bienvenues ! Consultez d'abord la [documentation architecture](./documentation/04-architecture-projet.md).

---

## Licence

Ce projet est à but éducatif.

---

## Ressources

- [Next.js Documentation](https://nextjs.org/docs)
- [Prisma Documentation](https://www.prisma.io/docs)
- [NextAuth Documentation](https://next-auth.js.org)
- [NextUI Documentation](https://nextui.org)

---

**Développé avec Next.js**
