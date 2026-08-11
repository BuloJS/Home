-- =============================================================================
-- Projet Supabase unique — schéma consolidé
--
-- Ce projet (pyduueytagmzsdwtzltu) porte désormais le compte unique et les
-- données des quatre sites : Home, Series, Simu-SCI et Finance.
--
-- À coller dans Supabase → SQL Editor → New query → Run.
-- Rejouable : on peut le relancer sans casser l'existant.
-- =============================================================================


-- --------------------------------------------------------------------- Home --
-- Données libres, une ligne par (utilisateur, application). Sert à Home pour
-- la liste des carrés, et à Finance pour son tableau de bord.

create table if not exists public.user_data (
  user_id    uuid        not null references auth.users (id) on delete cascade,
  app        text        not null,
  data       jsonb       not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, app)
);


-- ------------------------------------------------------------------- Series --
-- Reprise du schéma de Séries.log, à une différence près : la lecture n'est
-- plus publique. Dans le projet d'origine, les profils et les collections
-- étaient lisibles par n'importe qui (`using (true)`) ; ici tout est réservé
-- au propriétaire, conformément à l'objectif d'un accès strictement personnel.

create table if not exists public.profiles (
  id         uuid primary key references auth.users on delete cascade,
  name       text not null unique check (char_length(name) between 2 and 24),
  avatar     text not null default '🍿',
  created_at timestamptz not null default now()
);

create table if not exists public.series (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title      text not null check (char_length(title) between 1 and 200),
  year       int,
  seasons    int,
  episodes   int,
  tvmaze_id  int,
  genres     text[] not null default '{}',
  poster     text,
  status     text not null default 'watched'
             check (status in ('watched', 'watching', 'watchlist')),
  rating     numeric(2,1) check (rating > 0 and rating <= 5),
  priority   int not null default 2 check (priority between 1 and 3),
  review     text,
  favorite   boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists series_profile_idx on public.series (profile_id);

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists series_touch_updated_at on public.series;
create trigger series_touch_updated_at
  before update on public.series
  for each row execute function public.touch_updated_at();


-- ----------------------------------------------------------------- Simu-SCI --
-- Une ligne par utilisateur, contenant tout le patrimoine en JSON.

create table if not exists public.portfolios (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);


-- ------------------------------------------------- Règles d'accès (RLS) ------
-- Sans ces règles, la clé publique du site donnerait accès à toute la base.
-- Avec elles, la base elle-même refuse toute ligne qui n'appartient pas à
-- l'appelant : c'est ça qui protège réellement les données.

alter table public.user_data  enable row level security;
alter table public.profiles   enable row level security;
alter table public.series     enable row level security;
alter table public.portfolios enable row level security;

-- user_data --------------------------------------------------------------
drop policy if exists "user_data_select_own" on public.user_data;
drop policy if exists "user_data_insert_own" on public.user_data;
drop policy if exists "user_data_update_own" on public.user_data;
drop policy if exists "user_data_delete_own" on public.user_data;

create policy "user_data_select_own" on public.user_data
  for select using (auth.uid() = user_id);
create policy "user_data_insert_own" on public.user_data
  for insert with check (auth.uid() = user_id);
create policy "user_data_update_own" on public.user_data
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "user_data_delete_own" on public.user_data
  for delete using (auth.uid() = user_id);

-- profiles ---------------------------------------------------------------
drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_delete_own" on public.profiles;

create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
create policy "profiles_delete_own" on public.profiles
  for delete using (auth.uid() = id);

-- series -----------------------------------------------------------------
drop policy if exists "series_select_own" on public.series;
drop policy if exists "series_insert_own" on public.series;
drop policy if exists "series_update_own" on public.series;
drop policy if exists "series_delete_own" on public.series;

create policy "series_select_own" on public.series
  for select using (auth.uid() = profile_id);
create policy "series_insert_own" on public.series
  for insert with check (auth.uid() = profile_id);
create policy "series_update_own" on public.series
  for update using (auth.uid() = profile_id) with check (auth.uid() = profile_id);
create policy "series_delete_own" on public.series
  for delete using (auth.uid() = profile_id);

-- portfolios -------------------------------------------------------------
drop policy if exists "portfolios_select_own" on public.portfolios;
drop policy if exists "portfolios_insert_own" on public.portfolios;
drop policy if exists "portfolios_update_own" on public.portfolios;
drop policy if exists "portfolios_delete_own" on public.portfolios;

create policy "portfolios_select_own" on public.portfolios
  for select using (auth.uid() = user_id);
create policy "portfolios_insert_own" on public.portfolios
  for insert with check (auth.uid() = user_id);
create policy "portfolios_update_own" on public.portfolios
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "portfolios_delete_own" on public.portfolios
  for delete using (auth.uid() = user_id);


-- ---------------------------------------------------------------------------
-- OPTIONNEL — exiger la 2FA côté base de données.
--
-- Les règles ci-dessus acceptent une session ouverte au mot de passe seul.
-- Ce bloc refuse en plus toute requête dont le jeton n'est pas au niveau
-- « aal2 », c'est-à-dire dont la 2FA n'a pas été franchie : même quelqu'un
-- possédant ton mot de passe ne pourrait rien lire.
--
-- À N'EXÉCUTER QU'APRÈS avoir activé la 2FA et vérifié qu'elle fonctionne,
-- sinon tu te bloques toi-même. Pour revenir en arrière, ré-exécute le bloc
-- de règles ci-dessus.
-- ---------------------------------------------------------------------------

-- create or replace function public.has_required_aal()
-- returns boolean language sql stable security definer
-- set search_path = auth, public as $$
--   select case
--     when exists (select 1 from auth.mfa_factors f
--                  where f.user_id = auth.uid() and f.status = 'verified')
--     then coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
--     else true
--   end;
-- $$;
--
-- create policy "user_data_select_own" on public.user_data
--   for select using (auth.uid() = user_id and public.has_required_aal());
-- (et de même pour profiles, series et portfolios)
