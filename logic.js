// Pure-ish list logic: no DOM, no storage. Tested by logic.test.mjs.

export const emptyState = () => ({
  v: 1,
  items: [],
  categories: [],
  tags: [],
  prefs: { showAll: false, uncategorizedOpen: true, lastExport: null, theme: "system", palette: "catppuccin" },
});

// Case- and accent-insensitive: "atun" matches "Atún".
const norm = (s) => s.trim().toLocaleLowerCase().normalize("NFD").replace(/\p{Diacritic}/gu, "");
const byName = (a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: "base" });

// Catppuccin accents, in palette order. Tags and categories store the name; CSS maps it to --ctp-<name>.
export const COLORS = ["rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach", "yellow", "green", "teal", "sky", "sapphire", "blue", "lavender"];

// Empty query: the Pending/All filter applies. While searching, every item can match.
// A tag filter narrows either way.
export function visibleItems(state, query = "", tagId = null) {
  const q = norm(query);
  const items = tagId ? state.items.filter((i) => i.tagIds.includes(tagId)) : state.items;
  if (q) return items.filter((i) => norm(i.name).includes(q));
  return state.prefs.showAll ? items : items.filter((i) => i.needed);
}

// First color the list doesn't use yet, so a new tag or category differs from the rest until all 14 are taken.
export const nextColor = (list) => COLORS.find((c) => !list.some((x) => x.color === c)) ?? COLORS[list.length % COLORS.length];

// Uncategorized first, then categories A→Z. Empty groups dropped. Unknown categoryId → uncategorized.
export function groupByCategory(items, categories) {
  const groups = [{ category: null, items: [] }, ...[...categories].sort(byName).map((category) => ({ category, items: [] }))];
  const byId = new Map(groups.map((g) => [g.category?.id ?? null, g]));
  for (const item of items) (byId.get(item.categoryId) ?? groups[0]).items.push(item);
  return groups.filter((g) => g.items.length).map((g) => ({ ...g, items: g.items.sort(byName) }));
}

// Returns an error message, or null when the name is fine. Duplicates are case-insensitive.
export function validateName(name, list, selfId = null) {
  const n = norm(name);
  if (!n) return "Name is required";
  if (list.some((x) => x.id !== selfId && norm(x.name) === n)) return `"${name.trim()}" already exists`;
  return null;
}

export const findByName = (list, name) => list.find((x) => norm(x.name) === norm(name));

// Mutates state. A one-time item leaves the list for good once you have it (iOS ItemView.swift:22-24).
export function toggle(state, id) {
  const item = state.items.find((i) => i.id === id);
  if (!item) return state;
  if (item.needed && item.oneTime) state.items = state.items.filter((i) => i !== item);
  else item.needed = !item.needed;
  return state;
}

// Trust boundary: used for file imports and for whatever sits in localStorage.
export function parseBackup(text) {
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    throw new Error("Not a valid JSON file");
  }
  const named = (x) => typeof x?.id === "string" && typeof x.name === "string";
  if (data?.v !== 1 || !Array.isArray(data.items) || !Array.isArray(data.categories) || ![...data.items, ...data.categories].every(named)) {
    throw new Error("Not a Groceries+ backup");
  }
  const base = emptyState();
  // Backups from before tags have no tags list or tagIds. Unknown colors fall back to blue.
  const tags = Array.isArray(data.tags) ? data.tags.filter(named).map((t) => ({ ...t, color: COLORS.includes(t.color) ? t.color : "blue" })) : [];
  // Backups from before category colors: give each category a distinct color.
  const categories = [];
  for (const c of data.categories) categories.push({ ...c, color: COLORS.includes(c.color) ? c.color : nextColor(categories) });
  const tagIds = new Set(tags.map((t) => t.id));
  const items = data.items.map((i) => ({ ...i, tagIds: Array.isArray(i.tagIds) ? i.tagIds.filter((id) => tagIds.has(id)) : [] }));
  return { ...base, ...data, items, categories, tags, prefs: { ...base.prefs, ...data.prefs } };
}
