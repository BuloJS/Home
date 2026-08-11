# Home

Page d'accueil qui regroupe mes projets GitHub Pages, derrière une connexion
avec double authentification.

👉 https://bulojs.github.io/Home/

## Ce que ça fait

- **Connexion par e-mail + mot de passe**, avec **2FA TOTP** optionnelle
  (Google Authenticator, 1Password, Aegis…).
- **Session persistante** : une fois connecté sur un PC, tu y restes ; sur un
  autre PC, tu te reconnectes avec les mêmes identifiants.
- **Données synchronisées** dans Supabase, isolées par utilisateur, prêtes à
  être utilisées par les autres projets.
- Les carrés peuvent venir de la base plutôt que du code, pour ne pas exposer
  la liste des liens publiquement.

## Protéger les 3 autres sites

Les quatre sites sont servis par **la même origine** (`bulojs.github.io`), donc
ils partagent le même `localStorage` : la session ouverte sur Home est
directement visible par Series, Finance et Simu-SCI. **Aucune seconde
connexion n'est nécessaire.**

Dans chacun des trois repos :

1. Copie `assets/guard.js`, `assets/auth.js` et `assets/config.js` depuis ce
   repo, dans un dossier `assets/`.
2. Ajoute ces deux lignes tout en haut du `<head>` de la page, avant le reste :

```html
<script>document.documentElement.style.visibility = "hidden";</script>
<script type="module" src="assets/guard.js"></script>
```

C'est tout. Le comportement obtenu :

| Situation | Résultat |
|---|---|
| Accès direct à `/Series/` sans session | renvoi vers Home, puis retour automatique sur `/Series/` après connexion |
| Accès depuis Home, session ouverte | la page s'affiche, sans rien redemander |
| 2FA activée mais code non saisi | renvoi vers Home pour saisir le code |
| Réseau coupé / Supabase injoignable | accès refusé avec la raison affichée |

[`exemple-page-protegee.html`](exemple-page-protegee.html) est un modèle
complet et fonctionnel à recopier.

## Ce que ça ne fait pas

La garde ci-dessus empêche l'accès direct **dans un navigateur**, ce qui
couvre l'usage normal. Mais un site statique reste un ensemble de fichiers
publics : quelqu'un qui saurait les demander à la main (`curl`, cache de
GitHub, code source du repo) obtiendrait le HTML sans passer par la
connexion. La garde n'est pas contournable par accident, elle l'est par
quelqu'un de déterminé.

Pour qu'un contenu soit réellement inaccessible, il doit être **stocké dans
Supabase** plutôt qu'écrit en dur dans les fichiers : c'est alors la Row Level
Security de la base qui refuse de le servir à un visiteur non connecté, et là
il n'y a rien à contourner. C'est le chemin à prendre si les données de
Finance, par exemple, sont sensibles.

## Mise en route

### 1. Créer le projet Supabase

1. Crée un compte sur [supabase.com](https://supabase.com) et un nouveau projet
   (le plan gratuit suffit largement).
2. **Settings → API** : copie l'`URL` du projet et la clé `anon public`.
3. Colle-les dans [`assets/config.js`](assets/config.js).

Ces deux valeurs sont publiques par conception — la clé `anon` ne donne aucun
droit à elle seule. En revanche, **ne mets jamais** la clé `service_role` ni un
token GitHub dans ce repo : tout y est lisible par n'importe qui.

### 2. Créer la table

Dans Supabase → **SQL Editor → New query**, colle le contenu de
[`supabase/schema.sql`](supabase/schema.sql) et exécute-le. Ça crée la table
`user_data` et les règles d'isolation par utilisateur.

### 3. Créer ton compte

Ouvre le site, saisis ton e-mail et un mot de passe, puis **Créer le compte**.
Si Supabase demande une confirmation par e-mail (Authentication → Providers →
Email), valide le lien reçu avant de te connecter. Tu peux aussi désactiver
cette confirmation le temps du premier test.

### 4. Activer la 2FA

Une fois connecté, clique sur **Activer la 2FA** en bas de page, scanne le QR
code et saisis le code à 6 chiffres. À la prochaine connexion, le code sera
demandé après le mot de passe.

Pour aller plus loin, le bas de `supabase/schema.sql` contient des règles
optionnelles qui **exigent la 2FA au niveau de la base** : même quelqu'un
possédant ton mot de passe ne pourrait rien lire. À n'activer qu'une fois la
2FA en place, sous peine de te bloquer toi-même.

## Personnaliser les carrés

Par défaut, la liste est celle de `DEFAULT_SITES`, en bas de `index.html` :

```js
{ name: "MonProjet", url: "https://bulojs.github.io/MonProjet/", emoji: "🚀",
  desc: "Petite description", tint: ["#0a84ff", "#5e5ce6"] }
```

- `name` : le texte affiché — `url` : le lien
- `emoji` : l'icône de la pastille — `desc` : la ligne sous le nom
- `tint` : les deux couleurs du dégradé de la pastille

Pour que la liste ne soit **pas** publique, enregistre-la plutôt dans Supabase :
table `user_data`, `app` = `home`, `data` = `{ "sites": [ … ] }`. Si cette ligne
existe, elle remplace la liste du code.

## Réutiliser dans un autre projet

Copie `assets/auth.js` et `assets/config.js` dans le repo concerné :

```js
import { requireSession, loadData, saveData } from "./assets/auth.js";

await requireSession();                       // renvoie vers Home si non connecté
const data = await loadData("series");        // lit tes données
await saveData("series", { classement: [] }); // les enregistre
```

`assets/app.css` peut aussi être repris tel quel pour garder la même identité
visuelle.

## Activer GitHub Pages

Settings → Pages → Source `Deploy from a branch`, branche `main`, dossier
`/ (root)`.

## Dépendance externe

Le SDK Supabase est chargé depuis jsDelivr au moment de la connexion. Si le
CDN est injoignable, la page affiche l'erreur au lieu de rester bloquée.
