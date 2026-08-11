-- Schéma à exécuter une fois dans Supabase → SQL Editor → New query → Run.
--
-- Une seule table stocke les données de toutes les applis : une ligne par
-- (utilisateur, appli), le contenu étant du JSON libre. Le champ `app` vaut
-- "home", "series", "finance"… selon le projet qui écrit.

create table if not exists public.user_data (
  user_id    uuid        not null references auth.users (id) on delete cascade,
  app        text        not null,
  data       jsonb       not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, app)
);

-- Row Level Security : sans ces règles, la clé anon publique laisserait
-- n'importe qui lire la table. Avec elles, la base elle-même refuse toute
-- ligne qui n'appartient pas à l'appelant — c'est ça qui protège réellement
-- les données, pas le JavaScript de la page.
alter table public.user_data enable row level security;

drop policy if exists "lecture de ses propres donnees"     on public.user_data;
drop policy if exists "insertion de ses propres donnees"   on public.user_data;
drop policy if exists "mise a jour de ses propres donnees" on public.user_data;
drop policy if exists "suppression de ses propres donnees" on public.user_data;

create policy "lecture de ses propres donnees"
  on public.user_data for select
  using (auth.uid() = user_id);

create policy "insertion de ses propres donnees"
  on public.user_data for insert
  with check (auth.uid() = user_id);

create policy "mise a jour de ses propres donnees"
  on public.user_data for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "suppression de ses propres donnees"
  on public.user_data for delete
  using (auth.uid() = user_id);


-- ---------------------------------------------------------------------------
-- OPTIONNEL — exiger la 2FA côté base de données.
--
-- Les règles ci-dessus acceptent une session ouverte au mot de passe seul.
-- Le bloc suivant refuse en plus toute requête dont le jeton n'est pas au
-- niveau "aal2", c'est-à-dire dont la 2FA n'a pas été franchie : même un
-- attaquant qui aurait ton mot de passe ne pourrait rien lire.
--
-- À N'EXÉCUTER QU'APRÈS avoir activé la 2FA depuis la page Home, sinon tu
-- te bloques toi-même l'accès à tes données. Pour revenir en arrière,
-- ré-exécute simplement le bloc de règles du haut.
-- ---------------------------------------------------------------------------

-- drop policy if exists "lecture de ses propres donnees"     on public.user_data;
-- drop policy if exists "insertion de ses propres donnees"   on public.user_data;
-- drop policy if exists "mise a jour de ses propres donnees" on public.user_data;
-- drop policy if exists "suppression de ses propres donnees" on public.user_data;
--
-- create policy "lecture de ses propres donnees"
--   on public.user_data for select
--   using (auth.uid() = user_id and (select auth.jwt() ->> 'aal') = 'aal2');
--
-- create policy "insertion de ses propres donnees"
--   on public.user_data for insert
--   with check (auth.uid() = user_id and (select auth.jwt() ->> 'aal') = 'aal2');
--
-- create policy "mise a jour de ses propres donnees"
--   on public.user_data for update
--   using (auth.uid() = user_id and (select auth.jwt() ->> 'aal') = 'aal2')
--   with check (auth.uid() = user_id and (select auth.jwt() ->> 'aal') = 'aal2');
--
-- create policy "suppression de ses propres donnees"
--   on public.user_data for delete
--   using (auth.uid() = user_id and (select auth.jwt() ->> 'aal') = 'aal2');
