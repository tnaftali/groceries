<p align="center">
  <img src="icon-512.png" width="96" alt="Groceries+ icon">
</p>

<h1 align="center">Groceries+</h1>

<p align="center">
  A fast, private grocery list that lives on your phone.<br>
  <a href="https://tnaftali.github.io/groceries/"><strong>Open the app →</strong></a>
</p>

---

Most list apps want an account, a subscription, or a sync server. Groceries+ wants nothing. Open the link, add it to your Home Screen, and it works like a native app: offline, instant, and with your data staying on your device.

Keep one list of everything you buy. Mark what you need, and the list shows only that. At the store, tap an item to take it off the list until next time.

## Features

- **Search or add in one field.** Type to filter. Press Enter to add what isn't there yet.
- **Pending and All views.** See only what you need, or your whole catalog.
- **Categories.** Group items by aisle or store. Collapse the ones you don't need.
- **Two-column layout.** More items on screen, less scrolling in the aisle.
- **Quantities, important items and one-time items.** One-time items disappear once you tap them off the list.
- **Works offline.** A service worker caches the whole app.
- **Private by design.** No account, no server, no tracking. Your list stays in your browser.
- **Export and import.** Back up your list as JSON, or move it to another device.
- **Light and dark themes.** Catppuccin Latte and Macchiato. Follows your system, or pick one in Settings.

## Install on iPhone

1. Open [tnaftali.github.io/groceries](https://tnaftali.github.io/groceries/) in Safari.
2. Tap **Share → Add to Home Screen**.

On Android, open it in Chrome and tap **Add to Home screen** (or **Install app**).

## Develop

Plain HTML, CSS and JavaScript. No build step, no dependencies to install.

```sh
python3 -m http.server 8000   # http://localhost:8000
node --test                   # logic tests
```

GitHub Pages deploys `main` as-is. After changing app files, bump `VERSION` in `sw.js` so installed copies refresh their cache.

## Credits

- UI components: [Basecoat](https://basecoatui.com)
- Colors: [Catppuccin](https://catppuccin.com)
- Icons: [Lucide](https://lucide.dev)
- Cart icon: BUSAIRI, from the Noun Project
