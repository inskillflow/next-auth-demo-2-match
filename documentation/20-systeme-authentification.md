# Système d'Authentification - Next Match

Ce document explique en détail le système d'authentification complet de l'application Next Match, basé sur **NextAuth.js v5 (Auth.js)**.

---

## Table des Matières

1. [Architecture Globale](#architecture-globale)
2. [NextAuth.js - Configuration](#nextauthjs---configuration)
3. [Providers (Fournisseurs)](#providers-fournisseurs)
4. [Stratégie de Session (JWT)](#stratégie-de-session-jwt)
5. [Protection des Routes (Middleware)](#protection-des-routes-middleware)
6. [Inscription (Register)](#inscription-register)
7. [Connexion (Login)](#connexion-login)
8. [Vérification Email](#vérification-email)
9. [Réinitialisation Mot de Passe](#réinitialisation-mot-de-passe)
10. [Connexion Sociale (Google, GitHub)](#connexion-sociale-google-github)
11. [Système de Rôles](#système-de-rôles)
12. [Complete Profile Flow](#complete-profile-flow)
13. [Sécurité](#sécurité)
14. [Diagrammes de Flux](#diagrammes-de-flux)
15. [API et Server Actions](#api-et-server-actions)
16. [Configuration Environnement](#configuration-environnement)
17. [Troubleshooting](#troubleshooting)

---

## Architecture Globale

### Stack Technique

| Composant | Technologie | Rôle |
|-----------|-------------|------|
| **Framework Auth** | NextAuth.js v5 (Auth.js) | Gestion authentification |
| **Stratégie Session** | JWT (JSON Web Token) | Session stateless |
| **Base de Données** | PostgreSQL (Supabase/Neon) | Stockage users |
| **ORM** | Prisma | Accès base de données |
| **Hachage Passwords** | bcryptjs | Sécurité mots de passe |
| **Validation** | Zod | Validation schémas |
| **Email** | Resend | Envoi emails |
| **Providers** | Credentials, Google, GitHub | Méthodes connexion |

---

### Modèles de Données (Prisma)

#### User Model

```prisma
model User {
  id              String    @id @default(cuid())
  name            String?
  email           String?   @unique
  emailVerified   DateTime?
  passwordHash    String?
  image           String?
  profileComplete Boolean   @default(false)
  role            Role      @default(MEMBER)
  accounts        Account[]
  member          Member?
}
```

**Champs clés :**
- `emailVerified` : Null = non vérifié, Date = vérifié
- `profileComplete` : `false` = profil incomplet (social login)
- `role` : `MEMBER` ou `ADMIN`
- `passwordHash` : Null si connexion sociale (Google/GitHub)

---

#### Account Model (NextAuth)

```prisma
model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String          # "credentials", "google", "github"
  providerAccountId String
  refresh_token     String? @db.Text
  access_token      String? @db.Text
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String? @db.Text
  session_state     String?

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerAccountId])
}
```

**Rôle :** Gère les comptes OAuth (Google, GitHub).

---

#### Token Model (Verification & Reset)

```prisma
model Token {
  id      String    @id @default(cuid())
  email   String
  token   String    @unique
  expires DateTime
  type    TokenType
}

enum TokenType {
  VERIFICATION
  PASSWORD_RESET
}
```

**Rôle :** Tokens temporaires pour vérification email et reset password.

---

#### Member Model

```prisma
model Member {
  id                String    @id @default(cuid())
  userId            String    @unique
  name              String
  gender            String
  dateOfBirth       DateTime
  created           DateTime  @default(now())
  updated           DateTime  @default(now())
  description       String
  city              String
  country           String
  image             String?
  user              User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  photos            Photo[]
  sourceLikes       Like[]    @relation("source")
  targetLikes       Like[]    @relation("target")
  senderMessages    Message[] @relation("sender")
  recipientMessages Message[] @relation("recipient")
}
```

**Rôle :** Profil public de l'utilisateur (dating profile).

---

### Relation User ↔ Member

```
User (1) ─────── (0..1) Member
     ↑                     ↑
     │                     │
  Table Auth          Table Profils
  (privée)            (publique)
```

**Séparation des préoccupations :**
- **User** : Authentification, credentials, rôles
- **Member** : Profil public, photos, likes, messages

---

## NextAuth.js - Configuration

### Fichier : `src/auth.config.ts`

**Rôle :** Configuration des **providers** (fournisseurs d'authentification).

```typescript
import Credentials from "next-auth/providers/credentials"
import Google from "next-auth/providers/google"
import Github from "next-auth/providers/github"
import type { NextAuthConfig } from "next-auth"
import { loginSchema } from './lib/schemas/loginSchema'
import { getUserByEmail } from './app/actions/authActions'
import { compare } from 'bcryptjs'

export default {
  providers: [
    // Provider Google OAuth
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET
    }),
    
    // Provider GitHub OAuth
    Github({
      clientId: process.env.GITHUB_CLIENT_ID,
      clientSecret: process.env.GITHUB_CLIENT_SECRET
    }),
    
    // Provider Credentials (Email + Password)
    Credentials({
      name: 'credentials',
      async authorize(creds) {
        // Validation avec Zod
        const validated = loginSchema.safeParse(creds)

        if (validated.success) {
          const { email, password } = validated.data

          // Récupération utilisateur
          const user = await getUserByEmail(email)

          // Vérification password
          if (!user || !user.passwordHash || 
              !(await compare(password, user.passwordHash))) {
            return null
          }

          return user
        }

        return null
      }
    })
  ],
} satisfies NextAuthConfig
```

---

### Fichier : `src/auth.ts`

**Rôle :** Configuration principale NextAuth avec **callbacks**, **adapter**, et **session strategy**.

```typescript
import NextAuth from "next-auth"
import { PrismaAdapter } from "@auth/prisma-adapter"
import authConfig from "./auth.config"
import { prisma } from './lib/prisma'
import { Role } from '@prisma/client'

export const { handlers: {GET, POST}, auth, signIn, signOut } = NextAuth({
  // Callbacks : personnalisation JWT et Session
  callbacks: {
    // Callback JWT : Ajout de données custom au token
    async jwt({user, token}) {
      if (user) {
        token.profileComplete = user.profileComplete
        token.role = user.role
      }
      return token
    },
    
    // Callback Session : Ajout des données du token à la session
    async session({token, session}) {
      if (token.sub && session.user) {
        session.user.id = token.sub
        session.user.profileComplete = token.profileComplete as boolean
        session.user.role = token.role as Role
      }
      return session
    }
  },
  
  // Adapter Prisma : Lien avec la base de données
  adapter: PrismaAdapter(prisma),
  
  // Stratégie de session : JWT (stateless)
  session: { strategy: "jwt" },
  
  // Import des providers
  ...authConfig,
})
```

**Points clés :**
- **PrismaAdapter** : Synchronise NextAuth avec PostgreSQL
- **JWT Strategy** : Session sans état (pas de stockage côté serveur)
- **Callbacks** : Enrichissement du token avec `profileComplete` et `role`

---

### Extension TypeScript (Types Custom)

**Fichier : `src/types/next-auth.d.ts`**

```typescript
import { Role } from '@prisma/client'
import { DefaultSession } from 'next-auth'

declare module 'next-auth' {
  interface User {
    profileComplete: boolean
    role: Role
  }

  interface Session {
    user: {
      profileComplete: boolean
      role: Role
    } & DefaultSession['user']
  }
}

declare module 'next-auth/jwt' {
  interface JWT {
    profileComplete: boolean
    role: Role
  }
}
```

**Rôle :** Ajoute les propriétés custom `profileComplete` et `role` aux types NextAuth.

---

## Providers (Fournisseurs)

### 1. Credentials Provider (Email + Password)

**Flux :**

```mermaid
flowchart TD
    A[Utilisateur soumet Email + Password] -->|POST /api/auth/signin| B[NextAuth Credentials Provider]
    B --> C{Validation Zod}
    C -->|Invalide| D[Retour Erreur]
    C -->|Valide| E[Recherche User par Email]
    E -->|User introuvable| F[Retour null]
    E -->|User trouvé| G{Compare Password avec Hash}
    G -->|Incorrect| F
    G -->|Correct| H[Retour User Object]
    H --> I[NextAuth génère JWT]
    I --> J[Cookie de session créé]
    J --> K[Redirection /members]
    
    style A fill:#e1f5ff,stroke:#01579b,stroke-width:4px,color:#000
    style K fill:#c8e6c9,stroke:#2e7d32,stroke-width:4px,color:#000
    style D fill:#ffcdd2,stroke:#c62828,stroke-width:3px,color:#000
    style F fill:#ffcdd2,stroke:#c62828,stroke-width:3px,color:#000
```

**Code d'autorisation :**

```typescript
async authorize(creds) {
  const validated = loginSchema.safeParse(creds)
  
  if (validated.success) {
    const { email, password } = validated.data
    const user = await getUserByEmail(email)
    
    // Vérification du hash bcrypt
    if (!user || !user.passwordHash || 
        !(await compare(password, user.passwordHash))) {
      return null
    }
    
    return user
  }
  
  return null
}
```

---

### 2. Google Provider (OAuth 2.0)

**Configuration :**

```typescript
Google({
  clientId: process.env.GOOGLE_CLIENT_ID,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET
})
```

**Variables d'environnement :**

```env
GOOGLE_CLIENT_ID="your-client-id.apps.googleusercontent.com"
GOOGLE_CLIENT_SECRET="your-secret"
```

**Comment obtenir les credentials :**

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créez un nouveau projet
3. Activez **Google+ API**
4. Créez des **OAuth 2.0 credentials**
5. Authorized redirect URIs :
   ```
   http://localhost:3000/api/auth/callback/google
   https://votre-domaine.com/api/auth/callback/google
   ```

---

### 3. GitHub Provider (OAuth)

**Configuration :**

```typescript
Github({
  clientId: process.env.GITHUB_CLIENT_ID,
  clientSecret: process.env.GITHUB_CLIENT_SECRET
})
```

**Variables d'environnement :**

```env
GITHUB_CLIENT_ID="your-github-client-id"
GITHUB_CLIENT_SECRET="your-github-secret"
```

**Comment obtenir les credentials :**

1. Allez sur [GitHub Settings > Developer settings > OAuth Apps](https://github.com/settings/developers)
2. **New OAuth App**
3. **Homepage URL** : `http://localhost:3000`
4. **Authorization callback URL** :
   ```
   http://localhost:3000/api/auth/callback/github
   ```

---

## Stratégie de Session (JWT)

### JWT vs Database Sessions

| Aspect | JWT (Notre choix) | Database Sessions |
|--------|-------------------|-------------------|
| **Stockage** | Client (cookie) | Serveur (database) |
| **Scalabilité** | Excellente (stateless) | Limite (état serveur) |
| **Performance** | Rapide (pas de DB query) | Plus lent (query DB) |
| **Révocation** | Difficile (expire naturellement) | Facile (delete row) |
| **Données** | Limité (taille cookie) | Illimité |
| **Sécurité** | Signé (pas chiffré) | Sécurisé par DB |

**Choix JWT pour :**
- Application Next.js serverless (Vercel)
- Pas besoin de révocation immédiate
- Performance optimale

---

### Structure du JWT

**Token contient :**

```json
{
  "sub": "user-id-cuid",
  "name": "John Doe",
  "email": "john@example.com",
  "picture": "https://...",
  "profileComplete": true,
  "role": "MEMBER",
  "iat": 1697000000,
  "exp": 1697086400,
  "jti": "token-id"
}
```

**Enrichi par les callbacks :**
- `profileComplete` : Statut profil
- `role` : `MEMBER` ou `ADMIN`

---

### Accès à la Session

#### Côté Serveur (Server Components, Server Actions)

```typescript
import { auth } from '@/auth'

export default async function ServerComponent() {
  const session = await auth()
  
  if (!session?.user) {
    return <div>Non connecté</div>
  }
  
  return (
    <div>
      <p>ID: {session.user.id}</p>
      <p>Email: {session.user.email}</p>
      <p>Role: {session.user.role}</p>
      <p>Profil complet: {session.user.profileComplete ? 'Oui' : 'Non'}</p>
    </div>
  )
}
```

---

#### Côté Client (Client Components)

```typescript
'use client'
import { useSession } from 'next-auth/react'

export default function ClientComponent() {
  const { data: session, status } = useSession()
  
  if (status === 'loading') {
    return <div>Chargement...</div>
  }
  
  if (!session) {
    return <div>Non connecté</div>
  }
  
  return (
    <div>
      <p>Email: {session.user.email}</p>
      <p>Role: {session.user.role}</p>
    </div>
  )
}
```

**Important :** Le composant doit être wrappé dans un `<SessionProvider>`.

---

## Protection des Routes (Middleware)

### Fichier : `src/middleware.ts`

**Rôle :** Protège les routes **avant** même que la page soit chargée.

```typescript
import { NextResponse } from 'next/server'
import { auth } from './auth'
import { authRoutes, publicRoutes } from './routes'

export default auth((req) => {
  const { nextUrl } = req
  const isLoggedIn = !!req.auth
  
  const isPublic = publicRoutes.includes(nextUrl.pathname)
  const isAuthRoute = authRoutes.includes(nextUrl.pathname)
  const isProfileComplete = req.auth?.user.profileComplete
  const isAdmin = req.auth?.user.role === 'ADMIN'
  const isAdminRoute = nextUrl.pathname.startsWith('/admin')
  
  // 1. Routes publiques et admins passent toujours
  if (isPublic || isAdmin) {
    return NextResponse.next()
  }
  
  // 2. Protection routes admin
  if (isAdminRoute && !isAdmin) {
    return NextResponse.redirect(new URL('/', nextUrl))
  }
  
  // 3. Routes d'authentification (login, register)
  if (isAuthRoute) {
    if (isLoggedIn) {
      return NextResponse.redirect(new URL('/members', nextUrl))
    }
    return NextResponse.next()
  }
  
  // 4. Routes protégées nécessitent connexion
  if (!isPublic && !isLoggedIn) {
    return NextResponse.redirect(new URL('/login', nextUrl))
  }
  
  // 5. Profil incomplet → redirection /complete-profile
  if (isLoggedIn && !isProfileComplete && 
      nextUrl.pathname !== '/complete-profile') {
    return NextResponse.redirect(new URL('/complete-profile', nextUrl))
  }
  
  return NextResponse.next()
})

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|images|favicon.ico).*)']
}
```

---

### Fichier : `src/routes.ts`

**Configuration des routes :**

```typescript
export const publicRoutes = [
  '/'
]

export const authRoutes = [
  '/login',
  '/register',
  '/register/success',
  '/verify-email',
  '/forgot-password',
  '/reset-password'
]
```

**Logique :**
- `publicRoutes` : Accessibles sans connexion
- `authRoutes` : Accessibles seulement si **non connecté**
- Autres routes : Nécessitent connexion + profil complet

---

### Matrice de Protection

| Route | Non connecté | Connecté (profil incomplet) | Connecté (profil complet) | Admin |
|-------|--------------|----------------------------|---------------------------|-------|
| `/` (home) | ✅ Accès | ✅ Accès | ✅ Accès | ✅ Accès |
| `/login` | ✅ Accès | ❌ → `/members` | ❌ → `/members` | ❌ → `/members` |
| `/register` | ✅ Accès | ❌ → `/members` | ❌ → `/members` | ❌ → `/members` |
| `/members` | ❌ → `/login` | ❌ → `/complete-profile` | ✅ Accès | ✅ Accès |
| `/messages` | ❌ → `/login` | ❌ → `/complete-profile` | ✅ Accès | ✅ Accès |
| `/complete-profile` | ❌ → `/login` | ✅ Accès | ✅ Accès | ✅ Accès |
| `/admin/*` | ❌ → `/login` | ❌ → `/` | ❌ → `/` | ✅ Accès |

---

## Inscription (Register)

### Flux Complet

```mermaid
flowchart TD
    A[Utilisateur remplit formulaire] --> B[Validation Zod]
    B -->|Erreur| C[Affichage erreurs]
    B -->|OK| D[Vérification email existe]
    D -->|Existe| E[Erreur: User déjà existant]
    D -->|Nouveau| F[Hash password avec bcrypt]
    F --> G[Création User + Member en transaction]
    G --> H[Génération token verification]
    H --> I[Envoi email verification]
    I --> J[Redirection /register/success]
    
    style A fill:#e1f5ff,stroke:#01579b,stroke-width:4px,color:#000
    style J fill:#c8e6c9,stroke:#2e7d32,stroke-width:4px,color:#000
    style C fill:#ffcdd2,stroke:#c62828,stroke-width:3px,color:#000
    style E fill:#ffcdd2,stroke:#c62828,stroke-width:3px,color:#000
```

---

### Schémas de Validation (Zod)

**Fichier : `src/lib/schemas/registerSchema.ts`**

```typescript
import { z } from 'zod'
import { calculateAge } from '../util'

export const registerSchema = z.object({
  name: z.string().min(3),
  email: z.string().email(),
  password: z.string().min(6, {
    message: 'Password must be at least 6 characters'
  })
})

export const profileSchema = z.object({
  gender: z.string().min(1),
  description: z.string().min(1),
  city: z.string().min(1),
  country: z.string().min(1),
  dateOfBirth: z.string().min(1, {
    message: 'Date of birth is required'
  }).refine(dateString => {
    const age = calculateAge(new Date(dateString))
    return age >= 18
  }, {
    message: 'You must be at least 18 to use this app'
  }),
})

export const combinedRegisterSchema = registerSchema.and(profileSchema)
```

**Validation d'âge :** Minimum 18 ans.

---

### Server Action : `registerUser`

**Fichier : `src/app/actions/authActions.ts`**

```typescript
export async function registerUser(data: RegisterSchema): Promise<ActionResult<User>> {
  try {
    // 1. Validation Zod
    const validated = combinedRegisterSchema.safeParse(data)
    if (!validated.success) {
      return { status: 'error', error: validated.error.errors }
    }

    const { name, email, password, gender, description, 
            dateOfBirth, city, country } = validated.data

    // 2. Hash password (bcrypt avec salt 10)
    const hashedPassword = await bcrypt.hash(password, 10)

    // 3. Vérification unicité email
    const existingUser = await prisma.user.findUnique({
      where: { email }
    })
    if (existingUser) {
      return { status: 'error', error: 'User already exists' }
    }

    // 4. Création User + Member (transaction implicite)
    const user = await prisma.user.create({
      data: {
        name,
        email,
        passwordHash: hashedPassword,
        profileComplete: true,
        member: {
          create: {
            name,
            description,
            city,
            country,
            dateOfBirth: new Date(dateOfBirth),
            gender
          }
        }
      }
    })

    // 5. Génération token de vérification
    const verificationToken = await generateToken(email, TokenType.VERIFICATION)

    // 6. Envoi email
    await sendVerificationEmail(verificationToken.email, verificationToken.token)

    return { status: 'success', data: user }
  } catch (error) {
    console.log(error)
    return { status: 'error', error: 'Something went wrong' }
  }
}
```

---

### Composant Formulaire

**Fichier : `src/app/(auth)/register/RegisterForm.tsx`**

**Simplifié :**

```typescript
'use client'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { registerUser } from '@/app/actions/authActions'

export default function RegisterForm() {
  const form = useForm({
    resolver: zodResolver(combinedRegisterSchema),
    defaultValues: {
      name: '',
      email: '',
      password: '',
      gender: '',
      description: '',
      city: '',
      country: '',
      dateOfBirth: ''
    }
  })

  const onSubmit = async (data) => {
    const result = await registerUser(data)
    
    if (result.status === 'success') {
      router.push('/register/success')
    } else {
      // Affichage erreurs
      toast.error(result.error)
    }
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      {/* Champs de formulaire */}
    </form>
  )
}
```

---

## Connexion (Login)

### Flux Complet

```mermaid
flowchart TD
    A[Utilisateur soumet Email + Password] --> B{Email vérifié?}
    B -->|Non| C[Envoi nouveau token de vérification]
    C --> D[Erreur: Vérifiez votre email]
    B -->|Oui| E[NextAuth signIn credentials]
    E --> F{Credentials valides?}
    F -->|Non| G[Erreur: Identifiants invalides]
    F -->|Oui| H[Génération JWT]
    H --> I[Cookie de session créé]
    I --> J[Redirection /members]
    
    style A fill:#e1f5ff,stroke:#01579b,stroke-width:4px,color:#000
    style J fill:#c8e6c9,stroke:#2e7d32,stroke-width:4px,color:#000
    style D fill:#fff3cd,stroke:#856404,stroke-width:3px,color:#000
    style G fill:#ffcdd2,stroke:#c62828,stroke-width:3px,color:#000
```

---

### Schéma de Validation

**Fichier : `src/lib/schemas/loginSchema.ts`**

```typescript
import { z } from 'zod'

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6, {
    message: 'Password must be at least 6 characters'
  })
})

export type LoginSchema = z.infer<typeof loginSchema>
```

---

### Server Action : `signInUser`

```typescript
export async function signInUser(data: LoginSchema): Promise<ActionResult<string>> {
  try {
    // 1. Vérification utilisateur existe
    const existingUser = await getUserByEmail(data.email)
    if (!existingUser || !existingUser.email) {
      return { status: 'error', error: 'Invalid credentials' }
    }

    // 2. Vérification email vérifié
    if (!existingUser.emailVerified) {
      // Renvoie un nouveau token
      const token = await generateToken(existingUser.email, TokenType.VERIFICATION)
      await sendVerificationEmail(token.email, token.token)
      
      return { 
        status: 'error', 
        error: 'Please verify your email address before logging in' 
      }
    }

    // 3. Connexion via NextAuth
    const result = await signIn('credentials', {
      email: data.email,
      password: data.password,
      redirect: false
    })

    return { status: 'success', data: 'Logged in' }
  } catch (error) {
    if (error instanceof AuthError) {
      switch (error.type) {
        case 'CredentialsSignin':
          return { status: 'error', error: 'Invalid credentials' }
        default:
          return { status: 'error', error: 'Something went wrong' }
      }
    }
    return { status: 'error', error: 'Something else went wrong' }
  }
}
```

**Points clés :**
- Vérification email **avant** connexion
- `redirect: false` pour gérer redirection côté client
- Gestion erreurs NextAuth

---

### Composant Formulaire

**Fichier : `src/app/(auth)/login/LoginForm.tsx`**

```typescript
'use client'
import { signInUser } from '@/app/actions/authActions'

export default function LoginForm() {
  const form = useForm({
    resolver: zodResolver(loginSchema)
  })

  const onSubmit = async (data) => {
    const result = await signInUser(data)
    
    if (result.status === 'success') {
      router.push('/members')
      router.refresh() // Rafraîchit la session
    } else {
      toast.error(result.error)
    }
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      {/* Email input */}
      {/* Password input */}
      <button type="submit">Se connecter</button>
    </form>
  )
}
```

---

## Vérification Email

### Flux Complet

```mermaid
flowchart TD
    A[Inscription / Demande renvoie email] --> B[Génération token unique 96 chars]
    B --> C[Stockage Token dans DB avec expiration 24h]
    C --> D[Envoi email avec lien]
    D --> E[Utilisateur clique sur lien]
    E --> F[Requête GET /verify-email?token=xxx]
    F --> G{Token valide?}
    G -->|Non| H[Erreur: Token invalide]
    G -->|Oui| I{Token expiré?}
    I -->|Oui| J[Erreur: Token expiré]
    I -->|Non| K[Mise à jour User.emailVerified = Date]
    K --> L[Suppression Token de DB]
    L --> M[Succès: Email vérifié]
    M --> N[Redirection /login]
    
    style A fill:#e1f5ff,stroke:#01579b,stroke-width:4px,color:#000
    style M fill:#c8e6c9,stroke:#2e7d32,stroke-width:4px,color:#000
    style H fill:#ffcdd2,stroke:#c62828,stroke-width:3px,color:#000
    style J fill:#ffcdd2,stroke:#c62828,stroke-width:3px,color:#000
```

---

### Génération du Token

**Fichier : `src/lib/tokens.ts`**

```typescript
export async function generateToken(email: string, type: TokenType) {
  // 1. Génération token crypto sécurisé (96 caractères hexadécimaux)
  const arrayBuffer = new Uint8Array(48)
  crypto.getRandomValues(arrayBuffer)
  const token = Array.from(arrayBuffer, byte => 
    byte.toString(16).padStart(2, '0')
  ).join('')
  
  // 2. Expiration : 24 heures
  const expires = new Date(Date.now() + 1000 * 60 * 60 * 24)

  // 3. Suppression ancien token si existe
  const existingToken = await getTokenByEmail(email)
  if (existingToken) {
    await prisma.token.delete({ where: { id: existingToken.id } })
  }

  // 4. Création nouveau token
  return prisma.token.create({
    data: {
      email,
      token,
      expires,
      type
    }
  })
}
```

**Format token :** `a3f9e2c1b8d7...` (96 caractères hexadécimaux)

---

### Envoi Email

**Fichier : `src/lib/mail.ts`**

```typescript
import { Resend } from 'resend'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function sendVerificationEmail(email: string, token: string) {
  const link = `${process.env.NEXT_PUBLIC_BASE_URL}/verify-email?token=${token}`
  
  return resend.emails.send({
    from: 'onboarding@resend.dev',
    to: email,
    subject: 'Verify your email address',
    html: `
      <h1>Verify your email</h1>
      <p>Click the link below to verify your email address:</p>
      <a href="${link}">Verify Email</a>
      <p>This link will expire in 24 hours.</p>
    `
  })
}
```

**Lien généré :**
```
http://localhost:3000/verify-email?token=a3f9e2c1b8d7...
```

---

### Vérification du Token

**Server Action : `verifyEmail`**

```typescript
export async function verifyEmail(token: string): Promise<ActionResult<string>> {
  try {
    // 1. Récupération token
    const existingToken = await getTokenByToken(token)
    if (!existingToken) {
      return { status: 'error', error: 'Invalid token' }
    }

    // 2. Vérification expiration
    const hasExpired = new Date() > existingToken.expires
    if (hasExpired) {
      return { status: 'error', error: 'Token has expired' }
    }

    // 3. Récupération utilisateur
    const existingUser = await getUserByEmail(existingToken.email)
    if (!existingUser) {
      return { status: 'error', error: 'User not found' }
    }

    // 4. Mise à jour User.emailVerified
    await prisma.user.update({
      where: { id: existingUser.id },
      data: { emailVerified: new Date() }
    })

    // 5. Suppression token (usage unique)
    await prisma.token.delete({ where: { id: existingToken.id } })

    return { status: 'success', data: 'Success' }
  } catch (error) {
    console.log(error)
    throw error
  }
}
```

---

### Page de Vérification

**Fichier : `src/app/(auth)/verify-email/page.tsx`**

```typescript
import { verifyEmail } from '@/app/actions/authActions'

export default async function VerifyEmailPage({ searchParams }) {
  const { token } = searchParams
  
  if (!token) {
    return <div>Token manquant</div>
  }
  
  const result = await verifyEmail(token)
  
  if (result.status === 'success') {
    return (
      <div>
        <h1>Email vérifié avec succès !</h1>
        <Link href="/login">Se connecter</Link>
      </div>
    )
  }
  
  return (
    <div>
      <h1>Erreur</h1>
      <p>{result.error}</p>
    </div>
  )
}
```

---

## Réinitialisation Mot de Passe

### Flux Complet

```mermaid
flowchart TD
    A[Utilisateur clique Forgot Password] --> B[Formulaire: entrer email]
    B --> C[Server Action: generateResetPasswordEmail]
    C --> D{Email existe?}
    D -->|Non| E[Erreur: Email not found]
    D -->|Oui| F[Génération token PASSWORD_RESET]
    F --> G[Envoi email avec lien reset]
    G --> H[Message: Vérifiez vos emails]
    H --> I[Utilisateur clique lien email]
    I --> J[Page /reset-password?token=xxx]
    J --> K[Formulaire: nouveau password]
    K --> L[Server Action: resetPassword]
    L --> M{Token valide et non expiré?}
    M -->|Non| N[Erreur: Token invalide/expiré]
    M -->|Oui| O[Hash nouveau password]
    O --> P[Mise à jour User.passwordHash]
    P --> Q[Suppression token]
    Q --> R[Succès: Password mis à jour]
    R --> S[Redirection /login]
    
    style A fill:#e1f5ff,stroke:#01579b,stroke-width:4px,color:#000
    style R fill:#c8e6c9,stroke:#2e7d32,stroke-width:4px,color:#000
    style E fill:#ffcdd2,stroke:#c62828,stroke-width:3px,color:#000
    style N fill:#ffcdd2,stroke:#c62828,stroke-width:3px,color:#000
```

---

### Étape 1 : Demande de Réinitialisation

**Server Action : `generateResetPasswordEmail`**

```typescript
export async function generateResetPasswordEmail(email: string): Promise<ActionResult<string>> {
  try {
    // 1. Vérification utilisateur existe
    const existingUser = await getUserByEmail(email)
    if (!existingUser) {
      return { status: 'error', error: 'Email not found' }
    }

    // 2. Génération token PASSWORD_RESET
    const token = await generateToken(email, TokenType.PASSWORD_RESET)

    // 3. Envoi email
    await sendPasswordResetEmail(token.email, token.token)

    return { 
      status: 'success', 
      data: 'Password reset email has been sent. Please check your emails' 
    }
  } catch (error) {
    console.log(error)
    return { status: 'error', error: 'Something went wrong' }
  }
}
```

---

### Étape 2 : Envoi Email

```typescript
export async function sendPasswordResetEmail(email: string, token: string) {
  const link = `${process.env.NEXT_PUBLIC_BASE_URL}/reset-password?token=${token}`
  
  return resend.emails.send({
    from: 'onboarding@resend.dev',
    to: email,
    subject: 'Reset your password',
    html: `
      <h1>Reset your password</h1>
      <p>Click the link below to reset your password:</p>
      <a href="${link}">Reset Password</a>
      <p>This link will expire in 24 hours.</p>
      <p>If you didn't request this, please ignore this email.</p>
    `
  })
}
```

---

### Étape 3 : Réinitialisation

**Server Action : `resetPassword`**

```typescript
export async function resetPassword(
  password: string, 
  token: string | null
): Promise<ActionResult<string>> {
  try {
    if (!token) return { status: 'error', error: 'Missing token' }

    // 1. Vérification token
    const existingToken = await getTokenByToken(token)
    if (!existingToken) {
      return { status: 'error', error: 'Invalid token' }
    }

    // 2. Vérification expiration
    const hasExpired = new Date() > existingToken.expires
    if (hasExpired) {
      return { status: 'error', error: 'Token has expired' }
    }

    // 3. Récupération utilisateur
    const existingUser = await getUserByEmail(existingToken.email)
    if (!existingUser) {
      return { status: 'error', error: 'User not found' }
    }

    // 4. Hash nouveau password
    const hashedPassword = await bcrypt.hash(password, 10)

    // 5. Mise à jour password
    await prisma.user.update({
      where: { id: existingUser.id },
      data: { passwordHash: hashedPassword }
    })

    // 6. Suppression token
    await prisma.token.delete({
      where: { id: existingToken.id }
    })

    return { 
      status: 'success', 
      data: 'Password updated successfully. Please try logging in' 
    }
  } catch (error) {
    console.log(error)
    return { status: 'error', error: 'Something went wrong' }
  }
}
```

---

## Connexion Sociale (Google, GitHub)

### Flux OAuth 2.0

```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant A as Next Match
    participant N as NextAuth
    participant O as OAuth Provider<br/>(Google/GitHub)
    participant DB as Database

    U->>A: Clique "Sign in with Google"
    A->>N: signIn('google')
    N->>O: Redirection vers OAuth
    O->>U: Page de consentement
    U->>O: Autorise l'application
    O->>N: Callback avec code
    N->>O: Échange code contre tokens
    O->>N: access_token, id_token
    N->>DB: Cherche User par provider + providerAccountId
    
    alt Utilisateur existant
        DB->>N: User trouvé
        N->>A: Session créée
        A->>U: Redirection /members
    else Nouveau utilisateur
        N->>DB: Création User + Account
        DB->>N: User créé (profileComplete = false)
        N->>A: Session créée
        A->>U: Redirection /complete-profile
    end
```

---

### Composant Bouton Social Login

**Fichier : `src/app/(auth)/login/SocialLogin.tsx`**

```typescript
'use client'
import { signIn } from 'next-auth/react'
import { FcGoogle } from 'react-icons/fc'
import { FaGithub } from 'react-icons/fa'

export default function SocialLogin() {
  const onClick = (provider: 'google' | 'github') => {
    signIn(provider, {
      callbackUrl: '/members' // Redirection après succès
    })
  }

  return (
    <div className="flex gap-2">
      <button onClick={() => onClick('google')}>
        <FcGoogle size={30} />
        Continue with Google
      </button>
      
      <button onClick={() => onClick('github')}>
        <FaGithub size={30} />
        Continue with GitHub
      </button>
    </div>
  )
}
```

---

### Gestion Nouveau Utilisateur OAuth

**Différence avec Credentials :**

| Aspect | Credentials | OAuth (Google/GitHub) |
|--------|-------------|----------------------|
| **Email** | Fourni par user | Récupéré automatiquement |
| **Password** | Hash stocké | `passwordHash = null` |
| **Email vérifié** | `false` (nécessite vérification) | `true` (vérifié par provider) |
| **Profil complet** | `true` (formulaire complet) | `false` (manque infos dating) |
| **Table Account** | Pas créée | Créée automatiquement |

**Flux après première connexion OAuth :**

1. **User créé** : 
   - `emailVerified` = date (auto)
   - `profileComplete` = `false`
   - `passwordHash` = `null`

2. **Account créé** :
   - `provider` = `"google"` ou `"github"`
   - `providerAccountId` = ID OAuth
   - `access_token`, `refresh_token` stockés

3. **Middleware redirige** : `/complete-profile`

4. **Utilisateur complète profil** : Formulaire avec `gender`, `dateOfBirth`, `city`, `country`, `description`

5. **Member créé** : Profil public dating

6. **Mise à jour User** : `profileComplete` = `true`

7. **Accès complet** : Redirection `/members`

---

### Server Action : `completeSocialLoginProfile`

```typescript
export async function completeSocialLoginProfile(
  data: ProfileSchema
): Promise<ActionResult<string>> {
  // 1. Vérification session
  const session = await auth()
  if (!session?.user) {
    return { status: 'error', error: 'User not found' }
  }

  try {
    // 2. Mise à jour User et création Member
    const user = await prisma.user.update({
      where: { id: session.user.id },
      data: {
        profileComplete: true,
        member: {
          create: {
            name: session.user.name as string,
            image: session.user.image, // Photo de profil OAuth
            gender: data.gender,
            dateOfBirth: new Date(data.dateOfBirth),
            description: data.description,
            city: data.city,
            country: data.country
          }
        }
      },
      select: {
        accounts: {
          select: {
            provider: true
          }
        }
      }
    })

    return { status: 'success', data: user.accounts[0].provider }
  } catch (error) {
    console.log(error)
    throw error
  }
}
```

---

## Système de Rôles

### Enum Role

**Fichier : `prisma/schema.prisma`**

```prisma
enum Role {
  MEMBER
  ADMIN
}

model User {
  // ...
  role Role @default(MEMBER)
}
```

**Rôles disponibles :**
- **MEMBER** : Utilisateur standard (défaut)
- **ADMIN** : Administrateur (accès modération)

---

### Vérification Côté Serveur

**Fonction utilitaire :**

```typescript
export async function getUserRole() {
  const session = await auth()
  const role = session?.user.role
  
  if (!role) throw new Error('Not in role')
  
  return role
}
```

**Utilisation dans Server Action :**

```typescript
export async function deletePhoto(photoId: string) {
  const role = await getUserRole()
  
  if (role !== 'ADMIN') {
    throw new Error('Unauthorized')
  }
  
  // Action admin...
}
```

---

### Vérification Côté Client (Hook)

**Fichier : `src/hooks/useRole.ts`**

```typescript
import { useSession } from 'next-auth/react'
import { Role } from '@prisma/client'

export const useRole = () => {
  const { data: session } = useSession()
  
  const role = session?.user?.role
  
  return {
    isAdmin: role === 'ADMIN',
    isMember: role === 'MEMBER',
    role
  }
}
```

**Utilisation :**

```typescript
'use client'
import { useRole } from '@/hooks/useRole'

export default function AdminButton() {
  const { isAdmin } = useRole()
  
  if (!isAdmin) return null
  
  return <button>Action Admin</button>
}
```

---

### Protection Middleware

**Rappel `middleware.ts` :**

```typescript
const isAdmin = req.auth?.user.role === 'ADMIN'
const isAdminRoute = nextUrl.pathname.startsWith('/admin')

// Accès admin uniquement
if (isAdminRoute && !isAdmin) {
  return NextResponse.redirect(new URL('/', nextUrl))
}

// Admins bypass toutes protections
if (isAdmin) {
  return NextResponse.next()
}
```

---

## Complete Profile Flow

### Scénario : Social Login

**Problème :** Google/GitHub fournissent seulement `name`, `email`, `image`.

**Solution :** Formulaire `complete-profile` pour infos dating.

---

### Flux

```mermaid
flowchart TD
    A[Connexion Google/GitHub] --> B[NextAuth crée User + Account]
    B --> C[User.profileComplete = false]
    C --> D[Session créée]
    D --> E[Middleware détecte profil incomplet]
    E --> F[Redirection /complete-profile]
    F --> G[Utilisateur remplit formulaire]
    G --> H[Server Action: completeSocialLoginProfile]
    H --> I[Création Member avec infos dating]
    I --> J[User.profileComplete = true]
    J --> K[Rafraîchissement session]
    K --> L[Redirection /members]
    
    style A fill:#e1f5ff,stroke:#01579b,stroke-width:4px,color:#000
    style L fill:#c8e6c9,stroke:#2e7d32,stroke-width:4px,color:#000
```

---

### Formulaire Complete Profile

**Fichier : `src/app/(auth)/complete-profile/CompleteProfileForm.tsx`**

```typescript
'use client'
import { completeSocialLoginProfile } from '@/app/actions/authActions'

export default function CompleteProfileForm() {
  const form = useForm({
    resolver: zodResolver(profileSchema)
  })

  const onSubmit = async (data) => {
    const result = await completeSocialLoginProfile(data)
    
    if (result.status === 'success') {
      // Rafraîchir la session (important!)
      router.refresh()
      router.push('/members')
    } else {
      toast.error(result.error)
    }
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      {/* gender */}
      {/* dateOfBirth */}
      {/* city */}
      {/* country */}
      {/* description */}
      <button type="submit">Terminer mon profil</button>
    </form>
  )
}
```

---

## Sécurité

### Hachage des Mots de Passe

**Algorithme :** bcrypt avec salt 10

```typescript
import bcrypt from 'bcryptjs'

// Inscription
const hashedPassword = await bcrypt.hash(password, 10)

// Connexion
const isValid = await compare(password, user.passwordHash)
```

**Pourquoi bcrypt ?**
- Lent (ralentit attaques brute-force)
- Avec salt (chaque hash est unique)
- Standard industrie

---

### Génération de Tokens Sécurisés

```typescript
const arrayBuffer = new Uint8Array(48) // 48 bytes
crypto.getRandomValues(arrayBuffer)    // Crypto sécurisé
const token = Array.from(arrayBuffer, byte => 
  byte.toString(16).padStart(2, '0')
).join('')
// Résultat : 96 caractères hexadécimaux
```

**Entropie :** 48 bytes = 384 bits (impossible à brute-force)

---

### Expiration des Tokens

```typescript
const expires = new Date(Date.now() + 1000 * 60 * 60 * 24) // 24h
```

**Vérification expiration :**

```typescript
const hasExpired = new Date() > existingToken.expires
if (hasExpired) {
  return { status: 'error', error: 'Token has expired' }
}
```

---

### Protection CSRF

NextAuth inclut automatiquement la protection CSRF :

- Token CSRF dans les formulaires
- Vérification côté serveur
- Cookies `SameSite=Lax`

---

### Cookies HTTP-Only

NextAuth configure automatiquement :

```
Set-Cookie: next-auth.session-token=...; HttpOnly; Secure; SameSite=Lax
```

**HttpOnly** : Pas accessible par JavaScript (XSS protection)
**Secure** : HTTPS seulement (production)
**SameSite** : Protection CSRF

---

### Variables d'Environnement Sensibles

**Dans `.env` (JAMAIS dans Git) :**

```env
# NextAuth
NEXTAUTH_SECRET="votre-secret-long-aleatoire"
NEXTAUTH_URL="http://localhost:3000"

# Database
DATABASE_URL="postgresql://..."

# Credentials OAuth
GOOGLE_CLIENT_ID="..."
GOOGLE_CLIENT_SECRET="..."
GITHUB_CLIENT_ID="..."
GITHUB_CLIENT_SECRET="..."

# Email
RESEND_API_KEY="re_..."
```

**Génération `NEXTAUTH_SECRET` :**

```bash
openssl rand -base64 32
```

---

## Diagrammes de Flux

### Vue d'Ensemble du Système

```mermaid
flowchart TB
    subgraph CLIENT["🌐 Client (Browser)"]
        LF[LoginForm]
        RF[RegisterForm]
        SF[SocialLogin]
    end
    
    subgraph NEXTAUTH["🔐 NextAuth.js"]
        NA[NextAuth Core]
        CP[Credentials Provider]
        GP[Google Provider]
        GHP[GitHub Provider]
        JWT[JWT Strategy]
    end
    
    subgraph SERVER["⚙️ Server Actions"]
        SI[signInUser]
        RU[registerUser]
        VE[verifyEmail]
        RP[resetPassword]
        CSL[completeSocialLoginProfile]
    end
    
    subgraph DATABASE["🗄️ Database (PostgreSQL)"]
        UT[User Table]
        AT[Account Table]
        MT[Member Table]
        TT[Token Table]
    end
    
    subgraph SERVICES["📧 Services Externes"]
        RS[Resend Email]
    end
    
    LF -->|signInUser| SI
    RF -->|registerUser| RU
    SF -->|signIn provider| NA
    
    SI --> CP
    CP --> UT
    
    GP --> NA
    GHP --> NA
    NA --> AT
    NA --> UT
    NA --> JWT
    
    RU --> UT
    RU --> MT
    RU --> TT
    RU --> RS
    
    VE --> UT
    VE --> TT
    
    RP --> UT
    RP --> TT
    RP --> RS
    
    CSL --> UT
    CSL --> MT
    
    style CLIENT fill:#e3f2fd,stroke:#1976d2,stroke-width:3px,color:#000
    style NEXTAUTH fill:#fff3e0,stroke:#f57c00,stroke-width:3px,color:#000
    style SERVER fill:#f3e5f5,stroke:#7b1fa2,stroke-width:3px,color:#000
    style DATABASE fill:#e8f5e9,stroke:#388e3c,stroke-width:3px,color:#000
    style SERVICES fill:#fce4ec,stroke:#c2185b,stroke-width:3px,color:#000
```

---

### Cycle de Vie Session JWT

```mermaid
sequenceDiagram
    participant C as Client
    participant N as NextAuth
    participant DB as Database
    
    rect rgb(225, 245, 255)
        Note over C,DB: 🔵 INSCRIPTION
        C->>N: registerUser(data)
        N->>DB: Create User + Member
        N->>DB: Create Token
        N->>C: Email envoyé
    end
    
    rect rgb(255, 243, 205)
        Note over C,DB: 🟡 VÉRIFICATION EMAIL
        C->>N: verifyEmail(token)
        N->>DB: Update emailVerified
        N->>DB: Delete Token
        N->>C: Succès
    end
    
    rect rgb(200, 230, 201)
        Note over C,DB: 🟢 CONNEXION
        C->>N: signIn(credentials)
        N->>DB: Vérification User
        N->>N: Génération JWT
        N->>C: Cookie session créé
    end
    
    rect rgb(255, 224, 178)
        Note over C,DB: 🟠 REQUÊTES AUTHENTIFIÉES
        C->>N: Requête avec cookie
        N->>N: Validation JWT
        N->>C: Données session
    end
    
    rect rgb(255, 205, 210)
        Note over C,DB: 🔴 DÉCONNEXION
        C->>N: signOut()
        N->>C: Suppression cookie
    end
```

---

### Matrice Décisionnelle Middleware

```mermaid
flowchart TD
    START([Requête entrante]) --> CHECK_ADMIN{User.role == ADMIN?}
    
    CHECK_ADMIN -->|Oui| ALLOW[✅ NextResponse.next]
    CHECK_ADMIN -->|Non| CHECK_PUBLIC{Route publique?}
    
    CHECK_PUBLIC -->|Oui| ALLOW
    CHECK_PUBLIC -->|Non| CHECK_ADMIN_ROUTE{Route /admin/*?}
    
    CHECK_ADMIN_ROUTE -->|Oui| REDIRECT_HOME[❌ Redirect /]
    CHECK_ADMIN_ROUTE -->|Non| CHECK_AUTH_ROUTE{Route auth?<br/>/login, /register}
    
    CHECK_AUTH_ROUTE -->|Oui| CHECK_LOGGED_IN{isLoggedIn?}
    CHECK_LOGGED_IN -->|Oui| REDIRECT_MEMBERS[❌ Redirect /members]
    CHECK_LOGGED_IN -->|Non| ALLOW
    
    CHECK_AUTH_ROUTE -->|Non| CHECK_PROTECTED{Route protégée?}
    CHECK_PROTECTED -->|Oui| CHECK_LOGGED_IN2{isLoggedIn?}
    CHECK_LOGGED_IN2 -->|Non| REDIRECT_LOGIN[❌ Redirect /login]
    CHECK_LOGGED_IN2 -->|Oui| CHECK_PROFILE{profileComplete?}
    
    CHECK_PROFILE -->|Non| CHECK_COMPLETE{Route == /complete-profile?}
    CHECK_COMPLETE -->|Non| REDIRECT_COMPLETE[❌ Redirect /complete-profile]
    CHECK_COMPLETE -->|Oui| ALLOW
    
    CHECK_PROFILE -->|Oui| ALLOW
    
    style START fill:#e1f5ff,stroke:#01579b,stroke-width:4px,color:#000
    style ALLOW fill:#c8e6c9,stroke:#2e7d32,stroke-width:4px,color:#000
    style REDIRECT_HOME fill:#ffcdd2,stroke:#c62828,stroke-width:3px,color:#000
    style REDIRECT_MEMBERS fill:#fff3cd,stroke:#856404,stroke-width:3px,color:#000
    style REDIRECT_LOGIN fill:#ffcdd2,stroke:#c62828,stroke-width:3px,color:#000
    style REDIRECT_COMPLETE fill:#fff3cd,stroke:#856404,stroke-width:3px,color:#000
```

---

## API et Server Actions

### Routes API NextAuth

| Route | Méthode | Description |
|-------|---------|-------------|
| `/api/auth/signin` | GET | Page de connexion NextAuth |
| `/api/auth/callback/:provider` | GET | Callback OAuth |
| `/api/auth/signout` | POST | Déconnexion |
| `/api/auth/session` | GET | Récupération session |
| `/api/auth/csrf` | GET | Token CSRF |
| `/api/auth/providers` | GET | Liste providers |

**Configuration :** `src/app/api/auth/[...nextauth]/route.ts`

```typescript
import { handlers } from '@/auth'

export const { GET, POST } = handlers
```

---

### Server Actions Disponibles

**Fichier : `src/app/actions/authActions.ts`**

| Fonction | Paramètres | Retour | Description |
|----------|------------|--------|-------------|
| `signInUser` | `LoginSchema` | `ActionResult<string>` | Connexion credentials |
| `signOutUser` | - | `void` | Déconnexion |
| `registerUser` | `RegisterSchema` | `ActionResult<User>` | Inscription complète |
| `verifyEmail` | `token: string` | `ActionResult<string>` | Vérification email |
| `generateResetPasswordEmail` | `email: string` | `ActionResult<string>` | Demande reset password |
| `resetPassword` | `password, token` | `ActionResult<string>` | Reset password |
| `completeSocialLoginProfile` | `ProfileSchema` | `ActionResult<string>` | Compléter profil OAuth |
| `getUserByEmail` | `email: string` | `User \| null` | Recherche user |
| `getUserById` | `id: string` | `User \| null` | Recherche user |
| `getAuthUserId` | - | `string` | ID user connecté |
| `getUserRole` | - | `Role` | Rôle user connecté |

---

### Type `ActionResult`

**Fichier : `src/types/index.d.ts`**

```typescript
export type ActionResult<T> = 
  | { status: 'success'; data: T }
  | { status: 'error'; error: string | z.ZodIssue[] }
```

**Utilisation :**

```typescript
const result = await signInUser(data)

if (result.status === 'success') {
  console.log(result.data) // Type T
} else {
  console.error(result.error) // string | ZodIssue[]
}
```

---

## Configuration Environnement

### Variables Requises

**Fichier : `.env`**

```env
# ===========================
# DATABASE
# ===========================
DATABASE_URL="postgresql://user:password@host:5432/db"
DIRECT_URL="postgresql://user:password@host:5432/db"

# ===========================
# NEXTAUTH
# ===========================
NEXTAUTH_SECRET="votre-secret-aleatoire-long"
NEXTAUTH_URL="http://localhost:3000"

# ===========================
# GOOGLE OAUTH
# ===========================
GOOGLE_CLIENT_ID="xxx.apps.googleusercontent.com"
GOOGLE_CLIENT_SECRET="GOCSPX-xxx"

# ===========================
# GITHUB OAUTH
# ===========================
GITHUB_CLIENT_ID="Iv1.xxxx"
GITHUB_CLIENT_SECRET="xxx"

# ===========================
# EMAIL (RESEND)
# ===========================
RESEND_API_KEY="re_xxx"
NEXT_PUBLIC_BASE_URL="http://localhost:3000"

# ===========================
# CLOUDINARY (pour photos)
# ===========================
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="xxx"
CLOUDINARY_API_KEY="xxx"
CLOUDINARY_API_SECRET="xxx"

# ===========================
# PUSHER (pour messagerie)
# ===========================
NEXT_PUBLIC_PUSHER_APP_KEY="xxx"
PUSHER_APP_ID="xxx"
PUSHER_SECRET="xxx"
```

---

### Génération Secrets

**NEXTAUTH_SECRET :**

```bash
# Linux/Mac
openssl rand -base64 32

# PowerShell (Windows)
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))

# Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

---

### URLs de Callback OAuth

**Development :**
```
http://localhost:3000/api/auth/callback/google
http://localhost:3000/api/auth/callback/github
```

**Production :**
```
https://votredomaine.com/api/auth/callback/google
https://votredomaine.com/api/auth/callback/github
```

**Important :** Configurez ces URLs dans Google Cloud Console et GitHub OAuth Apps.

---

## Troubleshooting

### Erreur : "Invalid credentials"

**Causes possibles :**
1. Email incorrect
2. Password incorrect
3. Email non vérifié
4. User n'existe pas

**Solution :**
- Vérifiez email dans DB
- Vérifiez `emailVerified` n'est pas `null`
- Testez hash bcrypt :
  ```typescript
  const isValid = await compare('test123', user.passwordHash)
  console.log(isValid) // Doit être true
  ```

---

### Erreur : "Please verify your email"

**Cause :** `User.emailVerified` est `null`

**Solution :**
1. Vérifiez Token dans DB :
   ```sql
   SELECT * FROM "Token" WHERE email = 'user@example.com';
   ```
2. Vérifiez email Resend (spam, logs)
3. Test manuel :
   ```typescript
   await prisma.user.update({
     where: { email: 'user@example.com' },
     data: { emailVerified: new Date() }
   })
   ```

---

### Erreur : "Token has expired"

**Cause :** Token > 24h

**Solution :**
1. Demandez un nouveau token (renvoyer email)
2. Ou prolongez expiration :
   ```typescript
   const expires = new Date(Date.now() + 1000 * 60 * 60 * 48) // 48h
   ```

---

### Session non persistante après connexion

**Causes possibles :**
1. `NEXTAUTH_SECRET` manquant/incorrect
2. Cookie bloqué (SameSite)
3. Domaine incorrect

**Solution :**
1. Vérifiez `.env` :
   ```env
   NEXTAUTH_SECRET="..."
   NEXTAUTH_URL="http://localhost:3000"
   ```
2. Vérifiez cookies dans DevTools (Application > Cookies)
3. Redémarrez serveur Next.js

---

### OAuth ne fonctionne pas

**Causes :**
1. Credentials incorrects (CLIENT_ID, SECRET)
2. Callback URL incorrecte
3. API non activée (Google)

**Solution :**
1. Vérifiez `.env` :
   ```env
   GOOGLE_CLIENT_ID="..."
   GOOGLE_CLIENT_SECRET="..."
   ```
2. Vérifiez Callback URL dans console provider
3. Google : Activez **Google+ API**
4. Testez avec `console.log` dans `authorize()`

---

### Erreur : "profileComplete undefined"

**Cause :** Callbacks JWT/Session mal configurés

**Solution :**

Vérifiez `src/auth.ts` :

```typescript
callbacks: {
  async jwt({user, token}) {
    if (user) {
      token.profileComplete = user.profileComplete // Important
      token.role = user.role
    }
    return token
  },
  async session({token, session}) {
    if (token.sub && session.user) {
      session.user.id = token.sub
      session.user.profileComplete = token.profileComplete as boolean
      session.user.role = token.role as Role
    }
    return session
  }
}
```

---

### Middleware redirige en boucle

**Cause :** Logique de redirection incorrecte

**Checklist :**
1. Route `/complete-profile` n'est pas dans `authRoutes`
2. Condition `nextUrl.pathname !== '/complete-profile'` présente
3. `isPublic` ou `isAdmin` bypass

**Debug :**

```typescript
export default auth((req) => {
  console.log({
    path: req.nextUrl.pathname,
    isLoggedIn: !!req.auth,
    profileComplete: req.auth?.user.profileComplete
  })
  // ...
})
```

---

### Email ne s'envoie pas (Resend)

**Causes :**
1. `RESEND_API_KEY` invalide
2. `from` email non vérifié
3. Quota dépassé (free tier)

**Solution :**
1. Vérifiez API key dans [Resend Dashboard](https://resend.com/api-keys)
2. Utilisez `onboarding@resend.dev` (free tier)
3. Vérifiez domaine pour production
4. Consultez logs Resend

---

## Résumé

**Architecture :**
- **NextAuth.js v5** (Auth.js)
- **JWT Strategy** (stateless)
- **3 Providers** : Credentials, Google, GitHub
- **PrismaAdapter** : PostgreSQL

**Flux principaux :**
1. **Inscription** : Register → Email verification → Login
2. **Connexion Credentials** : Email + Password → JWT → Session
3. **Connexion OAuth** : Google/GitHub → Complete profile → Session
4. **Reset Password** : Email → Token → New password

**Sécurité :**
- Bcrypt pour passwords
- Tokens crypto sécurisés (96 chars)
- Expiration 24h
- HTTP-Only cookies
- CSRF protection

**Protection :**
- Middleware Next.js
- Routes publiques/privées/admin
- Vérification `profileComplete`
- Système de rôles

**Points clés :**
- Session JWT enrichie (`profileComplete`, `role`)
- Séparation `User` (auth) / `Member` (profil public)
- Social login nécessite complete profile
- Email verification obligatoire

---

**Ce système d'authentification est production-ready et suit les meilleures pratiques de sécurité.**

