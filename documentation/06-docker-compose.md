# Docker Compose et PostgreSQL

## Configuration avec Docker Compose

Votre projet utilise Docker Compose pour PostgreSQL. Cette configuration est déjà prête et fonctionne parfaitement.

---

## Fichier docker-compose.yml

```yaml
services:
  postgres:
    image: postgres
    environment:
      - POSTGRES_PASSWORD=postgrespw
    ports: 
      - 5432:5432
```

### Explication

- **image: postgres** - Utilise l'image officielle PostgreSQL
- **POSTGRES_PASSWORD** - Mot de passe du super-utilisateur `postgres`
- **ports: 5432:5432** - Expose le port PostgreSQL sur votre machine Windows
  - Format : `port_hôte:port_conteneur`
  - Accessible via `localhost:5432`

---

## Configuration DATABASE_URL

Avec Docker Compose, votre URL de connexion dans `.env` doit être :

```env
DATABASE_URL="postgresql://postgres:postgrespw@localhost:5432/nextmatch"
```

### Détails de l'URL

```
postgresql://[utilisateur]:[mot_de_passe]@[hôte]:[port]/[nom_base_de_données]
```

- **utilisateur** : `postgres` (par défaut)
- **mot_de_passe** : `postgrespw` (défini dans docker-compose.yml)
- **hôte** : `localhost` (grâce au mapping de ports)
- **port** : `5432` (port standard PostgreSQL)
- **nom_base_de_données** : `nextmatch` (sera créé automatiquement par Prisma)

---

## Commandes Docker Compose

### Démarrer PostgreSQL

```powershell
docker compose up -d
```

**Flags :**
- `-d` : Mode détaché (en arrière-plan)

### Vérifier le statut

```powershell
docker compose ps
```

**Sortie attendue :**
```
NAME                IMAGE      STATUS         PORTS
postgres-1          postgres   Up 2 minutes   0.0.0.0:5432->5432/tcp
```

### Voir les logs

```powershell
docker compose logs -f
```

**Flags :**
- `-f` : Mode suivi (affiche les nouveaux logs en temps réel)

### Arrêter PostgreSQL

```powershell
docker compose down
```

**Note :** Les données restent persistées même après l'arrêt.

### Redémarrer

```powershell
docker compose restart
```

---

## Workflow complet

### Première fois

```powershell
# 1. Démarrer PostgreSQL
docker compose up -d

# 2. Vérifier que c'est démarré
docker compose ps

# 3. Générer le client Prisma
npx prisma generate

# 4. Créer la base de données et appliquer les migrations
npx prisma migrate deploy

# 5. Peupler avec des données de test (optionnel)
npx prisma db seed

# 6. Démarrer l'application
npm run dev
```

### Démarrage quotidien

```powershell
# 1. Démarrer PostgreSQL (si arrêté)
docker compose up -d

# 2. Démarrer l'application
npm run dev
```

---

## Vérification de la connexion

### Avec Prisma

```powershell
npx prisma db pull
```

**Succès :** Affiche "Prisma schema loaded from prisma\schema.prisma"

**Échec :** Affiche "Error: P1001: Can't reach database server"

### Avec Prisma Studio

```powershell
npx prisma studio
```

Ouvre une interface graphique sur http://localhost:5555

---

## Accès direct à PostgreSQL

### Avec psql (si installé)

```powershell
psql -h localhost -U postgres -p 5432
```

Mot de passe : `postgrespw`

### Avec Docker exec

```powershell
docker compose exec postgres psql -U postgres
```

**Commandes SQL utiles :**
```sql
-- Lister les bases de données
\l

-- Se connecter à nextmatch
\c nextmatch

-- Lister les tables
\dt

-- Quitter
\q
```

---

## Gestion des données

### Sauvegarder les données

```powershell
docker compose exec postgres pg_dump -U postgres nextmatch > backup.sql
```

### Restaurer les données

```powershell
Get-Content backup.sql | docker compose exec -T postgres psql -U postgres nextmatch
```

### Reset complet de la base de données

**Option A : Avec Prisma (recommandé)**
```powershell
npx prisma migrate reset
```
Supprime et recrée la base, applique les migrations, exécute le seed.

**Option B : Avec Docker (supprime tout)**
```powershell
docker compose down -v
docker compose up -d
npx prisma migrate deploy
npx prisma db seed
```

Le flag `-v` supprime également les volumes (données persistées).

---

## Persistance des données

### Où sont stockées les données ?

Par défaut, Docker Compose utilise un **volume anonyme** pour persister les données PostgreSQL.

### Voir les volumes

```powershell
docker volume ls
```

### Ajouter un volume nommé (optionnel)

Modifiez `docker-compose.yml` :

```yaml
services:
  postgres:
    image: postgres
    environment:
      - POSTGRES_PASSWORD=postgrespw
    ports: 
      - 5432:5432
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

**Avantage :** Volume nommé plus facile à gérer.

---

## Problèmes courants

### Port 5432 déjà utilisé

**Cause :** PostgreSQL est déjà installé localement ou un autre conteneur utilise le port.

**Solution A : Arrêter le service local**
```powershell
Stop-Service postgresql*
```

**Solution B : Changer le port dans docker-compose.yml**
```yaml
ports: 
  - 5433:5432  # Utilise le port 5433 sur l'hôte
```

Puis dans `.env` :
```env
DATABASE_URL="postgresql://postgres:postgrespw@localhost:5433/nextmatch"
```

### Cannot connect to Docker daemon

**Cause :** Docker Desktop n'est pas démarré.

**Solution :**
1. Lancez Docker Desktop
2. Attendez que l'icône soit verte
3. Réessayez `docker compose up -d`

### "docker compose" command not found

**Cause :** Docker n'est pas installé ou pas dans le PATH.

**Solution :**
1. Téléchargez [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Installez et redémarrez Windows
3. Vérifiez : `docker --version`

### Conteneur démarre puis s'arrête immédiatement

**Vérification :**
```powershell
docker compose logs
```

**Causes fréquentes :**
- Port déjà utilisé
- Erreur dans docker-compose.yml
- Ressources insuffisantes

---

## Performance

### Améliorer les performances (optionnel)

Ajoutez dans `docker-compose.yml` :

```yaml
services:
  postgres:
    image: postgres
    environment:
      - POSTGRES_PASSWORD=postgrespw
    ports: 
      - 5432:5432
    command:
      - "postgres"
      - "-c"
      - "shared_buffers=256MB"
      - "-c"
      - "max_connections=200"
```

**Note :** Ces paramètres augmentent la mémoire utilisée par PostgreSQL.

---

## Variables d'environnement PostgreSQL

Autres variables disponibles dans docker-compose.yml :

```yaml
environment:
  - POSTGRES_USER=customuser       # Utilisateur personnalisé
  - POSTGRES_PASSWORD=postgrespw   # Mot de passe
  - POSTGRES_DB=nextmatch          # Base créée automatiquement
  - POSTGRES_INITDB_ARGS=--encoding=UTF-8  # Arguments d'initialisation
```

**Note :** Si vous changez ces valeurs, mettez à jour `DATABASE_URL` dans `.env`.

---

## Alternatives à Docker Compose

### PostgreSQL local

Si vous préférez installer PostgreSQL directement :

1. Téléchargez [PostgreSQL](https://www.postgresql.org/download/windows/)
2. Installez avec mot de passe `postgrespw`
3. Utilisez la même `DATABASE_URL`
4. Pas besoin de `docker compose up -d`

### Base de données cloud

**Supabase (gratuit) :**
- Créez un compte sur [Supabase](https://supabase.com)
- Créez un projet
- Copiez la connection string PostgreSQL
- Remplacez `DATABASE_URL` dans `.env`
- Pas besoin de Docker

**Neon (gratuit) :**
- Créez un compte sur [Neon](https://neon.tech)
- Créez une base de données
- Copiez la connection string
- Remplacez `DATABASE_URL` dans `.env`
- Pas besoin de Docker

---

## Résumé

- **Docker Compose expose PostgreSQL sur localhost:5432**
- **DATABASE_URL avec localhost fonctionne parfaitement**
- **Les données persistent entre les redémarrages**
- **Commandes essentielles :**
  - `docker compose up -d` - Démarrer
  - `docker compose down` - Arrêter
  - `docker compose ps` - Vérifier le statut
  - `docker compose logs -f` - Voir les logs

---

## Ressources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Docker Image](https://hub.docker.com/_/postgres)
- [Prisma with Docker](https://www.prisma.io/docs/guides/deployment/deployment-guides/deploying-to-docker)

