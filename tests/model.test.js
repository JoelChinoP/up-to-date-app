import test from "node:test";
import assert from "node:assert/strict";
import {
  analyzeBill,
  billStatus,
  demoData,
  emptyData,
  parseAmount,
  saveBill,
  saveService,
  validDate,
  validateData,
} from "../src/model.js";

test("montos en céntimos, con coma o punto y sin redondeo binario", () => {
  assert.equal(parseAmount("86.40"), 8640);
  assert.equal(parseAmount("0,01"), 1);
  for (const value of ["0", "-2", "1.234", "1e3", "NaN", "1000001"])
    assert.throws(() => parseAmount(value));
});
test("fechas reales y años bisiestos", () => {
  assert.equal(validDate("2024-02-29"), true);
  for (const value of ["2026-02-29", "2026-02-30", "2026-13-01", "1999-12-31"])
    assert.equal(validDate(value), false);
});
test("servicios únicos y categorías válidas", () => {
  const data = saveService(emptyData(), { name: " Luz ", category: "Luz" });
  assert.equal(data.services[0].name, "Luz");
  assert.throws(() => saveService(data, { name: "luz", category: "Luz" }));
  assert.throws(() =>
    saveService(data, { name: "Agua", category: "Inventada" }),
  );
});
test("un recibo por servicio y mes, editable sin duplicar", () => {
  const data = saveService(emptyData(), { name: "Luz", category: "Luz" });
  const input = {
    service_id: data.services[0].id,
    amount: "92",
    due_date: "2026-10-15",
  };
  const next = saveBill(data, input);
  assert.throws(() => saveBill(next, { ...input, due_date: "2026-10-29" }));
  const edited = saveBill(next, {
    ...input,
    id: next.bills[0].id,
    amount: "89",
  });
  assert.equal(edited.bills.length, 1);
  assert.equal(edited.bills[0].amount, 8900);
  assert.throws(() => saveBill(data, { ...input, service_id: "missing" }));
});
test("variación calculada solo con los 3 meses anteriores del mismo servicio", () => {
  const data = demoData(new Date(2026, 9, 3));
  const current = data.bills.find((bill) => bill.id === "demo-luz-3");
  const result = analyzeBill(current, [
    ...data.bills,
    { ...current, id: "future", due_date: "2026-11-15", amount: 100000 },
  ]);
  assert.equal(result.average, 6500);
  assert.ok(Math.abs(result.variation - 41.5384615) < 0.00001);
  assert.equal(result.kind, "unusual");
});
test("límites 10% y 25% inclusivos y reducción normal", () => {
  const earlier = [1, 2, 3].map((month) => ({
    service_id: "a",
    amount: 10000,
    due_date: `2026-0${month}-15`,
  }));
  for (const [amount, expected] of [
    [10999, "normal"],
    [11000, "increased"],
    [12500, "increased"],
    [12501, "unusual"],
    [9000, "normal"],
  ])
    assert.equal(
      analyzeBill({ service_id: "a", amount, due_date: "2026-04-15" }, earlier)
        .kind,
      expected,
    );
});
test("sin 3 antecedentes o promedio cero no se divide", () => {
  const current = { service_id: "a", amount: 1000, due_date: "2026-04-15" };
  assert.equal(analyzeBill(current, []).variation, null);
  assert.equal(
    analyzeBill(
      current,
      [1, 2, 3].map((m) => ({
        service_id: "a",
        amount: 0,
        due_date: `2026-0${m}-15`,
      })),
    ).variation,
    null,
  );
});
test("estados: vencido, hoy, próximo, pendiente y pagado", () => {
  for (const [date, expected] of [
    ["2026-10-02", "late"],
    ["2026-10-03", "soon"],
    ["2026-10-06", "soon"],
    ["2026-10-07", "pending"],
  ])
    assert.equal(
      billStatus({ due_date: date, paid: false }, "2026-10-03").kind,
      expected,
    );
  assert.equal(
    billStatus({ due_date: "2026-01-01", paid: true }, "2026-10-03").kind,
    "paid",
  );
});
test("respaldo validado y sin propiedades adicionales", () => {
  const data = demoData(new Date(2026, 9, 3));
  assert.equal(validateData(data).bills.length, 16);
  assert.throws(() => validateData({ ...data, version: 2 }));
  assert.throws(() =>
    validateData({ ...data, bills: [...data.bills, data.bills[0]] }),
  );
  assert.throws(() =>
    validateData({
      ...data,
      bills: [{ ...data.bills[0], service_id: "missing" }],
    }),
  );
  assert.throws(() =>
    validateData({ ...data, bills: [{ ...data.bills[0], amount: 1.1 }] }),
  );
  assert.throws(() =>
    validateData({ ...data, bills: [{ ...data.bills[0], paid_at: null }] }),
  );
  const safe = validateData({ ...data, dangerous: "ignored" });
  assert.equal("dangerous" in safe, false);
});
