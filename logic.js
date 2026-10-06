// Pure-ish list logic: no DOM, no storage. Tested by logic.test.mjs.

export const emptyState = () => ({
  v: 1,
  items: [],
  categories: [],
  prefs: { showAll: false, uncategorizedOpen: true, lastExport: null, theme: "system" },
});

const norm = (s) => s.trim().toLocaleLowerCase();
const byName = (a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: "base" });

// Empty query: the Pending/All filter applies. While searching, every item can match.
export function visibleItems(state, query = "") {
  const q = norm(query);
  if (q) return state.items.filter((i) => norm(i.name).includes(q));
  return state.prefs.showAll ? state.items : state.items.filter((i) => i.needed);
}

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
  return { ...base, ...data, prefs: { ...base.prefs, ...data.prefs } };
}
