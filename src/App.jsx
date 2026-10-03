import { useEffect, useRef, useState } from "react";
import { useRegisterSW } from "virtual:pwa-register/react";
import {
  analyzeBill,
  billStatus,
  CATEGORIES,
  dateLabel,
  demoData,
  emptyData,
  isoDate,
  money,
  monthLabel,
  saveBill,
  saveService,
  STORAGE_KEY,
  validateData,
} from "./model.js";

const paths = {
  check: "m5 12 4 4L19 6",
  home: "m3 10 9-7 9 7v10h-6v-6H9v6H3z",
  calendar: "M5 4h14v17H5z M8 2v4m8-4v4M5 10h14",
  receipt: "M6 3h12v18l-3-2-3 2-3-2-3 2z M9 8h6m-6 4h6",
  history: "M3 11a9 9 0 1 1 2 7M3 4v7h7m2-5v6l4 2",
  plus: "M12 5v14M5 12h14",
  close: "m6 6 12 12M6 18 18 6",
  left: "m15 5-7 7 7 7",
  right: "m9 5 7 7-7 7",
  bell: "M6 8a6 6 0 0 1 12 0v7l2 3H4l2-3zm4 13h4",
  settings:
    "M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8M12 2v3m0 14v3M2 12h3m14 0h3M5 5l2 2m10 10 2 2M5 19l2-2M17 7l2-2",
  light: "M9 18h6m-6 3h6M8 14a6 6 0 1 1 8 0l-1 2H9z",
  water: "M12 3S5 11 5 15a7 7 0 0 0 14 0c0-4-7-12-7-12z",
  wifi: "M2 8a16 16 0 0 1 20 0M5 12a11 11 0 0 1 14 0m-10 4a5 5 0 0 1 6 0m-3 4h.01",
  phone: "M7 2h10v20H7zm4 16h2",
  arrow: "m7 17 10-10M7 7h10v10",
  download: "M12 3v12m-5-5 5 5 5-5M4 16v5h16v-5",
  shield: "M12 2 4 5v7c0 5 8 10 8 10s8-5 8-10V5z M8 12l3 3 5-6",
  alert: "M12 8v5m0 4h.01M12 3 2 21h20z",
};
function Icon({ name, size = 22 }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.7"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d={paths[name] || paths.receipt} />
    </svg>
  );
}
const categoryIcon = (category) =>
  ({ Luz: "light", Agua: "water", Internet: "wifi", Teléfono: "phone" })[
    category
  ] || "receipt";
const navItems = [
  ["home", "Resumen", "home"],
  ["calendar", "Calendario", "calendar"],
  ["services", "Servicios", "receipt"],
  ["history", "Historial", "history"],
];

function Modal({ title, children, onClose, wide = false }) {
  const ref = useRef(null);
  useEffect(() => {
    ref.current.showModal();
  }, []);
  return (
    <dialog
      ref={ref}
      className={wide ? "wide" : ""}
      aria-labelledby="dialog-title"
      onCancel={onClose}
      onClick={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
    >
      <div className="dialog-head">
        <h2 id="dialog-title">{title}</h2>
        <button className="icon-button" aria-label="Cerrar" onClick={onClose}>
          <Icon name="close" />
        </button>
      </div>
      {children}
    </dialog>
  );
}

function BillForm({ data, initial, month, onSave, onClose }) {
  const [form, setForm] = useState({
    id: initial?.id,
    service_id: initial?.service_id || data.services[0]?.id || "",
    amount: initial?.id ? (initial.amount / 100).toFixed(2) : "",
    due_date: initial?.due_date || `${month}-15`,
  });
  const [error, setError] = useState("");
  return (
    <Modal title={initial ? "Editar recibo" : "Nuevo recibo"} onClose={onClose}>
      <p className="muted">Tres datos y un pendiente menos en tu cabeza.</p>
      <form
        onSubmit={(event) => {
          event.preventDefault();
          try {
            onSave(saveBill(data, form));
          } catch (err) {
            setError(err.message);
          }
        }}
      >
        <label>
          Servicio
          <select
            autoFocus
            value={form.service_id}
            onChange={(e) => setForm({ ...form, service_id: e.target.value })}
            required
          >
            {data.services.map((service) => (
              <option key={service.id} value={service.id}>
                {service.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          Monto (S/)
          <input
            value={form.amount}
            onChange={(e) => setForm({ ...form, amount: e.target.value })}
            inputMode="decimal"
            placeholder="0.00"
            maxLength={11}
            required
          />
        </label>
        <label>
          Fecha de vencimiento
          <input
            type="date"
            value={form.due_date}
            min="2000-01-01"
            max="2100-12-31"
            onChange={(e) => setForm({ ...form, due_date: e.target.value })}
            required
          />
        </label>
        {error && (
          <p className="form-error" role="alert">
            {error}
          </p>
        )}
        <p className="form-note">
          Un recibo por servicio y mes. Puedes corregirlo después.
        </p>
        <button className="primary full" type="submit">
          Guardar recibo
        </button>
      </form>
    </Modal>
  );
}

function ServiceForm({ data, initial, onSave, onClose }) {
  const [form, setForm] = useState(initial || { name: "", category: "Luz" });
  const [error, setError] = useState("");
  return (
    <Modal
      title={initial ? "Editar servicio" : "Nuevo servicio"}
      onClose={onClose}
    >
      <p className="muted">Dale un nombre fácil de reconocer.</p>
      <form
        onSubmit={(event) => {
          event.preventDefault();
          try {
            onSave(saveService(data, form));
          } catch (err) {
            setError(err.message);
          }
        }}
      >
        <label>
          Nombre del servicio
          <input
            autoFocus
            value={form.name}
            maxLength={50}
            placeholder="Por ejemplo, luz del hogar"
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            required
          />
        </label>
        <label>
          Categoría
          <select
            value={form.category}
            onChange={(e) => setForm({ ...form, category: e.target.value })}
          >
            {CATEGORIES.map((category) => (
              <option key={category}>{category}</option>
            ))}
          </select>
        </label>
        {error && (
          <p className="form-error" role="alert">
            {error}
          </p>
        )}
        <button className="primary full" type="submit">
          Guardar servicio
        </button>
      </form>
    </Modal>
  );
}

export default function App() {
  const [initial] = useState(() => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      return {
        data: raw ? validateData(JSON.parse(raw)) : emptyData(),
        error: "",
        raw,
      };
    } catch {
      return {
        data: emptyData(),
        error:
          "No pudimos leer tus datos. No se han borrado. Revisa los respaldos en Ajustes.",
        raw: null,
      };
    }
  });
  const [data, setData] = useState(initial.data);
  const [storageError, setStorageError] = useState(initial.error);
  const [recoveryRequired, setRecoveryRequired] = useState(
    Boolean(initial.error),
  );
  const [view, setView] = useState("home");
  const [month, setMonth] = useState(isoDate().slice(0, 7));
  const [today, setToday] = useState(isoDate());
  const [day, setDay] = useState(null);
  const [filter, setFilter] = useState("all");
  const [modal, setModal] = useState(null);
  const [toast, setToast] = useState("");
  const [online, setOnline] = useState(navigator.onLine);
  const [installPrompt, setInstallPrompt] = useState(null);
  const [notificationState, setNotificationState] = useState(
    "Notification" in window ? Notification.permission : "unsupported",
  );
  const [reminders, setReminders] = useState(() => {
    try {
      return localStorage.getItem("aldia_reminders") === "true";
    } catch {
      return false;
    }
  });
  const {
    offlineReady: [offlineReady],
    needRefresh: [needRefresh, setNeedRefresh],
    updateServiceWorker,
  } = useRegisterSW();
  const monthly = data.bills
    .filter((bill) => bill.due_date.startsWith(month))
    .sort((a, b) => a.due_date.localeCompare(b.due_date));
  const pending = monthly.filter((bill) => !bill.paid);
  const total = monthly.reduce((sum, bill) => sum + bill.amount, 0);
  const unpaid = pending.reduce((sum, bill) => sum + bill.amount, 0);
  const progress = total ? Math.round(((total - unpaid) / total) * 100) : 0;
  const late = pending.filter(
    (bill) => billStatus(bill, today).kind === "late",
  ).length;
  const soon = pending.filter(
    (bill) => billStatus(bill, today).kind === "soon",
  ).length;
  const allLate = data.bills.filter(
    (bill) => billStatus(bill, today).kind === "late",
  ).length;
  const increases = monthly.filter((bill) =>
    ["unusual", "increased"].includes(analyzeBill(bill, data.bills).kind),
  );
  const serviceById = (id) =>
    data.services.find((service) => service.id === id);

  useEffect(() => {
    const updateOnline = () => setOnline(navigator.onLine);
    const refreshToday = () => setToday(isoDate());
    const beforeInstall = (event) => {
      event.preventDefault();
      setInstallPrompt(event);
    };
    const installed = () => setInstallPrompt(null);
    window.addEventListener("online", updateOnline);
    window.addEventListener("offline", updateOnline);
    window.addEventListener("focus", refreshToday);
    window.addEventListener("beforeinstallprompt", beforeInstall);
    window.addEventListener("appinstalled", installed);
    const timer = setInterval(refreshToday, 60000);
    return () => {
      clearInterval(timer);
      window.removeEventListener("online", updateOnline);
      window.removeEventListener("offline", updateOnline);
      window.removeEventListener("focus", refreshToday);
      window.removeEventListener("beforeinstallprompt", beforeInstall);
      window.removeEventListener("appinstalled", installed);
    };
  }, []);

  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(""), 4500);
    return () => clearTimeout(timer);
  }, [toast]);

  useEffect(() => {
    if (!reminders || notificationState !== "granted") return;
    // 🐴 Recordatorios al abrir o mantener la app activa. Push con backend para avisos con la app cerrada.
    const due = data.bills.filter(
      (bill) =>
        !bill.paid && ["late", "soon"].includes(billStatus(bill, today).kind),
    );
    if (!due.length) return;
    try {
      const key = `aldia_notice_${today}`;
      const signature = due
        .map((bill) => `${bill.id}:${bill.due_date}`)
        .sort()
        .join("|");
      if (localStorage.getItem(key) === signature) return;
      navigator.serviceWorker?.ready
        .then((registration) =>
          registration.showNotification("AlDía · Revisa tus vencimientos", {
            body: `Tienes ${due.length} recibo(s) próximo(s) o vencido(s). Abre AlDía para revisarlos.`,
            icon: "/icon-192.png",
            tag: "aldia-reminder",
          }),
        )
        .then(() => localStorage.setItem(key, signature))
        .catch(() =>
          setToast(
            "No se pudo mostrar el aviso. Revisa tus vencimientos en Resumen.",
          ),
        );
    } catch {
      /* La lista de vencimientos sigue disponible sin notificaciones del sistema. */
    }
  }, [data, today, reminders, notificationState]);

  function commit(next, message = "Cambios guardados") {
    if (recoveryRequired) {
      setToast(
        "Recupera un respaldo válido o confirma el reinicio en Ajustes.",
      );
      return false;
    }
    try {
      const safe = validateData(next);
      localStorage.setItem(STORAGE_KEY, JSON.stringify(safe));
      setData(safe);
      setStorageError("");
      setToast(message);
      setModal(null);
      return true;
    } catch (error) {
      setStorageError(`No se guardaron los cambios. ${error.message}`);
      setToast("No pudimos guardar. Los datos anteriores siguen intactos.");
      return false;
    }
  }

  function changeMonth(delta) {
    const [year, number] = month.split("-").map(Number);
    const next = isoDate(new Date(year, number - 1 + delta, 2)).slice(0, 7);
    if (next >= "2000-01" && next <= "2100-12") setMonth(next);
    setDay(null);
  }

  function openNewBill() {
    if (!data.services.length) {
      setModal({ type: "service" });
      setToast("Primero agrega el servicio que quieres controlar.");
    } else setModal({ type: "bill" });
  }

  async function toggleReminders() {
    try {
      if (reminders) {
        localStorage.setItem("aldia_reminders", "false");
        setReminders(false);
        return;
      }
      if (!("Notification" in window)) {
        setToast(
          "Este navegador no permite avisos. Usa los recordatorios de Resumen.",
        );
        return;
      }
      const permission = await Notification.requestPermission();
      setNotificationState(permission);
      if (permission === "granted") {
        localStorage.setItem("aldia_reminders", "true");
        setReminders(true);
        setToast("Avisos activados para cuando uses la app.");
      } else
        setToast(
          "Sin permiso para notificaciones. Los recordatorios de Resumen siguen activos.",
        );
    } catch {
      setToast("No se pudieron activar los avisos en este navegador.");
    }
  }

  function downloadBackup(raw = false) {
    try {
      const content = raw
        ? localStorage.getItem(STORAGE_KEY)
        : JSON.stringify(data, null, 2);
      if (!content) {
        setToast("No hay datos guardados para exportar.");
        return;
      }
      const url = URL.createObjectURL(
        new Blob([content], { type: "application/json" }),
      );
      const link = document.createElement("a");
      link.href = url;
      link.download = `aldia-${today}${raw ? "-recuperacion" : ""}.json`;
      link.click();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    } catch {
      setToast("El navegador bloqueó la descarga del respaldo.");
    }
  }

  async function readBackup(event) {
    const file = event.target.files[0];
    event.target.value = "";
    if (!file) return;
    try {
      if (file.size > 5000000)
        throw new Error("El archivo debe ocupar menos de 5 MB.");
      const incoming = validateData(JSON.parse(await file.text()));
      setModal({
        type: "confirm",
        title: "¿Restaurar el respaldo?",
        text: `Reemplazará tus datos actuales por ${incoming.services.length} servicios y ${incoming.bills.length} recibos. Descarga un respaldo antes si quieres conservarlos.`,
        action: () => {
          try {
            localStorage.setItem(STORAGE_KEY, JSON.stringify(incoming));
            setData(incoming);
            setStorageError("");
            setRecoveryRequired(false);
            setModal(null);
            setToast("Respaldo restaurado.");
          } catch {
            setToast("No se pudo guardar el respaldo. Tus datos no cambiaron.");
          }
        },
      });
    } catch (error) {
      setToast(`No se importó el archivo. ${error.message}`);
    }
  }

  function billList(bills, empty = "No hay recibos para mostrar.") {
    if (!bills.length)
      return (
        <div className="empty-small">
          <Icon name="check" />
          <p>{empty}</p>
        </div>
      );
    return (
      <div className="bill-list">
        {bills.map((bill) => {
          const service = serviceById(bill.service_id);
          const status = billStatus(bill, today);
          const analysis = analyzeBill(bill, data.bills);
          return (
            <button
              className="bill-row"
              key={bill.id}
              onClick={() => setModal({ type: "detail", id: bill.id })}
            >
              <span
                className={`service-icon ${service.category.toLowerCase()}`}
              >
                <Icon name={categoryIcon(service.category)} />
              </span>
              <span className="bill-copy">
                <strong>{service.name}</strong>
                <span>
                  {dateLabel(bill.due_date)}{" "}
                  <span className={`status-dot ${status.kind}`} />{" "}
                  {status.label}
                </span>
                {analysis.kind === "unusual" && (
                  <span className="increase-note">
                    <Icon name="arrow" size={13} />{" "}
                    {analysis.variation.toFixed(0)}% más de lo habitual
                  </span>
                )}
              </span>
              <span className="bill-amount">
                {money(bill.amount)}
                <Icon name="right" size={16} />
              </span>
            </button>
          );
        })}
      </div>
    );
  }

  const selectedBill =
    modal?.type === "detail"
      ? data.bills.find((bill) => bill.id === modal.id)
      : null;
  const analysis = selectedBill ? analyzeBill(selectedBill, data.bills) : null;
  const daysInMonth = new Date(
    Number(month.slice(0, 4)),
    Number(month.slice(5, 7)),
    0,
  ).getDate();
  const firstDay = (new Date(`${month}-01T12:00:00`).getDay() + 6) % 7;

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <a
          className="brand"
          href="#"
          onClick={(e) => {
            e.preventDefault();
            setView("home");
          }}
          aria-label="AlDía, ir al resumen"
        >
          <span className="brand-mark">
            <Icon name="check" />
          </span>
          AlDía<span className="brand-period">.</span>
        </a>
        <p className="brand-caption">Tus recibos, bajo control.</p>
        <nav aria-label="Navegación principal">
          {navItems.map(([key, label, icon]) => (
            <button
              key={key}
              className={view === key ? "nav-item active" : "nav-item"}
              aria-current={view === key ? "page" : undefined}
              onClick={() => {
                setView(key);
                setFilter("all");
              }}
            >
              <Icon name={icon} />
              <span>{label}</span>
            </button>
          ))}
        </nav>
        <div className="sidebar-bottom">
          <div className="privacy-note">
            <Icon name="shield" />
            <p>
              Tu hogar. Tus datos.<span>Guardados en este dispositivo.</span>
            </p>
          </div>
          <button
            className="nav-item"
            onClick={() => setModal({ type: "settings" })}
          >
            <Icon name="settings" />
            Ajustes y respaldos
          </button>
        </div>
      </aside>

      <div className="main-wrap">
        <header className="topbar">
          <a
            className="brand mobile-brand"
            href="#"
            onClick={(e) => {
              e.preventDefault();
              setView("home");
            }}
          >
            <span className="brand-mark">
              <Icon name="check" />
            </span>
            AlDía.
          </a>
          <span className="desktop-top-label">
            Un poco de orden, más tranquilidad.
          </span>
          <div className="top-actions">
            <span className="device-label">
              <span className={`status-dot ${online ? "paid" : "soon"}`} />
              {online ? "Guardado local" : "Sin conexión"}
            </span>
            <button
              className="icon-button"
              aria-label="Ajustes y respaldos"
              onClick={() => setModal({ type: "settings" })}
            >
              <Icon name="settings" />
            </button>
          </div>
        </header>
        <main>
          {storageError && (
            <div className="notice error" role="alert">
              {storageError}{" "}
              <button onClick={() => setModal({ type: "settings" })}>
                Abrir ajustes
              </button>
            </div>
          )}
          {needRefresh && (
            <div className="notice">
              Hay una nueva versión. Guarda y cierra cualquier formulario antes
              de actualizar.
              <button onClick={() => updateServiceWorker(true)}>
                Actualizar
              </button>
              <button onClick={() => setNeedRefresh(false)}>Después</button>
            </div>
          )}
          {data.demo && (
            <div className="demo-banner">
              <span>Estás viendo datos de ejemplo. No son recibos reales.</span>
              <button onClick={() => setModal({ type: "settings" })}>
                Gestionar datos
              </button>
            </div>
          )}
          <div className="page-heading">
            <div>
              <p className="section-kicker">
                {view === "home" ? "Tu hogar, al día" : "Cada recibo cuenta"}
              </p>
              <h1>{navItems.find(([key]) => key === view)[1]}</h1>
              <p className="muted">
                {
                  {
                    home: "Lo importante de este mes, en un solo lugar.",
                    calendar:
                      "Organiza tu mes sin perder de vista un vencimiento.",
                    services: "Los gastos que vuelven cada mes.",
                    history: "Conoce cuánto pagas y cómo cambia con el tiempo.",
                  }[view]
                }
              </p>
            </div>
            <button
              className="primary new-button"
              onClick={
                view === "services"
                  ? () => setModal({ type: "service" })
                  : openNewBill
              }
            >
              <Icon name="plus" size={19} />
              {view === "services" ? "Nuevo servicio" : "Nuevo recibo"}
            </button>
          </div>

          {!data.services.length ? (
            <section className="welcome panel">
              <div className="welcome-icon">
                <Icon name="receipt" size={36} />
              </div>
              <h2>Un lugar para todos tus recibos.</h2>
              <p>
                Agrega tu primer servicio y empieza a organizar los pagos del
                hogar. Sin cuentas, sin conectar tu banco.
              </p>
              <button
                className="primary"
                onClick={() => setModal({ type: "service" })}
              >
                <Icon name="plus" size={18} />
                Agregar mi primer servicio
              </button>
              <button
                className="text-button"
                onClick={() =>
                  commit(
                    demoData(),
                    "Ejemplo cargado. Puedes borrarlo desde Ajustes.",
                  )
                }
              >
                Explorar con datos de ejemplo
              </button>
              <div className="welcome-benefits">
                <span>
                  <Icon name="calendar" />
                  Recuerda fechas
                </span>
                <span>
                  <Icon name="arrow" />
                  Detecta aumentos
                </span>
                <span>
                  <Icon name="shield" />
                  Conserva tus datos
                </span>
              </div>
            </section>
          ) : (
            <>
              {view !== "services" && (
                <div className="month-controls">
                  <div className="month-picker">
                    <button
                      className="icon-button"
                      aria-label="Mes anterior"
                      onClick={() => changeMonth(-1)}
                    >
                      <Icon name="left" size={18} />
                    </button>
                    <span>{monthLabel(month)}</span>
                    <button
                      className="icon-button"
                      aria-label="Mes siguiente"
                      onClick={() => changeMonth(1)}
                    >
                      <Icon name="right" size={18} />
                    </button>
                  </div>
                  {month !== today.slice(0, 7) && (
                    <button
                      className="text-button"
                      onClick={() => {
                        setMonth(today.slice(0, 7));
                        setDay(null);
                      }}
                    >
                      Volver a este mes
                    </button>
                  )}
                  <span className="month-count">
                    {monthly.length}{" "}
                    {monthly.length === 1 ? "recibo" : "recibos"}
                  </span>
                </div>
              )}

              {view === "home" && (
                <>
                  <section
                    className="summary-grid"
                    aria-label="Resumen mensual"
                  >
                    <div className="balance panel">
                      <div className="balance-label">
                        Por pagar este mes{" "}
                        <span className="balance-icon">
                          <Icon name="receipt" />
                        </span>
                      </div>
                      <strong className="big-amount">{money(unpaid)}</strong>
                      <span className="muted">
                        {pending.length}{" "}
                        {pending.length === 1
                          ? "recibo pendiente"
                          : "recibos pendientes"}
                      </span>
                      <div className="balance-foot">
                        <span
                          className={`status-pill ${late ? "late" : soon ? "soon" : "paid"}`}
                        >
                          <Icon
                            name={late || soon ? "bell" : "check"}
                            size={14}
                          />
                          {late
                            ? `${late} vencido(s)`
                            : soon
                              ? `${soon} próximo(s) a vencer`
                              : "Sin pagos urgentes este mes"}
                        </span>
                      </div>
                    </div>
                    <div className="progress-card panel">
                      <h2>Así va tu mes</h2>
                      <div className="progress-head">
                        <strong>{progress}%</strong>
                        <span>del monto pagado</span>
                      </div>
                      <progress
                        max="100"
                        value={progress}
                        aria-label="Porcentaje del monto pagado"
                      />
                      <div className="progress-values">
                        <div>
                          <span>
                            <i className="legend-dot green" />
                            Pagado
                          </span>
                          <strong>{money(total - unpaid)}</strong>
                        </div>
                        <div>
                          <span>
                            <i className="legend-dot pale" />
                            Total del mes
                          </span>
                          <strong>{money(total)}</strong>
                        </div>
                      </div>
                    </div>
                  </section>
                  {allLate > late && (
                    <div className="notice error">
                      También tienes {allLate - late} recibo(s) vencido(s) en
                      otros meses. Puedes revisarlos en Historial.
                    </div>
                  )}
                  <div className="home-grid">
                    <section className="panel">
                      <div className="panel-heading">
                        <h2>Próximos pagos</h2>
                        <button
                          className="text-button"
                          onClick={() => setView("calendar")}
                        >
                          Ver calendario
                        </button>
                      </div>
                      {billList(
                        pending,
                        monthly.length
                          ? "Todo pagado este mes. Una cosa menos."
                          : "Todavía no registraste recibos este mes.",
                      )}
                    </section>
                    <section className="insights panel">
                      <div className="panel-heading">
                        <h2>Ojo con estos montos</h2>
                        <Icon name="arrow" size={20} />
                      </div>
                      <p className="muted small">
                        Comparamos con los 3 recibos anteriores de cada
                        servicio.
                      </p>
                      {increases.length ? (
                        increases.map((bill) => {
                          const info = analyzeBill(bill, data.bills);
                          return (
                            <button
                              className={`insight-item ${info.kind}`}
                              key={bill.id}
                              onClick={() =>
                                setModal({ type: "detail", id: bill.id })
                              }
                            >
                              <span className="insight-label">
                                {serviceById(bill.service_id).name}
                                <span>+{info.variation.toFixed(1)}%</span>
                              </span>
                              <strong>{info.label}</strong>
                              <span>
                                Promedio anterior: {money(info.average)}
                              </span>
                              <span className="insight-link">
                                Revisar recibo <Icon name="right" size={14} />
                              </span>
                            </button>
                          );
                        })
                      ) : (
                        <div className="insight-empty">
                          <Icon name="check" />
                          <p>Sin aumentos para señalar.</p>
                          <span>
                            La comparación aparecerá cuando tengas tres recibos
                            anteriores.
                          </span>
                        </div>
                      )}
                      <p className="insight-disclaimer">
                        Una variación del monto no necesariamente significa
                        mayor consumo.
                      </p>
                    </section>
                  </div>
                  <div className="reminder-strip">
                    <span className="reminder-symbol">
                      <Icon name="bell" />
                    </span>
                    <div>
                      <strong>No dejes los vencimientos para después.</strong>
                      <p>
                        Avisos al abrir la app o mientras la mantengas activa.
                      </p>
                    </div>
                    <button className="secondary" onClick={toggleReminders}>
                      {reminders ? "Desactivar avisos" : "Activar avisos"}
                    </button>
                  </div>
                </>
              )}

              {view === "calendar" && (
                <div className="calendar-grid">
                  <section className="panel calendar-panel">
                    <div className="panel-heading">
                      <h2>Calendario de vencimientos</h2>
                      <button
                        className="text-button"
                        onClick={() => {
                          setMonth(today.slice(0, 7));
                          setDay(Number(today.slice(-2)));
                        }}
                      >
                        Hoy
                      </button>
                    </div>
                    <div
                      className="calendar"
                      role="group"
                      aria-label={monthLabel(month)}
                    >
                      {["L", "M", "M", "J", "V", "S", "D"].map(
                        (label, index) => (
                          <span className="weekday" key={index}>
                            {label}
                          </span>
                        ),
                      )}
                      {Array.from({ length: firstDay }, (_, index) => (
                        <span key={`blank-${index}`} />
                      ))}
                      {Array.from({ length: daysInMonth }, (_, index) => {
                        const number = index + 1;
                        const date = `${month}-${String(number).padStart(2, "0")}`;
                        const list = monthly.filter(
                          (bill) => bill.due_date === date,
                        );
                        return (
                          <button
                            key={number}
                            aria-label={`${number} de ${monthLabel(month)}, ${list.length} recibos`}
                            aria-pressed={day === number}
                            className={`calendar-day ${day === number ? "selected" : ""} ${date === today ? "today" : ""}`}
                            onClick={() =>
                              setDay(day === number ? null : number)
                            }
                          >
                            <span>{number}</span>
                            <span className="calendar-dots">
                              {list.slice(0, 3).map((bill) => (
                                <i
                                  key={bill.id}
                                  className={`status-dot ${billStatus(bill, today).kind}`}
                                />
                              ))}
                              {list.length > 3 && <small>+</small>}
                            </span>
                          </button>
                        );
                      })}
                    </div>
                    <div className="calendar-legend">
                      <span>
                        <i className="status-dot paid" />
                        Pagado
                      </span>
                      <span>
                        <i className="status-dot pending" />
                        Pendiente
                      </span>
                      <span>
                        <i className="status-dot late" />
                        Vencido
                      </span>
                    </div>
                  </section>
                  <section className="panel">
                    <div className="panel-heading">
                      <h2>{day ? `Vence el ${day}` : "Agenda del mes"}</h2>
                      {day && (
                        <button
                          className="text-button"
                          onClick={() => setDay(null)}
                        >
                          Ver todo
                        </button>
                      )}
                    </div>
                    {billList(
                      day
                        ? monthly.filter(
                            (bill) => Number(bill.due_date.slice(-2)) === day,
                          )
                        : monthly,
                      "No hay vencimientos para esta fecha.",
                    )}
                  </section>
                </div>
              )}

              {view === "services" && (
                <>
                  <div className="services-grid">
                    {data.services.map((service) => {
                      const bills = data.bills
                        .filter((bill) => bill.service_id === service.id)
                        .sort((a, b) => b.due_date.localeCompare(a.due_date));
                      const latest = bills[0];
                      return (
                        <section
                          className="panel service-card"
                          key={service.id}
                        >
                          <div className="service-card-top">
                            <span
                              className={`service-icon ${service.category.toLowerCase()}`}
                            >
                              <Icon name={categoryIcon(service.category)} />
                            </span>
                            <span className="category-label">
                              {service.category}
                            </span>
                            <button
                              className="icon-button"
                              aria-label={`Editar ${service.name}`}
                              onClick={() =>
                                setModal({ type: "service", initial: service })
                              }
                            >
                              <Icon name="settings" size={18} />
                            </button>
                          </div>
                          <h2>{service.name}</h2>
                          <p className="muted small">
                            {bills.length}{" "}
                            {bills.length === 1
                              ? "recibo registrado"
                              : "recibos registrados"}
                          </p>
                          <div className="service-latest">
                            <span>Último recibo</span>
                            <strong>
                              {latest ? money(latest.amount) : "Sin recibos"}
                            </strong>
                            {latest && (
                              <span>
                                {dateLabel(latest.due_date)} de{" "}
                                {latest.due_date.slice(0, 4)}
                              </span>
                            )}
                          </div>
                          <div className="service-card-actions">
                            <button
                              className="secondary"
                              onClick={() =>
                                setModal({
                                  type: "bill",
                                  initial: { service_id: service.id },
                                })
                              }
                            >
                              <Icon name="plus" size={16} />
                              Registrar recibo
                            </button>
                            <button
                              className="text-button danger-text"
                              onClick={() =>
                                setModal({
                                  type: "confirm",
                                  title: `¿Eliminar ${service.name}?`,
                                  text: `Se eliminarán el servicio y sus ${bills.length} recibos. Esta acción no se puede deshacer.`,
                                  action: () =>
                                    commit(
                                      {
                                        ...data,
                                        services: data.services.filter(
                                          (item) => item.id !== service.id,
                                        ),
                                        bills: data.bills.filter(
                                          (bill) =>
                                            bill.service_id !== service.id,
                                        ),
                                      },
                                      "Servicio eliminado.",
                                    ),
                                })
                              }
                            >
                              Eliminar
                            </button>
                          </div>
                        </section>
                      );
                    })}
                  </div>
                  <div className="quiet-note">
                    <Icon name="shield" size={18} />
                    <span>
                      No conectamos tu banco ni realizamos pagos. Tú eliges
                      dónde pagar.
                    </span>
                  </div>
                </>
              )}

              {view === "history" && (
                <section className="panel">
                  <div className="panel-heading history-heading">
                    <h2>Recibos de {monthLabel(month)}</h2>
                    <div className="filter-chips" aria-label="Filtrar recibos">
                      {[
                        ["all", "Todos"],
                        ["pending", "Pendientes"],
                        ["paid", "Pagados"],
                      ].map(([key, label]) => (
                        <button
                          key={key}
                          aria-pressed={filter === key}
                          className={filter === key ? "selected" : ""}
                          onClick={() => setFilter(key)}
                        >
                          {label}
                        </button>
                      ))}
                    </div>
                  </div>
                  {billList(
                    monthly.filter(
                      (bill) =>
                        filter === "all" ||
                        (filter === "paid" ? bill.paid : !bill.paid),
                    ),
                    "No hay recibos con este filtro.",
                  )}
                  <div className="history-total">
                    <span>Total registrado este mes</span>
                    <strong>{money(total)}</strong>
                  </div>
                </section>
              )}
            </>
          )}
          <footer className="app-footer">
            <span>AlDía acompaña tus pagos. No los realiza.</span>
            {offlineReady && (
              <span>
                <Icon name="check" size={13} />
                Disponible sin conexión
              </span>
            )}
          </footer>
        </main>
      </div>
      <nav className="bottom-nav" aria-label="Navegación móvil">
        {navItems.map(([key, label, icon]) => (
          <button
            key={key}
            aria-current={view === key ? "page" : undefined}
            className={view === key ? "active" : ""}
            onClick={() => {
              setView(key);
              setFilter("all");
            }}
          >
            <Icon name={icon} size={21} />
            <span>{label}</span>
          </button>
        ))}
      </nav>
      {toast && (
        <div className="toast" role="status">
          {toast}
          <button aria-label="Cerrar aviso" onClick={() => setToast("")}>
            <Icon name="close" size={16} />
          </button>
        </div>
      )}

      {modal?.type === "service" && (
        <ServiceForm
          data={data}
          initial={modal.initial}
          onClose={() => setModal(null)}
          onSave={(next) => commit(next, "Servicio guardado.")}
        />
      )}
      {modal?.type === "bill" && (
        <BillForm
          data={data}
          initial={modal.initial}
          key={modal.initial?.service_id || "new"}
          month={month}
          onClose={() => setModal(null)}
          onSave={(next) => commit(next, "Recibo guardado.")}
        />
      )}
      {selectedBill && (
        <Modal
          title={serviceById(selectedBill.service_id).name}
          onClose={() => setModal(null)}
        >
          <div className="detail-amount">
            <strong>{money(selectedBill.amount)}</strong>
            <span>
              Vencimiento: {dateLabel(selectedBill.due_date)} de{" "}
              {selectedBill.due_date.slice(0, 4)}
            </span>
            <span
              className={`status-pill ${billStatus(selectedBill, today).kind}`}
            >
              {billStatus(selectedBill, today).label}
              {selectedBill.paid_at
                ? ` el ${dateLabel(selectedBill.paid_at)}`
                : ""}
            </span>
          </div>
          <section className={`analysis-box ${analysis.kind}`}>
            <div className="analysis-heading">
              <h3>{analysis.label}</h3>
              {analysis.variation !== null && (
                <strong>
                  {analysis.variation >= 0 ? "+" : ""}
                  {analysis.variation.toFixed(1)}%
                </strong>
              )}
            </div>
            {analysis.average !== null && (
              <p>
                Promedio de los tres anteriores:{" "}
                <strong>{money(analysis.average)}</strong>
              </p>
            )}
            <div className="mini-chart">
              {[...analysis.previous]
                .reverse()
                .concat(selectedBill)
                .map((bill) => (
                  <div key={bill.id}>
                    <span>{money(bill.amount)}</span>
                    <i
                      style={{
                        height: `${Math.max(5, (bill.amount / Math.max(selectedBill.amount, ...analysis.previous.map((item) => item.amount))) * 72)}px`,
                      }}
                      className={bill.id === selectedBill.id ? "current" : ""}
                    />
                    <small>
                      {new Intl.DateTimeFormat("es-PE", {
                        month: "short",
                      }).format(new Date(`${bill.due_date}T12:00:00`))}
                    </small>
                  </div>
                ))}
            </div>
            <p className="small muted">
              Comparamos montos, no consumo. Revisa tu recibo o consulta a tu
              proveedor si no reconoces el aumento.
            </p>
          </section>
          <div className="detail-actions">
            <button
              className="primary full"
              onClick={() =>
                commit(
                  {
                    ...data,
                    bills: data.bills.map((bill) =>
                      bill.id === selectedBill.id
                        ? {
                            ...bill,
                            paid: !bill.paid,
                            paid_at: bill.paid ? null : today,
                          }
                        : bill,
                    ),
                  },
                  selectedBill.paid
                    ? "Recibo marcado como pendiente."
                    : "Pago registrado.",
                )
              }
            >
              <Icon name="check" size={18} />
              {selectedBill.paid ? "Volver a pendiente" : "Marcar como pagado"}
            </button>
            <button
              className="secondary full"
              onClick={() => setModal({ type: "bill", initial: selectedBill })}
            >
              Editar recibo
            </button>
            <button
              className="text-button danger-text"
              onClick={() =>
                setModal({
                  type: "confirm",
                  title: "¿Eliminar este recibo?",
                  text: "Se eliminará del historial y del resumen. Esta acción no se puede deshacer.",
                  action: () =>
                    commit(
                      {
                        ...data,
                        bills: data.bills.filter(
                          (bill) => bill.id !== selectedBill.id,
                        ),
                      },
                      "Recibo eliminado.",
                    ),
                })
              }
            >
              Eliminar recibo
            </button>
          </div>
        </Modal>
      )}
      {modal?.type === "confirm" && (
        <Modal title={modal.title} onClose={() => setModal(null)}>
          <p className="confirm-copy">{modal.text}</p>
          <div className="confirm-actions">
            <button className="secondary" onClick={() => setModal(null)}>
              Cancelar
            </button>
            <button className="primary" onClick={modal.action}>
              Confirmar
            </button>
          </div>
        </Modal>
      )}
      {modal?.type === "settings" && (
        <Modal title="Ajustes y respaldos" onClose={() => setModal(null)}>
          <p className="muted">
            Los datos se guardan solo en este navegador. No hay sincronización
            entre dispositivos.
          </p>
          <section className="settings-section">
            <h3>Conserva una copia</h3>
            <p className="small muted">
              Borrar los datos del navegador elimina tus recibos. Descarga un
              respaldo regularmente.
            </p>
            <button className="secondary full" onClick={() => downloadBackup()}>
              <Icon name="download" size={18} />
              Descargar respaldo
            </button>
            {storageError && (
              <button
                className="secondary full"
                onClick={() => downloadBackup(true)}
              >
                Descargar datos originales para recuperar
              </button>
            )}
            <label className="upload-label">
              Restaurar desde un archivo JSON
              <input
                type="file"
                accept="application/json,.json"
                onChange={readBackup}
              />
            </label>
          </section>
          <section className="settings-section">
            <h3>Recordatorios</h3>
            <p className="small muted">
              Avisos al abrir AlDía o mientras está activa. No se envían con la
              app cerrada. En iPhone pueden requerir instalarla en la pantalla
              de inicio.
            </p>
            <button
              className="secondary full"
              disabled={notificationState === "unsupported"}
              onClick={toggleReminders}
            >
              {reminders ? "Desactivar avisos" : "Activar avisos del navegador"}
            </button>
            <span className="small muted">
              Permiso:{" "}
              {
                {
                  granted: "concedido",
                  denied: "bloqueado; cámbialo en los ajustes del navegador",
                  default: "sin solicitar",
                  unsupported: "no compatible",
                }[notificationState]
              }
            </span>
          </section>
          <section className="settings-section">
            <h3>Instalar AlDía</h3>
            {installPrompt ? (
              <button
                className="primary full"
                onClick={async () => {
                  await installPrompt.prompt();
                  await installPrompt.userChoice;
                  setInstallPrompt(null);
                }}
              >
                Instalar en este dispositivo
              </button>
            ) : (
              <p className="small muted">
                En Chrome: menú → Instalar aplicación. En Safari: Compartir →
                Añadir a pantalla de inicio. Disponible desde HTTPS después de
                la primera carga.
              </p>
            )}
          </section>
          <button
            className="text-button danger-text"
            onClick={() =>
              setModal({
                type: "confirm",
                title: "¿Borrar todos los datos?",
                text: "Se eliminarán todos los servicios y recibos de este navegador. Descarga un respaldo antes de continuar.",
                action: () => {
                  try {
                    localStorage.setItem(
                      STORAGE_KEY,
                      JSON.stringify(emptyData()),
                    );
                    setData(emptyData());
                    setStorageError("");
                    setRecoveryRequired(false);
                    setModal(null);
                    setToast("Datos eliminados. Puedes empezar de nuevo.");
                  } catch {
                    setToast("No se pudieron borrar los datos.");
                  }
                },
              })
            }
          >
            Borrar todos los datos
          </button>
        </Modal>
      )}
    </div>
  );
}
