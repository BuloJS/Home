// Configuration Supabase.
//
// Ces deux valeurs sont PUBLIQUES par conception : la clé "anon" ne donne
// aucun droit par elle-même, c'est la Row Level Security (voir
// supabase/schema.sql) qui décide de ce que chaque utilisateur peut lire.
// Ne mets JAMAIS ici la clé "service_role" ni un token GitHub : ce fichier
// est servi tel quel à tous les visiteurs.
//
// Où les trouver : Supabase → ton projet → Settings → API.

export const SUPABASE_URL = "https://TON-PROJET.supabase.co";
export const SUPABASE_ANON_KEY = "TA_CLE_ANON";
