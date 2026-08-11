# Home

Page vitrine qui regroupe mes projets GitHub Pages sous forme de carrés cliquables.

👉 https://bulojs.github.io/Home/

## Activer GitHub Pages

Dans **Settings → Pages** du repo :

- **Source** : `Deploy from a branch`
- **Branch** : `main` / `/ (root)`

## Ajouter ou retirer un carré

Tout se passe dans la liste `SITES` en bas de `index.html` :

```js
const SITES = [
  { name: "MonProjet", url: "https://bulojs.github.io/MonProjet/", emoji: "🚀", desc: "Petite description" },
];
```

- `name` : le texte affiché sur le carré
- `url` : le lien
- `emoji` et `desc` : optionnels
