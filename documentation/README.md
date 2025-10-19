# Documentation Next Match

Bienvenue dans la documentation complète du projet **Next Match** !

---

## Table des matières

| Document | Description |
|----------|-------------|
| [01 - Guide de Démarrage](./01-guide-demarrage.md) | Installation et premier lancement du projet |
| [02 - Configuration Environnement](./02-configuration-environnement.md) | Configuration du fichier `.env` et services externes |
| [03 - Scripts d'Automatisation](./03-scripts-automatisation.md) | Utilisation des scripts et commandes disponibles |
| [04 - Architecture du Projet](./04-architecture-projet.md) | Structure du code et patterns utilisés |
| [05 - Troubleshooting](./05-troubleshooting.md) | Résolution des problèmes courants |
| [06 - Docker Compose](./06-docker-compose.md) | Configuration et utilisation de Docker Compose avec PostgreSQL |
| [07 - Guide Débutant Sans Docker](./07-guide-debutant-sans-docker.md) | Configuration complète étape par étape avec Neon, Cloudinary, Pusher, Resend |
| [08 - Troubleshooting Session](./08-troubleshooting-session.md) | Solutions détaillées de tous les problèmes rencontrés avec preset Cloudinary |
| [09 - Troubleshooting Emails Resend](./09-troubleshooting-emails-resend.md) | Configuration complète de Resend et résolution des problèmes d'envoi d'emails |
| [10 - Analyse Stack MVP](./10-analyse-stack-mvp.md) | Évaluation détaillée des services pour un MVP professionnel et alternatives |
| [11 - Optimisation Performance](./11-optimisation-performance-latence.md) | Résolution des problèmes de latence et optimisation de la connexion base de données |
| [12 - Comparaison Neon vs Supabase](./12-comparaison-neon-vs-supabase.md) | Analyse complète des performances, fonctionnalités et guide de migration |

---

## Démarrage rapide

### Vous êtes débutant ou n'avez pas Docker ?

**RECOMMANDÉ :** Suivez le [Guide Débutant Sans Docker](./07-guide-debutant-sans-docker.md)

Ce guide vous explique TOUT en détail, étape par étape :
- Créer votre base de données avec Neon
- Configurer Cloudinary pour les images
- Configurer Pusher pour la messagerie
- Configurer Resend pour les emails
- Créer le fichier `.env`
- Démarrer l'application

### Vous avez Docker et êtes à l'aise ?

1. **Lisez :** [01 - Guide de Démarrage](./01-guide-demarrage.md)
2. **Configurez :** [02 - Configuration Environnement](./02-configuration-environnement.md)
3. **Lancez :** Exécutez `setup.ps1` ou `setup.bat`
4. **Démarrez :** `npm run dev`

### Un problème ?

Consultez : [05 - Troubleshooting](./05-troubleshooting.md)

---

## À propos du projet

**Next Match** est une application de rencontres moderne construite avec :

- **Next.js 14** - Framework React avec App Router
- **PostgreSQL** - Base de données relationnelle
- **NextAuth v5** - Authentification complète
- **Cloudinary** - Gestion d'images
- **Pusher** - Messagerie temps réel
- **Tailwind CSS** & **NextUI** - Interface moderne

---

## Fonctionnalités principales

- Inscription et connexion (email/password, Google, GitHub)
- Profils utilisateurs avec photos
- Système de likes bidirectionnel
- Messagerie instantanée
- Présence en ligne
- Panel d'administration
- Modération de contenu
- Emails de vérification

---

## Commandes essentielles

```powershell
# Développement
npm run dev

# Production
npm run build
npm start

# Base de données
npx prisma studio       # Interface graphique
npx prisma migrate dev  # Nouvelle migration

# Docker
docker compose up -d    # Démarrer PostgreSQL
docker compose down     # Arrêter
```

---

## Structure de la documentation

```
documentation/
├── README.md                           # Ce fichier
├── 01-guide-demarrage.md              # Installation et premiers pas
├── 02-configuration-environnement.md  # Variables d'environnement
├── 03-scripts-automatisation.md       # Scripts et commandes
├── 04-architecture-projet.md          # Architecture et stack technique
├── 05-troubleshooting.md              # Dépannage
├── 06-docker-compose.md               # Docker Compose et PostgreSQL
├── 07-guide-debutant-sans-docker.md   # Guide complet pour débutants sans Docker
├── 08-troubleshooting-session.md      # Résolution détaillée des problèmes (preset, cluster, etc.)
├── 09-troubleshooting-emails-resend.md # Configuration Resend et envoi d'emails
├── 10-analyse-stack-mvp.md            # Évaluation des services pour un MVP professionnel
├── 11-optimisation-performance-latence.md # Optimisation performance et résolution latence BDD
└── 12-comparaison-neon-vs-supabase.md # Comparaison détaillée Neon vs Supabase avec migration
```

---

## Liens utiles

### Documentation officielle
- [Next.js](https://nextjs.org/docs)
- [Prisma](https://www.prisma.io/docs)
- [NextAuth](https://next-auth.js.org)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [NextUI](https://nextui.org)

### Services externes
- [Cloudinary](https://cloudinary.com)
- [Pusher](https://pusher.com)
- [Resend](https://resend.com)
- [Supabase](https://supabase.com) (alternative PostgreSQL)

### Outils
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [PostgreSQL](https://www.postgresql.org/download/windows/)
- [VS Code](https://code.visualstudio.com)

---

## Contribution

Pour contribuer au projet :

1. Lisez d'abord [04 - Architecture](./04-architecture-projet.md)
2. Suivez les conventions de code existantes
3. Testez vos modifications
4. Documentez les nouvelles fonctionnalités

---

## Support

Besoin d'aide ?

1. Consultez [05 - Troubleshooting](./05-troubleshooting.md)
2. Vérifiez les [Issues GitHub](../../issues)
3. Lisez la documentation des technologies utilisées

---

## Versions

- **Next.js** : 14.2.1
- **React** : 18
- **Node.js** : >= 18
- **PostgreSQL** : 13+
- **Prisma** : 5.11.0

---

## Licence

Ce projet est à but éducatif.

---

**Bonne lecture et bon développement !**

*Dernière mise à jour : Octobre 2024*
