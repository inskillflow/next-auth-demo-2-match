# Flux Complet d'Authentification - Analyse Détaillée

Ce document explique **EXACTEMENT** comment fonctionne le système d'authentification de Next Match, avec tous les extraits de code et le flux de données complet.

---

## 🔍 Question Clé : Y a-t-il Deux Bases de Données ?

### ❌ **NON - Il n'y a qu'UNE SEULE base de données**

**Clarification importante :**

| Ce que vous pourriez penser | Ce qui se passe réellement |
|----------------------------|---------------------------|
| NextAuth stocke dans sa propre DB | ❌ Faux |
| Supabase Auth gère l'authentification | ❌ Faux |
| Deux bases séparées communiquent | ❌ Faux |

**La vérité :**

```
┌─────────────────────────────────────────────────┐
│  IL N'Y A QU'UNE SEULE BASE DE DONNÉES          │
│  PostgreSQL hébergée sur Supabase               │
│                                                 │
│  Supabase est utilisé UNIQUEMENT comme         │
│  provider PostgreSQL (comme Neon)               │
│                                                 │
│  Supabase Auth n'est PAS utilisé               │
│  Supabase Storage n'est PAS utilisé            │
│  Supabase Realtime n'est PAS utilisé           │
│                                                 │
│  Seul PostgreSQL de Supabase est utilisé       │
└─────────────────────────────────────────────────┘
```

### Architecture Réelle

```mermaid
flowchart TB
    subgraph CLIENT["🌐 Client (Browser)"]
        FORM[Formulaire React]
        COOKIE[Cookie HTTP-Only<br/>next-auth.session-token]
    end
    
    subgraph NEXTJS["⚡ Next.js Server"]
        SA[Server Actions<br/>registerUser, signInUser]
        NA[NextAuth.js<br/>JWT Strategy]
        PR[Prisma ORM]
    end
    
    subgraph DATABASE["🗄️ PostgreSQL (Supabase)"]
        UT[User Table]
        AT[Account Table]
        MT[Member Table]
        TT[Token Table]
        PT[Photo Table]
        LT[Like Table]
        MSG[Message Table]
    end
    
    FORM -->|1. POST data| SA
    SA -->|2. Prisma query| PR
    PR -->|3. SQL INSERT/SELECT| DATABASE
    DATABASE -->|4. Data| PR
    PR -->|5. User object| NA
    NA -->|6. Generate JWT| COOKIE
    COOKIE -->|7. Toutes requêtes| NEXTJS
    
    style CLIENT fill:#e3f2fd,stroke:#1976d2,stroke-width:4px,color:#000
    style NEXTJS fill:#fff3e0,stroke:#f57c00,stroke-width:4px,color:#000
    style DATABASE fill:#e8f5e9,stroke:#388e3c,stroke-width:4px,color:#000
```

**Une seule base de données PostgreSQL, accessible via Prisma.**

---

## 📝 Question 1 : Comment on Fait le POST des Users ?

### Flux Complet d'Inscription avec Code

```mermaid
sequenceDiagram
    actor U as 👤 Utilisateur
    participant F as 📱 RegisterForm<br/>(Client)
    participant SA as ⚙️ Server Action<br/>registerUser
    participant Z as ✅ Zod Validation
    participant B as 🔐 bcrypt
    participant P as 🗄️ Prisma
    participant DB as 🐘 PostgreSQL<br/>(Supabase)
    participant R as 📧 Resend
    
    rect rgb(225, 245, 255)
        Note over U,F: ÉTAPE 1 : Remplissage Formulaire
        U->>F: Remplit name, email, password
        U->>F: Remplit gender, dateOfBirth, city, etc.
        U->>F: Clique "Submit"
    end
    
    rect rgb(255, 243, 224)
        Note over F,SA: ÉTAPE 2 : Envoi au Serveur
        F->>SA: POST registerUser(data)
        Note over SA: data = {<br/>name, email, password,<br/>gender, dateOfBirth,<br/>city, country, description<br/>}
    end
    
    rect rgb(255, 243, 205)
        Note over SA,Z: ÉTAPE 3 : Validation
        SA->>Z: combinedRegisterSchema.safeParse(data)
        Z->>Z: Vérifie email format
        Z->>Z: Vérifie password >= 6 chars
        Z->>Z: Vérifie age >= 18 ans
        Z-->>SA: ✅ validated.success = true
    end
    
    rect rgb(255, 224, 178)
        Note over SA,B: ÉTAPE 4 : Hash Password
        SA->>B: bcrypt.hash(password, 10)
        B->>B: Génère salt
        B->>B: Hash avec salt
        B-->>SA: hashedPassword
    end
    
    rect rgb(225, 245, 255)
        Note over SA,DB: ÉTAPE 5 : Vérification Email Unique
        SA->>P: prisma.user.findUnique({where: {email}})
        P->>DB: SELECT * FROM "User" WHERE email = ?
        DB-->>P: null (n'existe pas)
        P-->>SA: null
    end
    
    rect rgb(200, 230, 201)
        Note over SA,DB: ÉTAPE 6 : Création User + Member
        SA->>P: prisma.user.create({<br/>data: {..., member: {create: {...}}}<br/>})
        P->>DB: BEGIN TRANSACTION
        P->>DB: INSERT INTO "User" VALUES (...)
        P->>DB: INSERT INTO "Member" VALUES (...)
        P->>DB: COMMIT
        DB-->>P: User + Member créés
        P-->>SA: user object
    end
    
    rect rgb(255, 235, 238)
        Note over SA,R: ÉTAPE 7 : Email Vérification
        SA->>SA: generateToken(email, VERIFICATION)
        SA->>DB: INSERT INTO "Token" (token, expires, email)
        SA->>R: sendVerificationEmail(email, token)
        R->>U: 📧 Email avec lien
    end
    
    rect rgb(200, 230, 201)
        Note over SA,F: ÉTAPE 8 : Réponse
        SA-->>F: {status: 'success', data: user}
        F->>F: router.push('/register/success')
    end
```

---

### CODE DÉTAILLÉ : Étape par Étape

#### ÉTAPE 1 : Formulaire Client (React)

**Fichier : `src/app/(auth)/register/RegisterForm.tsx`**

```typescript
'use client';

import { registerUser } from '@/app/actions/authActions';
import { RegisterSchema } from '@/lib/schemas/registerSchema';
import { useForm } from 'react-hook-form';

export default function RegisterForm() {
  const [activeStep, setActiveStep] = useState(0);
  
  // React Hook Form avec validation Zod
  const methods = useForm<RegisterSchema>({
    resolver: zodResolver(currentValidationSchema),
    mode: 'onTouched'
  });

  const { handleSubmit, getValues } = methods;

  // 🔥 FONCTION PRINCIPALE : Soumission du formulaire
  const onSubmit = async () => {
    // Récupère TOUTES les données du formulaire
    const data = getValues();
    
    // ⚡ APPEL SERVER ACTION
    const result = await registerUser(data);
    
    if (result.status === 'success') {
      router.push('/register/success');
    } else {
      // Affiche les erreurs
      handleFormServerErrors(result, setError);
    }
  }

  return (
    <FormProvider {...methods}>
      <form onSubmit={handleSubmit(onNext)}>
        {/* Étape 1 : Email, Password, Name */}
        {activeStep === 0 && <UserDetailsForm />}
        
        {/* Étape 2 : Gender, DateOfBirth, City, Country, Description */}
        {activeStep === 1 && <ProfileForm />}
        
        <Button type='submit'>
          {activeStep === 1 ? 'Submit' : 'Continue'}
        </Button>
      </form>
    </FormProvider>
  );
}
```

**Données envoyées :**

```typescript
{
  name: "John Doe",
  email: "john@example.com",
  password: "password123",
  gender: "male",
  dateOfBirth: "1995-06-15",
  city: "Paris",
  country: "France",
  description: "Passionate about traveling and meeting new people."
}
```

---

#### ÉTAPE 2 : Server Action (Next.js)

**Fichier : `src/app/actions/authActions.ts`**

```typescript
'use server';

import { prisma } from '@/lib/prisma';
import { combinedRegisterSchema, RegisterSchema } from '@/lib/schemas/registerSchema';
import bcrypt from 'bcryptjs';
import { generateToken } from '@/lib/tokens';
import { sendVerificationEmail } from '@/lib/mail';
import { TokenType } from '@prisma/client';

export async function registerUser(
  data: RegisterSchema
): Promise<ActionResult<User>> {
  
  try {
    // ════════════════════════════════════════════
    // 1️⃣ VALIDATION ZOD
    // ════════════════════════════════════════════
    const validated = combinedRegisterSchema.safeParse(data);
    
    if (!validated.success) {
      return { 
        status: 'error', 
        error: validated.error.errors 
      };
    }

    const { 
      name, 
      email, 
      password, 
      gender, 
      description, 
      dateOfBirth, 
      city, 
      country 
    } = validated.data;

    // ════════════════════════════════════════════
    // 2️⃣ HASH PASSWORD (bcrypt)
    // ════════════════════════════════════════════
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Exemple :
    // Input:  "password123"
    // Output: "$2a$10$KXE.nPqxs8M7KQxcH.1bPeX5Y9..."
    
    // ════════════════════════════════════════════
    // 3️⃣ VÉRIFICATION EMAIL UNIQUE
    // ════════════════════════════════════════════
    const existingUser = await prisma.user.findUnique({
      where: { email }
    });
    
    // SQL généré par Prisma :
    // SELECT * FROM "User" WHERE email = 'john@example.com'
    
    if (existingUser) {
      return { 
        status: 'error', 
        error: 'User already exists' 
      };
    }

    // ════════════════════════════════════════════
    // 4️⃣ CRÉATION USER + MEMBER (TRANSACTION)
    // ════════════════════════════════════════════
    const user = await prisma.user.create({
      data: {
        name,
        email,
        passwordHash: hashedPassword,
        profileComplete: true,
        
        // 🔥 CRÉATION RELATION MEMBRE (nested create)
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
    });
    
    // SQL généré par Prisma :
    // BEGIN;
    //   INSERT INTO "User" (id, name, email, passwordHash, profileComplete, role) 
    //   VALUES ('cuid...', 'John Doe', 'john@example.com', '$2a$10...', true, 'MEMBER');
    //   
    //   INSERT INTO "Member" (id, userId, name, gender, dateOfBirth, description, city, country)
    //   VALUES ('cuid...', 'cuid-user-id', 'John Doe', 'male', '1995-06-15', 'Passionate...', 'Paris', 'France');
    // COMMIT;

    // ════════════════════════════════════════════
    // 5️⃣ GÉNÉRATION TOKEN VÉRIFICATION
    // ════════════════════════════════════════════
    const verificationToken = await generateToken(
      email, 
      TokenType.VERIFICATION
    );
    
    // SQL généré :
    // INSERT INTO "Token" (id, email, token, expires, type)
    // VALUES ('cuid...', 'john@example.com', 'a3f9e2c1b8d7...', '2024-10-22 10:00:00', 'VERIFICATION');

    // ════════════════════════════════════════════
    // 6️⃣ ENVOI EMAIL
    // ════════════════════════════════════════════
    await sendVerificationEmail(
      verificationToken.email, 
      verificationToken.token
    );
    
    // Appel API Resend :
    // POST https://api.resend.com/emails
    // {
    //   from: "onboarding@resend.dev",
    //   to: "john@example.com",
    //   subject: "Verify your email address",
    //   html: "<a href='http://localhost:3000/verify-email?token=a3f9e2c1...'>Verify</a>"
    // }

    // ════════════════════════════════════════════
    // 7️⃣ RETOUR SUCCESS
    // ════════════════════════════════════════════
    return { 
      status: 'success', 
      data: user 
    };
    
  } catch (error) {
    console.log(error);
    return { 
      status: 'error', 
      error: 'Something went wrong' 
    };
  }
}
```

---

#### Données Créées dans PostgreSQL

**Table `User` :**

| id | name | email | passwordHash | emailVerified | profileComplete | role |
|----|------|-------|--------------|---------------|-----------------|------|
| cuid_abc123 | John Doe | john@example.com | $2a$10$KXE... | NULL | true | MEMBER |

**Table `Member` :**

| id | userId | name | gender | dateOfBirth | city | country | description |
|----|--------|------|--------|-------------|------|---------|-------------|
| cuid_def456 | cuid_abc123 | John Doe | male | 1995-06-15 | Paris | France | Passionate... |

**Table `Token` :**

| id | email | token | expires | type |
|----|-------|-------|---------|------|
| cuid_ghi789 | john@example.com | a3f9e2c1b8d7... | 2024-10-22 10:00:00 | VERIFICATION |

---

## 🔐 Question 2 : Comment les Sessions Sont Gérées ?

### Il N'Y A PAS Deux Bases de Données pour les Sessions

**Clarification :**

```
❌ FAUX : NextAuth stocke dans sa DB, Supabase dans la sienne
✅ VRAI : NextAuth utilise JWT (pas de stockage DB des sessions)
```

### Stratégie JWT (JSON Web Token)

**Configuration : `src/auth.ts`**

```typescript
import NextAuth from "next-auth";
import { PrismaAdapter } from "@auth/prisma-adapter";
import { prisma } from './lib/prisma';

export const { handlers, auth, signIn, signOut } = NextAuth({
  
  // ═══════════════════════════════════════════════
  // 🔥 STRATÉGIE SESSION : JWT (STATELESS)
  // ═══════════════════════════════════════════════
  session: { 
    strategy: "jwt" // ← PAS de stockage en DB
  },
  
  // ═══════════════════════════════════════════════
  // ADAPTER PRISMA : Pour User/Account/etc.
  // ═══════════════════════════════════════════════
  adapter: PrismaAdapter(prisma),
  
  // ═══════════════════════════════════════════════
  // CALLBACKS : Enrichissement JWT
  // ═══════════════════════════════════════════════
  callbacks: {
    
    // 1️⃣ Callback JWT : Appelé quand JWT est créé/actualisé
    async jwt({ user, token }) {
      if (user) {
        // Ajoute des données custom au token
        token.profileComplete = user.profileComplete;
        token.role = user.role;
      }
      return token;
    },
    
    // 2️⃣ Callback Session : Appelé pour chaque requête
    async session({ token, session }) {
      if (token.sub && session.user) {
        // Transfert données du token vers la session
        session.user.id = token.sub;
        session.user.profileComplete = token.profileComplete as boolean;
        session.user.role = token.role as Role;
      }
      return session;
    }
  }
});
```

---

### Flux Complet de Session JWT

```mermaid
sequenceDiagram
    actor U as 👤 Utilisateur
    participant B as 🌐 Browser
    participant N as ⚡ Next.js Server
    participant NA as 🔐 NextAuth
    participant P as 🗄️ Prisma
    participant DB as 🐘 PostgreSQL
    
    rect rgb(225, 245, 255)
        Note over U,B: CONNEXION (Credentials)
        U->>B: Formulaire login<br/>email + password
        B->>N: POST signInUser(data)
        N->>P: prisma.user.findUnique({where: {email}})
        P->>DB: SELECT * FROM "User" WHERE email = ?
        DB-->>P: User object
        P-->>N: user
        N->>N: bcrypt.compare(password, passwordHash)
        Note over N: ✅ Password correct
    end
    
    rect rgb(255, 243, 224)
        Note over N,NA: GÉNÉRATION JWT
        N->>NA: signIn('credentials', {email, password})
        NA->>NA: Callback jwt({ user })
        Note over NA: token = {<br/>sub: user.id,<br/>email: user.email,<br/>profileComplete: true,<br/>role: 'MEMBER',<br/>iat: timestamp,<br/>exp: timestamp + 30d<br/>}
        NA->>NA: Signe JWT avec NEXTAUTH_SECRET
        Note over NA: JWT signé :<br/>eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.<br/>eyJzdWIiOiJjaWQxMjMiLCJlbWFpbCI6ImpvaG4u...<br/>SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
    end
    
    rect rgb(200, 230, 201)
        Note over NA,B: CRÉATION COOKIE
        NA->>B: Set-Cookie: next-auth.session-token=eyJhbGc...<br/>HttpOnly; Secure; SameSite=Lax; Path=/
        B->>B: Stocke cookie
        Note over B: Cookie stocké dans le browser<br/>❌ PAS accessible par JavaScript<br/>✅ Envoyé automatiquement à chaque requête
    end
    
    rect rgb(255, 235, 238)
        Note over B,N: REQUÊTES SUIVANTES
        loop Chaque requête
            B->>N: GET /members<br/>Cookie: next-auth.session-token=eyJhbGc...
            N->>NA: auth() - Lecture JWT
            NA->>NA: Vérifie signature JWT
            NA->>NA: Vérifie expiration
            NA->>NA: Callback session({ token })
            NA-->>N: session = {<br/>user: {<br/>id, email,<br/>profileComplete,<br/>role<br/>}<br/>}
            N-->>B: Page /members avec données user
        end
    end
    
    rect rgb(255, 205, 210)
        Note over U,B: DÉCONNEXION
        U->>B: Clique "Logout"
        B->>N: POST signOut()
        N->>B: Set-Cookie: next-auth.session-token=; Max-Age=0
        B->>B: Supprime cookie
        Note over B: Cookie supprimé<br/>Session terminée
    end
```

---

### Où est le JWT Stocké ?

#### 1️⃣ **Cookie HTTP-Only dans le Browser**

**Après connexion, dans DevTools (Application > Cookies) :**

```
Name:     next-auth.session-token
Value:    eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJjaWQxMjMiLCJlbWFpbCI6ImpvaG5AZXhhbXBsZS5jb20iLCJwcm9maWxlQ29tcGxldGUiOnRydWUsInJvbGUiOiJNRU1CRVIiLCJpYXQiOjE2OTcwMDAwMDAsImV4cCI6MTY5OTY3ODQwMH0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
Domain:   localhost
Path:     /
HttpOnly: ✅ (inaccessible par JS)
Secure:   ✅ (HTTPS en production)
SameSite: Lax
Expires:  30 jours
```

**Décoder le JWT (jwt.io) :**

```json
{
  "sub": "clw9k2x0a0000qw8r1g2h3j4k",
  "email": "john@example.com",
  "name": "John Doe",
  "picture": null,
  "profileComplete": true,
  "role": "MEMBER",
  "iat": 1697000000,
  "exp": 1699678400,
  "jti": "clw9k2x0a0001qw8r5m6n7o8p"
}
```

#### 2️⃣ **❌ PAS Stocké en Base de Données**

**Il n'y a AUCUNE table "Session" dans PostgreSQL :**

```sql
-- Cette table N'EXISTE PAS
SELECT * FROM "Session"; -- ❌ Table inexistante
```

**Pourquoi ?**

Avec JWT, la session est **stateless** :
- Pas besoin de query DB pour vérifier la session
- Performance maximale
- Scalabilité infinie (serverless)

**Comparaison :**

| Aspect | JWT (Notre cas) | Database Sessions |
|--------|-----------------|-------------------|
| **Stockage** | Cookie client | Table Session en DB |
| **Query DB par requête** | ❌ Non | ✅ Oui (SELECT * FROM Session) |
| **Performance** | ⚡ Très rapide | 🐌 Plus lent |
| **Scalabilité** | ♾️ Infinie | 📊 Limitée |
| **Révocation immédiate** | ❌ Difficile | ✅ Facile (DELETE) |

---

### Comment Accéder à la Session ?

#### Côté Serveur (Server Components, Server Actions)

**Fichier : `src/app/members/page.tsx`**

```typescript
import { auth } from '@/auth';
import { redirect } from 'next/navigation';

export default async function MembersPage() {
  // 🔥 RÉCUPÉRATION SESSION
  const session = await auth();
  
  // session.user contient :
  // - id : "clw9k2x0a0000qw8r1g2h3j4k"
  // - email : "john@example.com"
  // - name : "John Doe"
  // - profileComplete : true
  // - role : "MEMBER"
  
  if (!session?.user) {
    redirect('/login');
  }
  
  return (
    <div>
      <h1>Bienvenue {session.user.name}</h1>
      <p>Email: {session.user.email}</p>
      <p>Role: {session.user.role}</p>
    </div>
  );
}
```

**Ce qui se passe :**

```typescript
// 1. auth() lit le cookie
const cookie = req.cookies.get('next-auth.session-token');

// 2. Vérifie la signature JWT avec NEXTAUTH_SECRET
const isValid = verifyJWT(cookie, process.env.NEXTAUTH_SECRET);

// 3. Décode le JWT
const token = decodeJWT(cookie);
// token = { sub: "clw9k2x0a...", email: "john@...", ... }

// 4. Callback session({ token })
const session = {
  user: {
    id: token.sub,
    email: token.email,
    name: token.name,
    profileComplete: token.profileComplete,
    role: token.role
  }
};

// 5. Retourne session
return session;
```

**❌ AUCUNE REQUÊTE EN BASE DE DONNÉES** pour vérifier la session.

---

#### Côté Client (Client Components)

**Fichier : `src/components/navbar/UserMenu.tsx`**

```typescript
'use client';

import { useSession } from 'next-auth/react';

export default function UserMenu() {
  // 🔥 HOOK CLIENT
  const { data: session, status } = useSession();
  
  if (status === 'loading') {
    return <div>Chargement...</div>;
  }
  
  if (!session) {
    return <Link href="/login">Se connecter</Link>;
  }
  
  return (
    <div>
      <p>Bonjour {session.user.name}</p>
      <button onClick={() => signOut()}>
        Se déconnecter
      </button>
    </div>
  );
}
```

**Prérequis :** Le composant doit être wrappé dans `<SessionProvider>`.

**Fichier : `src/components/Providers.tsx`**

```typescript
'use client';

import { SessionProvider } from 'next-auth/react';

export default function Providers({ children, userId, profileComplete }) {
  return (
    <SessionProvider>
      {/* Tous les children peuvent utiliser useSession() */}
      {children}
    </SessionProvider>
  );
}
```

**Layout principal : `src/app/layout.tsx`**

```typescript
import { auth } from '@/auth';
import Providers from '@/components/Providers';

export default async function RootLayout({ children }) {
  const session = await auth();
  const userId = session?.user?.id || null;
  const profileComplete = session?.user?.profileComplete || false;
  
  return (
    <html>
      <body>
        <Providers userId={userId} profileComplete={profileComplete}>
          {children}
        </Providers>
      </body>
    </html>
  );
}
```

---

### Middleware : Protection des Routes

**Fichier : `src/middleware.ts`**

```typescript
import { NextResponse } from 'next/server';
import { auth } from './auth';
import { authRoutes, publicRoutes } from './routes';

export default auth((req) => {
  const { nextUrl } = req;
  
  // 🔥 LECTURE SESSION DEPUIS JWT
  const isLoggedIn = !!req.auth;
  const isProfileComplete = req.auth?.user.profileComplete;
  const isAdmin = req.auth?.user.role === 'ADMIN';
  
  // req.auth contient la session décodée depuis le JWT
  // req.auth = {
  //   user: { id, email, profileComplete, role },
  //   expires: "2024-11-20T10:00:00.000Z"
  // }
  
  const isPublic = publicRoutes.includes(nextUrl.pathname);
  const isAuthRoute = authRoutes.includes(nextUrl.pathname);
  const isAdminRoute = nextUrl.pathname.startsWith('/admin');
  
  // ════════════════════════════════════════════════
  // PROTECTION 1 : Routes publiques et admins
  // ════════════════════════════════════════════════
  if (isPublic || isAdmin) {
    return NextResponse.next();
  }
  
  // ════════════════════════════════════════════════
  // PROTECTION 2 : Routes admin
  // ════════════════════════════════════════════════
  if (isAdminRoute && !isAdmin) {
    return NextResponse.redirect(new URL('/', nextUrl));
  }
  
  // ════════════════════════════════════════════════
  // PROTECTION 3 : Routes auth (login, register)
  // ════════════════════════════════════════════════
  if (isAuthRoute) {
    if (isLoggedIn) {
      // Déjà connecté → redirige vers /members
      return NextResponse.redirect(new URL('/members', nextUrl));
    }
    return NextResponse.next();
  }
  
  // ════════════════════════════════════════════════
  // PROTECTION 4 : Routes protégées
  // ════════════════════════════════════════════════
  if (!isPublic && !isLoggedIn) {
    // Non connecté → redirige vers /login
    return NextResponse.redirect(new URL('/login', nextUrl));
  }
  
  // ════════════════════════════════════════════════
  // PROTECTION 5 : Profil incomplet
  // ════════════════════════════════════════════════
  if (isLoggedIn && !isProfileComplete && 
      nextUrl.pathname !== '/complete-profile') {
    return NextResponse.redirect(new URL('/complete-profile', nextUrl));
  }
  
  return NextResponse.next();
});

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|images|favicon.ico).*)']
};
```

**Ce middleware s'exécute AVANT chaque requête.**

**Ordre d'exécution :**

```
1. Browser envoie requête GET /members
2. Cookie next-auth.session-token envoyé
3. Middleware s'exécute
4. auth((req) => {...}) décode JWT automatiquement
5. req.auth = session décodée
6. Vérifications
7. Si OK → NextResponse.next() → Page chargée
8. Si KO → Redirect
```

---

## 🔄 Connexion Base de Données : Prisma

### Configuration Prisma

**Fichier : `src/lib/prisma.ts`**

```typescript
import { PrismaClient } from '@prisma/client';

// Singleton pattern pour éviter multiple connexions
const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma = globalForPrisma.prisma || new PrismaClient({
  log: ['query'] // Log SQL en développement
});

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}
```

**Variable d'environnement `.env` :**

```env
DATABASE_URL="postgresql://postgres.project:PASSWORD@host:5432/postgres"
```

**Cette URL pointe vers Supabase PostgreSQL.**

---

### PrismaAdapter : Lien NextAuth ↔ PostgreSQL

**Fichier : `src/auth.ts`**

```typescript
import { PrismaAdapter } from "@auth/prisma-adapter";
import { prisma } from './lib/prisma';

export const { handlers, auth, signIn, signOut } = NextAuth({
  
  // 🔥 ADAPTER : Gère User, Account automatiquement
  adapter: PrismaAdapter(prisma),
  
  // ...
});
```

**Rôle de l'adapter :**

1. **Connexion Credentials** : Rien (géré manuellement)
2. **Connexion Google/GitHub** :
   - Crée User si n'existe pas
   - Crée Account avec tokens OAuth
   - Lie User ↔ Account

**Exemple OAuth :**

```typescript
// Utilisateur se connecte avec Google

// 1. NextAuth reçoit les infos de Google
const googleUser = {
  id: "google-id-123456",
  email: "john@gmail.com",
  name: "John Doe",
  image: "https://lh3.googleusercontent.com/..."
};

// 2. PrismaAdapter cherche User existant
const existingUser = await prisma.user.findUnique({
  where: { email: "john@gmail.com" }
});

if (!existingUser) {
  // 3. Crée User + Account
  await prisma.user.create({
    data: {
      email: "john@gmail.com",
      name: "John Doe",
      image: "https://...",
      emailVerified: new Date(), // Auto-vérifié par Google
      profileComplete: false,    // Doit compléter profil
      
      accounts: {
        create: {
          type: "oauth",
          provider: "google",
          providerAccountId: "google-id-123456",
          access_token: "ya29.a0AfH6...",
          token_type: "Bearer",
          scope: "openid profile email",
          id_token: "eyJhbGciOiJSUzI1NiIsImtpZCI6IjE4MmU..."
        }
      }
    }
  });
}

// 4. Génère JWT
// 5. Cookie créé
```

**Tables créées :**

```sql
-- Table User
INSERT INTO "User" (id, email, name, image, emailVerified, profileComplete)
VALUES ('clw9k...', 'john@gmail.com', 'John Doe', 'https://...', NOW(), false);

-- Table Account
INSERT INTO "Account" (userId, type, provider, providerAccountId, access_token, ...)
VALUES ('clw9k...', 'oauth', 'google', 'google-id-123456', 'ya29.a0AfH6...', ...);
```

---

## 📊 Schéma Complet : Une Seule Base de Données

```mermaid
erDiagram
    User ||--o{ Account : "OAuth providers"
    User ||--o| Member : "Profil public"
    Member ||--o{ Photo : "Photos"
    Member ||--o{ Like : "Likes source"
    Member ||--o{ Like : "Likes target"
    Member ||--o{ Message : "Messages envoyés"
    Member ||--o{ Message : "Messages reçus"
    
    User {
        string id PK
        string email UNIQUE
        string name
        string passwordHash NULLABLE
        datetime emailVerified NULLABLE
        boolean profileComplete
        enum role
    }
    
    Account {
        string id PK
        string userId FK
        string provider
        string providerAccountId
        string access_token NULLABLE
        string refresh_token NULLABLE
    }
    
    Member {
        string id PK
        string userId FK-UNIQUE
        string name
        string gender
        date dateOfBirth
        string description
        string city
        string country
    }
    
    Token {
        string id PK
        string email
        string token UNIQUE
        datetime expires
        enum type
    }
    
    Photo {
        string id PK
        string memberId FK
        string url
        string publicId
        boolean isApproved
    }
    
    Like {
        string sourceUserId FK-PK
        string targetUserId FK-PK
    }
    
    Message {
        string id PK
        string senderId FK
        string recipientId FK
        string text
        datetime created
        datetime dateRead NULLABLE
    }
```

**Toutes ces tables sont dans PostgreSQL hébergé sur Supabase.**

**Prisma gère TOUTES les requêtes vers cette unique base.**

---

## 🎯 Résumé : Réponses aux Questions

### Question 1 : Comment on Fait le POST des Users ?

**Réponse :**

1. **Formulaire React** collecte les données (RegisterForm.tsx)
2. **Server Action** `registerUser()` est appelée
3. **Validation Zod** vérifie les données
4. **bcrypt** hash le password
5. **Prisma** insère dans PostgreSQL :
   - Table `User` (credentials auth)
   - Table `Member` (profil public)
   - Table `Token` (vérification email)
6. **Resend** envoie l'email de vérification
7. **Réponse** retournée au client

**Code clé :**

```typescript
// Client
const result = await registerUser(data);

// Server
const user = await prisma.user.create({
  data: {
    name, email, passwordHash: await bcrypt.hash(password, 10),
    member: { create: { name, gender, dateOfBirth, city, country, description } }
  }
});
```

---

### Question 2 : Comment les Infos de l'Utilisateur Actuel sont Passées ?

**Réponse :**

**❌ PAS deux bases de données**

**✅ Une seule base PostgreSQL (Supabase)**

**Session gérée par JWT :**

1. **Connexion** → NextAuth génère JWT
2. **JWT stocké** dans cookie HTTP-Only
3. **Chaque requête** → Cookie envoyé automatiquement
4. **NextAuth décode** JWT → `session.user`
5. **Aucune query DB** pour vérifier session

**Code clé :**

```typescript
// Server Component
const session = await auth(); // Lit JWT depuis cookie
console.log(session.user.id, session.user.email);

// Client Component
const { data: session } = useSession(); // Hook React
console.log(session.user.id);

// Middleware
export default auth((req) => {
  const isLoggedIn = !!req.auth; // JWT décodé automatiquement
});
```

---

### Question 3 : Orchestration Entre Deux Bases de Données ?

**Réponse :**

**❌ Il n'y a PAS deux bases de données**

**Architecture réelle :**

```
┌─────────────────────────────────────┐
│  Next.js Application                │
│  ├─ NextAuth.js (JWT Strategy)      │
│  ├─ Prisma ORM                      │
│  └─ Server Actions                  │
└──────────────┬──────────────────────┘
               │
               │ DATABASE_URL
               │
               ▼
┌─────────────────────────────────────┐
│  PostgreSQL (Hébergé sur Supabase)  │
│  ├─ Table User                      │
│  ├─ Table Account                   │
│  ├─ Table Member                    │
│  ├─ Table Token                     │
│  ├─ Table Photo                     │
│  ├─ Table Like                      │
│  └─ Table Message                   │
└─────────────────────────────────────┘
```

**Supabase est utilisé UNIQUEMENT comme PostgreSQL.**

**Services Supabase NON utilisés :**
- ❌ Supabase Auth
- ❌ Supabase Storage
- ❌ Supabase Realtime
- ❌ Supabase Edge Functions

**Services utilisés ailleurs :**
- Images → Cloudinary
- Temps réel → Pusher
- Email → Resend

---

## 🔍 Vérification : Où Sont les Données ?

### Tester avec Prisma Studio

```powershell
npx prisma studio
```

**Interface graphique ouvre sur `http://localhost:5555`**

**Tables visibles :**
- User (avec vos utilisateurs)
- Account (OAuth Google/GitHub)
- Member (profils publics)
- Token (vérification email)
- Photo (photos uploadées)
- Like (likes bidirectionnels)
- Message (messagerie)

**Toutes ces tables sont dans PostgreSQL Supabase.**

---

### Tester avec SQL Direct

```sql
-- Connexion directe à PostgreSQL (Supabase)
psql "postgresql://postgres.project:PASSWORD@host:5432/postgres"

-- Liste les tables
\dt

-- Affiche les users
SELECT id, email, "emailVerified", "profileComplete", role FROM "User";

-- Affiche les members
SELECT id, name, gender, city, country FROM "Member";

-- Affiche les accounts (OAuth)
SELECT "userId", provider, "providerAccountId" FROM "Account";
```

**Tout est dans la même base de données PostgreSQL.**

---

## ✅ Conclusion

**Architecture :**

```
Client → Server Actions → Prisma → PostgreSQL (Supabase)
                ↓
            NextAuth JWT
                ↓
         Cookie HTTP-Only
                ↓
       Session automatique
```

**Pas d'orchestration entre deux bases.**

**Une seule base PostgreSQL hébergée sur Supabase, accessible via Prisma, avec sessions JWT dans des cookies.**

**Simple, performant, scalable.**

