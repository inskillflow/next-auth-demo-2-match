# Scripts d'Automatisation

Ce projet inclut plusieurs scripts pour faciliter l'installation et le démarrage.

---

## Scripts disponibles

### `setup.ps1` - Installation complète (PowerShell)

Script d'initialisation automatique du projet pour Windows PowerShell.

**Utilisation :**
```powershell
.\setup.ps1
```

**Ce qu'il fait :**
1.  Vérifie l'existence du fichier `.env`
2.  Génère le client Prisma
3.  Applique les migrations de base de données
4. 🌱 Peuple la base avec des données de test (seed)
5.  Installe/vérifie les dépendances npm

**Prérequis :**
- Fichier `.env` configuré
- PostgreSQL démarré
- Node.js installé

---

### `setup.bat` - Installation complète (Batch)

Alternative au script PowerShell pour CMD/Command Prompt.

**Utilisation :**
```cmd
setup.bat
```

**Fonctionnalités identiques à `setup.ps1`**

---

### `start-dev.bat` - Démarrage rapide

Lance directement le serveur de développement après vérification du `.env`.

**Utilisation :**
```cmd
start-dev.bat
```

**Ce qu'il fait :**
1.  Vérifie que `.env` existe
2.  Lance `npm run dev`
3. 🌐 Ouvre automatiquement http://localhost:3000

**Idéal pour :** Démarrage quotidien après la première installation.

---

## Workflow recommandé

### Première installation

```powershell
# 1. Créer le fichier .env (voir documentation/02-configuration-environnement.md)

# 2. Démarrer PostgreSQL
docker compose up -d

# 3. Exécuter le script d'installation
.\setup.ps1

# 4. Démarrer le serveur de développement
npm run dev
```

### Démarrage quotidien

```cmd
# 1. Démarrer PostgreSQL (si nécessaire)
docker compose up -d

# 2. Lancer l'application
start-dev.bat
```

---

## Commandes npm détaillées

### `npm run dev`
Lance le serveur de développement avec hot-reload.

```powershell
npm run dev
```

**Caractéristiques :**
-  Hot-reload automatique
-  Messages d'erreur détaillés
- 🌐 Accessible sur http://localhost:3000

### `npm run build`
Compile l'application pour la production.

```powershell
npm run build
```

**Crée :**
- Dossier `.next/` optimisé
- Bundles JavaScript minifiés
- Pages statiques pré-rendues

### `npm start`
Lance le serveur de production (nécessite un build).

```powershell
npm run build
npm start
```

** Important :** Ne peut pas être utilisé sans avoir exécuté `npm run build` avant.

### `npm run lint`
Vérifie le code avec ESLint.

```powershell
npm run lint
```

### `npm run vercel-build`
Build spécial pour le déploiement Vercel.

```powershell
npm run vercel-build
```

**Exécute automatiquement :**
1. `prisma generate`
2. `prisma migrate deploy`
3. `prisma db seed`
4. `next build`

---

## Commandes Prisma

### Générer le client
Génère le client TypeScript pour accéder à la base de données.

```powershell
npx prisma generate
```

**Quand l'utiliser :**
- Après modification de `schema.prisma`
- Après `npm install` sur un nouveau projet

### Créer une migration
Crée une nouvelle migration basée sur les changements du schéma.

```powershell
npx prisma migrate dev --name nom_de_la_migration
```

**Exemple :**
```powershell
npx prisma migrate dev --name add_user_bio
```

### Appliquer les migrations
Applique toutes les migrations en attente.

```powershell
# Développement
npx prisma migrate dev

# Production
npx prisma migrate deploy
```

### Reset de la base de données
** ATTENTION : Supprime toutes les données !**

```powershell
npx prisma migrate reset
```

**Réexécute automatiquement :**
1. Suppression de la BDD
2. Recréation de la BDD
3. Migrations
4. Seed

### Prisma Studio
Interface graphique pour visualiser et éditer les données.

```powershell
npx prisma studio
```

**Accessible sur :** http://localhost:5555

### Peupler la base de données
Exécute le script de seed pour insérer des données de test.

```powershell
npx prisma db seed
```

**Script utilisé :** `prisma/seed.ts`

---

## Commandes Docker

### Démarrer PostgreSQL

```powershell
docker compose up -d
```

**Flags :**
- `-d` : Mode détaché (en arrière-plan)

### Arrêter PostgreSQL

```powershell
docker compose down
```

### Voir les logs

```powershell
docker compose logs -f
```

**Flags :**
- `-f` : Mode suivi (affiche les nouveaux logs en temps réel)

### Voir le statut

```powershell
docker compose ps
```

### Redémarrer

```powershell
docker compose restart
```

### Supprimer les volumes (reset complet)

** ATTENTION : Supprime toutes les données de la BDD !**

```powershell
docker compose down -v
```

---

## Scripts de diagnostic

### Vérifier la connexion PostgreSQL

```powershell
npx prisma db pull
```

Si la connexion fonctionne, le schéma sera synchronisé.

### Afficher la version de Node.js

```powershell
node --version
```

**Minimum requis :** v18.0.0 ou supérieur

### Afficher la version de npm

```powershell
npm --version
```

### Vérifier les dépendances obsolètes

```powershell
npm outdated
```

### Mettre à jour les dépendances

```powershell
npm update
```

---

## Scripts personnalisés

### Créer un script personnalisé

Ajoutez dans `package.json` :

```json
{
  "scripts": {
    "db:reset": "npx prisma migrate reset --force",
    "db:studio": "npx prisma studio",
    "dev:clean": "rm -rf .next && npm run dev"
  }
}
```

**Utilisation :**
```powershell
npm run db:reset
npm run db:studio
npm run dev:clean
```

---

## Raccourcis clavier utiles

### Dans le terminal (npm run dev)

| Raccourci | Action |
|-----------|--------|
| `Ctrl + C` | Arrêter le serveur |
| `R` | Redémarrer le serveur |
| `O` | Ouvrir dans le navigateur |

### Dans Prisma Studio

| Raccourci | Action |
|-----------|--------|
| `Ctrl + K` | Recherche rapide |
| `Ctrl + N` | Nouvelle ligne |
| `Ctrl + S` | Sauvegarder |

---

## Ressources

- [Next.js CLI](https://nextjs.org/docs/api-reference/cli)
- [Prisma CLI](https://www.prisma.io/docs/reference/api-reference/command-reference)
- [Docker Compose CLI](https://docs.docker.com/compose/reference/)

