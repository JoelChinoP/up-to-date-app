export const STORAGE_KEY = "aldia_v1";
export const CATEGORIES = [
  "Luz",
  "Agua",
  "Internet",
  "Teléfono",
  "Streaming",
  "Alquiler",
  "Otros",
];
export const money = (cents) =>
  new Intl.NumberFormat("es-PE", { style: "currency", currency: "PEN" }).format(
    cents / 100,
  );
export const isoDate = (date = new Date()) =>
  `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
export const monthLabel = (month) =>
  new Intl.DateTimeFormat("es-PE", { month: "long", year: "numeric" }).format(
    new Date(`${month}-02T12:00:00`),
  );
export const dateLabel = (date) =>
  new Intl.DateTimeFormat("es-PE", { day: "numeric", month: "short" }).format(
    new Date(`${date}T12:00:00`),
  );
export const emptyData = () => ({
  version: 1,
  services: [],
  bills: [],
  demo: false,
});

export function parseAmount(value) {
  const text = String(value).trim().replace(",", ".");
  if (!/^\d{1,7}(\.\d{1,2})?$/.test(text))
    throw new Error("Ingresa un monto positivo con hasta dos decimales.");
  const [whole, fraction = ""] = text.split(".");
  const cents = Number(whole) * 100 + Number(fraction.padEnd(2, "0"));
  if (cents < 1 || cents > 100000000)
    throw new Error("El monto debe estar entre S/ 0.01 y S/ 1 000 000.");
  return cents;
}

export function validDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(`${value}T12:00:00`);
  return (
    !Number.isNaN(date.valueOf()) &&
    isoDate(date) === value &&
    value >= "2000-01-01" &&
    value <= "2100-12-31"
  );
}

export function billStatus(bill, today = isoDate()) {
  if (bill.paid) return { kind: "paid", label: "Pagado" };
  const days = Math.round(
    (Date.parse(`${bill.due_date}T12:00:00Z`) -
      Date.parse(`${today}T12:00:00Z`)) /
      86400000,
  );
  if (days < 0)
    return {
      kind: "late",
      label: `Vencido hace ${-days} ${days === -1 ? "día" : "días"}`,
    };
  if (days === 0) return { kind: "soon", label: "Vence hoy" };
  return {
    kind: days <= 3 ? "soon" : "pending",
    label: `Vence en ${days} ${days === 1 ? "día" : "días"}`,
  };
}

export function analyzeBill(bill, bills) {
  const previous = bills
    .filter(
      (item) =>
        item.service_id === bill.service_id &&
        item.due_date.slice(0, 7) < bill.due_date.slice(0, 7),
    )
    .sort((a, b) => b.due_date.localeCompare(a.due_date))
    .slice(0, 3);
  if (previous.length < 3)
    return {
      kind: "unknown",
      label: "Aún no hay 3 recibos anteriores",
      average: null,
      variation: null,
      previous,
    };
  const average = previous.reduce((sum, item) => sum + item.amount, 0) / 3;
  if (average <= 0)
    return {
      kind: "unknown",
      label: "Sin base suficiente para comparar",
      average: null,
      variation: null,
      previous,
    };
  const variation = ((bill.amount - average) / average) * 100;
  const kind =
    variation > 25 ? "unusual" : variation >= 10 ? "increased" : "normal";
  return {
    kind,
    label:
      kind === "unusual"
        ? "Aumento inusual"
        : kind === "increased"
          ? "Monto en aumento"
          : "Dentro de lo habitual",
    average,
    variation,
    previous,
  };
}

export function saveService(data, input) {
  const name = input.name.trim();
  if (!name || name.length > 50)
    throw new Error("El nombre debe tener entre 1 y 50 caracteres.");
  if (!CATEGORIES.includes(input.category))
    throw new Error("Selecciona una categoría válida.");
  if (
    data.services.some(
      (service) =>
        service.id !== input.id &&
        service.name.toLocaleLowerCase() === name.toLocaleLowerCase(),
    )
  )
    throw new Error("Ya tienes un servicio con ese nombre.");
  const service = {
    id: input.id || crypto.randomUUID(),
    name,
    category: input.category,
  };
  return {
    ...data,
    services: input.id
      ? data.services.map((item) => (item.id === input.id ? service : item))
      : [...data.services, service],
  };
}

export function saveBill(data, input) {
  if (!data.services.some((service) => service.id === input.service_id))
    throw new Error("Primero registra un servicio.");
  if (!validDate(input.due_date))
    throw new Error("Selecciona una fecha válida entre 2000 y 2100.");
  if (
    data.bills.some(
      (bill) =>
        bill.id !== input.id &&
        bill.service_id === input.service_id &&
        bill.due_date.slice(0, 7) === input.due_date.slice(0, 7),
    )
  )
    throw new Error(
      "Este servicio ya tiene un recibo en ese mes. Puedes editarlo desde su detalle.",
    );
  const existing = data.bills.find((bill) => bill.id === input.id);
  const bill = {
    id: existing?.id || crypto.randomUUID(),
    service_id: input.service_id,
    amount: parseAmount(input.amount),
    due_date: input.due_date,
    paid: existing?.paid || false,
    paid_at: existing?.paid_at || null,
    created_at: existing?.created_at || new Date().toISOString(),
  };
  return {
    ...data,
    bills: existing
      ? data.bills.map((item) => (item.id === bill.id ? bill : item))
      : [...data.bills, bill],
  };
}

export function validateData(input) {
  if (
    input?.version !== 1 ||
    !Array.isArray(input.services) ||
    !Array.isArray(input.bills)
  )
    throw new Error("El archivo no tiene el formato de respaldo de AlDía.");
  if (input.services.length > 500 || input.bills.length > 10000)
    throw new Error(
      "El respaldo supera el límite de 500 servicios o 10 000 recibos.",
    );
  const ids = new Set();
  const names = new Set();
  for (const service of input.services) {
    if (
      typeof service.id !== "string" ||
      !service.id ||
      ids.has(service.id) ||
      typeof service.name !== "string" ||
      !service.name.trim() ||
      service.name.length > 50 ||
      names.has(service.name.trim().toLocaleLowerCase()) ||
      !CATEGORIES.includes(service.category)
    )
      throw new Error("El respaldo contiene servicios inválidos o duplicados.");
    ids.add(service.id);
    names.add(service.name.trim().toLocaleLowerCase());
  }
  const billIds = new Set();
  const months = new Set();
  for (const bill of input.bills) {
    const month = `${bill.service_id}:${String(bill.due_date).slice(0, 7)}`;
    if (
      typeof bill.id !== "string" ||
      !bill.id ||
      billIds.has(bill.id) ||
      !ids.has(bill.service_id) ||
      !Number.isSafeInteger(bill.amount) ||
      bill.amount <= 0 ||
      bill.amount > 100000000 ||
      !validDate(bill.due_date) ||
      typeof bill.paid !== "boolean" ||
      (bill.paid ? !validDate(bill.paid_at) : bill.paid_at !== null) ||
      typeof bill.created_at !== "string" ||
      Number.isNaN(Date.parse(bill.created_at)) ||
      months.has(month)
    )
      throw new Error("El respaldo contiene recibos inválidos o duplicados.");
    billIds.add(bill.id);
    months.add(month);
  }
  // 🐴 MVP local, con un techo de 10 000 recibos. Migrar a una BD para volúmenes mayores.
  return {
    version: 1,
    demo: input.demo === true,
    services: input.services.map(({ id, name, category }) => ({
      id,
      name: name.trim(),
      category,
    })),
    bills: input.bills.map(
      ({ id, service_id, amount, due_date, paid, paid_at, created_at }) => ({
        id,
        service_id,
        amount,
        due_date,
        paid,
        paid_at,
        created_at,
      }),
    ),
  };
}

export function demoData(today = new Date()) {
  const services = [
    { id: "demo-luz", name: "Luz del hogar", category: "Luz" },
    { id: "demo-agua", name: "Agua", category: "Agua" },
    { id: "demo-internet", name: "Internet", category: "Internet" },
    { id: "demo-telefono", name: "Teléfono", category: "Teléfono" },
  ];
  const amounts = [
    [6100, 6800, 6600, 9200],
    [4000, 4200, 4100, 4210],
    [7990, 7990, 7990, 7990],
    [3990, 3990, 3990, 3990],
  ];
  const days = [15, 19, 22, 2];
  const bills = services.flatMap((service, index) =>
    amounts[index].map((amount, offset) => {
      const due_date = isoDate(
        new Date(
          today.getFullYear(),
          today.getMonth() - 3 + offset,
          days[index],
        ),
      );
      const paid = offset < 3 || index === 3;
      return {
        id: `${service.id}-${offset}`,
        service_id: service.id,
        amount,
        due_date,
        paid,
        paid_at: paid ? due_date : null,
        created_at: `${due_date}T12:00:00.000Z`,
      };
    }),
  );
  return { version: 1, services, bills, demo: true };
}
