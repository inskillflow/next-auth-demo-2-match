# Optimisations de Performance - Next Match

Ce document identifie toutes les sources de latence dans votre application et fournit des solutions concrètes pour améliorer la performance.

---

## Table des Matières

1. [Diagnostic de Latence](#diagnostic-de-latence)
2. [Optimisation Base de Données](#optimisation-base-de-données)
3. [Optimisation Requêtes Prisma](#optimisation-requêtes-prisma)
4. [Optimisation Images Cloudinary](#optimisation-images-cloudinary)
5. [Caching Next.js](#caching-nextjs)
6. [Optimisation Composants](#optimisation-composants)
7. [Optimisation Pusher/Realtime](#optimisation-pusherrealtime)
8. [Quick Wins (Résultats Immédiats)](#quick-wins-résultats-immédiats)
9. [Optimisations Avancées](#optimisations-avancées)
10. [Checklist Performance](#checklist-performance)

---

## Diagnostic de Latence

### Mesurer Où Est le Problème

#### Dans le Terminal Next.js

Quand vous utilisez l'app, regardez les logs :

```
GET /members 200 in 3245ms   ← LENT (> 1 seconde)
POST /api/messages 200 in 892ms  ← ACCEPTABLE
GET /members/userId 200 in 156ms ← RAPIDE
```

**Sources de latence :**

| Temps | Source Probable |
|-------|-----------------|
| > 3000ms | Cold start base de données (Neon) |
| 1000-3000ms | Requêtes N+1 (multiples queries) |
| 500-1000ms | Images non optimisées |
| 200-500ms | Pas de cache |
| < 200ms | Normal |

---

### Activer les Logs Prisma

**Fichier : `src/lib/prisma.ts`**

```typescript
export const prisma = new PrismaClient({
  log: [
    { level: 'query', emit: 'event' },
    { level: 'error', emit: 'stdout' },
  ],
})

prisma.$on('query' as any, (e: any) => {
  console.log('Query: ' + e.query)
  console.log('Duration: ' + e.duration + 'ms')
  
  // Alerter si requête lente
  if (e.duration > 500) {
    console.warn('⚠️ SLOW QUERY:', e.query)
  }
})
```

**Redémarrez et vous verrez TOUTES les requêtes avec leur temps.**

---

## Optimisation Base de Données

### Problème 1 : Cold Start (Si Neon)

**Symptôme :**
```
Première requête après 5+ min : 2000-5000ms
Requêtes suivantes : 50-200ms
```

**Solution 1 : Migrer vers Supabase (RECOMMANDÉ)**

```env
# Remplacer Neon par Supabase
DATABASE_URL="postgresql://postgres.project:pass@aws-region.pooler.supabase.com:6543/postgres?pgbouncer=true"
```

**Gain : 0 cold start, toujours rapide**

Voir **Document 13 : Migration Neon vers Supabase**

---

**Solution 2 : Connection Pooling (Si vous gardez Neon)**

```env
# Utiliser l'URL pooled de Neon
DATABASE_URL="postgresql://user:pass@host-pooler.region.aws.neon.tech:5432/db?pgbouncer=true&connection_limit=10"
```

**Gain : 50-70% plus rapide**

Voir **Document 11 : Optimisation Performance**

---

**Solution 3 : Upgrade Neon Scale ($19/mois)**

Pas de cold start, base toujours active.

---

### Problème 2 : Pas d'Index sur Requêtes Fréquentes

**Vérifier les index :**

```sql
-- Connexion à votre base
-- Vérifier les index existants
SELECT tablename, indexname FROM pg_indexes WHERE schemaname = 'public';
```

**Ajouter des index si manquants :**

**Fichier : `prisma/schema.prisma`**

```prisma
model Member {
  id          String @id @default(cuid())
  userId      String @unique
  gender      String
  city        String
  country     String
  created     DateTime @default(now())
  
  // ← Ajouter index sur colonnes filtrées souvent
  @@index([gender])
  @@index([created])
  @@index([city, country])
}

model Like {
  sourceUserId String
  targetUserId String
  
  @@id([sourceUserId, targetUserId])
  // ← Index déjà sur la clé composite
}

model Message {
  id          String @id @default(cuid())
  senderId    String
  recipientId String
  created     DateTime @default(now())
  dateRead    DateTime?
  
  // ← Index pour requêtes fréquentes
  @@index([recipientId, dateRead])
  @@index([senderId])
  @@index([recipientId])
  @@index([created])
}
```

**Appliquer :**

```bash
npx prisma migrate dev --name add_indexes
```

**Gain : 30-70% plus rapide sur requêtes filtrées**

---

## Optimisation Requêtes Prisma

### Problème : Requêtes N+1

#### Exemple MAUVAIS (Lent)

```typescript
// Récupérer tous les membres
const members = await prisma.member.findMany()

// Pour chaque membre, récupérer ses photos
for (const member of members) {
  const photos = await prisma.photo.findMany({
    where: { memberId: member.id }
  })
  member.photos = photos
}

// Total : 1 + N requêtes (N = nombre de membres)
// Si 20 membres : 21 requêtes !
```

---

#### Exemple BON (Rapide)

```typescript
// Une seule requête avec include
const members = await prisma.member.findMany({
  include: {
    photos: {
      where: { isApproved: true },
      take: 1 // Seulement la première photo
    }
  }
})

// Total : 1 seule requête avec JOIN
```

**Gain : 10-20x plus rapide**

---

### Optimisation : Select Seulement les Champs Nécessaires

#### AVANT (Lent - tout récupéré)

```typescript
const members = await prisma.member.findMany({
  include: {
    photos: true,
    sourceLikes: true,
    targetLikes: true,
    senderMessages: true,
    recipientMessages: true,
    user: true
  }
})

// Récupère TOUT (beaucoup de données inutiles)
```

---

#### APRÈS (Rapide - seulement nécessaire)

```typescript
const members = await prisma.member.findMany({
  select: {
    id: true,
    name: true,
    gender: true,
    dateOfBirth: true,
    city: true,
    country: true,
    image: true,
    description: true,
    
    // Seulement première photo approuvée
    photos: {
      where: { isApproved: true },
      take: 1,
      select: {
        url: true
      }
    }
  },
  
  // Pagination
  take: 20,
  skip: (page - 1) * 20,
  
  // Tri
  orderBy: { created: 'desc' }
})
```

**Gain : 40-60% moins de données, 2-3x plus rapide**

---

### Exemple Concret : Page Members

**Fichier : `src/app/actions/memberActions.ts`**

**AVANT (Non optimisé) :**

```typescript
export async function getMembers() {
  return prisma.member.findMany({
    include: {
      photos: true
    }
  })
}
```

**APRÈS (Optimisé) :**

```typescript
export async function getMembers(
  page: number = 1, 
  filters?: { gender?: string, ageMin?: number, ageMax?: number }
) {
  return prisma.member.findMany({
    // ← SELECT seulement les champs affichés
    select: {
      id: true,
      userId: true,
      name: true,
      gender: true,
      dateOfBirth: true,
      city: true,
      country: true,
      image: true,
      
      // ← Une seule photo approuvée
      photos: {
        where: { isApproved: true },
        take: 1,
        select: {
          url: true
        },
        orderBy: { id: 'asc' }
      }
    },
    
    // ← Filtres
    where: {
      gender: filters?.gender,
      dateOfBirth: {
        gte: filters?.ageMax ? new Date(new Date().getFullYear() - filters.ageMax, 0, 1) : undefined,
        lte: filters?.ageMin ? new Date(new Date().getFullYear() - filters.ageMin, 11, 31) : undefined
      }
    },
    
    // ← Pagination
    take: 20,
    skip: (page - 1) * 20,
    
    // ← Tri
    orderBy: { created: 'desc' }
  })
}
```

**Gain : 5-10x plus rapide**

---

## Optimisation Images Cloudinary

### Problème : Images Trop Lourdes

#### AVANT (Non optimisé)

```typescript
// URL brute
https://res.cloudinary.com/demo/image/upload/sample.jpg
// Taille : 2-5 MB
// Temps de chargement : 2-5 secondes
```

---

#### APRÈS (Optimisé avec Transformations)

**Fichier : `src/lib/util.ts`**

```typescript
export function transformImageUrl(url: string | null): string {
  if (!url) return '/images/user.png' // Fallback
  
  // Déjà une URL Cloudinary transformée
  if (url.includes('/upload/')) {
    return url
  }
  
  // Ajouter transformations Cloudinary
  return url.replace(
    '/upload/',
    '/upload/w_500,h_500,c_fill,q_auto,f_auto/'
    //         │      │      │      │      │
    //         │      │      │      │      └─ Format auto (WebP/AVIF)
    //         │      │      │      └─ Qualité auto
    //         │      │      └─ Crop fill
    //         │      └─ Height 500px
    //         └─ Width 500px
  )
}
```

**Utilisation :**

```typescript
// Composant MemberImage
<Image 
  src={transformImageUrl(member.image)} 
  alt={member.name}
  width={500}
  height={500}
/>
```

**Résultat :**
```
https://res.cloudinary.com/demo/image/upload/w_500,h_500,c_fill,q_auto,f_auto/sample.jpg
// Taille : 50-150 KB (10-50x plus petit !)
// Temps : 200-500ms
```

**Gain : 10-50x plus rapide**

---

### Optimisation : Lazy Loading Images

**Fichier : `src/components/MemberCard.tsx`**

```typescript
import Image from 'next/image'

export default function MemberCard({ member }) {
  return (
    <div>
      <Image 
        src={member.image}
        alt={member.name}
        width={300}
        height={300}
        loading="lazy"  // ← Lazy load
        placeholder="blur"  // ← Placeholder flou
        blurDataURL="data:image/jpeg;base64,/9j/4AAQSkZJRg..."  // ← Mini image
      />
    </div>
  )
}
```

**Gain : Images hors écran ne chargent pas → 50-70% moins de requêtes**

---

## Caching Next.js

### Problème : Pas de Cache

#### AVANT (Requête à chaque fois)

```typescript
export async function getMembers() {
  // Appelé à CHAQUE visite de /members
  return prisma.member.findMany()
}
```

---

#### APRÈS (Avec Cache)

```typescript
import { unstable_cache } from 'next/cache'

export const getMembers = unstable_cache(
  async (page: number, filters: Filters) => {
    return prisma.member.findMany({
      // ... query
    })
  },
  ['members-list'], // Cache key
  {
    revalidate: 60, // ← Cache pendant 60 secondes
    tags: ['members']
  }
)
```

**Utilisation :**

```typescript
// Premier appel : Query DB (300ms)
const members = await getMembers(1, filters)

// Appels suivants dans les 60s : Cache (5ms)
const members = await getMembers(1, filters)
```

**Invalidation du cache quand données changent :**

```typescript
import { revalidateTag } from 'next/cache'

export async function updateMember(id: string, data: any) {
  await prisma.member.update({
    where: { id },
    data
  })
  
  // ← Invalider le cache
  revalidateTag('members')
}
```

**Gain : 50-100x plus rapide après premier chargement**

---

### Cache pour Images

```typescript
// app/members/page.tsx
export const revalidate = 300 // 5 minutes

export default async function MembersPage() {
  const members = await getMembers()
  return <MembersList members={members} />
}
```

**Next.js génère une version statique pendant 5 minutes.**

---

## Optimisation Composants

### Problème : Re-renders Inutiles

#### AVANT (Re-render à chaque changement parent)

```typescript
export default function MemberCard({ member }) {
  // Re-render à chaque changement du parent
  console.log('MemberCard rendered')
  
  return (
    <div>
      <img src={member.image} />
      <h2>{member.name}</h2>
    </div>
  )
}
```

---

#### APRÈS (Mémoïsé)

```typescript
import { memo } from 'react'

const MemberCard = memo(({ member }) => {
  return (
    <div>
      <img src={member.image} />
      <h2>{member.name}</h2>
    </div>
  )
})

export default MemberCard
```

**Gain : Ne re-render que si `member` change**

---

### Optimisation : Debounce des Filtres

**Fichier : `src/hooks/useFilters.ts`**

**AVANT (Requête à chaque changement) :**

```typescript
const handleFilterChange = (value) => {
  setFilter(value)
  // Requête immédiate
  router.push(`/members?gender=${value}`)
}
```

---

**APRÈS (Avec debounce) :**

```typescript
import { useDeferredValue } from 'react'

export function useFilters() {
  const [filters, setFilters] = useState({})
  
  // ← Debounce automatique
  const deferredFilters = useDeferredValue(filters)
  
  useEffect(() => {
    // Ne s'exécute qu'après 300ms d'inactivité
    router.push(`/members?${new URLSearchParams(deferredFilters)}`)
  }, [deferredFilters])
  
  return { filters, setFilters }
}
```

**Gain : Évite 10-20 requêtes inutiles quand user ajuste un slider**

---

## Optimisation Pusher/Realtime

### Problème : Trop d'Événements

**AVANT (Tous les événements) :**

```typescript
channel.bind('message:new', (data) => {
  setMessages(prev => [...prev, data])
})

channel.bind('message:updated', (data) => {
  setMessages(prev => prev.map(m => m.id === data.id ? data : m))
})

channel.bind('message:deleted', (data) => {
  setMessages(prev => prev.filter(m => m.id !== data.id))
})

// 3 bindings, 3 listeners
```

---

**APRÈS (Event batching) :**

```typescript
channel.bind_global((eventName, data) => {
  // Un seul listener pour tous les événements
  
  if (eventName === 'message:new') {
    setMessages(prev => [...prev, data])
  }
  else if (eventName === 'message:updated') {
    setMessages(prev => prev.map(m => m.id === data.id ? data : m))
  }
  else if (eventName === 'message:deleted') {
    setMessages(prev => prev.filter(m => m.id !== data.id))
  }
})
```

**Gain : Moins de listeners = moins de mémoire**

---

### Optimisation : Unsubscribe Proprement

```typescript
useEffect(() => {
  const channel = pusher.subscribe('messages')
  channel.bind('message:new', handleNewMessage)
  
  // ← IMPORTANT : Cleanup
  return () => {
    channel.unbind('message:new', handleNewMessage)
    pusher.unsubscribe('messages')
  }
}, [])
```

**Sans cleanup : Memory leaks !**

---

## Quick Wins (Résultats Immédiats)

### 1. Pagination (5 minutes)

**AVANT :**
```typescript
// Charge TOUS les membres (peut être 100+)
const members = await prisma.member.findMany()
```

**APRÈS :**
```typescript
// Charge seulement 20 à la fois
const members = await prisma.member.findMany({
  take: 20,
  skip: (page - 1) * 20
})
```

**Gain : 5-10x plus rapide**

---

### 2. Optimisation next/image (2 minutes)

**AVANT :**
```typescript
<img src={member.image} />
```

**APRÈS :**
```typescript
import Image from 'next/image'

<Image 
  src={member.image}
  width={300}
  height={300}
  alt={member.name}
  loading="lazy"
  quality={75}  // ← 75 au lieu de 100 par défaut
/>
```

**Gain : 30-50% images plus légères**

---

### 3. Reducer Payload Pusher (5 minutes)

**AVANT (Tout le message) :**
```typescript
await pusherServer.trigger(channelId, 'message:new', {
  id: message.id,
  text: message.text,
  senderId: message.senderId,
  recipientId: message.recipientId,
  created: message.created,
  sender: {
    id: sender.id,
    name: sender.name,
    image: sender.image,
    member: {
      id: sender.member.id,
      name: sender.member.name,
      gender: sender.member.gender,
      // ... beaucoup de données
    }
  }
})
```

**APRÈS (Seulement essentiel) :**
```typescript
await pusherServer.trigger(channelId, 'message:new', {
  id: message.id,
  text: message.text,
  senderId: message.senderId,
  created: message.created,
  senderName: sender.name,  // ← Juste le nom
  senderImage: sender.image  // ← Juste l'image
})
```

**Gain : 70-80% payload plus léger, broadcast plus rapide**

---

### 4. Prefetch Links (2 minutes)

**Fichier : `src/components/MemberCard.tsx`**

```typescript
import Link from 'next/link'

export default function MemberCard({ member }) {
  return (
    <Link 
      href={`/members/${member.userId}`}
      prefetch={true}  // ← Prefetch au hover
    >
      <div>...</div>
    </Link>
  )
}
```

**Quand user survole la carte, la page est déjà chargée !**

**Gain : Navigation instantanée**

---

### 5. Static Metadata (1 minute)

**Fichier : `src/app/members/page.tsx`**

```typescript
export const metadata = {
  title: 'Members | Next Match',
  description: 'Browse dating profiles'
}

// ← Ajouter
export const revalidate = 60 // Régénère toutes les 60s

export default async function MembersPage() {
  const members = await getMembers()
  return <MembersList members={members} />
}
```

**Gain : Page statique servie par CDN**

---

## Optimisations Avancées

### 1. React Server Components (Déjà fait !)

**Votre app utilise déjà RSC :** ✅

**Avantage :**
- Pas de JavaScript côté client
- Rendu serveur
- Données fetchées côté serveur

---

### 2. Parallel Data Fetching

**AVANT (Séquentiel - lent) :**

```typescript
export default async function MemberProfilePage({ params }) {
  const member = await getMemberById(params.userId)  // 200ms
  const photos = await getPhotosByMemberId(params.userId)  // 100ms
  const likes = await getLikeCount(params.userId)  // 50ms
  
  // Total : 350ms
}
```

---

**APRÈS (Parallèle - rapide) :**

```typescript
export default async function MemberProfilePage({ params }) {
  // ← Toutes les requêtes en parallèle
  const [member, photos, likes] = await Promise.all([
    getMemberById(params.userId),     // 200ms \
    getPhotosByMemberId(params.userId), // 100ms  } En même temps
    getLikeCount(params.userId)        // 50ms  /
  ])
  
  // Total : 200ms (temps de la plus lente)
}
```

**Gain : 40-60% plus rapide**

---

### 3. Streaming avec Suspense

**AVANT (Bloque toute la page) :**

```typescript
export default async function MembersPage() {
  const members = await getMembers() // 2000ms
  return <MembersList members={members} />
  
  // Page blanche pendant 2000ms
}
```

---

**APRÈS (Streaming) :**

```typescript
import { Suspense } from 'react'

export default function MembersPage() {
  return (
    <div>
      <h1>Members</h1>  {/* ← Affiché immédiatement */}
      
      <Suspense fallback={<LoadingSpinner />}>
        <MembersContent />  {/* ← Charge après */}
      </Suspense>
    </div>
  )
}

async function MembersContent() {
  const members = await getMembers()
  return <MembersList members={members} />
}
```

**User voit la page immédiatement, contenu arrive après.**

**Gain : Time to First Byte (TTFB) 80-90% plus rapide**

---

### 4. Optimistic Updates

**Fichier : `src/components/LikeButton.tsx`**

**AVANT (Attend la réponse) :**

```typescript
const handleLike = async () => {
  const result = await toggleLikeMember(memberId)
  
  if (result.status === 'success') {
    setIsLiked(!isLiked)  // ← Change après 500ms
  }
}

// Utilisateur attend 500ms pour voir le changement
```

---

**APRÈS (Optimistic) :**

```typescript
const handleLike = async () => {
  // ← Mise à jour immédiate (optimistic)
  setIsLiked(!isLiked)
  
  // Requête serveur en arrière-plan
  const result = await toggleLikeMember(memberId)
  
  if (result.status === 'error') {
    // Rollback si erreur
    setIsLiked(isLiked)
    toast.error('Failed to like')
  }
}

// Utilisateur voit le changement INSTANTANÉMENT
```

**Gain : Feedback instantané, app sent plus rapide**

---

## Checklist Performance

### À Faire MAINTENANT (Impact majeur)

- [ ] **Migrer vers Supabase** (si Neon)
  - Élimine cold start
  - Document 13
  - Temps : 20 min
  - Gain : 5-10x plus rapide au démarrage

- [ ] **Ajouter pagination** partout
  - `take: 20, skip: (page-1)*20`
  - Temps : 30 min
  - Gain : 5-10x

- [ ] **Optimiser requêtes Prisma**
  - Utiliser `select` au lieu de tout récupérer
  - Utiliser `include` au lieu de queries multiples
  - Temps : 2 heures
  - Gain : 3-5x

- [ ] **Transformer images Cloudinary**
  - `w_500,h_500,c_fill,q_auto,f_auto`
  - Temps : 30 min
  - Gain : 10-50x taille images

- [ ] **Activer logs Prisma**
  - Identifier requêtes lentes
  - Temps : 5 min
  - Gain : Diagnostic

---

### Optimisations Intermédiaires

- [ ] **Ajouter index Prisma**
  - Sur colonnes filtrées
  - Temps : 1 heure
  - Gain : 30-70%

- [ ] **Cache Next.js**
  - `unstable_cache` sur getters
  - Temps : 2-3 heures
  - Gain : 50-100x

- [ ] **Optimistic updates**
  - Likes, messages
  - Temps : 2 heures
  - Gain : UX instantané

- [ ] **Lazy loading images**
  - `loading="lazy"`
  - Temps : 30 min
  - Gain : 50% moins de requêtes

---

### Optimisations Avancées

- [ ] **Parallel fetching**
  - `Promise.all()`
  - Temps : 1-2 heures
  - Gain : 40-60%

- [ ] **Streaming avec Suspense**
  - `<Suspense>`
  - Temps : 2-3 heures
  - Gain : TTFB 80-90%

- [ ] **Database pooling**
  - Connection pooler
  - Temps : 5 min
  - Gain : 30-50%

- [ ] **CDN pour assets**
  - Vercel Edge
  - Temps : Automatique
  - Gain : Global

---

## Mesures de Performance

### Avant Optimisations

```
Page Members (première fois) : 3000-5000ms
Page Members (après) : 800-1500ms
Login : 2000-4000ms
Upload photo : 1000-2000ms
Envoyer message : 500-1000ms
```

---

### Après Optimisations (Objectifs)

```
Page Members (première fois) : 300-800ms   ← 5-10x plus rapide
Page Members (après/cache) : 50-150ms     ← 20-50x plus rapide
Login : 400-800ms                         ← 3-5x plus rapide
Upload photo : 400-800ms                  ← 2-3x plus rapide
Envoyer message : 100-300ms               ← 3-5x plus rapide
```

---

## Code Complet Optimisé

### Fichier : `src/app/actions/memberActions.ts` (Optimisé)

```typescript
import { unstable_cache } from 'next/cache'
import { prisma } from '@/lib/prisma'

export const getMembers = unstable_cache(
  async (page: number = 1, filters?: {
    gender?: string
    ageMin?: number
    ageMax?: number
    withPhoto?: boolean
  }) => {
    return prisma.member.findMany({
      // SELECT seulement nécessaire
      select: {
        id: true,
        userId: true,
        name: true,
        gender: true,
        dateOfBirth: true,
        city: true,
        country: true,
        image: true,
        
        // Une seule photo
        photos: {
          where: { isApproved: true },
          take: 1,
          select: { url: true }
        }
      },
      
      // Filtres
      where: {
        gender: filters?.gender,
        ...(filters?.withPhoto && {
          photos: {
            some: { isApproved: true }
          }
        }),
        ...(filters?.ageMin || filters?.ageMax) && {
          dateOfBirth: {
            gte: filters?.ageMax 
              ? new Date(new Date().getFullYear() - filters.ageMax, 0, 1) 
              : undefined,
            lte: filters?.ageMin 
              ? new Date(new Date().getFullYear() - filters.ageMin, 11, 31) 
              : undefined
          }
        }
      },
      
      // Pagination
      take: 20,
      skip: (page - 1) * 20,
      
      // Tri
      orderBy: { created: 'desc' }
    })
  },
  ['members-list'],
  {
    revalidate: 60,
    tags: ['members']
  }
)
```

---

## Résumé

**Principales causes de latence :**

1. **Cold start Neon** (1-3s) → Migrer Supabase
2. **Requêtes N+1** → Utiliser `include`
3. **Pas de pagination** → Ajouter `take/skip`
4. **Images non optimisées** → Transformations Cloudinary
5. **Pas de cache** → `unstable_cache`

**Quick wins (1-2 heures de travail) :**
- Supabase migration : 5-10x plus rapide
- Pagination : 5-10x
- Images : 10-50x
- Select seulement nécessaire : 2-3x

**Gain total potentiel : 50-100x plus rapide !**

---

**Commencez par migrer vers Supabase (Document 13) et ajouter la pagination. Vous verrez une ÉNORME différence immédiatement !**

