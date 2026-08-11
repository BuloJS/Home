# Transvaser les données vers le projet unique

Tout converge vers le projet de Home, `pyduueytagmzsdwtzltu`. Les données
restées dans les anciens projets doivent être recopiées : un projet Supabase
ne peut pas lire la base d'un autre.

**À exécuter par toi** — ces manipulations demandent d'être connecté à tes deux
projets dans le tableau de bord Supabase.

Tout se fait dans **SQL Editor**, sans export de fichier : on fait produire du
JSON par l'ancien projet, on le colle dans le nouveau.

> **Les blocs à coller sont délimités par `$json$`, pas par des apostrophes.**
> C'est volontaire : un titre comme `Tom Clancy's Jack Ryan` contient une
> apostrophe, qui refermerait une chaîne SQL classique en plein milieu et
> ferait échouer la requête. La notation `$json$ … $json$` de PostgreSQL n'a
> pas ce défaut — le contenu est pris tel quel, apostrophes comprises. Ne
> remplace donc pas ces `$json$` par des `'`.

---

## Étape 0 — préparer le projet d'arrivée

1. Dans le **nouveau** projet, exécute [`schema.sql`](schema.sql).
2. Récupère l'identifiant de ton compte, il servira partout ensuite :

```sql
select id, email from auth.users;
```

Note la valeur de `id` (de la forme `3f6c…`). Elle est appelée `<TON_UID>`
dans la suite.

3. Crée ton profil Series dans le nouveau projet :

```sql
insert into public.profiles (id, name, avatar)
values ('<TON_UID>', 'Bulo', '🍿')
on conflict (id) do nothing;
```

---

## Étape 1 — Series (`aozedjtxlpnaznytdwav`)

**Dans l'ANCIEN projet**, récupère toute la collection en une seule valeur :

```sql
select coalesce(jsonb_agg(to_jsonb(s) - 'id' - 'profile_id'), '[]'::jsonb)
from public.series s;
```

Copie le résultat (le gros bloc `[...]`).

**Dans le NOUVEAU projet**, colle-le à la place de `<COLLER_ICI>` :

```sql
insert into public.series (
  profile_id, title, year, seasons, episodes, tvmaze_id, genres, poster,
  status, rating, priority, review, favorite, created_at, updated_at
)
select
  '<TON_UID>', x.title, x.year, x.seasons, x.episodes, x.tvmaze_id, x.genres,
  x.poster, x.status, x.rating, x.priority, x.review, x.favorite,
  x.created_at, x.updated_at
from jsonb_populate_recordset(null::public.series, $json$<COLLER_ICI>$json$::jsonb) x;
```

Les identifiants d'origine sont volontairement écartés : de nouveaux sont
générés, et tout est rattaché à ton compte du nouveau projet.

Vérifie :

```sql
select count(*) from public.series;
```

Si un essai précédent a laissé des lignes incomplètes, vide la table dans le
**nouveau** projet avant de relancer l'import — l'ancien projet n'est pas
touché :

```sql
delete from public.series;
```

---

## Étape 2 — Simu-SCI (`auxgbubbtfvriysagnwr`)

Une seule ligne à déplacer.

**Dans l'ANCIEN projet** :

```sql
select data from public.portfolios;
```

**Dans le NOUVEAU projet** :

```sql
insert into public.portfolios (user_id, data)
values ('<TON_UID>', $json$<COLLER_ICI>$json$::jsonb)
on conflict (user_id) do update set data = excluded.data, updated_at = now();
```

---

## Étape 3 — Finance

Finance ne stocke rien dans Supabase aujourd'hui : ses données sont dans le
`localStorage` de ton navigateur, donc **uniquement sur le PC où tu les as
saisies**. Il n'y a rien à transvaser depuis un serveur — il faut les remonter
depuis le navigateur.

Sur le PC qui contient les données, ouvre le site Finance, puis la console
(F12) et exécute :

```js
copy(localStorage.getItem('compta.epargne.v1'));
```

> Cette commande extrait **uniquement** le tableau. Une version précédente de
> ce guide recopiait tout le `localStorage`, ce qui produisait une enveloppe
> `{"compta.epargne.v1": "{…}"}` que l'application ne reconnaissait pas :
> elle repartait alors sur un tableau vide. Le code sait désormais déballer
> cette enveloppe, mais autant enregistrer directement la bonne forme.

Le contenu est copié dans le presse-papier. Colle-le dans le nouveau projet :

```sql
insert into public.user_data (user_id, app, data)
values ('<TON_UID>', 'finance', $json$<COLLER_ICI>$json$::jsonb)
on conflict (user_id, app) do update set data = excluded.data, updated_at = now();
```

Finance relit désormais ces données depuis Supabase et les y réenregistre :
elles te suivent d'un PC à l'autre.

Si tu as utilisé l'ancienne commande et que ta ligne contient l'enveloppe,
tu peux la remettre à plat — facultatif, le code sait la lire :

```sql
update public.user_data
set data = (data ->> 'compta.epargne.v1')::jsonb
where app = 'finance' and data ? 'compta.epargne.v1';
```

---

## Étape 4 — vérifier avant de supprimer

Ne supprime **rien** dans les anciens projets tant que tu n'as pas confirmé,
sur chaque site, que tes données sont bien là. Les anciens projets ne coûtent
rien tant qu'ils dorment ; garde-les quelques jours en filet de sécurité.

```sql
select
  (select count(*) from public.series)     as series,
  (select count(*) from public.portfolios) as portefeuilles,
  (select count(*) from public.user_data)  as donnees_libres;
```
