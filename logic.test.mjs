// Run: node --test web/logic.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { emptyState, visibleItems, groupByCategory, validateName, toggle, parseBackup } from "./logic.js";

const fixture = () => ({
  ...emptyState(),
  categories: [
    { id: "c2", name: "Veg", open: true },
    { id: "c1", name: "Dairy", open: true },
  ],
  items: [
    { id: "a", name: "milk", needed: true, categoryId: "c1", quantity: 2, oneTime: false },
    { id: "b", name: "Carrots", needed: false, categoryId: "c2", quantity: 1, oneTime: false },
    { id: "c", name: "batteries", needed: true, categoryId: null, quantity: 1, oneTime: true },
    { id: "d", name: "apples", needed: true, categoryId: "gone", quantity: 1, oneTime: false },
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
