# Équivalence Clerk vs NextAuth.js

Ce document montre comment l'application Next Match serait implémentée avec **Clerk** au lieu de **NextAuth.js**, avec tous les équivalents de code côte à côte.

---

## Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Installation & Configuration](#installation--configuration)
3. [Inscription (Register)](#inscription-register)
4. [Connexion (Login)](#connexion-login)
5. [Protection des Routes](#protection-des-routes)
6. [Accès aux Données Utilisateur](#accès-aux-données-utilisateur)
7. [OAuth Social](#oauth-social)
8. [Gestion du Profil](#gestion-du-profil)
9. [Vérification Email](#vérification-email)
10. [Reset Password](#reset-password)
11. [Déconnexion](#déconnexion)
12. [Middleware](#middleware)
13. [Base de Données](#base-de-données)
14. [Webhooks (Important!)](#webhooks-important)
15. [Comparaison Complète](#comparaison-complète)
16. [Migration Guide](#migration-guide)
17. [Coûts](#coûts)

---

## Vue d'Ensemble

### Architecture Actuelle (NextAuth.js)

```
Client → Server Actions → NextAuth → Prisma → PostgreSQL
                ↓
            JWT Cookie
```

### Architecture avec Clerk

```
Client → Clerk Components → Clerk API → Clerk Database
         ↓                      ↓
    Clerk Session          Webhooks → Your API → Prisma → PostgreSQL
```

**Différence majeure :** Clerk gère TOUT l'auth (UI + backend + database), vous synchronisez via webhooks.

---

## Installation & Configuration

### ACTUEL : NextAuth.js

**Installation :**
```bash
npm install next-auth@beta @auth/prisma-adapter
npm install bcryptjs @types/bcryptjs
```

**Configuration `.env` :**
```env
NEXTAUTH_SECRET="votre-secret"
NEXTAUTH_URL="http://localhost:3000"
DATABASE_URL="postgresql://..."

GOOGLE_CLIENT_ID="..."
GOOGLE_CLIENT_SECRET="..."
GITHUB_CLIENT_ID="..."
GITHUB_CLIENT_SECRET="..."
```

**Fichiers à créer :**
- `src/auth.config.ts`
- `src/auth.ts`
- `src/app/api/auth/[...nextauth]/route.ts`
- `src/middleware.ts`

**Lignes de code : ~300 lignes**

---

### AVEC CLERK

**Installation :**
```bash
npm install @clerk/nextjs
```

**Configuration `.env` :**
```env
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_..."
CLERK_SECRET_KEY="sk_test_..."

# URLs de redirection (optionnel)
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/members
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/members
```

**Fichiers à créer :**
- `src/middleware.ts` (minimal)
- `src/app/api/webhooks/clerk/route.ts` (pour sync DB)

**Lignes de code : ~50 lignes**

---

## Inscription (Register)

### ACTUEL : NextAuth.js

**1. Formulaire Client (`RegisterForm.tsx`) :**

```typescript
'use client'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Input, Select, Button } from '@nextui-org/react'

export default function RegisterForm() {
  const form = useForm({
    resolver: zodResolver(combinedRegisterSchema)
  })
  
  const onSubmit = async (data) => {
    const result = await registerUser(data)
    
    if (result.status === 'success') {
      router.push('/register/success')
    }
  }
  
  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      <Input {...register('name')} label="Name" />
      <Input {...register('email')} label="Email" />
      <Input {...register('password')} type="password" label="Password" />
      <Select {...register('gender')} label="Gender">
        <SelectItem value="male">Male</SelectItem>
        <SelectItem value="female">Female</SelectItem>
      </Select>
      <Input {...register('dateOfBirth')} type="date" label="Date of Birth" />
      <Input {...register('city')} label="City" />
      <Input {...register('country')} label="Country" />
      <Textarea {...register('description')} label="Description" />
      <Button type="submit">Register</Button>
    </form>
  )
}
```

**2. Server Action (`authActions.ts`) :**

```typescript
'use server'
export async function registerUser(data: RegisterSchema) {
  // Validation
  const validated = combinedRegisterSchema.safeParse(data)
  if (!validated.success) {
    return { status: 'error', error: validated.error.errors }
  }

  // Hash password
  const hashedPassword = await bcrypt.hash(data.password, 10)

  // Vérifier email unique
  const existingUser = await prisma.user.findUnique({
    where: { email: data.email }
  })
  if (existingUser) {
    return { status: 'error', error: 'User already exists' }
  }

  // Créer user + member
  const user = await prisma.user.create({
    data: {
      name: data.name,
      email: data.email,
      passwordHash: hashedPassword,
      profileComplete: true,
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
  })

  // Envoyer email vérification
  const token = await generateToken(data.email, TokenType.VERIFICATION)
  await sendVerificationEmail(token.email, token.token)

  return { status: 'success', data: user }
}
```

**Lignes de code : ~150 lignes**

---

### AVEC CLERK

**1. Page d'Inscription (`app/sign-up/page.tsx`) :**

```typescript
import { SignUp } from '@clerk/nextjs'

export default function SignUpPage() {
  return (
    <div className="flex items-center justify-center min-h-screen">
      <SignUp 
        appearance={{
          elements: {
            formButtonPrimary: 'bg-blue-500 hover:bg-blue-600',
            card: 'shadow-xl'
          }
        }}
        routing="path"
        path="/sign-up"
        signInUrl="/sign-in"
      />
    </div>
  )
}
```

**2. Formulaire Profil Supplémentaire (après inscription Clerk) :**

```typescript
'use client'
import { useUser } from '@clerk/nextjs'
import { useState } from 'react'

export default function CompleteProfileForm() {
  const { user } = useUser()
  const [formData, setFormData] = useState({
    gender: '',
    dateOfBirth: '',
    city: '',
    country: '',
    description: ''
  })

  const onSubmit = async (e) => {
    e.preventDefault()
    
    // Mettre à jour Clerk metadata
    await user.update({
      publicMetadata: {
        profileComplete: true
      }
    })
    
    // Sauvegarder dans votre DB via API
    await fetch('/api/members/create', {
      method: 'POST',
      body: JSON.stringify({
        clerkId: user.id,
        name: user.fullName,
        email: user.primaryEmailAddress.emailAddress,
        ...formData
      })
    })
    
    router.push('/members')
  }

  return (
    <form onSubmit={onSubmit}>
      <select value={formData.gender} onChange={e => setFormData({...formData, gender: e.target.value})}>
        <option value="male">Male</option>
        <option value="female">Female</option>
      </select>
      <input type="date" value={formData.dateOfBirth} onChange={e => setFormData({...formData, dateOfBirth: e.target.value})} />
      <input value={formData.city} onChange={e => setFormData({...formData, city: e.target.value})} placeholder="City" />
      <input value={formData.country} onChange={e => setFormData({...formData, country: e.target.value})} placeholder="Country" />
      <textarea value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})} placeholder="Description" />
      <button type="submit">Complete Profile</button>
    </form>
  )
}
```

**3. API Route pour Créer Member (`app/api/members/create/route.ts`) :**

```typescript
import { auth } from '@clerk/nextjs'
import { prisma } from '@/lib/prisma'

export async function POST(req: Request) {
  const { userId } = auth()
  
  if (!userId) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }
  
  const data = await req.json()
  
  const member = await prisma.member.create({
    data: {
      clerkId: data.clerkId,
      name: data.name,
      email: data.email,
      gender: data.gender,
      dateOfBirth: new Date(data.dateOfBirth),
      city: data.city,
      country: data.country,
      description: data.description
    }
  })
  
  return Response.json({ member })
}
```

**Lignes de code : ~80 lignes**

**Avantages Clerk :**
- ✅ UI d'inscription déjà stylée
- ✅ Validation email automatique (pas besoin de tokens)
- ✅ Password hashing géré
- ✅ Rate limiting intégré
- ✅ Responsive automatique

**Inconvénients Clerk :**
- ❌ Moins de contrôle sur le formulaire
- ❌ Besoin d'un formulaire séparé pour infos supplémentaires
- ❌ Dépendance à Clerk API

---

## Connexion (Login)

### ACTUEL : NextAuth.js

**Formulaire (`LoginForm.tsx`) :**

```typescript
'use client'
export default function LoginForm() {
  const form = useForm({
    resolver: zodResolver(loginSchema)
  })

  const onSubmit = async (data: LoginSchema) => {
    const result = await signInUser(data)
    
    if (result.status === 'success') {
      router.push('/members')
    } else {
      toast.error(result.error)
    }
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      <Input {...register('email')} label="Email" />
      <Input {...register('password')} type="password" label="Password" />
      <Button type="submit">Login</Button>
    </form>
  )
}
```

**Server Action :**

```typescript
'use server'
export async function signInUser(data: LoginSchema) {
  const existingUser = await getUserByEmail(data.email)
  
  if (!existingUser || !existingUser.email) {
    return { status: 'error', error: 'Invalid credentials' }
  }

  if (!existingUser.emailVerified) {
    return { status: 'error', error: 'Please verify your email' }
  }

  const result = await signIn('credentials', {
    email: data.email,
    password: data.password,
    redirect: false
  })

  return { status: 'success', data: 'Logged in' }
}
```

---

### AVEC CLERK

**Page de Connexion (`app/sign-in/page.tsx`) :**

```typescript
import { SignIn } from '@clerk/nextjs'

export default function SignInPage() {
  return (
    <div className="flex items-center justify-center min-h-screen">
      <SignIn 
        appearance={{
          elements: {
            formButtonPrimary: 'bg-blue-500 hover:bg-blue-600',
            card: 'shadow-xl',
            footerAction: 'hidden' // Cacher "Don't have an account?"
          }
        }}
        routing="path"
        path="/sign-in"
        signUpUrl="/sign-up"
        afterSignInUrl="/members"
      />
    </div>
  )
}
```

**C'est TOUT ! Clerk gère :**
- ✅ Validation email/password
- ✅ Vérification email
- ✅ Rate limiting
- ✅ Session creation
- ✅ Redirections

**Lignes de code : 15 lignes** vs **150 lignes** avec NextAuth

---

## Protection des Routes

### ACTUEL : NextAuth.js

**Middleware (`middleware.ts`) :**

```typescript
import { auth } from './auth'
import { NextResponse } from 'next/server'

export default auth((req) => {
  const { nextUrl } = req
  const isLoggedIn = !!req.auth
  const isProfileComplete = req.auth?.user.profileComplete
  
  const isPublic = publicRoutes.includes(nextUrl.pathname)
  const isAuthRoute = authRoutes.includes(nextUrl.pathname)
  
  // Routes publiques et admins
  if (isPublic || req.auth?.user.role === 'ADMIN') {
    return NextResponse.next()
  }
  
  // Routes auth (login, register)
  if (isAuthRoute) {
    if (isLoggedIn) {
      return NextResponse.redirect(new URL('/members', nextUrl))
    }
    return NextResponse.next()
  }
  
  // Routes protégées
  if (!isPublic && !isLoggedIn) {
    return NextResponse.redirect(new URL('/login', nextUrl))
  }
  
  // Profil incomplet
  if (isLoggedIn && !isProfileComplete && nextUrl.pathname !== '/complete-profile') {
    return NextResponse.redirect(new URL('/complete-profile', nextUrl))
  }
  
  return NextResponse.next()
})

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|images|favicon.ico).*)']
}
```

**Lignes de code : 40 lignes**

---

### AVEC CLERK

**Middleware (`middleware.ts`) :**

```typescript
import { authMiddleware } from '@clerk/nextjs'

export default authMiddleware({
  // Routes publiques (pas besoin d'auth)
  publicRoutes: [
    '/',
    '/api/webhooks/clerk'
  ],
  
  // Routes ignorées (toujours accessibles)
  ignoredRoutes: [
    '/api/public(.*)'
  ],
  
  // Callback après auth
  afterAuth(auth, req) {
    // Si connecté mais profil incomplet
    if (auth.userId && !auth.sessionClaims?.metadata?.profileComplete) {
      const completeProfileUrl = new URL('/complete-profile', req.url)
      if (req.nextUrl.pathname !== '/complete-profile') {
        return NextResponse.redirect(completeProfileUrl)
      }
    }
    
    // Si sur page auth mais déjà connecté
    if (auth.userId && ['/sign-in', '/sign-up'].includes(req.nextUrl.pathname)) {
      return NextResponse.redirect(new URL('/members', req.url))
    }
  }
})

export const config = {
  matcher: ['/((?!.+\\.[\\w]+$|_next).*)', '/', '/(api|trpc)(.*)']
}
```

**Lignes de code : 25 lignes**

**Avantages Clerk :**
- ✅ Plus simple
- ✅ Protection automatique
- ✅ Session refresh automatique

---

## Accès aux Données Utilisateur

### ACTUEL : NextAuth.js

**Server Component :**

```typescript
import { auth } from '@/auth'

export default async function MembersPage() {
  const session = await auth()
  
  if (!session?.user) {
    redirect('/login')
  }
  
  return (
    <div>
      <h1>Welcome {session.user.name}</h1>
      <p>Email: {session.user.email}</p>
      <p>ID: {session.user.id}</p>
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
  
  if (status === 'loading') return <div>Loading...</div>
  if (!session) return null
  
  return (
    <div>
      <p>{session.user.email}</p>
      <p>{session.user.name}</p>
    </div>
  )
}
```

---

### AVEC CLERK

**Server Component :**

```typescript
import { currentUser } from '@clerk/nextjs'
import { redirect } from 'next/navigation'

export default async function MembersPage() {
  const user = await currentUser()
  
  if (!user) {
    redirect('/sign-in')
  }
  
  return (
    <div>
      <h1>Welcome {user.firstName} {user.lastName}</h1>
      <p>Email: {user.primaryEmailAddress?.emailAddress}</p>
      <p>ID: {user.id}</p>
      <p>Profile Image: <img src={user.imageUrl} /></p>
    </div>
  )
}
```

**Client Component :**

```typescript
'use client'
import { useUser } from '@clerk/nextjs'

export default function ProfileCard() {
  const { user, isLoaded, isSignedIn } = useUser()
  
  if (!isLoaded) return <div>Loading...</div>
  if (!isSignedIn) return null
  
  return (
    <div>
      <img src={user.imageUrl} alt="Profile" />
      <p>{user.fullName}</p>
      <p>{user.primaryEmailAddress?.emailAddress}</p>
      <p>Joined: {new Date(user.createdAt).toLocaleDateString()}</p>
    </div>
  )
}
```

**Avantages Clerk :**
- ✅ Plus d'infos disponibles (imageUrl, createdAt, etc.)
- ✅ API plus riche
- ✅ Pas besoin de SessionProvider wrapper

---

## OAuth Social

### ACTUEL : NextAuth.js

**Configuration (`auth.config.ts`) :**

```typescript
import Google from "next-auth/providers/google"
import Github from "next-auth/providers/github"

export default {
  providers: [
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET
    }),
    Github({
      clientId: process.env.GITHUB_CLIENT_ID,
      clientSecret: process.env.GITHUB_CLIENT_SECRET
    })
  ]
}
```

**Composant (`SocialLogin.tsx`) :**

```typescript
'use client'
import { signIn } from 'next-auth/react'

export default function SocialLogin() {
  return (
    <div>
      <button onClick={() => signIn('google', { callbackUrl: '/members' })}>
        Continue with Google
      </button>
      <button onClick={() => signIn('github', { callbackUrl: '/members' })}>
        Continue with GitHub
      </button>
    </div>
  )
}
```

**Setup OAuth Apps :**
- Créer app Google Cloud Console
- Créer app GitHub OAuth
- Configurer callback URLs
- Ajouter keys dans `.env`

---

### AVEC CLERK

**Configuration (Dashboard Clerk) :**

1. Aller sur https://dashboard.clerk.com
2. Configure > Social Connections
3. Enable Google ✅
4. Enable GitHub ✅
5. C'est TOUT !

**Clerk gère AUTOMATIQUEMENT :**
- Les OAuth Apps (pas besoin de créer dans Google/GitHub)
- Les callback URLs
- Les secrets
- L'UI des boutons

**Affichage :**

Les boutons Google/GitHub apparaissent **automatiquement** dans `<SignIn />` et `<SignUp />` !

**Si vous voulez des boutons custom :**

```typescript
'use client'
import { useSignIn } from '@clerk/nextjs'

export default function SocialLogin() {
  const { signIn } = useSignIn()
  
  return (
    <div>
      <button onClick={() => signIn.authenticateWithRedirect({
        strategy: 'oauth_google',
        redirectUrl: '/members',
        redirectUrlComplete: '/members'
      })}>
        Continue with Google
      </button>
      
      <button onClick={() => signIn.authenticateWithRedirect({
        strategy: 'oauth_github',
        redirectUrl: '/members',
        redirectUrlComplete: '/members'
      })}>
        Continue with GitHub
      </button>
    </div>
  )
}
```

**Avantages Clerk :**
- ✅ Pas besoin de créer OAuth apps
- ✅ Configuration en 2 clics
- ✅ Plus de providers disponibles (30+)
- ✅ Gestion des tokens automatique

---

## Gestion du Profil

### ACTUEL : NextAuth.js

**Mise à jour profil :**

```typescript
'use server'
export async function updateUserProfile(data: UpdateProfileSchema) {
  const session = await auth()
  if (!session?.user?.id) {
    return { status: 'error', error: 'Unauthorized' }
  }

  const updatedUser = await prisma.user.update({
    where: { id: session.user.id },
    data: {
      name: data.name,
      member: {
        update: {
          city: data.city,
          country: data.country,
          description: data.description
        }
      }
    }
  })

  return { status: 'success', data: updatedUser }
}
```

---

### AVEC CLERK

**Mise à jour profil Clerk :**

```typescript
'use client'
import { useUser } from '@clerk/nextjs'

export default function EditProfileForm() {
  const { user } = useUser()
  const [formData, setFormData] = useState({
    firstName: user.firstName,
    lastName: user.lastName
  })

  const onSubmit = async (e) => {
    e.preventDefault()
    
    // Mettre à jour Clerk
    await user.update({
      firstName: formData.firstName,
      lastName: formData.lastName
    })
    
    // Mettre à jour votre DB
    await fetch('/api/members/update', {
      method: 'PATCH',
      body: JSON.stringify({
        clerkId: user.id,
        name: `${formData.firstName} ${formData.lastName}`,
        city: formData.city,
        country: formData.country
      })
    })
    
    toast.success('Profile updated')
  }

  return <form onSubmit={onSubmit}>...</form>
}
```

**Ou utiliser le composant Clerk :**

```typescript
import { UserProfile } from '@clerk/nextjs'

export default function ProfilePage() {
  return (
    <div>
      <UserProfile 
        appearance={{
          elements: {
            card: 'shadow-xl'
          }
        }}
      />
    </div>
  )
}
```

**Avantages Clerk :**
- ✅ UI de profil complète fournie
- ✅ Upload image intégré
- ✅ Changement email/password géré
- ✅ 2FA intégré

---

## Vérification Email

### ACTUEL : NextAuth.js

**Génération token :**

```typescript
export async function generateToken(email: string, type: TokenType) {
  const arrayBuffer = new Uint8Array(48)
  crypto.getRandomValues(arrayBuffer)
  const token = Array.from(arrayBuffer, byte => 
    byte.toString(16).padStart(2, '0')
  ).join('')
  
  const expires = new Date(Date.now() + 1000 * 60 * 60 * 24)

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

**Envoi email :**

```typescript
export async function sendVerificationEmail(email: string, token: string) {
  const link = `${process.env.NEXT_PUBLIC_BASE_URL}/verify-email?token=${token}`
  
  return resend.emails.send({
    from: 'onboarding@resend.dev',
    to: email,
    subject: 'Verify your email',
    html: `<a href="${link}">Verify Email</a>`
  })
}
```

**Vérification :**

```typescript
export async function verifyEmail(token: string) {
  const existingToken = await getTokenByToken(token)
  if (!existingToken) {
    return { status: 'error', error: 'Invalid token' }
  }

  const hasExpired = new Date() > existingToken.expires
  if (hasExpired) {
    return { status: 'error', error: 'Token has expired' }
  }

  await prisma.user.update({
    where: { email: existingToken.email },
    data: { emailVerified: new Date() }
  })

  await prisma.token.delete({ where: { id: existingToken.id } })

  return { status: 'success', data: 'Success' }
}
```

**Lignes de code : ~100 lignes**

---

### AVEC CLERK

**Configuration (Dashboard Clerk) :**

1. Email & SMS > Email verification
2. Enable "Require email verification" ✅
3. Customize email template (optionnel)

**Dans le code :**

**RIEN À FAIRE !**

Clerk envoie automatiquement l'email de vérification et gère tout le flow.

**Si l'utilisateur n'a pas vérifié :**

```typescript
'use client'
import { useUser } from '@clerk/nextjs'

export default function VerificationBanner() {
  const { user } = useUser()
  
  if (user?.emailAddresses[0]?.verification?.status === 'verified') {
    return null
  }
  
  return (
    <div className="bg-yellow-100 p-4">
      <p>Please verify your email address</p>
      <button onClick={() => user.emailAddresses[0].prepareVerification({ strategy: 'email_code' })}>
        Resend verification email
      </button>
    </div>
  )
}
```

**Lignes de code : ~15 lignes**

**Avantages Clerk :**
- ✅ Gestion automatique
- ✅ UI fournie
- ✅ Pas de tokens à gérer
- ✅ Emails brandés

---

## Reset Password

### ACTUEL : NextAuth.js

**Formulaire demande :**

```typescript
'use client'
export default function ForgotPasswordForm() {
  const [email, setEmail] = useState('')

  const onSubmit = async (e) => {
    e.preventDefault()
    const result = await generateResetPasswordEmail(email)
    toast.success('Check your email')
  }

  return (
    <form onSubmit={onSubmit}>
      <input value={email} onChange={e => setEmail(e.target.value)} />
      <button type="submit">Send Reset Email</button>
    </form>
  )
}
```

**Server Actions :**

```typescript
export async function generateResetPasswordEmail(email: string) {
  const existingUser = await getUserByEmail(email)
  if (!existingUser) {
    return { status: 'error', error: 'Email not found' }
  }

  const token = await generateToken(email, TokenType.PASSWORD_RESET)
  await sendPasswordResetEmail(token.email, token.token)

  return { status: 'success', data: 'Email sent' }
}

export async function resetPassword(password: string, token: string) {
  const existingToken = await getTokenByToken(token)
  if (!existingToken) {
    return { status: 'error', error: 'Invalid token' }
  }

  const hasExpired = new Date() > existingToken.expires
  if (hasExpired) {
    return { status: 'error', error: 'Token has expired' }
  }

  const hashedPassword = await bcrypt.hash(password, 10)

  await prisma.user.update({
    where: { email: existingToken.email },
    data: { passwordHash: hashedPassword }
  })

  await prisma.token.delete({ where: { id: existingToken.id } })

  return { status: 'success', data: 'Password updated' }
}
```

**Lignes de code : ~80 lignes**

---

### AVEC CLERK

**RIEN À FAIRE !**

Clerk gère automatiquement le "Forgot password?" dans le formulaire de login.

**Si vous voulez un lien custom :**

```typescript
'use client'
import { useSignIn } from '@clerk/nextjs'
import { useRouter } from 'next/navigation'

export default function ForgotPasswordLink() {
  const { signIn } = useSignIn()
  const router = useRouter()

  const handleForgotPassword = async () => {
    await signIn.create({
      strategy: 'reset_password_email_code',
      identifier: 'user@example.com' // ou demander à l'utilisateur
    })
    
    router.push('/reset-password')
  }

  return (
    <button onClick={handleForgotPassword}>
      Forgot password?
    </button>
  )
}
```

**Page reset password :**

```typescript
'use client'
import { useSignIn } from '@clerk/nextjs'

export default function ResetPasswordPage() {
  const { signIn } = useSignIn()
  const [code, setCode] = useState('')
  const [password, setPassword] = useState('')

  const onSubmit = async (e) => {
    e.preventDefault()
    
    await signIn.attemptFirstFactor({
      strategy: 'reset_password_email_code',
      code,
      password
    })
    
    router.push('/sign-in')
  }

  return (
    <form onSubmit={onSubmit}>
      <input value={code} onChange={e => setCode(e.target.value)} placeholder="Verification code" />
      <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="New password" />
      <button type="submit">Reset Password</button>
    </form>
  )
}
```

**Lignes de code : ~30 lignes**

---

## Déconnexion

### ACTUEL : NextAuth.js

```typescript
'use client'
import { signOut } from 'next-auth/react'

export default function LogoutButton() {
  return (
    <button onClick={() => signOut({ redirectTo: '/' })}>
      Logout
    </button>
  )
}
```

---

### AVEC CLERK

```typescript
'use client'
import { useClerk } from '@clerk/nextjs'

export default function LogoutButton() {
  const { signOut } = useClerk()
  
  return (
    <button onClick={() => signOut({ redirectUrl: '/' })}>
      Logout
    </button>
  )
}
```

**Ou utiliser le composant :**

```typescript
import { UserButton } from '@clerk/nextjs'

export default function Header() {
  return (
    <header>
      {/* Affiche avatar + menu dropdown avec logout */}
      <UserButton afterSignOutUrl="/" />
    </header>
  )
}
```

**Avantages Clerk :**
- ✅ Composant UserButton avec menu complet
- ✅ Avatar + settings + logout
- ✅ Multi-session support

---

## Middleware

### Comparaison Complète

| Fonctionnalité | NextAuth.js | Clerk |
|----------------|-------------|-------|
| **Configuration** | ~40 lignes | ~25 lignes |
| **Routes publiques** | Array manuel | Array + regex |
| **Protection auto** | Non | Oui |
| **Session refresh** | Manuel | Automatique |
| **Multi-tenancy** | Pas supporté | Supporté |
| **Org support** | Non | Oui (native) |

---

## Base de Données

### ACTUEL : NextAuth.js

**Schéma Prisma complet géré par vous :**

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

model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String? @db.Text
  access_token      String? @db.Text
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String? @db.Text
  session_state     String?
  user              User @relation(fields: [userId], references: [id], onDelete: Cascade)
  @@unique([provider, providerAccountId])
}

model Member {
  id          String   @id @default(cuid())
  userId      String   @unique
  name        String
  gender      String
  dateOfBirth DateTime
  description String
  city        String
  country     String
  user        User @relation(fields: [userId], references: [id])
}

model Token {
  id      String    @id @default(cuid())
  email   String
  token   String    @unique
  expires DateTime
  type    TokenType
}
```

**Vous gérez TOUT :**
- Migrations
- Relations
- Données auth + app

---

### AVEC CLERK

**Schéma Prisma simplifié (seulement données app) :**

```prisma
model Member {
  id          String   @id @default(cuid())
  clerkId     String   @unique  // Référence à Clerk user
  name        String
  email       String   @unique
  gender      String
  dateOfBirth DateTime
  description String
  city        String
  country     String
  imageUrl    String?
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}

// Pas besoin de User, Account, Token !
// Clerk gère tout ça
```

**Synchronisation via Webhooks (IMPORTANT !) :**

```typescript
// app/api/webhooks/clerk/route.ts
import { Webhook } from 'svix'
import { prisma } from '@/lib/prisma'

export async function POST(req: Request) {
  const WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET
  
  const payload = await req.text()
  const headers = {
    'svix-id': req.headers.get('svix-id'),
    'svix-timestamp': req.headers.get('svix-timestamp'),
    'svix-signature': req.headers.get('svix-signature')
  }

  const wh = new Webhook(WEBHOOK_SECRET)
  let evt

  try {
    evt = wh.verify(payload, headers)
  } catch (err) {
    return Response.json({ error: 'Invalid signature' }, { status: 400 })
  }

  const { id, email_addresses, first_name, last_name, image_url } = evt.data

  // user.created
  if (evt.type === 'user.created') {
    await prisma.member.create({
      data: {
        clerkId: id,
        email: email_addresses[0].email_address,
        name: `${first_name} ${last_name}`,
        imageUrl: image_url
      }
    })
  }

  // user.updated
  if (evt.type === 'user.updated') {
    await prisma.member.update({
      where: { clerkId: id },
      data: {
        email: email_addresses[0].email_address,
        name: `${first_name} ${last_name}`,
        imageUrl: image_url
      }
    })
  }

  // user.deleted
  if (evt.type === 'user.deleted') {
    await prisma.member.delete({
      where: { clerkId: id }
    })
  }

  return Response.json({ success: true })
}
```

**Configuration Webhook (Dashboard Clerk) :**

1. Configure > Webhooks
2. Add Endpoint: `https://votre-domaine.com/api/webhooks/clerk`
3. Subscribe to events:
   - user.created
   - user.updated
   - user.deleted
4. Copy webhook secret → `.env`

**Avantages Clerk :**
- ✅ Schéma plus simple
- ✅ Pas de gestion User/Account
- ✅ Sync automatique via webhooks

**Inconvénients Clerk :**
- ❌ Dépendance Clerk pour données auth
- ❌ Besoin webhooks (complexité)
- ❌ Délai sync (quelques ms)

---

## Webhooks (Important!)

### Événements Clerk Disponibles

| Événement | Description | Action |
|-----------|-------------|--------|
| `user.created` | Nouvel utilisateur | Créer Member en DB |
| `user.updated` | Profil mis à jour | Mettre à jour Member |
| `user.deleted` | Compte supprimé | Supprimer Member |
| `session.created` | Nouvelle session | Logger connexion |
| `session.ended` | Déconnexion | Logger déconnexion |
| `email.created` | Nouvel email | Sync email |
| `organization.created` | Nouvelle org | Créer org en DB |

**Webhooks sont ESSENTIELS avec Clerk pour garder votre DB à jour !**

---

## Comparaison Complète

### Lignes de Code

| Fonctionnalité | NextAuth.js | Clerk | Réduction |
|----------------|-------------|-------|-----------|
| **Installation & Config** | 300 lignes | 50 lignes | -83% |
| **Register** | 150 lignes | 80 lignes | -47% |
| **Login** | 150 lignes | 15 lignes | -90% |
| **Email Verification** | 100 lignes | 15 lignes | -85% |
| **Password Reset** | 80 lignes | 30 lignes | -63% |
| **OAuth Social** | 60 lignes | 20 lignes | -67% |
| **Middleware** | 40 lignes | 25 lignes | -38% |
| **Webhooks** | 0 lignes | 80 lignes | +∞ |
| **TOTAL** | ~880 lignes | ~315 lignes | **-64%** |

**Clerk = 64% moins de code à écrire/maintenir**

---

### Fonctionnalités Incluses

| Fonctionnalité | NextAuth.js | Clerk |
|----------------|-------------|-------|
| **Login UI** | ❌ À créer | ✅ Fournie |
| **Register UI** | ❌ À créer | ✅ Fournie |
| **Profile UI** | ❌ À créer | ✅ Fournie |
| **Email Templates** | ❌ À créer | ✅ Fournies |
| **Email Sending** | ❌ Resend séparé | ✅ Intégré |
| **Rate Limiting** | ❌ À ajouter | ✅ Intégré |
| **2FA** | ❌ À implémenter | ✅ Intégré |
| **Session Management** | ⚠️ Basique | ✅ Avancé |
| **Multi-session** | ❌ Non | ✅ Oui |
| **Organizations** | ❌ Non | ✅ Oui |
| **Admin Dashboard** | ❌ Non | ✅ Oui |
| **Analytics** | ❌ Non | ✅ Oui |
| **Audit Logs** | ❌ À créer | ✅ Fournis |
| **Customisation** | ✅✅✅ Max | ⚠️ Limitée |
| **Self-hosted** | ✅ Oui | ❌ Non |
| **Vendor Lock-in** | ✅ Aucun | ❌ Fort |

---

### Sécurité

| Aspect | NextAuth.js | Clerk |
|--------|-------------|-------|
| **Password Hashing** | ✅ bcrypt (vous) | ✅ bcrypt (Clerk) |
| **Rate Limiting** | ❌ À ajouter | ✅ Intégré |
| **CSRF Protection** | ✅ Oui | ✅ Oui |
| **XSS Protection** | ✅ Oui | ✅ Oui |
| **Session Hijacking** | ⚠️ JWT limité | ✅ Protection avancée |
| **Brute Force** | ❌ À gérer | ✅ Protection auto |
| **Bot Detection** | ❌ Non | ✅ Oui |
| **Device Fingerprint** | ❌ Non | ✅ Oui |
| **Anomaly Detection** | ❌ Non | ✅ Oui |
| **SOC 2 Compliant** | ⚠️ À vous | ✅ Oui |
| **GDPR Compliant** | ⚠️ À vous | ✅ Oui |

---

### Performance

| Métrique | NextAuth.js | Clerk |
|----------|-------------|-------|
| **Auth Check** | ~10ms (JWT local) | ~20ms (API call) |
| **Login** | ~200ms | ~300ms |
| **Register** | ~300ms | ~400ms |
| **Cold Start** | Excellent | Bon |
| **Scalabilité** | Infinie (JWT) | Très haute |
| **Latence** | Minimale | +10-20ms |

**NextAuth.js est plus rapide** (tout en local), mais différence négligeable.

---

## Migration Guide

### Migrer de NextAuth vers Clerk

**Étape 1 : Installation**

```bash
npm uninstall next-auth @auth/prisma-adapter
npm install @clerk/nextjs
```

**Étape 2 : Configuration**

```env
# Supprimer
- NEXTAUTH_SECRET
- NEXTAUTH_URL
- GOOGLE_CLIENT_ID (Clerk gère)
- GITHUB_CLIENT_SECRET (Clerk gère)

# Ajouter
+ NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_..."
+ CLERK_SECRET_KEY="sk_test_..."
+ CLERK_WEBHOOK_SECRET="whsec_..."
```

**Étape 3 : Supprimer fichiers NextAuth**

```bash
rm src/auth.ts
rm src/auth.config.ts
rm -rf src/app/api/auth
rm src/app/(auth)/*  # Remplacer par Clerk components
```

**Étape 4 : Mettre à jour Middleware**

```typescript
// Avant : NextAuth
import { auth } from './auth'
export default auth((req) => { ... })

// Après : Clerk
import { authMiddleware } from '@clerk/nextjs'
export default authMiddleware({ ... })
```

**Étape 5 : Mettre à jour Schéma Prisma**

```prisma
model Member {
  id          String @id @default(cuid())
  - userId      String @unique  // Supprimer
  + clerkId     String @unique  // Ajouter
  ...
}

- model User { ... }           // Supprimer
- model Account { ... }         // Supprimer
- model Token { ... }           // Supprimer
```

**Étape 6 : Migration données existantes**

```typescript
// Script de migration
import { clerkClient } from '@clerk/nextjs'

async function migrateUsers() {
  const users = await prisma.user.findMany({
    include: { member: true }
  })

  for (const user of users) {
    // Créer user dans Clerk
    const clerkUser = await clerkClient.users.createUser({
      emailAddress: [user.email],
      firstName: user.name.split(' ')[0],
      lastName: user.name.split(' ')[1],
      password: crypto.randomBytes(32).toString('hex') // Générer nouveau password
    })

    // Mettre à jour Member avec clerkId
    await prisma.member.update({
      where: { userId: user.id },
      data: { clerkId: clerkUser.id }
    })

    // Envoyer email pour réinitialiser password
    await clerkClient.users.updateUser(clerkUser.id, {
      passwordDigest: undefined // Force password reset
    })
  }
}
```

**Étape 7 : Setup Webhooks**

Voir section Webhooks ci-dessus.

**Étape 8 : Mettre à jour composants**

```typescript
// Avant : NextAuth
import { useSession } from 'next-auth/react'
const { data: session } = useSession()

// Après : Clerk
import { useUser } from '@clerk/nextjs'
const { user } = useUser()
```

**Temps estimé : 2-4 jours**

---

## Coûts

### NextAuth.js

| Service | Coût | Usage |
|---------|------|-------|
| **NextAuth** | Gratuit | Illimité |
| **PostgreSQL** | Variable | Selon provider |
| **Email (Resend)** | $0-20/mois | 3,000-100,000 emails |
| **Cloudinary** | $0-89/mois | Images |
| **Pusher** | $0-49/mois | Messaging |
| **TOTAL** | **~$0-160/mois** | Tous services |

---

### Clerk

| Plan | Coût | MAU | Fonctionnalités |
|------|------|-----|-----------------|
| **Free** | $0 | 10,000 | Toutes features, limited support |
| **Pro** | $25/mois + $0.02/MAU | Illimité | Priority support, advanced features |
| **Enterprise** | Custom | Illimité | SLA, custom contract, dedicated support |

**Exemple coûts :**

| Users Actifs/Mois | Coût Clerk | Économie Services | Total Net |
|-------------------|------------|-------------------|-----------|
| **1,000** | $25 | -$0 (free tier services) | **+$25/mois** |
| **5,000** | $25 + $100 = $125 | -$40 (Resend, etc.) | **+$85/mois** |
| **10,000** | $25 + $200 = $225 | -$80 | **+$145/mois** |
| **50,000** | $25 + $1,000 = $1,025 | -$200 | **+$825/mois** |

**Clerk coûte plus cher à grande échelle**, mais économise temps de développement.

---

## Recommandation Finale

### Quand Utiliser NextAuth.js

✅ **Choisissez NextAuth.js si :**
- Vous voulez un contrôle total
- Budget limité à long terme
- Customisation importante nécessaire
- Pas de vendor lock-in
- Vous aimez coder
- MVP avec fonctionnalités auth custom
- Open source important

**→ Votre cas actuel (Next Match) : NextAuth.js est BON**

---

### Quand Utiliser Clerk

✅ **Choisissez Clerk si :**
- Vous voulez lancer TRÈS vite
- Budget OK ($25-200/mois)
- UI auth pas priorité (utilisez composants Clerk)
- Besoin 2FA, organizations, multi-tenant
- Équipe petite (pas le temps de coder auth)
- Startup en croissance rapide
- Focus sur business logic, pas auth

**→ Pour un prototype rapide : Clerk serait PARFAIT**

---

## Conclusion

### Verdict

**NextAuth.js :**
- Plus de code (~880 lignes)
- Contrôle total
- Gratuit
- Flexible +++
- Maintenance à vous

**Clerk :**
- Moins de code (~315 lignes, -64%)
- Contrôle limité
- Payant ($25-1000+/mois)
- UI fournie
- Maintenance par Clerk

**Pour Next Match :**

Votre architecture actuelle avec **NextAuth.js est EXCELLENTE** car :
- Vous avez déjà tout codé
- Customisation importante (dating app)
- Pas de coût récurrent
- Vous contrôlez tout

**Rester sur NextAuth.js = Bon choix !**

**Migrer vers Clerk serait intéressant si :**
- Vous voulez gagner du temps dev futur
- Budget disponible
- Vous voulez 2FA/Organizations facilement
- Vous préférez focus sur features dating

---

**Les deux sont d'excellents choix. NextAuth.js = Plus de travail mais gratuit et flexible. Clerk = Moins de travail mais payant et lock-in.**

