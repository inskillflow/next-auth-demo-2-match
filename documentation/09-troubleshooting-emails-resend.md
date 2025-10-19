# Troubleshooting - Problème d'Envoi d'Emails avec Resend

Ce document détaille le problème des emails qui ne s'envoient pas lors de l'inscription ou de la réinitialisation de mot de passe, et comment le résoudre.

---

## Table des Matières

1. [Symptômes du Problème](#symptômes-du-problème)
2. [Cause Principale](#cause-principale)
3. [Solution Rapide](#solution-rapide)
4. [Configuration Complète de Resend](#configuration-complète-de-resend)
5. [Domaine Par Défaut vs Domaine Personnalisé](#domaine-par-défaut-vs-domaine-personnalisé)
6. [Configuration d'un Domaine Personnalisé](#configuration-dun-domaine-personnalisé)
7. [Vérifications et Tests](#vérifications-et-tests)
8. [Problèmes Courants](#problèmes-courants)
9. [Alternative Sans Email](#alternative-sans-email)

---

## Symptômes du Problème

### Ce que vous observez

Lors de l'inscription d'un nouveau compte :

```
✓ You have successfully registered
Please verify your email address before you can login
```

**MAIS :**
- Aucun email n'arrive dans votre boîte de réception
- Pas d'email dans les spams non plus
- L'utilisateur est créé dans la base de données
- Le message dit qu'un email a été envoyé, mais rien n'arrive

### Captures d'écran typiques

**Page après inscription :**
```
┌────────────────────────────────────────────┐
│  ✓ You have successfully registered       │
│                                            │
│  Please verify your email address         │
│  before you can login                      │
│                                            │
│  [Go to login]                             │
└────────────────────────────────────────────┘
```

**Boîte email :**
```
Inbox: (vide)
Spam: (vide)
```

---

## Cause Principale

### Deux problèmes possibles

#### Problème 1 : Clé API Resend manquante ou vide

Le fichier `.env` ne contient pas la clé API Resend, ou elle est vide :

```env
RESEND_API_KEY=""   ← VIDE = Pas d'envoi
```

#### Problème 2 : Adresse d'expéditeur non configurée

Le code essaie d'envoyer depuis un domaine non configuré :

**Dans `src/lib/mail.ts` :**
```typescript
from: 'mail@nextmatch.trycatchlearn.com'  ← Ce domaine n'existe pas
```

**Résultat :** Resend refuse d'envoyer l'email car le domaine n'est pas vérifié.

---

## Solution Rapide

### Étape 1 : Obtenir une clé API Resend

#### 1.1 - Créer un compte Resend

1. Allez sur : https://resend.com
2. Cliquez sur **"Sign Up"**
3. Inscrivez-vous avec :
   - Email
   - Mot de passe
   - Ou utilisez GitHub
4. Vérifiez votre email de confirmation

#### 1.2 - Créer une API Key

1. Une fois connecté sur Resend Dashboard
2. Dans le menu de gauche, cliquez sur **"API Keys"**
3. Cliquez sur **"Create API Key"** ou **"+ Create"**
4. Remplissez :
   - **Name** : `nextmatch` (pour identifier cette clé)
   - **Permission** : Laissez **"Full Access"**
5. Cliquez sur **"Create"**
6. **IMPORTANT :** Une clé apparaît qui commence par `re_`
7. **COPIEZ IMMÉDIATEMENT** cette clé (vous ne pourrez plus la revoir après)

**Format de la clé :**
```
re_DETBnxkU_8sAQhkqS1rvCjASZjpWB3AKL
```

### Étape 2 : Ajouter la clé dans .env

Ouvrez votre fichier `.env` à la racine du projet et ajoutez ou modifiez cette ligne :

```env
# Resend (Envoi d'emails)
RESEND_API_KEY="re_votre_cle_ici"
```

**Exemple complet :**
```env
RESEND_API_KEY="re_DETBnxkU_8sAQhkqS1rvCjASZjpWB3AKL"
```

**Vérifications :**
- Pas d'espace avant ou après les guillemets
- La clé commence bien par `re_`
- Les guillemets sont présents

### Étape 3 : Modifier l'adresse d'expéditeur

Ouvrez le fichier `src/lib/mail.ts` et modifiez les deux fonctions :

**AVANT (ne fonctionne pas) :**
```typescript
export async function sendVerificationEmail(email: string, token: string) {
    const link = `${baseUrl}/verify-email?token=${token}`;

    return resend.emails.send({
        from: 'mail@nextmatch.trycatchlearn.com',  // ← Domaine non configuré
        to: email,
        subject: 'Verify your email address',
        html: `...`
    })
}
```

**APRÈS (fonctionne) :**
```typescript
export async function sendVerificationEmail(email: string, token: string) {
    const link = `${baseUrl}/verify-email?token=${token}`;

    return resend.emails.send({
        from: 'onboarding@resend.dev',  // ← Domaine par défaut de Resend
        to: email,
        subject: 'Verify your email address',
        html: `...`
    })
}
```

**Faites la même modification pour la deuxième fonction :**

```typescript
export async function sendPasswordResetEmail(email: string, token: string) {
    const link = `${baseUrl}/reset-password?token=${token}`;

    return resend.emails.send({
        from: 'onboarding@resend.dev',  // ← Changé ici aussi
        to: email,
        subject: 'Reset your password',
        html: `...`
    })
}
```

### Étape 4 : Redémarrer l'application

```powershell
# Dans le terminal où tourne npm run dev
# Appuyez sur Ctrl + C pour arrêter

# Puis redémarrez
npm run dev
```

**IMPORTANT :** Le redémarrage est obligatoire car les variables d'environnement ne sont chargées qu'au démarrage.

### Étape 5 : Tester

1. Allez sur http://localhost:3000/register
2. Créez un compte avec un **nouvel email** (pas un déjà utilisé)
3. Complétez l'inscription
4. **Vérifiez votre boîte email** (inbox et spam)
5. L'email devrait arriver en 1-2 minutes

**L'email viendra de :** `onboarding@resend.dev`

---

## Configuration Complète de Resend

### Compte Resend - Informations

**Gratuit :**
- 100 emails par jour
- 3,000 emails par mois
- Domaine par défaut (`onboarding@resend.dev`)
- API complète

**Payant (si besoin plus tard) :**
- Plus d'emails
- Domaines personnalisés illimités
- Support prioritaire

### Dashboard Resend

Une fois connecté sur https://resend.com, vous avez accès à :

#### 1. Emails (Historique)

```
Menu: Emails
```

Voir tous les emails envoyés :
- ✅ **Delivered** : Email livré avec succès
- ⏳ **Queued** : En attente d'envoi
- 📧 **Sent** : Envoyé par Resend
- ❌ **Failed** : Échec (voir la raison)

**Informations disponibles :**
- Date et heure d'envoi
- Destinataire
- Sujet
- Statut
- Raison de l'échec (si applicable)

#### 2. API Keys (Clés)

```
Menu: API Keys
```

Gérer vos clés API :
- Créer de nouvelles clés
- Voir les clés existantes (nom et date de création)
- Révoquer des clés
- **Note :** Les clés ne sont visibles qu'une seule fois à la création

#### 3. Domains (Domaines)

```
Menu: Domains
```

Gérer vos domaines d'envoi :
- Ajouter un domaine personnalisé
- Vérifier le statut DNS
- Voir les enregistrements DNS nécessaires

#### 4. Settings (Paramètres)

```
Menu: Settings
```

Configuration du compte :
- Informations du compte
- Webhooks (notifications)
- Limites et quotas

---

## Domaine Par Défaut vs Domaine Personnalisé

### Domaine Par Défaut : `onboarding@resend.dev`

#### Avantages

✅ **Aucune configuration nécessaire**
- Fonctionne immédiatement après création du compte
- Pas de DNS à configurer
- Pas de domaine à acheter

✅ **Parfait pour le développement**
- Tests rapides
- Développement local
- Démonstrations

✅ **Gratuit**
- Inclus dans tous les plans

#### Inconvénients

⚠️ **Pas professionnel**
- L'email vient de `onboarding@resend.dev`
- Pas votre marque

⚠️ **Peut finir dans les spams**
- Domaine partagé par tous les utilisateurs Resend
- Réputation partagée

⚠️ **Limite de 100 emails/jour** (gratuit)
- Suffisant pour le dev
- Trop peu pour la production

#### Quand l'utiliser

**Utilisez le domaine par défaut pour :**
- Développement et tests locaux ✅
- Prototypes et démonstrations ✅
- Apprentissage ✅
- Applications personnelles ✅

**Ne pas utiliser pour :**
- Production avec vrais utilisateurs ❌
- Applications commerciales ❌
- Grandes audiences ❌

---

### Domaine Personnalisé : `noreply@votresite.com`

#### Avantages

✅ **Professionnel**
- Email vient de votre domaine
- Renforce votre marque
- Plus crédible

✅ **Meilleure délivrabilité**
- Réputation propre à votre domaine
- Moins de risque de spam
- Contrôle total

✅ **Limites plus élevées**
- Selon votre plan Resend
- Pas de limite sur le domaine lui-même

#### Inconvénients

❌ **Configuration nécessaire**
- Enregistrements DNS à ajouter
- Vérification du domaine (5-30 minutes)
- Connaissance technique requise

❌ **Domaine requis**
- Vous devez posséder un nom de domaine
- Coût : 10-15€/an

#### Quand l'utiliser

**Utilisez un domaine personnalisé pour :**
- Production ✅
- Application commerciale ✅
- Clients réels ✅
- Grande audience ✅

---

### Tableau Comparatif

| Critère | Domaine Par Défaut | Domaine Personnalisé |
|---------|-------------------|---------------------|
| **Configuration** | ✅ Aucune | ⚠️ DNS requis |
| **Coût** | ✅ Gratuit | ⚠️ 10-15€/an (domaine) |
| **Temps setup** | ✅ 0 minute | ⚠️ 30 minutes |
| **Professionnalisme** | ⚠️ Basique | ✅ Élevé |
| **Délivrabilité** | ⚠️ Moyenne | ✅ Élevée |
| **Limite emails** | ⚠️ 100/jour (gratuit) | ✅ Selon plan |
| **Dev/Tests** | ✅ Parfait | ⚠️ Overkill |
| **Production** | ⚠️ Acceptable (petit) | ✅ Idéal |
| **Réputation** | ⚠️ Partagée | ✅ Propre |
| **Contrôle** | ⚠️ Limité | ✅ Total |

---

## Configuration d'un Domaine Personnalisé

Si vous voulez utiliser votre propre domaine (exemple : `monsite.com`), voici la procédure complète.

### Prérequis

Vous devez **posséder un nom de domaine** acheté chez :
- GoDaddy
- Namecheap
- OVH
- Google Domains
- Cloudflare
- Gandi
- etc.

**Coût :** Environ 10-15€ par an selon l'extension (.com, .fr, .io, etc.)

---

### Étape 1 : Ajouter le domaine dans Resend

#### 1.1 - Accéder à la section Domains

1. Allez sur https://resend.com
2. Connectez-vous à votre compte
3. Dans le menu de gauche, cliquez sur **"Domains"**
4. Vous voyez la liste de vos domaines (vide au début)

#### 1.2 - Ajouter un nouveau domaine

1. Cliquez sur **"Add Domain"** ou **"+ Add"**
2. Une popup s'ouvre
3. Entrez votre nom de domaine : `monsite.com`
4. **NE PAS** mettre `www.` ou `https://`, juste le nom de domaine
5. Cliquez sur **"Add"** ou **"Continue"**

#### 1.3 - Choisir la région (optionnel)

1. Sélectionnez la région la plus proche de vos utilisateurs :
   - **US East** : Amérique du Nord
   - **EU West** : Europe
   - **AP Southeast** : Asie
2. Cliquez sur **"Continue"**

---

### Étape 2 : Récupérer les enregistrements DNS

Resend va afficher une page avec les **enregistrements DNS** à ajouter.

#### 2.1 - Enregistrements à copier

**Exemple des enregistrements fournis par Resend :**

```
┌─────────────────────────────────────────────────────────────┐
│  DNS Records to Add                                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  SPF Record (TXT)                                            │
│  ────────────────                                           │
│  Type:  TXT                                                  │
│  Name:  @                                                    │
│  Value: v=spf1 include:resend.com ~all                      │
│                                                              │
│  DKIM Record (CNAME)                                         │
│  ─────────────────────                                      │
│  Type:  CNAME                                                │
│  Name:  resend._domainkey                                    │
│  Value: resend._domainkey.resend.com                        │
│                                                              │
│  MX Record (Optional for bounce handling)                    │
│  ────────────────────────────────────────                   │
│  Type:  MX                                                   │
│  Name:  @                                                    │
│  Value: feedback-smtp.resend.com                            │
│  Priority: 10                                                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**IMPORTANT :** Notez ou copiez ces valeurs, vous en aurez besoin pour l'étape suivante.

#### 2.2 - Explication des enregistrements

**SPF (Sender Policy Framework) :**
- Indique que Resend est autorisé à envoyer des emails pour votre domaine
- Obligatoire pour que les emails ne soient pas marqués comme spam

**DKIM (DomainKeys Identified Mail) :**
- Signature cryptographique qui prouve que l'email vient bien de votre domaine
- Obligatoire pour l'authentification

**MX (Mail Exchange) :**
- Optionnel
- Permet de recevoir les notifications de rebond (bounce)
- Recommandé mais pas obligatoire

---

### Étape 3 : Ajouter les DNS chez votre hébergeur

Les étapes varient selon votre hébergeur. Voici les procédures pour les plus courants :

---

#### Configuration chez GoDaddy

1. **Connexion**
   - Allez sur https://godaddy.com
   - Connectez-vous

2. **Accéder à la gestion DNS**
   - Cliquez sur votre nom (en haut à droite)
   - **"Mes produits"** ou **"My Products"**
   - Trouvez votre domaine
   - Cliquez sur **"DNS"** ou **"Gérer DNS"**

3. **Ajouter l'enregistrement SPF (TXT)**
   - Descendez à la section **"Records"** ou **"Enregistrements"**
   - Cliquez sur **"Add"** ou **"Ajouter"**
   - Sélectionnez **"TXT"**
   - **Name** : `@`
   - **Value** : `v=spf1 include:resend.com ~all`
   - **TTL** : 3600 (par défaut)
   - Cliquez sur **"Save"**

4. **Ajouter l'enregistrement DKIM (CNAME)**
   - Cliquez sur **"Add"** à nouveau
   - Sélectionnez **"CNAME"**
   - **Name** : `resend._domainkey`
   - **Value** : `resend._domainkey.resend.com`
   - **TTL** : 3600
   - Cliquez sur **"Save"**

5. **Ajouter l'enregistrement MX (optionnel)**
   - Cliquez sur **"Add"**
   - Sélectionnez **"MX"**
   - **Name** : `@`
   - **Value** : `feedback-smtp.resend.com`
   - **Priority** : `10`
   - **TTL** : 3600
   - Cliquez sur **"Save"**

---

#### Configuration chez OVH

1. **Connexion**
   - Allez sur https://ovh.com
   - Connectez-vous à votre espace client

2. **Accéder à la zone DNS**
   - Menu **"Web Cloud"**
   - Cliquez sur **"Noms de domaine"**
   - Sélectionnez votre domaine
   - Onglet **"Zone DNS"**

3. **Ajouter l'enregistrement SPF (TXT)**
   - Cliquez sur **"Ajouter une entrée"**
   - Sélectionnez **"TXT"**
   - **Sous-domaine** : Laissez vide (ou mettez `@`)
   - **Valeur** : `v=spf1 include:resend.com ~all`
   - Cliquez sur **"Suivant"** puis **"Valider"**

4. **Ajouter l'enregistrement DKIM (CNAME)**
   - Cliquez sur **"Ajouter une entrée"**
   - Sélectionnez **"CNAME"**
   - **Sous-domaine** : `resend._domainkey`
   - **Cible** : `resend._domainkey.resend.com`
   - Cliquez sur **"Suivant"** puis **"Valider"**

5. **Ajouter l'enregistrement MX (optionnel)**
   - Cliquez sur **"Ajouter une entrée"**
   - Sélectionnez **"MX"**
   - **Sous-domaine** : Laissez vide
   - **Cible** : `feedback-smtp.resend.com`
   - **Priorité** : `10`
   - Cliquez sur **"Suivant"** puis **"Valider"**

**Note OVH :** Les modifications DNS peuvent prendre 4-24 heures.

---

#### Configuration chez Namecheap

1. **Connexion**
   - Allez sur https://namecheap.com
   - Connectez-vous

2. **Accéder aux DNS**
   - **"Domain List"**
   - Cliquez sur **"Manage"** à côté de votre domaine
   - Onglet **"Advanced DNS"**

3. **Ajouter les enregistrements**
   - Suivez le même processus que GoDaddy
   - Les champs sont identiques

---

#### Configuration chez Cloudflare

1. **Connexion**
   - Allez sur https://cloudflare.com
   - Connectez-vous

2. **Sélectionner le domaine**
   - Cliquez sur votre domaine dans la liste

3. **Accéder aux DNS**
   - Menu **"DNS"** sur le côté

4. **Ajouter les enregistrements**
   - Cliquez sur **"Add record"**
   - Suivez le même processus que les autres

**Astuce Cloudflare :** Désactivez le proxy (nuage orange) pour les enregistrements CNAME et MX (cliquez sur le nuage pour qu'il devienne gris).

---

### Étape 4 : Vérifier le domaine sur Resend

Une fois les DNS ajoutés chez votre hébergeur :

#### 4.1 - Attendre la propagation DNS

- **Minimum** : 5 minutes
- **Maximum** : 48 heures (rare)
- **Généralement** : 30 minutes à 2 heures

#### 4.2 - Vérifier sur Resend

1. Retournez sur https://resend.com
2. Menu **"Domains"**
3. Trouvez votre domaine
4. Cliquez sur **"Verify"** ou **"Check DNS"**

**Résultats possibles :**

```
✓ SPF Record Found
✓ DKIM Record Found
✓ Domain Verified
```

Ou :

```
✗ SPF Record Not Found
✗ DKIM Record Not Found
? Verification Pending
```

Si les enregistrements ne sont pas trouvés :
- Attendez encore 15-30 minutes
- Vérifiez que vous avez bien ajouté les enregistrements
- Vérifiez qu'il n'y a pas de typo dans les valeurs

#### 4.3 - Statut vérifié

Quand le domaine est vérifié, vous verrez :

```
┌────────────────────────────────────┐
│  monsite.com              ✓        │
│  Verified                          │
│  Created: Oct 19, 2024             │
└────────────────────────────────────┘
```

---

### Étape 5 : Modifier le code

Une fois le domaine vérifié, modifiez `src/lib/mail.ts` :

**Changez :**
```typescript
from: 'onboarding@resend.dev'
```

**En :**
```typescript
from: 'noreply@monsite.com'
```

Ou n'importe quelle adresse sur votre domaine :
- `hello@monsite.com`
- `support@monsite.com`
- `contact@monsite.com`
- etc.

**Code complet :**
```typescript
export async function sendVerificationEmail(email: string, token: string) {
    const link = `${baseUrl}/verify-email?token=${token}`;

    return resend.emails.send({
        from: 'noreply@monsite.com',  // ← Votre domaine
        to: email,
        subject: 'Verify your email address',
        html: `
            <h1>Verify your email address</h1>
            <p>Click the link below to verify your email address</p>
            <a href="${link}">Verify email</a>
        `
    })
}

export async function sendPasswordResetEmail(email: string, token: string) {
    const link = `${baseUrl}/reset-password?token=${token}`;

    return resend.emails.send({
        from: 'noreply@monsite.com',  // ← Votre domaine
        to: email,
        subject: 'Reset your password',
        html: `
            <h1>You have requested to reset your password</h1>
            <p>Click the link below to reset password</p>
            <a href="${link}">Reset password</a>
        `
    })
}
```

### Étape 6 : Redémarrer et tester

```powershell
# Arrêter le serveur (Ctrl + C)
npm run dev
```

Créez un nouveau compte et vérifiez que l'email arrive maintenant de votre domaine !

---

## Vérifications et Tests

### Vérifier que la clé API est chargée

Dans PowerShell :

```powershell
# Voir si la variable existe dans .env
Get-Content .env | Select-String "RESEND"
```

**Résultat attendu :**
```
RESEND_API_KEY="re_DETBnxkU_8sAQhkqS1rvCjASZjpWB3AKL"
```

### Vérifier les logs du serveur

Quand vous créez un compte, regardez dans le terminal où tourne `npm run dev`.

**Si l'email est envoyé avec succès :**
```
Email sent successfully to: user@example.com
```

**Si erreur :**
```
Error sending email: Missing API key
```
Ou :
```
Error sending email: Domain not verified
```

### Tester l'envoi d'email de vérification

1. Allez sur http://localhost:3000/register
2. Créez un compte avec un **nouvel email**
3. Complétez l'inscription
4. Vérifiez votre boîte email (inbox et spam)
5. L'email devrait arriver en 1-2 minutes

### Tester l'envoi d'email de reset password

1. Allez sur http://localhost:3000/login
2. Cliquez sur **"Forgot password"**
3. Entrez votre email
4. Cliquez sur **"Send reset link"**
5. Vérifiez votre boîte email

### Vérifier dans Resend Dashboard

1. Allez sur https://resend.com
2. Menu **"Emails"**
3. Vous voyez l'historique :

```
┌────────────────────────────────────────────────────────────┐
│  Date         To                Subject            Status   │
├────────────────────────────────────────────────────────────┤
│  Oct 19 10:30 user@test.com     Verify your...    Delivered│
│  Oct 19 10:25 other@test.com    Verify your...    Delivered│
└────────────────────────────────────────────────────────────┘
```

### Cliquer sur un email pour voir les détails

- **To** : Destinataire
- **From** : Expéditeur
- **Subject** : Sujet
- **Status** : Statut (Delivered, Failed, etc.)
- **Events** : Timeline de l'envoi
- **Content** : Aperçu du HTML

---

## Problèmes Courants

### Problème 1 : "Missing API key"

**Erreur dans les logs :**
```
Error sending email: Missing API key
```

**Causes :**
1. La clé n'est pas dans `.env`
2. La clé est vide : `RESEND_API_KEY=""`
3. Le serveur n'a pas été redémarré après l'ajout

**Solution :**
1. Vérifiez `.env` : `Get-Content .env | Select-String "RESEND"`
2. Ajoutez la clé si manquante
3. Redémarrez : `Ctrl + C` puis `npm run dev`

---

### Problème 2 : "Domain not verified"

**Erreur dans les logs :**
```
Error sending email: Domain not verified
```

**Cause :**
Vous essayez d'envoyer depuis un domaine non configuré dans Resend.

**Solution :**
- **Option A :** Utilisez `onboarding@resend.dev` (domaine par défaut)
- **Option B :** Configurez votre domaine (voir section Configuration d'un Domaine Personnalisé)

---

### Problème 3 : Email arrive dans les spams

**Symptôme :**
L'email est envoyé mais arrive dans le dossier spam.

**Causes :**
1. Domaine par défaut utilisé (`onboarding@resend.dev`)
2. Réputation du domaine faible
3. Contenu suspect (trop de liens, mots-clés spam)

**Solutions :**
1. **Configurez votre propre domaine** avec SPF/DKIM
2. **Demandez aux utilisateurs d'ajouter l'adresse aux contacts**
3. **Amélio rez le contenu** :
   - Ajoutez plus de texte
   - Évitez les MAJUSCULES
   - Limitez les liens
   - Ajoutez un logo ou image

---

### Problème 4 : Email n'arrive jamais

**Symptôme :**
Statut "Delivered" sur Resend mais aucun email reçu.

**Causes :**
1. Email bloqué par le serveur de réception
2. Adresse email invalide
3. Boîte pleine

**Solutions :**
1. Vérifiez les spams
2. Vérifiez l'adresse email
3. Essayez avec un autre email (Gmail, Outlook)
4. Vérifiez le statut sur Resend Dashboard

---

### Problème 5 : "Rate limit exceeded"

**Erreur :**
```
Error: Rate limit exceeded (100 emails per day)
```

**Cause :**
Vous avez atteint la limite du plan gratuit (100 emails/jour).

**Solutions :**
- **Attendre 24h** pour que le quota se réinitialise
- **Upgrader vers un plan payant** sur Resend
- **Utiliser plusieurs comptes** (pour dev seulement)

---

### Problème 6 : DNS ne se propage pas

**Symptôme :**
Après ajout des DNS, Resend dit toujours "Not verified".

**Causes :**
1. Les DNS ne sont pas encore propagés (prend du temps)
2. Erreur dans les valeurs entrées
3. Mauvais type d'enregistrement

**Solutions :**
1. **Attendre** : 30 minutes à 2 heures généralement
2. **Vérifier les DNS avec un outil** :
   - https://mxtoolbox.com/SuperTool.aspx
   - Entrez : `resend._domainkey.votredomaine.com`
   - Vérifiez que ça pointe vers `resend._domainkey.resend.com`
3. **Vérifier les valeurs** : Pas de typo, pas d'espace
4. **Recontacter l'hébergeur** si ça ne fonctionne toujours pas après 24h

---

## Alternative Sans Email

Si vous ne voulez pas configurer Resend pour le moment, vous pouvez vérifier les emails manuellement.

### Méthode : Utiliser Prisma Studio

#### Étape 1 : Ouvrir Prisma Studio

```powershell
npx prisma studio
```

Cela ouvre une interface sur http://localhost:5555

#### Étape 2 : Modifier l'utilisateur

1. Cliquez sur la table **"User"** dans la sidebar
2. Trouvez votre utilisateur (cherchez par email)
3. Cliquez sur la ligne de l'utilisateur

#### Étape 3 : Vérifier manuellement l'email

1. Trouvez le champ **`emailVerified`**
2. Actuellement il est `null` (non vérifié)
3. Cliquez sur le champ
4. Entrez la date actuelle : `2024-10-19` (format YYYY-MM-DD)
5. Ou cliquez sur l'icône calendrier et sélectionnez aujourd'hui
6. En haut à droite, cliquez sur **"Save 1 change"**

#### Étape 4 : Se connecter

1. Fermez Prisma Studio (Ctrl + C dans le terminal)
2. Allez sur http://localhost:3000/login
3. Connectez-vous avec votre email et mot de passe
4. Ça devrait fonctionner maintenant !

---

## Résumé - Checklist Complète

### Configuration Minimale (Développement)

- [ ] Compte Resend créé sur https://resend.com
- [ ] API Key créée (commence par `re_`)
- [ ] API Key ajoutée dans `.env` : `RESEND_API_KEY="re_..."`
- [ ] Adresse expéditeur changée en `onboarding@resend.dev` dans `src/lib/mail.ts`
- [ ] Application redémarrée avec `npm run dev`
- [ ] Test d'envoi d'email effectué
- [ ] Email reçu (inbox ou spam)

### Configuration Production (Optionnel)

- [ ] Nom de domaine acheté
- [ ] Domaine ajouté sur Resend Dashboard
- [ ] Enregistrements DNS (SPF, DKIM, MX) ajoutés chez l'hébergeur
- [ ] Attente de la propagation DNS (30 min - 2h)
- [ ] Domaine vérifié sur Resend (statut "Verified")
- [ ] Adresse expéditeur changée en `noreply@votredomaine.com`
- [ ] Application redémarrée
- [ ] Test d'envoi effectué

---

## Commandes Utiles

### Vérifier le .env

```powershell
# Voir toutes les variables Resend
Get-Content .env | Select-String "RESEND"

# Voir toutes les variables d'environnement
Get-Content .env
```

### Redémarrer l'application

```powershell
# Arrêter (Ctrl + C)
# Puis redémarrer
npm run dev
```

### Ouvrir Prisma Studio

```powershell
npx prisma studio
```

### Nettoyer le cache Next.js

```powershell
Remove-Item -Recurse -Force .next
npm run dev
```

---

## Ressources

### Documentation Officielle

- **Resend Documentation** : https://resend.com/docs
- **Resend Quick Start** : https://resend.com/docs/quickstart
- **Resend API Reference** : https://resend.com/docs/api-reference

### Outils de Vérification DNS

- **MX Toolbox** : https://mxtoolbox.com
- **DNS Checker** : https://dnschecker.org
- **What's My DNS** : https://whatsmydns.net

### Support

- **Resend Support** : support@resend.com
- **Resend Discord** : https://resend.com/discord

---

## Notes Importantes

### Sécurité

1. **Ne jamais commiter la clé API** dans Git
   - Le `.env` est dans `.gitignore`
   - Ne partagez jamais votre clé publiquement

2. **Révoquer une clé compromise**
   - Allez sur Resend Dashboard → API Keys
   - Cliquez sur "Revoke" pour la clé compromise
   - Créez une nouvelle clé
   - Mettez à jour le `.env`

3. **Utilisez des clés différentes** pour dev/prod
   - Clé de dev dans `.env.local`
   - Clé de prod sur votre serveur

### Limites du Plan Gratuit

- **100 emails par jour**
- **3,000 emails par mois**
- **1 domaine personnalisé**
- **Support communautaire**

Si vous dépassez ces limites, upgrader vers un plan payant (à partir de $20/mois).

### Best Practices

1. **Toujours tester** avant de déployer en production
2. **Monitorer les bounces** (emails rejetés)
3. **Garder le HTML simple** pour éviter les spams
4. **Ajouter un lien de désinscription** si newsletters
5. **Respecter le RGPD** pour les utilisateurs européens

---

**Ce document couvre tous les aspects de la configuration des emails avec Resend !**

