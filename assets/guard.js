// Garde d'accès à déposer sur Series, Finance et Simu-SCI.
//
// Principe : les quatre sites sont servis par la même origine
// (https://bulojs.github.io), donc ils partagent le même localStorage. La
// session ouverte sur Home est visible ici sans nouvelle connexion. Si elle
// manque, le visiteur est renvoyé vers Home, qui le ramènera une fois
// connecté.
//
// Installation — dans le <head> de la page à protéger, avant tout le reste :
//
//   <script>document.documentElement.style.visibility = "hidden";</script>
//   <script type="module" src="assets/guard.js"></script>
//
// La première ligne masque la page tant que la session n'est pas vérifiée ;
// la garde la réaffiche elle-même. Copie aussi auth.js et config.js dans le
// même dossier.
//
// LIMITE À CONNAÎTRE : un site statique reste téléchargeable. Cette garde
// empêche l'accès direct par l'URL dans un navigateur, pas quelqu'un qui
// irait chercher les fichiers à la main. Pour un contenu réellement privé,
// il faut le stocker dans Supabase, où la RLS le refuse aux non-connectés.

import { getSession, getAssuranceLevel, needsMfaChallenge } from "./auth.js";
import { HOME_PATH } from "./config.js";

const BOUNCE_KEY = "guard:bounces";
const MAX_BOUNCES = 3;

function reveal() {
  document.documentElement.style.visibility = "";
  sessionStorage.removeItem(BOUNCE_KEY);
}

/** Affiche un message plein écran plutôt que de boucler indéfiniment. */
function stop(text) {
  document.documentElement.style.visibility = "";
  document.body.innerHTML = "";
  const p = document.createElement("p");
  p.style.cssText =
    "max-width:34rem;margin:22vh auto;padding:0 1.5rem;text-align:center;" +
    "font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;" +
    "font-size:1rem;line-height:1.5;color:#aeb0b6";
  p.textContent = text;
  document.body.appendChild(p);
}

function redirectToHome() {
  // Compteur anti-aller-retour : si Home nous renvoie ici alors que la
  // session est toujours refusée, on s'arrête au lieu de boucler.
  const bounces = Number(sessionStorage.getItem(BOUNCE_KEY) || 0) + 1;
  if (bounces > MAX_BOUNCES) {
    sessionStorage.removeItem(BOUNCE_KEY);
    stop("Connexion impossible. Ouvre la page d'accueil pour te connecter, puis reviens.");
    return;
  }
  sessionStorage.setItem(BOUNCE_KEY, String(bounces));

  const next = window.location.pathname + window.location.search + window.location.hash;
  window.location.replace(`${HOME_PATH}?next=${encodeURIComponent(next)}`);
}

try {
  const session = await getSession();
  if (!session || needsMfaChallenge(await getAssuranceLevel())) {
    redirectToHome();
  } else {
    reveal();
  }
} catch (error) {
  // Réseau coupé, CDN injoignable, projet en pause : on refuse l'accès
  // plutôt que d'afficher le contenu par accident.
  stop(`Vérification de la session impossible : ${error.message}`);
}
