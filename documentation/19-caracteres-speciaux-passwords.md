# Gestion des Caractères Spéciaux dans les Mots de Passe

Ce document explique comment gérer les caractères spéciaux dans les mots de passe de base de données et les encoder correctement pour les URLs de connexion.

---

## Table des Matières

1. [Le Problème](#le-problème)
2. [Comprendre l'Encodage URL](#comprendre-lencodage-url)
3. [Table de Conversion Complète](#table-de-conversion-complète)
4. [Exemples Pratiques](#exemples-pratiques)
5. [Méthodes d'Encodage](#méthodes-dencodage)
6. [Erreurs Courantes](#erreurs-courantes)
7. [Meilleures Pratiques](#meilleures-pratiques)
8. [Solutions Automatiques](#solutions-automatiques)

---

## Le Problème

### Symptômes

Quand vous utilisez un mot de passe avec des caractères spéciaux dans une URL de connexion :

```
Error: Can't reach database server
Error: Tenant or user not found
Error: Authentication failed
```

### Exemple du Problème

**Mot de passe :** `@7V@_np_+BHtKP@`

**URL INCORRECTE (ne fonctionne pas) :**
```
postgresql://postgres:@7V@_np_+BHtKP@@host.com:5432/db
```

**Problème :** Le serveur interprète mal les caractères `@` et `+`.

**URL CORRECTE (fonctionne) :**
```
postgresql://postgres:%407V%40_np_%2BBHtKP%40@host.com:5432/db
```

---

## Comprendre l'Encodage URL

### Qu'est-ce que l'Encodage URL ?

L'encodage URL (aussi appelé "percent encoding") remplace les caractères spéciaux par leur code en hexadécimal précédé de `%`.

### Format Général

```
%XX
```

- `%` : Préfixe obligatoire
- `XX` : Code hexadécimal du caractère (2 chiffres)

### Pourquoi C'est Nécessaire ?

Certains caractères ont une **signification spéciale** dans les URLs :

**Structure d'une URL :**
```
protocol://username:password@hostname:port/database?params
         ↑        ↑        ↑        ↑    ↑        ↑
      signaux de séparation
```

**Si votre mot de passe contient `@` ou `:` :**
```
postgresql://user:pass@word@host.com
                     ↑     ↑
              Où est la séparation ?
```

Le serveur ne peut pas savoir où le mot de passe se termine.

---

## Table de Conversion Complète

### Caractères Spéciaux Courants

| Caractère | Description | Code ASCII | Encodé URL | Fréquence |
|-----------|-------------|------------|------------|-----------|
| ` ` | Espace | 32 | `%20` | Très fréquent |
| `!` | Exclamation | 33 | `%21` | Fréquent |
| `"` | Guillemet double | 34 | `%22` | Moyen |
| `#` | Dièse/Hash | 35 | `%23` | Fréquent |
| `$` | Dollar | 36 | `%24` | Moyen |
| `%` | Pourcent | 37 | `%25` | Rare |
| `&` | Esperluette | 38 | `%26` | Fréquent |
| `'` | Apostrophe | 39 | `%27` | Moyen |
| `(` | Parenthèse ouvrante | 40 | `%28` | Rare |
| `)` | Parenthèse fermante | 41 | `%29` | Rare |
| `*` | Astérisque | 42 | `%2A` | Moyen |
| `+` | Plus | 43 | `%2B` | Très fréquent |
| `,` | Virgule | 44 | `%2C` | Rare |
| `/` | Slash | 47 | `%2F` | Fréquent |
| `:` | Deux-points | 58 | `%3A` | Très fréquent |
| `;` | Point-virgule | 59 | `%3B` | Rare |
| `<` | Inférieur | 60 | `%3C` | Rare |
| `=` | Égal | 61 | `%3D` | Fréquent |
| `>` | Supérieur | 62 | `%3E` | Rare |
| `?` | Point d'interrogation | 63 | `%3F` | Fréquent |
| `@` | Arobase | 64 | `%40` | Très fréquent |
| `[` | Crochet ouvrant | 91 | `%5B` | Rare |
| `\` | Backslash | 92 | `%5C` | Rare |
| `]` | Crochet fermant | 93 | `%5D` | Rare |
| `^` | Accent circonflexe | 94 | `%5E` | Rare |
| `` ` `` | Backtick | 96 | `%60` | Rare |
| `{` | Accolade ouvrante | 123 | `%7B` | Rare |
| `|` | Pipe | 124 | `%7C` | Rare |
| `}` | Accolade fermante | 125 | `%7D` | Rare |
| `~` | Tilde | 126 | `%7E` | Rare |

---

### Caractères QUI N'ONT PAS BESOIN d'Encodage

| Caractère | Description | Sûr ? |
|-----------|-------------|-------|
| `A-Z` | Lettres majuscules | Oui |
| `a-z` | Lettres minuscules | Oui |
| `0-9` | Chiffres | Oui |
| `-` | Tiret | Oui |
| `_` | Underscore | Oui |
| `.` | Point | Oui |

---

## Exemples Pratiques

### Exemple 1 : Votre Cas Réel

**Mot de passe original :**
```
@7V@_np_+BHtKP@
```

**Analyse caractère par caractère :**
```
@ → %40   (arobase - code 64)
7 → 7     (chiffre - OK)
V → V     (lettre - OK)
@ → %40   (arobase - code 64)
_ → _     (underscore - OK)
n → n     (lettre - OK)
p → p     (lettre - OK)
_ → _     (underscore - OK)
+ → %2B   (plus - code 43)
B → B     (lettre - OK)
H → H     (lettre - OK)
t → t     (lettre - OK)
K → K     (lettre - OK)
P → P     (lettre - OK)
@ → %40   (arobase - code 64)
```

**Mot de passe encodé :**
```
%407V%40_np_%2BBHtKP%40
```

**URL complète :**
```
postgresql://postgres.project:%407V%40_np_%2BBHtKP%40@host.com:5432/db
```

---

### Exemple 2 : Password avec Plusieurs Caractères Spéciaux

**Mot de passe :**
```
My+Pass@2024!
```

**Encodage :**
```
M → M
y → y
+ → %2B
P → P
a → a
s → s
s → s
@ → %40
2 → 2
0 → 0
2 → 2
4 → 4
! → %21
```

**Résultat :**
```
My%2BPass%402024%21
```

**URL :**
```
postgresql://user:My%2BPass%402024%21@host:5432/db
```

---

### Exemple 3 : Password avec Espace

**Mot de passe :**
```
Hello World 123
```

**Encodage :**
```
Hello → Hello
(espace) → %20
World → World
(espace) → %20
123 → 123
```

**Résultat :**
```
Hello%20World%20123
```

**URL :**
```
postgresql://user:Hello%20World%20123@host:5432/db
```

---

### Exemple 4 : Password avec Slash

**Mot de passe :**
```
Admin/2024
```

**Encodage :**
```
Admin → Admin
/ → %2F
2024 → 2024
```

**Résultat :**
```
Admin%2F2024
```

---

## Méthodes d'Encodage

### Méthode 1 : En Ligne (Recommandé pour Débutants)

**Site :** https://www.urlencoder.org/

**Étapes :**
1. Allez sur le site
2. Collez votre mot de passe dans la zone de texte
3. Cliquez sur **"Encode"**
4. Copiez le résultat
5. Utilisez-le dans votre URL

**Avantages :**
- Très simple
- Visuel
- Pas d'installation

**Inconvénient :**
- Vous envoyez votre mot de passe sur internet (utilisez HTTPS)

---

### Méthode 2 : PowerShell (Recommandé pour Sécurité)

**Commande :**
```powershell
Add-Type -AssemblyName System.Web
[System.Web.HttpUtility]::UrlEncode("VOTRE_MOT_DE_PASSE")
```

**Exemple avec votre mot de passe :**
```powershell
Add-Type -AssemblyName System.Web
[System.Web.HttpUtility]::UrlEncode("@7V@_np_+BHtKP@")
```

**Résultat :**
```
%407V%40_np_%2bBHtKP%40
```

**Note :** PowerShell peut encoder `+` en `%2b` (minuscule) au lieu de `%2B` (majuscule). Les deux fonctionnent.

**Avantages :**
- Local (sécurisé)
- Rapide
- Fiable

---

### Méthode 3 : Node.js (Pour Développeurs)

**Commande :**
```powershell
node -e "console.log(encodeURIComponent('VOTRE_MOT_DE_PASSE'))"
```

**Exemple :**
```powershell
node -e "console.log(encodeURIComponent('@7V@_np_+BHtKP@'))"
```

**Résultat :**
```
%407V%40_np_%2BBHtKP%40
```

**Avantages :**
- Très précis
- Standard JavaScript
- Utilisable dans scripts

---

### Méthode 4 : Python (Si Installé)

**Commande :**
```python
python -c "import urllib.parse; print(urllib.parse.quote('@7V@_np_+BHtKP@'))"
```

**Résultat :**
```
%407V%40_np_%2BBHtKP%40
```

---

### Méthode 5 : Manuelle (Si Pas d'Outils)

**Référez-vous à la table de conversion :**

1. Écrivez votre mot de passe
2. Pour chaque caractère spécial, cherchez dans la table
3. Remplacez par le code `%XX`

**Exemple :**
```
Original : @7V@_np_+BHtKP@
Étape 1  : %407V@_np_+BHtKP@    (premier @)
Étape 2  : %407V%40_np_+BHtKP@  (deuxième @)
Étape 3  : %407V%40_np_%2BBHtKP@ (le +)
Étape 4  : %407V%40_np_%2BBHtKP%40 (dernier @)
```

---

## Erreurs Courantes

### Erreur 1 : Oublier d'Encoder

**Symptôme :**
```
Error: Can't parse connection string
```

**Cause :**
Vous avez mis le mot de passe tel quel sans encodage.

**Solution :**
Encodez le mot de passe avant de le mettre dans l'URL.

---

### Erreur 2 : Encoder Tout l'URL

**INCORRECT :**
```
DATABASE_URL="%70%6F%73%74%67%72%65%73%71%6C%3A%2F%2F..."
```

**CORRECT :**
```
DATABASE_URL="postgresql://user:PASSWORD_ENCODÉ@host:5432/db"
```

**Important :** Encodez SEULEMENT le mot de passe, pas toute l'URL !

---

### Erreur 3 : Encoder Deux Fois

**Mot de passe :** `Pass@123`

**Encodage correct :** `Pass%40123`

**INCORRECT (double encodage) :** `Pass%2540123`
- `%40` encodé devient `%2540` (le `%` est encodé)

**Solution :** Encodez une seule fois.

---

### Erreur 4 : Confondre Majuscules/Minuscules

**Les deux fonctionnent :**
- `%2B` (majuscule)
- `%2b` (minuscule)

**Recommandation :** Utilisez les majuscules (plus standard).

---

### Erreur 5 : Oublier le Pourcentage

**INCORRECT :** `Pass40123` (juste le nombre)

**CORRECT :** `Pass%40123` (avec le `%`)

---

## Meilleures Pratiques

### 1. Créer des Mots de Passe Sans Caractères Spéciaux

**Pour les bases de données, privilégiez :**

**BONS (pas besoin d'encodage) :**
```
MonPassword123
SecureDB2024
MyAppDatabaseKey
ProductionDB456
Secure_Pass_2024
```

**Caractères autorisés sans encodage :**
- Lettres : `A-Z`, `a-z`
- Chiffres : `0-9`
- Tiret : `-`
- Underscore : `_`
- Point : `.`

---

### 2. Éviter Ces Caractères dans les Passwords BDD

**Problématiques (nécessitent encodage) :**
```
@ # $ % & + = / : ; ? ! * ' " ( ) [ ] { } < > | \ ^ ` ~
```

**Particulièrement problématiques :**
- `@` : Sépare credentials de host
- `:` : Sépare username de password
- `/` : Sépare parties de l'URL
- `?` : Démarre les query parameters
- `&` : Sépare les query parameters
- `=` : Sépare clé et valeur dans query params

---

### 3. Workflow Recommandé

**Pour Supabase/Neon/Tout Service Cloud :**

#### Option A : Générer Sans Caractères Spéciaux

1. Cliquez sur "Generate password"
2. Si le password contient `@`, `+`, `#`, etc.
3. **Régénérez** jusqu'à avoir un simple
4. Ou modifiez manuellement (retirez les spéciaux)

#### Option B : Encoder Systématiquement

1. Générez n'importe quel password
2. **Copiez-le immédiatement** dans un fichier texte
3. Encodez-le avec un outil
4. Utilisez la version encodée dans l'URL

---

### 4. Stocker les Deux Versions

**Dans un fichier sécurisé (PAS dans Git) :**

```
SUPABASE PROJECT: nextmatch
Date: 2024-10-19

Password Original: @7V@_np_+BHtKP@
Password Encodé: %407V%40_np_%2BBHtKP%40

DATABASE_URL: postgresql://postgres.id:PASSWORD_ENCODÉ@host:5432/db
```

**Pourquoi stocker les deux ?**
- Original : Pour se reconnecter au dashboard
- Encodé : Pour l'URL de connexion

---

## Solutions Automatiques

### Script PowerShell Réutilisable

Créez un fichier `encode-password.ps1` :

```powershell
# Script pour encoder un mot de passe en URL
param(
    [Parameter(Mandatory=$true)]
    [string]$Password
)

Add-Type -AssemblyName System.Web
$encoded = [System.Web.HttpUtility]::UrlEncode($Password)

Write-Host "Password Original : $Password"
Write-Host "Password Encodé   : $encoded"
Write-Host ""
Write-Host "Utilisez dans votre URL :"
Write-Host "postgresql://user:$encoded@host:5432/db"
```

**Utilisation :**
```powershell
.\encode-password.ps1 -Password "@7V@_np_+BHtKP@"
```

**Résultat :**
```
Password Original : @7V@_np_+BHtKP@
Password Encodé   : %407V%40_np_%2BBHtKP%40

Utilisez dans votre URL :
postgresql://user:%407V%40_np_%2BBHtKP%40@host:5432/db
```

---

### Script Node.js

Créez `encode-password.js` :

```javascript
// Script pour encoder un mot de passe
const password = process.argv[2];

if (!password) {
  console.log('Usage: node encode-password.js "votre_mot_de_passe"');
  process.exit(1);
}

const encoded = encodeURIComponent(password);

console.log('Password Original :', password);
console.log('Password Encodé   :', encoded);
console.log('');
console.log('URL format :');
console.log(`postgresql://user:${encoded}@host:5432/db`);
```

**Utilisation :**
```powershell
node encode-password.js "@7V@_np_+BHtKP@"
```

---

### Extension VS Code

**Extension recommandée :**
"URL Encoder/Decoder"

**Utilisation :**
1. Sélectionnez votre mot de passe
2. Ctrl + Shift + P
3. Tapez "URL Encode"
4. Votre texte est encodé automatiquement

---

## Cas Spéciaux

### Cas 1 : Mot de Passe avec %

**Mot de passe :** `100%Valid`

**Encodage :**
```
100 → 100
% → %25
Valid → Valid
```

**Résultat :** `100%25Valid`

**Important :** Le `%` lui-même doit être encodé en `%25` !

---

### Cas 2 : Mot de Passe Déjà Partiellement Encodé

**Ne double-encodez PAS !**

**Si vous voyez déjà `%XX` dans le mot de passe :**
- C'est déjà encodé
- Ne ré-encodez pas

**Test :**
```
Pass%40word → Déjà encodé (contient %40)
Pass@word   → Pas encodé (contient @ brut)
```

---

### Cas 3 : Caractères Accentués

**Mot de passe :** `Café2024`

**Encodage :**
```
C → C
a → a
f → f
é → %C3%A9 (UTF-8 encoding)
2024 → 2024
```

**Résultat :** `Caf%C3%A92024`

**Recommandation :** Évitez les accents dans les passwords BDD.

---

## Vérification

### Comment Vérifier que Votre Encodage est Correct

**Test 1 : Décoder et Vérifier**

PowerShell :
```powershell
Add-Type -AssemblyName System.Web
[System.Web.HttpUtility]::UrlDecode("%407V%40_np_%2BBHtKP%40")
```

**Résultat attendu :** `@7V@_np_+BHtKP@`

Si vous obtenez votre mot de passe original, l'encodage est correct !

---

**Test 2 : Tester la Connexion**

```powershell
npx prisma db pull
```

Si ça fonctionne, votre URL (et donc l'encodage) est correct.

---

## Format Complet URL de Connexion

### Anatomie d'une URL PostgreSQL

```
postgresql://username:password@hostname:port/database?parameters
│          │        │        │        │    │        │
│          │        │        │        │    │        └─ Query params
│          │        │        │        │    └─ Nom base de données
│          │        │        │        └─ Port (5432, 6543, etc.)
│          │        │        └─ Nom d'hôte
│          │        └─ Mot de passe (DOIT être encodé si spéciaux)
│          └─ Nom d'utilisateur
└─ Protocole
```

### Exemples de Query Parameters Courants

```
?sslmode=require              # SSL obligatoire
&pgbouncer=true               # Utilise pgBouncer
&connection_limit=10          # Limite connexions
&pool_timeout=10              # Timeout pool
&schema=public                # Schéma par défaut
```

**Séparation :**
- Premier paramètre : `?`
- Suivants : `&`

---

## Outils et Ressources

### Outils en Ligne

**Encodeurs URL :**
- https://www.urlencoder.org/ (Simple)
- https://meyerweb.com/eric/tools/dencoder/ (Encode + Decode)
- https://www.freeformatter.com/url-encoder.html (Détaillé)

**Testeurs de Connexion :**
- pgAdmin (GUI PostgreSQL)
- DBeaver (Multi-database)
- Prisma Studio (`npx prisma studio`)

---

### Documentation Officielle

**Encodage URL :**
- RFC 3986 : https://datatracker.ietf.org/doc/html/rfc3986
- MDN Web Docs : https://developer.mozilla.org/en-US/docs/Glossary/percent-encoding

**Connection Strings :**
- PostgreSQL : https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING
- Prisma : https://www.prisma.io/docs/reference/database-reference/connection-urls
- Supabase : https://supabase.com/docs/guides/database/connecting-to-postgres

---

## Quick Reference - Caractères les Plus Courants

**Mémorisez ces 5 :**

```
@ → %40
+ → %2B
# → %23
& → %26
= → %3D
```

**Ces 5 caractères représentent 90% des cas.**

---

## Checklist de Dépannage

### Si Erreur de Connexion

- [ ] Vérifiez que le mot de passe est encodé
- [ ] Vérifiez qu'il n'y a pas de double encodage
- [ ] Testez avec `npx prisma db pull`
- [ ] Vérifiez qu'il n'y a pas d'espace avant/après l'URL
- [ ] Vérifiez que les guillemets sont présents
- [ ] Décodez l'URL encodée pour vérifier qu'elle donne le password original
- [ ] En dernier recours : Générez un nouveau password sans caractères spéciaux

---

## Exemple Complet - Workflow

### Scénario : Nouvelle Base Supabase

**Étape 1 : Création du Projet**
```
Supabase Dashboard → New Project
Database Password → Generate → Copie: P@ss+Word#123
```

**Étape 2 : Identification des Caractères Spéciaux**
```
P → OK
@ → SPÉCIAL (arobase)
s → OK
s → OK
+ → SPÉCIAL (plus)
W → OK
o → OK
r → OK
d → OK
# → SPÉCIAL (dièse)
1 → OK
2 → OK
3 → OK
```

**Étape 3 : Encodage**
```
PowerShell:
Add-Type -AssemblyName System.Web
[System.Web.HttpUtility]::UrlEncode("P@ss+Word#123")

Résultat: P%40ss%2BWord%23123
```

**Étape 4 : Construction URL**
```env
DATABASE_URL="postgresql://postgres.id:P%40ss%2BWord%23123@aws-region.pooler.supabase.com:5432/postgres"
```

**Étape 5 : Test**
```powershell
npx prisma db pull
```

**Étape 6 : Si Succès**
Utilisez cette URL dans votre `.env`

---

## Résumé

**Trois règles d'or :**

1. **Encodez SEULEMENT le mot de passe** (pas toute l'URL)
2. **Encodez AVANT de mettre dans .env** (pas après)
3. **Utilisez un outil** (ne faites pas manuellement si complexe)

**Caractères à toujours encoder :**
- `@` → `%40`
- `+` → `%2B`
- `#` → `%23`
- `&` → `%26`
- `=` → `%3D`
- `:` → `%3A` (si dans le password, rare)

**Meilleur choix :** Créez des passwords **SANS** ces caractères dès le début !

---

**Ce guide vous servira pour tous vos futurs projets avec bases de données cloud.**

