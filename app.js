import { emptyState, visibleItems, groupByCategory, validateName, findByName, toggle, parseBackup } from "./logic.js";

const KEY = "groceries.v1";
const NEW_CATEGORY = "__new";
const $ = (sel) => document.querySelector(sel);

const list = $("#list");
const search = $("#search");
const itemDialog = $("#item-dialog");
const itemForm = $("#item-form");
const categoryDialog = $("#category-dialog");
const categoryForm = $("#category-form");
const settingsDialog = $("#settings-dialog");

let state = load();
let query = "";
let editingItemId = null;
let editingCategoryId = null;

// ---------- Storage ----------

function load() {
  let raw = null;
  try {
    raw = localStorage.getItem(KEY);
  } catch {}
  if (!raw) return emptyState();
  try {
    return parseBackup(raw);
  } catch {
    // Keep the bad copy so nothing is lost, then start clean.
    try {
      localStorage.setItem(`${KEY}.corrupt`, raw);
    } catch {}
    queueMicrotask(() => toast("Saved data was unreadable. Started fresh; the old copy is kept."));
    return emptyState();
  }
}

function save() {
  try {
    localStorage.setItem(KEY, JSON.stringify(state));
    applyScheme(); // global from index.html; picks up theme changes from Settings, import, or clear
  } catch {
    toast("Couldn't save. Export a backup from Settings.");
  }
}

// The only mutation path: change, persist, redraw (animated where supported).
function update(fn) {
  fn(state);
  save();
  animate(render);
}

const reduceMotion = matchMedia("(prefers-reduced-motion: reduce)");
function animate(fn) {
  if (!document.startViewTransition || reduceMotion.matches) return fn();
  // A rapid second change skips the running transition; that rejection is expected.
  document.startViewTransition(fn).ready.catch(() => {});
}

// ---------- DOM helpers ----------

function h(tag, attrs = {}, ...children) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (v === false || v == null) continue;
    if (k === "class") el.className = v;
    else if (k === "style") el.style.cssText = v;
    else if (k in el && typeof v !== "string") el[k] = v;
    else el.setAttribute(k, v === true ? "" : v);
  }
  el.append(...children.flat().filter((c) => c != null && c !== false));
  return el;
}

function icon(name, cls) {
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  const use = document.createElementNS("http://www.w3.org/2000/svg", "use");
  use.setAttribute("href", `#i-${name}`);
  svg.append(use);
  if (cls) svg.setAttribute("class", cls);
  svg.setAttribute("aria-hidden", "true");
  return svg;
}

function toast(message) {
  const el = h("div", { class: "toast", role: "status" }, h("div", { class: "toast-content" }, h("section", {}, h("h2", {}, message))));
  $("#toaster").append(el);
  setTimeout(() => {
    el.setAttribute("aria-hidden", "true");
    setTimeout(() => el.remove(), 400);
  }, 2600);
}

const uid = () => crypto.randomUUID?.() ?? `${Date.now().toString(36)}${Math.random().toString(36).slice(2)}`;

// ---------- Render ----------

function render() {
  for (const b of document.querySelectorAll("[data-filter]")) {
    b.setAttribute("aria-pressed", String((b.dataset.filter === "all") === state.prefs.showAll));
  }

  const searching = query.trim() !== "";
  const groups = groupByCategory(visibleItems(state, query), state.categories);

  if (!groups.length) {
    list.replaceChildren(emptyView(searching));
    return;
  }

  list.replaceChildren(
    ...groups.map(({ category, items }) => {
      const open = searching || (category ? category.open : state.prefs.uncategorizedOpen);
      return h(
        "details",
        { class: category ? "group" : "group uncategorized", open, "data-category": category?.id ?? "" },
        h(
          "summary",
          {},
          h("span", { class: "title" }, category?.name ?? "Uncategorized"),
          h("span", { class: "count" }, String(items.filter((i) => i.needed).length)),
          category && h("button", { class: "btn edit", "data-variant": "ghost", "data-size": "icon-sm", type: "button", "data-edit-category": category.id, "aria-label": `Edit ${category.name}` }, icon("pencil")),
          icon("chevron", "chevron"),
        ),
        h("ul", { class: "rows" }, items.map(rowView)),
      );
    }),
  );
}

function rowView(item) {
  return h(
    "li",
    { class: item.needed ? "row needed" : "row", style: `view-transition-name: i-${item.id}` },
    h(
      "label",
      {},
      h("input", { class: "input", type: "checkbox", role: "switch", checked: item.needed, "data-toggle": item.id, "aria-label": `${item.name} on the list` }),
      h("span", { class: "name" }, item.name),
      item.quantity > 1 && h("span", { class: "qty" }, `×${item.quantity}`),
      item.oneTime && icon("sparkles", "once"),
      item.important && h("span", { class: "important", title: "Important" }),
    ),
    h("button", { class: "btn edit", "data-variant": "ghost", "data-size": "icon-sm", type: "button", "data-edit-item": item.id, "aria-label": `Edit ${item.name}` }, icon("pencil")),
  );
}

function emptyView(searching) {
  if (searching) return h("div", { class: "empty" }, h("strong", {}, "No match"), `Press Enter or + to add “${query.trim()}”.`);
  if (!state.items.length) return h("div", { class: "empty" }, h("strong", {}, "Your list is empty"), "Type an item above and press Enter.");
  return h("div", { class: "empty" }, h("strong", {}, "All done"), "Nothing pending. Switch to All to see everything.");
}

// ---------- List events ----------

list.addEventListener("change", (e) => {
  const id = e.target.dataset?.toggle;
  if (!id) return;
  toggle(state, id);
  save();
  if (visibleItems(state, query).some((i) => i.id === id)) {
    // Row stays put: patch it in place. A re-render would swap the switch mid-slide and flicker.
    const row = e.target.closest(".row");
    const group = row.closest(".group");
    row.classList.toggle("needed", e.target.checked);
    group.querySelector(".count").textContent = String(group.querySelectorAll(".row.needed").length);
  } else {
    // Row leaves (Pending view, or a one-time item): let the switch finish sliding, then animate it out.
    setTimeout(() => animate(render), 200);
  }
});

list.addEventListener("click", (e) => {
  const itemBtn = e.target.closest("[data-edit-item]");
  const catBtn = e.target.closest("[data-edit-category]");
  if (itemBtn) openItemDialog(state.items.find((i) => i.id === itemBtn.dataset.editItem));
  if (catBtn) {
    e.preventDefault(); // don't also toggle the <details>
    openCategoryDialog(state.categories.find((c) => c.id === catBtn.dataset.editCategory));
  }
});

// <details> toggle doesn't bubble; capture it. Persist open state, but not while search forces sections open.
list.addEventListener(
  "toggle",
  (e) => {
    if (!e.target.matches?.("details.group") || query.trim()) return;
    const id = e.target.dataset.category;
    const open = e.target.open;
    if (!id) {
      if (state.prefs.uncategorizedOpen === open) return;
      state.prefs.uncategorizedOpen = open;
    } else {
      const cat = state.categories.find((c) => c.id === id);
      if (!cat || cat.open === open) return;
      cat.open = open;
    }
    save();
  },
  true,
);

for (const b of document.querySelectorAll("[data-filter]")) {
  b.addEventListener("click", () => update((s) => (s.prefs.showAll = b.dataset.filter === "all")));
}

// ---------- Search / quick add ----------

search.addEventListener("input", () => {
  query = search.value;
  render();
});

$("#search-form").addEventListener("submit", (e) => {
  e.preventDefault();
  const name = search.value.trim();
  if (!name) return;
  const existing = findByName(state.items, name);
  if (existing) {
    if (!existing.needed) update(() => (existing.needed = true));
    toast(`${existing.name} is on the list`);
    clearSearch();
  } else {
    openItemDialog(null, name);
  }
});

$("#add-btn").addEventListener("click", () => openItemDialog(null, search.value.trim()));

function clearSearch() {
  search.value = query = "";
  render();
}

// ---------- Item dialog ----------

function openItemDialog(item, name = "") {
  editingItemId = item?.id ?? null;
  const f = itemForm.elements;
  $("#item-title").textContent = item ? "Edit item" : "Add item";
  f.name.value = item?.name ?? name;
  const byName = (a, b) => a.name.localeCompare(b.name);
  f.category.replaceChildren(
    h("option", { value: "" }, "None"),
    ...[...state.categories].sort(byName).map((c) => h("option", { value: c.id }, c.name)),
    h("option", { value: NEW_CATEGORY }, "New category…"),
  );
  f.category.value = item?.categoryId ?? "";
  f.newCategory.value = "";
  f.newCategory.hidden = true;
  f.quantity.value = item?.quantity ?? 1;
  f.oneTime.checked = item?.oneTime ?? false;
  f.important.checked = item?.important ?? false;
  $("#item-delete").hidden = !item;
  $("#item-error").textContent = "";
  itemDialog.showModal();
  if (!item) f.name.focus();
}

itemForm.elements.category.addEventListener("change", (e) => {
  const input = itemForm.elements.newCategory;
  input.hidden = e.target.value !== NEW_CATEGORY;
  if (!input.hidden) input.focus();
});

itemForm.addEventListener("submit", (e) => {
  e.preventDefault();
  const f = itemForm.elements;
  const creating = f.category.value === NEW_CATEGORY;
  const error = validateName(f.name.value, state.items, editingItemId) ?? (creating && !f.newCategory.value.trim() ? "Category name is required" : null);
  if (error) {
    $("#item-error").textContent = error;
    return;
  }
  const isNew = !editingItemId;
  update((s) => {
    let category = s.categories.find((c) => c.id === f.category.value) ?? null;
    if (creating) {
      // Typing an existing name reuses that category instead of making a duplicate.
      const name = f.newCategory.value.trim();
      category = findByName(s.categories, name);
      if (!category) s.categories.push((category = { id: uid(), name, open: true }));
    }
    const fields = {
      name: f.name.value.trim(),
      categoryId: category?.id ?? null,
      quantity: Math.min(20, Math.max(1, Math.round(Number(f.quantity.value)) || 1)),
      oneTime: f.oneTime.checked,
      important: f.important.checked,
    };
    if (isNew) s.items.push({ id: uid(), needed: true, createdAt: new Date().toISOString(), ...fields });
    else Object.assign(s.items.find((i) => i.id === editingItemId), fields);
  });
  itemDialog.close();
  if (isNew) clearSearch();
});

$("#item-delete").addEventListener("click", () => {
  const item = state.items.find((i) => i.id === editingItemId);
  if (!item || !confirm(`Delete “${item.name}”?`)) return;
  itemDialog.close();
  update((s) => (s.items = s.items.filter((i) => i.id !== item.id)));
});

// ---------- Category dialog ----------

function openCategoryDialog(category) {
  if (!category) return;
  editingCategoryId = category.id;
  categoryForm.elements.name.value = category.name;
  $("#category-error").textContent = "";
  categoryDialog.showModal();
}

categoryForm.addEventListener("submit", (e) => {
  e.preventDefault();
  const name = categoryForm.elements.name.value;
  const error = validateName(name, state.categories, editingCategoryId);
  if (error) {
    $("#category-error").textContent = error;
    return;
  }
  categoryDialog.close();
  update((s) => (s.categories.find((c) => c.id === editingCategoryId).name = name.trim()));
});

$("#category-delete").addEventListener("click", () => {
  const category = state.categories.find((c) => c.id === editingCategoryId);
  if (!category || !confirm(`Delete “${category.name}”? Its items become uncategorized.`)) return;
  categoryDialog.close();
  update((s) => {
    s.categories = s.categories.filter((c) => c.id !== category.id);
    for (const i of s.items) if (i.categoryId === category.id) i.categoryId = null;
  });
});

// ---------- Settings ----------

function renderTheme() {
  for (const b of document.querySelectorAll("[data-theme]")) b.setAttribute("aria-pressed", String(b.dataset.theme === state.prefs.theme));
}

for (const b of document.querySelectorAll("[data-theme]")) {
  b.addEventListener("click", () => {
    state.prefs.theme = b.dataset.theme;
    save();
    renderTheme();
  });
}

$("#settings-btn").addEventListener("click", async () => {
  renderTheme();
  $("#s-items").textContent = `${state.items.filter((i) => i.needed).length} pending · ${state.items.length} total`;
  $("#s-categories").textContent = String(state.categories.length);
  $("#s-export").textContent = state.prefs.lastExport ? new Date(state.prefs.lastExport).toLocaleString() : "Never";
  $("#s-storage").textContent = "…";
  settingsDialog.showModal();
  const persisted = await navigator.storage?.persisted?.().catch(() => undefined);
  $("#s-storage").textContent = persisted === undefined ? "Unknown (needs HTTPS)" : persisted ? "Persistent" : "Best effort";
});

$("#export-btn").addEventListener("click", () => {
  state.prefs.lastExport = new Date().toISOString();
  save();
  const blob = new Blob([JSON.stringify(state, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  h("a", { href: url, download: `groceries-${state.prefs.lastExport.slice(0, 10)}.json` }).click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
  $("#s-export").textContent = new Date(state.prefs.lastExport).toLocaleString();
  toast("Backup exported");
});

$("#import-btn").addEventListener("click", () => $("#import-file").click());

$("#import-file").addEventListener("change", async (e) => {
  const file = e.target.files[0];
  e.target.value = ""; // allow picking the same file again
  if (!file) return;
  try {
    const next = parseBackup(await file.text());
    if (!confirm(`Replace your ${state.items.length} items with ${next.items.length} from the backup?`)) return;
    settingsDialog.close();
    update(() => (state = next));
    toast("Backup imported");
  } catch (err) {
    toast(err.message);
  }
});

$("#clear-btn").addEventListener("click", () => {
  if (!confirm("Delete every item and category? Export a backup first if unsure.")) return;
  settingsDialog.close();
  update(() => (state = emptyState()));
  toast("All data cleared");
});

// ---------- Dialog chrome ----------

for (const dialog of document.querySelectorAll("dialog")) {
  dialog.addEventListener("click", (e) => {
    if (e.target === dialog || e.target.closest("[data-close]")) dialog.close();
  });
}

// ---------- Start ----------

navigator.storage?.persist?.().catch(() => {});
navigator.serviceWorker?.register("sw.js").catch(() => {}); // offline cache; needs HTTPS or localhost
render();
