// Run: node --test
import { test } from "node:test";
import assert from "node:assert/strict";
import { emptyState, visibleItems, groupByCategory, validateName, toggle, parseBackup, nextTagColor, TAG_COLORS } from "./logic.js";

const fixture = () => ({
  ...emptyState(),
  categories: [
    { id: "c2", name: "Veg", open: true },
    { id: "c1", name: "Dairy", open: true },
  ],
  tags: [{ id: "t1", name: "Costco", color: "red" }],
  items: [
    { id: "a", name: "milk", needed: true, categoryId: "c1", quantity: 2, oneTime: false, tagIds: ["t1"] },
    { id: "b", name: "Carrots", needed: false, categoryId: "c2", quantity: 1, oneTime: false, tagIds: ["t1"] },
    { id: "c", name: "batteries", needed: true, categoryId: null, quantity: 1, oneTime: true, tagIds: [] },
    { id: "d", name: "apples", needed: true, categoryId: "gone", quantity: 1, oneTime: false, tagIds: [] },
  ],
});

test("visibleItems: pending, all, search ignores filter", () => {
  const s = fixture();
  assert.deepEqual(visibleItems(s).map((i) => i.id), ["a", "c", "d"]);
  s.prefs.showAll = true;
  assert.equal(visibleItems(s).length, 4);
  s.prefs.showAll = false;
  assert.deepEqual(visibleItems(s, " CARR ").map((i) => i.id), ["b"]);
});

test("groupByCategory: uncategorized first, A→Z, orphans uncategorized, empty dropped", () => {
  const s = fixture();
  const groups = groupByCategory(visibleItems(s), s.categories);
  assert.deepEqual(groups.map((g) => g.category?.name ?? null), [null, "Dairy"]);
  assert.deepEqual(groups[0].items.map((i) => i.name), ["apples", "batteries"]);
});

test("validateName: required, case-insensitive duplicate, self allowed", () => {
  const { items } = fixture();
  assert.equal(validateName("  ", items), "Name is required");
  assert.match(validateName("MILK", items), /already exists/);
  assert.equal(validateName("Milk", items, "a"), null);
  assert.equal(validateName("bread", items), null);
});

test("toggle: flips needed; one-time item is removed once got", () => {
  const s = fixture();
  toggle(s, "b");
  assert.equal(s.items.find((i) => i.id === "b").needed, true);
  toggle(s, "c");
  assert.equal(s.items.some((i) => i.id === "c"), false);
});

test("parseBackup: round-trips, fills prefs, rejects junk", () => {
  const s = fixture();
  const back = parseBackup(JSON.stringify({ ...s, prefs: { showAll: true } }));
  assert.equal(back.items.length, 4);
  assert.equal(back.prefs.uncategorizedOpen, true);
  assert.throws(() => parseBackup("nope"), /valid JSON/);
  assert.throws(() => parseBackup('{"v":2,"items":[],"categories":[]}'), /Groceries\+ backup/);
  assert.throws(() => parseBackup('{"v":1,"items":[{"id":1}],"categories":[]}'), /Groceries\+ backup/);
});

test("visibleItems: tag filter narrows pending, all and search", () => {
  const s = fixture();
  assert.deepEqual(visibleItems(s, "", "t1").map((i) => i.id), ["a"]);
  s.prefs.showAll = true;
  assert.deepEqual(visibleItems(s, "", "t1").map((i) => i.id), ["a", "b"]);
  assert.deepEqual(visibleItems(s, "carr", "t1").map((i) => i.id), ["b"]);
  assert.deepEqual(visibleItems(s, "apples", "t1"), []);
});

test("nextTagColor: first unused, then cycles", () => {
  assert.equal(nextTagColor([]), "rosewater");
  assert.equal(nextTagColor([{ color: "rosewater" }, { color: "pink" }]), "flamingo");
  assert.equal(nextTagColor(TAG_COLORS.map((color) => ({ color }))), "rosewater");
});

test("parseBackup: old backups get tags; dangling tagIds and bad colors are cleaned", () => {
  const old = parseBackup(JSON.stringify({ v: 1, items: [{ id: "a", name: "Milk" }], categories: [] }));
  assert.deepEqual(old.tags, []);
  assert.deepEqual(old.items[0].tagIds, []);
  const s = parseBackup(JSON.stringify({ v: 1, categories: [], tags: [{ id: "t", name: "Bulk", color: "neon" }], items: [{ id: "a", name: "Milk", tagIds: ["t", "gone"] }] }));
  assert.equal(s.tags[0].color, "blue");
  assert.deepEqual(s.items[0].tagIds, ["t"]);
});

