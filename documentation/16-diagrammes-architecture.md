# Diagrammes d'Architecture - Next Match

Ce document contient tous les diagrammes d'architecture du projet en format Mermaid pour visualiser les flux de données, les composants et les interactions.

---

## Table des Matières

1. [Architecture Globale](#architecture-globale)
2. [Schéma de Base de Données](#schéma-de-base-de-données)
3. [Flux d'Authentification](#flux-dauthentification)
4. [Flux d'Inscription](#flux-dinscription)
5. [Flux de Messagerie Temps Réel](#flux-de-messagerie-temps-réel)
6. [Flux d'Upload d'Images](#flux-dupload-dimages)
7. [Flux de Modération](#flux-de-modération)
8. [Flux de Likes](#flux-de-likes)
9. [Architecture des Composants](#architecture-des-composants)
10. [Infrastructure et Services](#infrastructure-et-services)

---

## Architecture Globale

### Vue d'Ensemble du Système

```mermaid
graph TB
    subgraph "Client Browser"
        UI[Interface Next.js]
        Components[React Components]
        Hooks[Custom Hooks]
    end

    subgraph "Next.js Server"
        Pages[App Router Pages]
        ServerActions[Server Actions]
        API[API Routes]
        Middleware[Middleware]
    end

    subgraph "Services Externes"
        Neon[(Neon/Supabase<br/>PostgreSQL)]
        Cloudinary[Cloudinary<br/>Images]
        Pusher[Pusher/Ably<br/>Temps Réel]
        Resend[Resend<br/>Emails]
    end

    subgraph "Authentication"
        NextAuth[NextAuth v5]
        Providers[OAuth Providers]
    end

    UI --> Components
    Components --> Hooks
    Hooks --> ServerActions
    Pages --> ServerActions
    ServerActions --> Neon
    API --> Neon
    API --> Cloudinary
    API --> Pusher
    ServerActions --> Resend
    Middleware --> NextAuth
    NextAuth --> Providers
    NextAuth --> Neon

    style Neon fill:#0ea5e9,stroke:#0369a1,stroke-width:2px,color:#fff
    style Cloudinary fill:#1e40af,stroke:#1e3a8a,stroke-width:2px,color:#fff
    style Pusher fill:#6b21a8,stroke:#581c87,stroke-width:2px,color:#fff
    style Resend fill:#1f2937,stroke:#111827,stroke-width:2px,color:#fff
    style NextAuth fill:#7c3aed,stroke:#6d28d9,stroke-width:2px,color:#fff
```

---

## Schéma de Base de Données

### Relations Entre Tables

```mermaid
erDiagram
    USER ||--o| MEMBER : "has one"
    USER ||--o{ ACCOUNT : "has many"
    MEMBER ||--o{ PHOTO : "has many"
    MEMBER ||--o{ LIKE : "source of"
    MEMBER ||--o{ LIKE : "target of"
    MEMBER ||--o{ MESSAGE : "sends"
    MEMBER ||--o{ MESSAGE : "receives"
    
    USER {
        string id PK
        string email UK
        string name
        datetime emailVerified
        string passwordHash
        string image
        boolean profileComplete
        enum role
    }
    
    MEMBER {
        string id PK
        string userId FK,UK
        string name
        string gender
        datetime dateOfBirth
        string description
        string city
        string country
        string image
        datetime created
        datetime updated
    }
    
    PHOTO {
        string id PK
        string url
        string publicId
        boolean isApproved
        string memberId FK
    }
    
    LIKE {
        string sourceUserId PK,FK
        string targetUserId PK,FK
    }
    
    MESSAGE {
        string id PK
        string text
        datetime created
        string senderId FK
        string recipientId FK
        datetime dateRead
        boolean senderDeleted
        boolean recipientDeleted
    }
    
    ACCOUNT {
        string id PK
        string userId FK
        string provider
        string providerAccountId
        string access_token
        string refresh_token
    }
    
    TOKEN {
        string id PK
        string email
        string token
        datetime expires
        enum type
    }
```

---

## Flux d'Authentification

### Login avec Email/Password

```mermaid
sequenceDiagram
    participant User as Utilisateur
    participant Browser as Navigateur
    participant Form as LoginForm
    participant ServerAction as authActions
    participant NextAuth as NextAuth
    participant DB as Base de Données
    participant Session as Session JWT

    User->>Browser: Visite /login
    Browser->>Form: Affiche formulaire
    User->>Form: Entre email/password
    Form->>Form: Validation Zod
    Form->>ServerAction: signInWithCredentials()
    ServerAction->>NextAuth: signIn('credentials')
    NextAuth->>DB: SELECT User WHERE email
    DB-->>NextAuth: User data
    NextAuth->>NextAuth: Compare password (bcrypt)
    
    alt Password Correct
        NextAuth->>Session: Crée JWT token
        Session-->>Browser: Set cookie
        Browser->>Browser: Redirect /members
        Browser-->>User: Page MATCHES
    else Password Incorrect
        NextAuth-->>Form: Error
        Form-->>User: "Invalid credentials"
    end
```

---

### Login avec Google OAuth

```mermaid
sequenceDiagram
    participant User as Utilisateur
    participant Browser as Navigateur
    participant NextAuth as NextAuth
    participant Google as Google OAuth
    participant DB as Base de Données
    participant Session as Session

    User->>Browser: Clic "Login with Google"
    Browser->>NextAuth: Request OAuth
    NextAuth->>Google: Redirect to Google Login
    User->>Google: Authentification Google
    Google->>NextAuth: Callback avec token
    NextAuth->>Google: Verify token
    Google-->>NextAuth: User info (email, name)
    NextAuth->>DB: Cherche ou crée User
    
    alt User Exists
        NextAuth->>DB: UPDATE lastLogin
    else New User
        NextAuth->>DB: INSERT User + Account
    end
    
    NextAuth->>Session: Crée JWT
    Session-->>Browser: Set cookie
    Browser->>Browser: Redirect /complete-profile
    Browser-->>User: Formulaire profil
```

---

## Flux d'Inscription

### Inscription Complète

```mermaid
sequenceDiagram
    participant User as Utilisateur
    participant RegisterForm as Formulaire
    participant ServerAction as registerUser()
    participant DB as Base de Données
    participant Tokens as generateToken()
    participant Resend as Service Email
    participant Email as Boîte Email

    User->>RegisterForm: Entre email/password
    RegisterForm->>RegisterForm: Validation Zod
    RegisterForm->>ServerAction: registerUser(data)
    
    ServerAction->>DB: Check if email exists
    
    alt Email Déjà Utilisé
        DB-->>ServerAction: User exists
        ServerAction-->>RegisterForm: Error "Email exists"
        RegisterForm-->>User: Message erreur
    else Email Disponible
        ServerAction->>ServerAction: Hash password (bcrypt)
        ServerAction->>DB: INSERT User
        DB-->>ServerAction: User créé
        
        ServerAction->>Tokens: generateToken(email, VERIFICATION)
        Tokens->>DB: INSERT Token
        DB-->>Tokens: Token créé
        Tokens-->>ServerAction: Token string
        
        ServerAction->>Resend: sendVerificationEmail(email, token)
        Resend->>Email: Envoie email
        Email-->>User: Reçoit email
        
        ServerAction-->>RegisterForm: Success
        RegisterForm->>Browser: Redirect /register/success
        Browser-->>User: "Check your email"
    end
```

---

### Vérification Email

```mermaid
sequenceDiagram
    participant User as Utilisateur
    participant Email as Email
    participant Browser as Navigateur
    participant VerifyPage as Page verify-email
    participant ServerAction as verifyEmail()
    participant DB as Base de Données

    Email->>User: Email avec lien
    User->>Email: Clic sur lien
    Email->>Browser: Ouvre /verify-email?token=xxx
    Browser->>VerifyPage: Charge page
    VerifyPage->>ServerAction: verifyEmail(token)
    
    ServerAction->>DB: SELECT Token WHERE token
    
    alt Token Valide et Non Expiré
        DB-->>ServerAction: Token found
        ServerAction->>DB: UPDATE User SET emailVerified
        ServerAction->>DB: DELETE Token
        ServerAction-->>VerifyPage: Success
        VerifyPage->>Browser: Redirect /login
        Browser-->>User: "Email verified! Login"
    else Token Invalid ou Expiré
        DB-->>ServerAction: Not found ou expired
        ServerAction-->>VerifyPage: Error
        VerifyPage-->>User: "Invalid or expired token"
    end
```

---

## Flux de Messagerie Temps Réel

### Envoi et Réception de Message

```mermaid
sequenceDiagram
    participant UserA as Utilisateur A<br/>(Navigateur)
    participant FormA as ChatForm
    participant Action as createMessage()
    participant DB as Base de Données
    participant Pusher as Pusher Server
    participant PusherClient as Pusher Client
    participant UserB as Utilisateur B<br/>(Navigateur)
    participant UIB as Chat UI

    UserA->>FormA: Tape message "Hello"
    FormA->>Action: createMessage(recipientId, text)
    
    Action->>DB: INSERT Message
    DB-->>Action: Message créé
    
    Action->>Pusher: trigger('private-chatId', 'message:new', data)
    Pusher-->>PusherClient: Broadcast message
    
    par Affichage chez A et B
        Action-->>FormA: Message créé
        FormA->>FormA: Affiche message (optimistic)
    and
        PusherClient->>UserB: Événement reçu
        UserB->>UIB: useMessages hook détecte
        UIB->>UIB: Ajoute message à la liste
        UIB-->>UserB: Affiche "Hello" instantanément
    end
```

---

### Avec Supabase Realtime (Alternative)

```mermaid
sequenceDiagram
    participant UserA as Utilisateur A
    participant Form as ChatForm
    participant Action as createMessage()
    participant DB as Supabase DB
    participant Realtime as Supabase Realtime
    participant UserB as Utilisateur B
    participant UI as Chat UI

    UserA->>Form: Tape "Hello"
    Form->>Action: createMessage(recipientId, text)
    
    Action->>DB: INSERT Message
    
    DB->>DB: Détecte changement (postgres_changes)
    DB->>Realtime: Broadcast automatique
    
    par
        DB-->>Action: Message créé
        Action-->>Form: Success
        Form->>Form: Affiche message
    and
        Realtime->>UserB: Événement INSERT
        UserB->>UI: useMessages hook
        UI->>UI: Ajoute message
        UI-->>UserB: Affiche "Hello"
    end

    Note over Action,Realtime: Pas besoin de trigger manuel !<br/>Supabase diffuse automatiquement
```

---

## Flux d'Upload d'Images

### Upload avec Cloudinary

```mermaid
sequenceDiagram
    participant User as Utilisateur
    participant Button as Upload Button
    participant Widget as Cloudinary Widget
    participant Cloudinary as Cloudinary API
    participant SignAPI as /api/sign-image
    participant Action as addImage()
    participant DB as Base de Données
    participant Admin as Admin Dashboard

    User->>Button: Clic "Upload new image"
    Button->>Widget: Ouvre widget Cloudinary
    User->>Widget: Sélectionne image.jpg
    
    Widget->>SignAPI: Request signature (si signed)
    SignAPI-->>Widget: Signature
    
    Widget->>Cloudinary: POST /upload<br/>+ image<br/>+ preset: nextmatch
    
    Cloudinary->>Cloudinary: Valide preset (unsigned)
    Cloudinary->>Cloudinary: Upload image
    Cloudinary->>Cloudinary: Génère URL + transformations
    
    Cloudinary-->>Widget: {url, publicId}
    Widget-->>Button: Upload success
    
    Button->>Action: addImage(url, publicId)
    Action->>DB: INSERT Photo<br/>isApproved: false
    DB-->>Action: Photo créée
    Action-->>Button: Success
    Button-->>User: Affiche "Awaiting approval"
    
    Admin->>DB: SELECT Photos WHERE !isApproved
    DB-->>Admin: Liste photos en attente
    Admin->>Admin: Review photo
    Admin->>DB: UPDATE Photo SET isApproved=true
    DB-->>User: Photo maintenant visible
```

---

### Flux de Transformation d'Image Cloudinary

```mermaid
graph LR
    A[Image Originale<br/>4000x3000<br/>5 MB] --> B[Upload vers<br/>Cloudinary]
    B --> C{Preset:<br/>nextmatch}
    
    C --> D[Transformation 1:<br/>Resize 800x800]
    C --> E[Transformation 2:<br/>Format auto WebP]
    C --> F[Transformation 3:<br/>Quality auto]
    C --> G[Transformation 4:<br/>Crop fill]
    
    D --> H[Image Finale<br/>800x800<br/>150 KB]
    E --> H
    F --> H
    G --> H
    
    H --> I[CDN Mondial]
    I --> J[Utilisateur Europe<br/>Frankfurt CDN]
    I --> K[Utilisateur USA<br/>Virginia CDN]
    I --> L[Utilisateur Asie<br/>Singapore CDN]
    
    style B fill:#1e40af,stroke:#1e3a8a,stroke-width:2px,color:#fff
    style I fill:#1e40af,stroke:#1e3a8a,stroke-width:2px,color:#fff
```

---

## Flux de Modération

### Système d'Approbation des Photos

```mermaid
stateDiagram-v2
    [*] --> Uploaded: User upload image
    
    Uploaded --> AwaitingApproval: Photo.isApproved = false
    
    AwaitingApproval --> UnderReview: Admin opens /admin/moderation
    
    UnderReview --> Approved: Admin clicks Approve
    UnderReview --> Rejected: Admin clicks Reject
    
    Approved --> Visible: Photo.isApproved = true
    Rejected --> Deleted: DELETE Photo
    
    Visible --> [*]: Photo displayed publicly
    Deleted --> [*]: Photo removed
    
    note right of AwaitingApproval
        Photo existe en BDD
        Mais non visible publiquement
    end note
    
    note right of Visible
        Photo visible sur profil
        Et dans page MATCHES
    end note
```

---

## Flux de Likes

### Système de Likes Bidirectionnel

```mermaid
sequenceDiagram
    participant UserA as User A<br/>(todd)
    participant UI as Member Card
    participant Action as toggleLikeMember()
    participant DB as Base de Données
    participant UserB as User B<br/>(lisa)
    participant Notif as Notifications

    UserA->>UI: Clic ❤️ sur Lisa
    UI->>Action: toggleLikeMember(lisaId)
    
    Action->>DB: Check if Like exists
    
    alt Like N'existe Pas
        DB-->>Action: Not found
        Action->>DB: INSERT Like<br/>source: todd<br/>target: lisa
        DB-->>Action: Like créé
        
        Action->>DB: Check if Lisa a liké Todd
        
        alt Match (Lisa a aussi liké Todd)
            DB-->>Action: Mutual like found
            Action->>Notif: Envoie notification "It's a match!"
            Notif-->>UserA: Toast "You matched with Lisa!"
            Notif-->>UserB: Toast "You matched with Todd!"
        else Pas de Match
            DB-->>Action: No mutual like
            Action-->>UserA: Like added
        end
        
        Action-->>UI: Update UI (❤️ rouge)
    else Like Existe Déjà
        DB-->>Action: Like found
        Action->>DB: DELETE Like
        DB-->>Action: Like supprimé
        Action-->>UI: Update UI (❤️ gris)
    end
```

---

### Visualisation des Relations de Likes

```mermaid
graph TD
    subgraph "User A Perspective"
        A[Todd]
        A -->|likes| B[Lisa]
        A -->|likes| C[Karen]
        D[Margo] -->|likes| A
    end
    
    subgraph "Mutual Matches"
        A -.Match!.- B
    end
    
    subgraph "Lists"
        E[Members I Liked<br/>Lisa, Karen]
        F[Members Who Liked Me<br/>Margo, Lisa]
        G[Mutual Matches<br/>Lisa]
    end
    
    style A fill:#2563eb,stroke:#1e40af,stroke-width:2px,color:#fff
    style B fill:#db2777,stroke:#be185d,stroke-width:2px,color:#fff
    style G fill:#059669,stroke:#047857,stroke-width:2px,color:#fff
```

---

## Architecture des Composants

### Hiérarchie des Composants (Page Members)

```mermaid
graph TD
    Page[app/members/page.tsx<br/>Server Component] --> Filters[FiltersWrapper<br/>Client Component]
    Page --> MemberCards[Liste de MemberCard]
    Page --> Pagination[PaginationComponent]
    
    Filters --> FilterButtons[Gender Buttons]
    Filters --> AgeSlider[Age Range Slider]
    Filters --> PhotoToggle[With Photo Toggle]
    Filters --> OrderBy[Order By Dropdown]
    
    MemberCards --> Card1[MemberCard<br/>Client Component]
    MemberCards --> Card2[MemberCard]
    MemberCards --> Card3[MemberCard]
    
    Card1 --> CardImage[MemberImage]
    Card1 --> LikeBtn[LikeButton<br/>Client Component]
    Card1 --> CardInfo[CardInnerWrapper]
    
    CardImage --> PresenceAvatar[PresenceAvatar<br/>Presence Dot]
    LikeBtn --> ServerAction[toggleLikeMember<br/>Server Action]
    
    style Page fill:#16a34a,stroke:#15803d,stroke-width:2px,color:#fff
    style Card1 fill:#2563eb,stroke:#1e40af,stroke-width:2px,color:#fff
    style LikeBtn fill:#db2777,stroke:#be185d,stroke-width:2px,color:#fff
    style ServerAction fill:#d97706,stroke:#b45309,stroke-width:2px,color:#fff
```

---

### Flux de Données avec Zustand

```mermaid
graph LR
    subgraph "User Actions"
        A[Clic Filter Gender]
        B[Change Age Range]
        C[Toggle With Photo]
    end
    
    subgraph "Zustand Store"
        Store[useFilterStore]
    end
    
    subgraph "URL State"
        Params[Search Params]
    end
    
    subgraph "Server"
        Action[getMembers<br/>Server Action]
        DB[(Database)]
    end
    
    subgraph "UI Update"
        List[Member List]
    end
    
    A --> Store
    B --> Store
    C --> Store
    
    Store --> Params
    Params --> Action
    Action --> DB
    DB --> List
    
    style Store fill:#d97706,stroke:#b45309,stroke-width:2px,color:#fff
    style DB fill:#2563eb,stroke:#1e40af,stroke-width:2px,color:#fff
```

---

## Infrastructure et Services

### Architecture Cloud Complète

```mermaid
graph TB
    subgraph "User Devices"
        Desktop[Desktop Browser]
        Mobile[Mobile Browser]
    end
    
    subgraph "Vercel Edge Network"
        Edge[Edge Functions]
        CDN[Static Assets CDN]
    end
    
    subgraph "Next.js Application"
        NextApp[Next.js App<br/>Vercel]
        ServerComponents[Server Components]
        API[API Routes]
    end
    
    subgraph "Database"
        Neon[(Neon PostgreSQL<br/>us-east-1)]
        Supabase[(Supabase PostgreSQL<br/>us-east-1)]
    end
    
    subgraph "External Services"
        Cloud[Cloudinary<br/>Image CDN]
        Push[Pusher<br/>WebSocket mt1]
        Email[Resend<br/>Email Service]
    end
    
    subgraph "Authentication"
        Auth[NextAuth<br/>JWT Sessions]
        Google[Google OAuth]
        GitHub[GitHub OAuth]
    end
    
    Desktop --> Edge
    Mobile --> Edge
    Edge --> NextApp
    CDN --> Desktop
    CDN --> Mobile
    
    NextApp --> ServerComponents
    NextApp --> API
    
    ServerComponents --> Neon
    ServerComponents --> Supabase
    API --> Cloud
    API --> Push
    ServerComponents --> Email
    
    ServerComponents --> Auth
    Auth --> Google
    Auth --> GitHub
    
    style NextApp fill:#1f2937,stroke:#111827,stroke-width:2px,color:#fff
    style Neon fill:#0284c7,stroke:#0369a1,stroke-width:2px,color:#fff
    style Supabase fill:#059669,stroke:#047857,stroke-width:2px,color:#fff
    style Cloud fill:#1e40af,stroke:#1e3a8a,stroke-width:2px,color:#fff
    style Push fill:#6b21a8,stroke:#581c87,stroke-width:2px,color:#fff
    style Email fill:#1f2937,stroke:#111827,stroke-width:2px,color:#fff
```

---

### Stack Actuelle vs Stack Recommandée

```mermaid
graph LR
    subgraph "Stack Actuelle"
        direction TB
        A1[Next.js 14]
        A2[Neon PostgreSQL]
        A3[Cloudinary]
        A4[Pusher]
        A5[Resend]
        A6[NextAuth]
        
        A1 --> A2
        A1 --> A3
        A1 --> A4
        A1 --> A5
        A1 --> A6
    end
    
    subgraph "Stack Recommandée"
        direction TB
        B1[Next.js 14]
        B2[Supabase<br/>BDD + Realtime]
        B3[Cloudinary]
        B4[Resend]
        B5[NextAuth]
        
        B1 --> B2
        B1 --> B3
        B1 --> B4
        B1 --> B5
    end
    
    A1 -.Migration.-> B1
    A2 -.Remplacé par.-> B2
    A3 -.Gardé.-> B3
    A4 -.Remplacé par.-> B2
    A5 -.Gardé.-> B4
    A6 -.Gardé.-> B5
    
    style A2 fill:#dc2626,stroke:#b91c1c,stroke-width:2px,color:#fff
    style A4 fill:#dc2626,stroke:#b91c1c,stroke-width:2px,color:#fff
    style B2 fill:#16a34a,stroke:#15803d,stroke-width:2px,color:#fff
```

---

## Flux de Données - Cycle de Vie Complet

### Du Login au Message

```mermaid
flowchart TD
    Start([Utilisateur arrive sur l'app]) --> Login{Connecté ?}
    
    Login -->|Non| LoginPage[Page /login]
    LoginPage --> Auth[Authentification]
    Auth --> Session[Session créée JWT]
    
    Login -->|Oui| CheckProfile{Profil<br/>complet ?}
    
    CheckProfile -->|Non| CompleteProfile[/complete-profile]
    CompleteProfile --> CreateMember[Créer Member]
    CreateMember --> CheckProfile
    
    CheckProfile -->|Oui| HomePage[Page d'accueil]
    Session --> HomePage
    
    HomePage --> Matches[/members]
    Matches --> LoadMembers[getMembers<br/>Server Action]
    LoadMembers --> FilterMembers{Filtres actifs ?}
    
    FilterMembers -->|Oui| QueryFiltered[Query avec WHERE]
    FilterMembers -->|Non| QueryAll[Query tous membres]
    
    QueryFiltered --> DisplayCards[Affiche Member Cards]
    QueryAll --> DisplayCards
    
    DisplayCards --> UserAction{Action<br/>utilisateur ?}
    
    UserAction -->|❤️ Like| LikeAction[toggleLikeMember]
    UserAction -->|💬 Message| MessagePage[/members/userId/chat]
    UserAction -->|👤 View| ProfilePage[/members/userId]
    
    LikeAction --> CheckMatch{Match<br/>mutuel ?}
    CheckMatch -->|Oui| Notification[Toast "It's a match!"]
    CheckMatch -->|Non| UpdateUI[Update UI seulement]
    
    MessagePage --> LoadMessages[getMessagesByUser]
    LoadMessages --> DisplayMessages[Affiche messages]
    DisplayMessages --> RealtimeListener[Écoute Pusher/Supabase]
    
    RealtimeListener --> NewMessage{Nouveau<br/>message ?}
    NewMessage -->|Oui| UpdateMessages[Ajoute à la liste]
    NewMessage -->|Non| RealtimeListener
    
    UpdateMessages --> DisplayMessages
    
    style HomePage fill:#2563eb,stroke:#1e40af,stroke-width:2px,color:#fff
    style Matches fill:#2563eb,stroke:#1e40af,stroke-width:2px,color:#fff
    style MessagePage fill:#059669,stroke:#047857,stroke-width:2px,color:#fff
    style Notification fill:#d97706,stroke:#b45309,stroke-width:2px,color:#fff
```

---

## Architecture de Sécurité

### Middleware et Protection des Routes

```mermaid
flowchart TD
    Request[Requête HTTP] --> Middleware[middleware.ts]
    
    Middleware --> CheckAuth{Session<br/>valide ?}
    
    CheckAuth -->|Non| CheckRoute{Route<br/>publique ?}
    
    CheckRoute -->|Oui| AllowPublic[Autoriser]
    CheckRoute -->|Non| RedirectLogin[Redirect /login]
    
    CheckAuth -->|Oui| CheckComplete{Profil<br/>complet ?}
    
    CheckComplete -->|Non| CheckNeedProfile{Route nécessite<br/>profil ?}
    
    CheckNeedProfile -->|Oui| RedirectComplete[Redirect /complete-profile]
    CheckNeedProfile -->|Non| Allow[Autoriser]
    
    CheckComplete -->|Oui| CheckRole{Rôle<br/>requis ?}
    
    CheckRole -->|Admin| IsAdmin{User =<br/>Admin ?}
    CheckRole -->|Member| AllowMember[Autoriser]
    
    IsAdmin -->|Oui| AllowAdmin[Autoriser /admin]
    IsAdmin -->|Non| Forbidden[403 Forbidden]
    
    AllowPublic --> Page[Render Page]
    Allow --> Page
    AllowMember --> Page
    AllowAdmin --> Page
    RedirectLogin --> LoginPage[/login]
    RedirectComplete --> CompletePage[/complete-profile]
    
    style Middleware fill:#d97706,stroke:#b45309,stroke-width:2px,color:#fff
    style CheckAuth fill:#db2777,stroke:#be185d,stroke-width:2px,color:#fff
    style Page fill:#059669,stroke:#047857,stroke-width:2px,color:#fff
    style Forbidden fill:#dc2626,stroke:#b91c1c,stroke-width:2px,color:#fff
```

---

## Flux Complet : Use Case Messagerie

### Scénario : Todd envoie message à Lisa

```mermaid
sequenceDiagram
    autonumber
    participant T as Todd<br/>(Browser 1)
    participant TUI as Chat UI
    participant SA as Server Action
    participant DB as Database
    participant PS as Pusher Server
    participant PC as Pusher Client
    participant LUI as Chat UI
    participant L as Lisa<br/>(Browser 2)

    Note over T,L: Todd et Lisa sont tous deux en ligne

    T->>TUI: Tape "Hey Lisa!"
    TUI->>TUI: Validation locale
    TUI->>SA: createMessage(lisaId, "Hey Lisa!")
    
    SA->>SA: Vérif auth & permissions
    SA->>DB: INSERT INTO Message<br/>(senderId: todd, recipientId: lisa)
    DB-->>SA: Message ID créé
    
    SA->>DB: UPDATE Member SET updated=now()<br/>WHERE userId=todd
    
    SA->>PS: trigger('private-todd-lisa', 'message:new', {<br/>  id, text, senderId, created<br/>})
    
    par Broadcast Pusher
        PS-->>PC: Event to all subscribers
    and Réponse à Todd
        SA-->>TUI: {status: 'success', message: {...}}
        TUI->>TUI: Ajoute message (optimistic UI)
        TUI-->>T: Affiche "Hey Lisa!" immédiatement
    end
    
    PC->>L: Événement 'message:new'
    L->>LUI: Hook useMessages détecte
    LUI->>LUI: Ajoute message à state
    LUI->>LUI: Joue son notification
    LUI->>LUI: Affiche toast "New message from Todd"
    LUI-->>L: Message "Hey Lisa!" apparaît

    Note over T,L: Total time: <500ms
```

---

## Architecture des Hooks Personnalisés

### Dépendances entre Hooks

```mermaid
graph TD
    subgraph "Stores Zustand"
        MessageStore[useMessageStore<br/>Messages]
        PresenceStore[usePresenceStore<br/>Online Users]
        FilterStore[useFilterStore<br/>Filters State]
        PaginationStore[usePaginationStore<br/>Pagination]
    end
    
    subgraph "Hooks Personnalisés"
        UseMessages[useMessages<br/>Messaging Logic]
        UsePresence[usePresenceChannel<br/>Presence Logic]
        UseNotif[useNotificationChannel<br/>Notifications]
        UseFilters[useFilters<br/>Filter Logic]
    end
    
    subgraph "Services"
        Pusher[Pusher Client]
        ServerActions[Server Actions]
    end
    
    UseMessages --> MessageStore
    UseMessages --> Pusher
    UseMessages --> ServerActions
    
    UsePresence --> PresenceStore
    UsePresence --> Pusher
    
    UseNotif --> Pusher
    UseNotif --> MessageStore
    
    UseFilters --> FilterStore
    UseFilters --> PaginationStore
    
    style MessageStore fill:#d97706,stroke:#b45309,stroke-width:2px,color:#fff
    style UseMessages fill:#2563eb,stroke:#1e40af,stroke-width:2px,color:#fff
    style Pusher fill:#6b21a8,stroke:#581c87,stroke-width:2px,color:#fff
```

---

## Flux de Reset Password

### Processus Complet de Réinitialisation

```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant FP as Forgot Password Page
    participant SA as Server Action
    participant DB as Database
    participant Resend as Resend
    participant Email as Email
    participant RP as Reset Password Page

    U->>FP: Entre email
    FP->>SA: generateResetPasswordEmail(email)
    
    SA->>DB: SELECT User WHERE email
    
    alt User Existe
        DB-->>SA: User found
        SA->>SA: generateToken(email, PASSWORD_RESET)
        SA->>DB: INSERT Token<br/>type: PASSWORD_RESET<br/>expires: +1 hour
        DB-->>SA: Token créé
        
        SA->>Resend: sendPasswordResetEmail(email, token)
        Resend->>Email: Email avec lien<br/>/reset-password?token=xxx
        Email-->>U: Reçoit email
        
        SA-->>FP: Success
        FP-->>U: "Check your email"
        
        U->>Email: Clic sur lien
        Email->>RP: Ouvre /reset-password?token=xxx
        RP->>RP: Affiche formulaire nouveau password
        U->>RP: Entre nouveau password
        
        RP->>SA: resetPassword(token, newPassword)
        SA->>DB: SELECT Token WHERE token AND !expired
        
        alt Token Valide
            DB-->>SA: Token valid
            SA->>SA: Hash new password (bcrypt)
            SA->>DB: UPDATE User SET passwordHash
            SA->>DB: DELETE Token
            SA-->>RP: Success
            RP->>RP: Redirect /login
            RP-->>U: "Password reset! Login now"
        else Token Invalid ou Expiré
            DB-->>SA: Not found or expired
            SA-->>RP: Error
            RP-->>U: "Invalid or expired token"
        end
        
    else User N'existe Pas
        DB-->>SA: Not found
        SA-->>FP: Success (pour sécurité)
        FP-->>U: "Check your email"
        Note over FP,U: Message identique même si email invalide<br/>pour éviter énumération des emails
    end
```

---

## Déploiement et CI/CD

### Workflow de Déploiement sur Vercel

```mermaid
graph LR
    subgraph "Développement Local"
        Dev[Développeur]
        Git[Git Local]
    end
    
    subgraph "GitHub"
        Repo[Repository]
        PR[Pull Request]
    end
    
    subgraph "Vercel"
        Build[Build Process]
        Preview[Preview Deploy]
        Prod[Production Deploy]
    end
    
    subgraph "Services"
        DB[(Supabase)]
        Cloud[Cloudinary]
        Push[Pusher/Ably]
        Mail[Resend]
    end
    
    Dev -->|git commit| Git
    Git -->|git push| Repo
    Repo -->|Webhook| Build
    
    Build -->|Pour chaque commit| Preview
    Build -->|Sur main branch| Prod
    
    Preview --> DB
    Prod --> DB
    
    Prod --> Cloud
    Prod --> Push
    Prod --> Mail
    
    style Build fill:#1f2937,stroke:#111827,stroke-width:2px,color:#fff
    style Prod fill:#1f2937,stroke:#111827,stroke-width:2px,color:#fff
    style DB fill:#059669,stroke:#047857,stroke-width:2px,color:#fff
```

---

## Performance et Caching

### Stratégie de Cache Next.js

```mermaid
graph TD
    Request[Request /members] --> Cache{Cache<br/>valide ?}
    
    Cache -->|Oui| Cached[Retourne données<br/>en cache<br/>⚡ <10ms]
    
    Cache -->|Non| ServerAction[getMembers<br/>Server Action]
    
    ServerAction --> DB[Query Database<br/>⏱️ 100-300ms]
    DB --> Transform[Transform data<br/>mappings.ts]
    Transform --> Store[Store in cache<br/>revalidate: 60s]
    Store --> Return[Return data]
    
    Cached --> Display[Affiche UI]
    Return --> Display
    
    Update[Mutation<br/>updateMember] --> Invalidate[revalidateTag<br/>'members']
    Invalidate --> Cache
    
    style Cached fill:#059669,stroke:#047857,stroke-width:2px,color:#fff
    style ServerAction fill:#d97706,stroke:#b45309,stroke-width:2px,color:#fff
    style DB fill:#2563eb,stroke:#1e40af,stroke-width:2px,color:#fff
```

---

## Gestion des États

### State Management dans l'Application

```mermaid
graph TB
    subgraph "Server State"
        Database[(Database<br/>Source of Truth)]
        ServerActions[Server Actions<br/>Mutations]
    end
    
    subgraph "Client State - Zustand"
        Messages[MessageStore<br/>Messages en cours]
        Presence[PresenceStore<br/>Users online]
        Filters[FilterStore<br/>Active filters]
        Pagination[PaginationStore<br/>Page state]
    end
    
    subgraph "Local State - React"
        FormState[React Hook Form<br/>Form data]
        UIState[useState<br/>UI interactions]
    end
    
    subgraph "URL State"
        SearchParams[Search Params<br/>Filters, page]
    end
    
    subgraph "Auth State"
        Session[NextAuth Session<br/>User info]
    end
    
    Database --> ServerActions
    ServerActions --> Messages
    ServerActions --> Presence
    
    Filters <--> SearchParams
    Pagination <--> SearchParams
    
    Session --> UIState
    
    style Database fill:#2563eb,stroke:#1e40af,stroke-width:2px,color:#fff
    style Messages fill:#d97706,stroke:#b45309,stroke-width:2px,color:#fff
    style Session fill:#7c3aed,stroke:#6d28d9,stroke-width:2px,color:#fff
```

---

## Architecture de Sécurité - Layers

### Couches de Protection

```mermaid
graph TD
    Internet[Internet / Users] --> L1[Layer 1: Edge CDN<br/>Vercel Edge<br/>DDoS Protection]
    
    L1 --> L2[Layer 2: Middleware<br/>Auth Check<br/>Route Protection]
    
    L2 --> L3[Layer 3: Server Actions<br/>Session Validation<br/>Authorization]
    
    L3 --> L4[Layer 4: Input Validation<br/>Zod Schemas<br/>Data Sanitization]
    
    L4 --> L5[Layer 5: Prisma ORM<br/>SQL Injection Prevention<br/>Type Safety]
    
    L5 --> L6[Layer 6: Database<br/>Row Level Security RLS<br/>Encryption at Rest]
    
    L6 --> Data[(Données Sécurisées)]
    
    style L1 fill:#dc2626,stroke:#b91c1c,stroke-width:2px,color:#fff
    style L2 fill:#ea580c,stroke:#c2410c,stroke-width:2px,color:#fff
    style L3 fill:#d97706,stroke:#b45309,stroke-width:2px,color:#fff
    style L4 fill:#ca8a04,stroke:#a16207,stroke-width:2px,color:#fff
    style L5 fill:#65a30d,stroke:#4d7c0f,stroke-width:2px,color:#fff
    style L6 fill:#16a34a,stroke:#15803d,stroke-width:2px,color:#fff
    style Data fill:#059669,stroke:#047857,stroke-width:2px,color:#fff
```

---

## Comparaison des Architectures

### Architecture Monolithique vs Serverless

```mermaid
graph TB
    subgraph "Architecture Traditionnelle"
        direction LR
        MT[Serveur<br/>Node.js]
        MDB[(PostgreSQL<br/>Même serveur)]
        MRedis[(Redis<br/>Sessions)]
        
        MT --- MDB
        MT --- MRedis
    end
    
    subgraph "Architecture Next Match Serverless"
        direction LR
        Edge[Vercel Edge]
        Serverless[Next.js<br/>Serverless Functions]
        ExtDB[(Supabase<br/>Managé)]
        ExtCache[Vercel KV<br/>ou Cache Next.js]
        ExtRT[Supabase Realtime<br/>Managé]
        
        Edge --> Serverless
        Serverless --> ExtDB
        Serverless --> ExtCache
        Serverless --> ExtRT
    end
    
    style MT fill:#dc2626,stroke:#b91c1c,stroke-width:2px,color:#fff
    style Edge fill:#059669,stroke:#047857,stroke-width:2px,color:#fff
    style Serverless fill:#059669,stroke:#047857,stroke-width:2px,color:#fff
```

**Avantages Serverless :**
- ✅ Pas de serveur à gérer
- ✅ Scale automatique
- ✅ Paiement à l'usage
- ✅ 0 maintenance

---

## Flux de Données Optimisé

### Avec Caching et Optimistic Updates

```mermaid
sequenceDiagram
    participant U as User
    participant UI as Interface
    participant Cache as Next.js Cache
    participant SA as Server Action
    participant DB as Database
    participant RT as Realtime

    U->>UI: Action (Like profile)
    
    UI->>UI: Optimistic Update<br/>(❤️ devient rouge immédiatement)
    UI-->>U: Feedback instantané ⚡
    
    par Requête serveur en arrière-plan
        UI->>SA: toggleLikeMember()
        SA->>Cache: Check cache
        
        alt Cache Hit
            Cache-->>SA: Cached data
        else Cache Miss
            SA->>DB: Query
            DB-->>SA: Data
            SA->>Cache: Store result
        end
        
        SA->>DB: INSERT/DELETE Like
        DB-->>SA: Success
        SA->>Cache: Invalidate cache
        SA->>RT: Notify other user
        SA-->>UI: Confirmation
    end
    
    alt Success
        UI->>UI: Confirme optimistic update
    else Error
        UI->>UI: Rollback optimistic update
        UI-->>U: Affiche erreur
    end
```

---

## Résumé Architectural

### Principes de Design

```mermaid
mindmap
  root((Next Match<br/>Architecture))
    Performance
      Server Components
      Caching agressif
      Optimistic Updates
      Image Optimization
    Sécurité
      Middleware Auth
      Input Validation
      SQL Injection Protection
      CSRF Protection
    Scalabilité
      Serverless Functions
      CDN Global
      Database Pooling
      Edge Computing
    Expérience Dev
      TypeScript Strict
      Prisma Type Safety
      Hot Reload
      Error Boundaries
    Expérience User
      Temps Réel
      Feedback Immédiat
      Progressive Enhancement
      Responsive Design
```

---

## Stack Technique Visuelle

### Technologies et Relations

```mermaid
graph TB
    subgraph "Frontend"
        React[React 18<br/>Server Components]
        NextUI[NextUI<br/>Components]
        Tailwind[Tailwind CSS<br/>Styling]
        Framer[Framer Motion<br/>Animations]
        Icons[React Icons]
    end
    
    subgraph "Framework"
        Next[Next.js 14<br/>App Router]
        NextImg[next/image<br/>Optimization]
        NextFont[next/font<br/>Font Optimization]
    end
    
    subgraph "Backend"
        ServerActions[Server Actions]
        APIRoutes[API Routes]
        Middleware[Middleware]
    end
    
    subgraph "Data Layer"
        Prisma[Prisma ORM<br/>Type-safe queries]
        Zod[Zod<br/>Validation]
    end
    
    subgraph "Auth"
        NextAuth[NextAuth v5<br/>JWT Sessions]
        Bcrypt[bcryptjs<br/>Password Hashing]
    end
    
    subgraph "State"
        Zustand[Zustand<br/>Global State]
        RHF[React Hook Form<br/>Form State]
    end
    
    React --> Next
    NextUI --> React
    Tailwind --> React
    Framer --> React
    Icons --> React
    
    Next --> ServerActions
    Next --> APIRoutes
    Next --> Middleware
    Next --> NextImg
    Next --> NextFont
    
    ServerActions --> Prisma
    APIRoutes --> Prisma
    ServerActions --> Zod
    
    Middleware --> NextAuth
    NextAuth --> Bcrypt
    NextAuth --> Prisma
    
    React --> Zustand
    React --> RHF
    
    style Next fill:#1f2937,stroke:#111827,stroke-width:2px,color:#fff
    style React fill:#0ea5e9,stroke:#0369a1,stroke-width:2px,color:#fff
    style Prisma fill:#1f2937,stroke:#111827,stroke-width:2px,color:#fff
    style NextAuth fill:#7c3aed,stroke:#6d28d9,stroke-width:2px,color:#fff
```

---

## Flux de Données par Fonctionnalité

### Feature : Système de Filtres

```mermaid
flowchart LR
    User[Utilisateur] -->|Change filter| UI[Filter UI]
    
    UI -->|Update| Store[useFilterStore<br/>Zustand]
    
    Store -->|Sync| URL[URL Search Params<br/>?gender=female&age=18-100]
    
    URL -->|Trigger| ServerComponent[MembersPage<br/>Server Component]
    
    ServerComponent -->|Call| Action[getMembers<br/>with filters]
    
    Action -->|Build query| Prisma[Prisma Query Builder]
    
    Prisma -->|Execute| DB[(Database)]
    
    DB -->|Results| Transform[Transform data<br/>mappings.ts]
    
    Transform -->|Return| Display[Display Members]
    
    Display -->|Render| User
    
    style Store fill:#d97706,stroke:#b45309,stroke-width:2px,color:#fff
    style DB fill:#2563eb,stroke:#1e40af,stroke-width:2px,color:#fff
    style Prisma fill:#1f2937,stroke:#111827,stroke-width:2px,color:#fff
```

---

## Architecture de Déploiement

### Production sur Vercel

```mermaid
graph TB
    subgraph "Git Repository"
        Main[main branch]
        Dev[dev branch]
        Feature[feature branches]
    end
    
    subgraph "Vercel Platform"
        BuildMain[Production Build]
        BuildDev[Preview Build]
        BuildFeature[Preview Builds]
        
        ProdDeploy[Production<br/>nextmatch.vercel.app]
        PreviewDeploy[Preview<br/>feature-xyz.vercel.app]
    end
    
    subgraph "Edge Network"
        EdgeUS[Edge US]
        EdgeEU[Edge EU]
        EdgeAsia[Edge Asia]
    end
    
    subgraph "Services Production"
        ProdDB[(Supabase Prod)]
        ProdCloud[Cloudinary]
        ProdPush[Pusher/Ably]
        ProdMail[Resend]
    end
    
    Main -->|Push| BuildMain
    BuildMain --> ProdDeploy
    
    Dev -->|Push| BuildDev
    BuildDev --> PreviewDeploy
    
    Feature -->|PR| BuildFeature
    BuildFeature --> PreviewDeploy
    
    ProdDeploy --> EdgeUS
    ProdDeploy --> EdgeEU
    ProdDeploy --> EdgeAsia
    
    ProdDeploy --> ProdDB
    ProdDeploy --> ProdCloud
    ProdDeploy --> ProdPush
    ProdDeploy --> ProdMail
    
    style Main fill:#059669,stroke:#047857,stroke-width:2px,color:#fff
    style ProdDeploy fill:#1f2937,stroke:#111827,stroke-width:2px,color:#fff
    style ProdDB fill:#059669,stroke:#047857,stroke-width:2px,color:#fff
```

---

## Récapitulatif de la Documentation

**Vous avez maintenant 16 documents complets :**

```
documentation/
├── 01 - Guide démarrage
├── 02 - Configuration environnement  
├── 03 - Scripts automatisation
├── 04 - Architecture projet
├── 05 - Troubleshooting général
├── 06 - Docker Compose
├── 07 - Guide débutant sans Docker
├── 08 - Troubleshooting session (Cloudinary, Pusher)
├── 09 - Troubleshooting emails Resend
├── 10 - Analyse stack MVP
├── 11 - Optimisation performance
├── 12 - Comparaison Neon vs Supabase
├── 13 - Migration vers Supabase
├── 14 - Comparaison services emails
├── 15 - Comparaison services temps réel
└── 16 - Diagrammes architecture ← NOUVEAU !
```

**Documentation professionnelle COMPLÈTE avec diagrammes visuels !**

