import { move, emptyState, visibleItems, groupByCategory, validateName, findByName, toggle, parseBackup, COLORS, nextColor } from "./logic.js";

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
const tagbar = $("#tagbar");
const tagDialog = $("#tag-dialog");
const tagForm = $("#tag-form");

let state = load();
let query = "";
let tagFilter = null; // tag id; not saved, the app opens unfiltered
let editingItemId = null;
let editingCategoryId = null;
let editingTagId = null;
let editMode = false; // Edit mode: a tile tap opens the editor instead of toggling
// Item dialog tags: the ticked ids, and tags made in this dialog. New tags join state only on Save.
let pickedTagIds = new Set();
let draftTags = [];

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

// A colored chip. The color name maps to a palette variable, so it follows the theme.
function tagChip(tag, tagName = "span", attrs = {}) {
  return h(tagName, { class: "tag", style: `--c: var(--ctp-${tag.color})`, ...attrs }, tag.name);
}

const tagsOf = (item) => item.tagIds.map((id) => state.tags.find((t) => t.id === id)).filter(Boolean);

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

  if (!state.tags.some((t) => t.id === tagFilter)) tagFilter = null;
  tagbar.hidden = !state.tags.length;
  tagbar.replaceChildren(...state.tags.map((t) => tagChip(t, "button", { type: "button", "data-tag-filter": t.id, "aria-pressed": String(t.id === tagFilter) })));

  const searching = query.trim() !== "";
  const groups = groupByCategory(visibleItems(state, query, tagFilter), state.categories);

  if (!groups.length) {
    list.replaceChildren(emptyView(searching));
    return;
  }

  // Arrows step over visible neighbours only, so a move is never invisible.
  const shown = groups.filter((g) => g.category).map((g) => g.category.id);
  const arrow = (category, delta, name, cls) => {
    const to = shown[shown.indexOf(category.id) + delta];
    return h("button", { class: "btn edit", "data-variant": "ghost", "data-size": "icon-sm", type: "button", "data-move-category": category.id, "data-to": to, disabled: !to, "aria-label": `Move ${category.name} ${delta < 0 ? "up" : "down"}` }, icon(name, cls));
  };
  list.replaceChildren(
    ...groups.map(({ category, items }) => {
      const open = searching || (category ? category.open : state.prefs.uncategorizedOpen);
      return h(
        "details",
        { class: "group", open, "data-category": category?.id ?? "" },
        h(
          "summary",
          {},
          titleView(category?.name ?? "Uncategorized"),
          h("span", { class: "count" }, String(items.filter((i) => i.needed).length)),
          category && arrow(category, -1, "chevron", "up"),
          category && arrow(category, 1, "chevron"),
          category && h("button", { class: "btn edit", "data-variant": "ghost", "data-size": "icon-sm", type: "button", "data-edit-category": category.id, "aria-label": `Edit ${category.name}` }, icon("pencil")),
          icon("chevron", "chevron"),
        ),
        h("ul", { class: "tiles" }, items.map(tileView)),
      );
    }),
  );
}

// A leading emoji ("🥬 Produce") gets its own tinted square.
function titleView(name) {
  const [, emoji, rest] = name.match(/^(\p{Extended_Pictographic}\uFE0F?)\s*(.*)$/u) ?? [];
  return h("span", { class: "title" }, emoji && h("span", { class: "emoji", "aria-hidden": "true" }, emoji), emoji ? rest : name);
}

// Order: name, quantity, important dot, one-time sparkles, tag labels. The name comes first so it scans fast.
function tileView(item) {
  return h(
    "li",
    {},
    h(
      "button",
      { class: "tile", type: "button", "aria-pressed": String(item.needed), "data-item": item.id, style: `view-transition-name: i-${item.id}` },
      h("span", { class: "name" }, item.name),
      item.quantity > 1 && h("span", { class: "qty" }, `×${item.quantity}`),
      item.important && h("span", { class: "important", title: "Important" }),
      item.oneTime && icon("sparkles", "once"),
      tagsOf(item).map((t) => tagChip(t, "span", { class: "tag mini" })),
      icon("pencil", "pencil"),
    ),
  );
}

function emptyView(searching) {
  if (searching) return h("div", { class: "empty" }, h("strong", {}, "No match"), `Press Enter or + to add “${query.trim()}”.`);
  if (!state.items.length) return h("div", { class: "empty" }, h("strong", {}, "Your list is empty"), "Type an item above and press Enter.");
  const tag = state.tags.find((t) => t.id === tagFilter);
  if (tag) return h("div", { class: "empty" }, h("strong", {}, "Nothing here"), `No ${state.prefs.showAll ? "" : "pending "}items tagged “${tag.name}”.`);
  return h("div", { class: "empty" }, h("strong", {}, "All done"), "Nothing pending. Switch to All to see everything.");
}

// ---------- List events ----------

function toggleTile(tile) {
  const id = tile.dataset.item;
  toggle(state, id);
  save();
  const on = state.items.some((i) => i.id === id && i.needed); // a one-time item is gone once you have it
  tile.setAttribute("aria-pressed", String(on));
  const group = tile.closest(".group");
  group.querySelector(".count").textContent = String(group.querySelectorAll('.tile[aria-pressed="true"]').length);
  // Tile leaves (Pending view, or a one-time item): show the off state for a beat, then animate it out.
  if (!visibleItems(state, query, tagFilter).some((i) => i.id === id)) setTimeout(() => animate(render), 250);
}

// Long-press (~0.45 s) a tile to edit it. Moving the finger (a scroll) cancels.
let press = null;
let pressed = false; // the long-press fired; swallow the click that follows
const cancelPress = () => {
  clearTimeout(press?.timer);
  press = null;
};

list.addEventListener("pointerdown", (e) => {
  const tile = e.target.closest("[data-item]");
  pressed = false;
  if (!tile || e.button) return;
  press = {
    x: e.clientX,
    y: e.clientY,
    timer: setTimeout(() => {
      press = null;
      pressed = true;
      openItemDialog(state.items.find((i) => i.id === tile.dataset.item));
    }, 450),
  };
});
list.addEventListener("pointermove", (e) => {
  if (press && Math.hypot(e.clientX - press.x, e.clientY - press.y) > 10) cancelPress();
});
for (const type of ["pointerup", "pointercancel"]) list.addEventListener(type, cancelPress);
list.addEventListener("contextmenu", (e) => {
  if (e.target.closest("[data-item]")) e.preventDefault();
});

list.addEventListener("click", (e) => {
  const tile = e.target.closest("[data-item]");
  const catBtn = e.target.closest("[data-edit-category]");
  const moveBtn = e.target.closest("[data-move-category]");
  if (tile && !pressed) editMode ? openItemDialog(state.items.find((i) => i.id === tile.dataset.item)) : toggleTile(tile);
  if (moveBtn) {
    e.preventDefault(); // don't also toggle the <details>
    update((s) => move(s.categories, moveBtn.dataset.moveCategory, moveBtn.dataset.to));
  }
  if (catBtn) {
    e.preventDefault(); // don't also toggle the <details>
    openCategoryDialog(state.categories.find((c) => c.id === catBtn.dataset.editCategory));
  }
  pressed = false;
});

$("#edit-btn").addEventListener("click", (e) => {
  editMode = !editMode;
  e.currentTarget.setAttribute("aria-pressed", String(editMode));
  e.currentTarget.textContent = editMode ? "Done" : "Edit";
  document.body.classList.toggle("editing", editMode);
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

// Tap a tag to filter by it; tap it again to clear.
tagbar.addEventListener("click", (e) => {
  const id = e.target.closest("[data-tag-filter]")?.dataset.tagFilter;
  if (!id) return;
  tagFilter = tagFilter === id ? null : id;
  animate(render);
});

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

$("#search-clear").addEventListener("click", () => {
  clearSearch();
  search.focus();
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
  f.category.replaceChildren(
    h("option", { value: "" }, "None"),
    ...state.categories.map((c) => h("option", { value: c.id }, c.name)),
    h("option", { value: NEW_CATEGORY }, "New category…"),
  );
  f.category.value = item?.categoryId ?? "";
  f.newCategory.value = "";
  f.newCategory.hidden = true;
  f.quantity.value = item?.quantity ?? 1;
  f.oneTime.checked = item?.oneTime ?? false;
  f.important.checked = item?.important ?? false;
  // A new item starts with the active tag filter, so it stays in view after Save.
  pickedTagIds = new Set(item ? item.tagIds : tagFilter ? [tagFilter] : []);
  draftTags = [];
  closeNewTag();
  renderDialogTags();
  $("#item-delete").hidden = !item;
  $("#item-error").textContent = "";
  itemDialog.showModal();
  // showModal focuses the first field, which opens the keyboard. On edit, move focus to the dialog itself.
  (item ? itemDialog : f.name).focus();
}

const newTagPanel = $("#f-new-tag");

function renderDialogTags() {
  $("#f-tags").replaceChildren(
    ...[...state.tags, ...draftTags].map((t) => tagChip(t, "button", { type: "button", "data-pick-tag": t.id, "aria-pressed": String(pickedTagIds.has(t.id)) })),
    h("button", { class: "tag add-tag", type: "button", "data-new-tag": "", "aria-expanded": String(!newTagPanel.hidden) }, "+ New tag"),
  );
}

function openNewTag() {
  const f = itemForm.elements;
  f.newTag.value = "";
  renderSwatches($("#f-tag-colors"), nextColor([...state.tags, ...draftTags]));
  newTagPanel.hidden = false;
  renderDialogTags();
  f.newTag.focus();
}

// One radio per palette color, named color within its form.
function renderSwatches(container, selected) {
  container.replaceChildren(
    ...COLORS.map((c) => h("input", { type: "radio", name: "color", value: c, checked: c === selected, style: `--c: var(--ctp-${c})`, "aria-label": c })),
  );
}

function closeNewTag() {
  newTagPanel.hidden = true;
}

function addTag() {
  const f = itemForm.elements;
  const all = [...state.tags, ...draftTags];
  const name = f.newTag.value.trim();
  if (!name) return f.newTag.focus();
  // Typing an existing name picks that tag instead of making a duplicate.
  let tag = findByName(all, name);
  if (!tag) draftTags.push((tag = { id: uid(), name, color: f.color.value }));
  pickedTagIds.add(tag.id);
  closeNewTag();
  renderDialogTags();
}

$("#f-tags").addEventListener("click", (e) => {
  const pick = e.target.closest("[data-pick-tag]");
  if (pick) {
    const id = pick.dataset.pickTag;
    pickedTagIds.has(id) ? pickedTagIds.delete(id) : pickedTagIds.add(id);
    pick.setAttribute("aria-pressed", String(pickedTagIds.has(id)));
  } else if (e.target.closest("[data-new-tag]")) {
    newTagPanel.hidden ? openNewTag() : (closeNewTag(), renderDialogTags());
  }
});

$("#f-tag-add").addEventListener("click", addTag);

// Enter in the tag name adds the tag; it must not submit the item form.
itemForm.elements.newTag.addEventListener("keydown", (e) => {
  if (e.key !== "Enter") return;
  e.preventDefault();
  addTag();
});

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
      if (!category) s.categories.push((category = { id: uid(), name, open: true, color: nextColor(s.categories) }));
    }
    for (const t of draftTags) if (pickedTagIds.has(t.id)) s.tags.push(t);
    const fields = {
      name: f.name.value.trim(),
      categoryId: category?.id ?? null,
      quantity: Math.min(20, Math.max(1, Math.round(Number(f.quantity.value)) || 1)),
      oneTime: f.oneTime.checked,
      important: f.important.checked,
      tagIds: [...pickedTagIds].filter((id) => s.tags.some((t) => t.id === id)),
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
  update((s) => Object.assign(s.categories.find((c) => c.id === editingCategoryId), { name: name.trim() }));
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

// ---------- Tag dialog (opened from Settings) ----------

function renderTagList() {
  const list = $("#s-tag-list");
  if (!state.tags.length) return list.replaceChildren(h("li", { class: "none" }, "No tags yet. Add one from an item."));
  // Same order as the filter bar; the arrows reorder both.
  const btn = (attrs, name, cls) => h("button", { class: "btn edit", "data-variant": "ghost", "data-size": "icon-sm", type: "button", ...attrs }, icon(name, cls));
  const last = state.tags.length - 1;
  list.replaceChildren(
    ...state.tags.map((t, i) =>
      h(
        "li",
        {},
        tagChip(t),
        h(
          "span",
          { class: "actions" },
          btn({ "data-move-tag": t.id, "data-delta": -1, "aria-label": `Move ${t.name} up`, disabled: i === 0 }, "chevron", "up"),
          btn({ "data-move-tag": t.id, "data-delta": 1, "aria-label": `Move ${t.name} down`, disabled: i === last }, "chevron"),
          btn({ "data-edit-tag": t.id, "aria-label": `Edit ${t.name}` }, "pencil"),
        ),
      ),
    ),
  );
}

$("#s-tag-list").addEventListener("click", (e) => {
  const move = e.target.closest("[data-move-tag]");
  if (move) {
    const from = state.tags.findIndex((t) => t.id === move.dataset.moveTag);
    update((s) => s.tags.splice(from + Number(move.dataset.delta), 0, ...s.tags.splice(from, 1)));
    return renderTagList();
  }
  const tag = state.tags.find((t) => t.id === e.target.closest("[data-edit-tag]")?.dataset.editTag);
  if (!tag) return;
  editingTagId = tag.id;
  tagForm.elements.name.value = tag.name;
  renderSwatches($("#t-colors"), tag.color);
  $("#tag-error").textContent = "";
  tagDialog.showModal();
});

tagForm.addEventListener("submit", (e) => {
  e.preventDefault();
  const f = tagForm.elements;
  const error = validateName(f.name.value, state.tags, editingTagId);
  if (error) {
    $("#tag-error").textContent = error;
    return;
  }
  tagDialog.close();
  update((s) => Object.assign(s.tags.find((t) => t.id === editingTagId), { name: f.name.value.trim(), color: f.color.value }));
  renderTagList();
});

$("#tag-delete").addEventListener("click", () => {
  const tag = state.tags.find((t) => t.id === editingTagId);
  if (!tag) return;
  const used = state.items.filter((i) => i.tagIds.includes(tag.id)).length;
  if (!confirm(`Delete “${tag.name}”?${used ? ` It's removed from ${used} item${used === 1 ? "" : "s"}.` : ""}`)) return;
  tagDialog.close();
  update((s) => {
    s.tags = s.tags.filter((t) => t.id !== tag.id);
    for (const i of s.items) i.tagIds = i.tagIds.filter((id) => id !== tag.id);
  });
  renderTagList();
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
  $("#s-tags").textContent = String(state.tags.length);
  renderTagList();
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
  if (!confirm("Delete every item, category and tag? Export a backup first if unsure.")) return;
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
