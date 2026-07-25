/* ui.jsx — shared primitives for 省钱搭子 app kit */
const { useState, useEffect, useRef } = React;

/* ---- Lucide icon (React-safe: fills a managed span via innerHTML) ---- */
function Icon({ name, size = 24, color, style, className }) {
  const ref = useRef(null);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    el.innerHTML = `<i data-lucide="${name}"></i>`;
    if (window.lucide) lucide.createIcons({ nameAttr: "data-lucide" });
  }, [name]);
  return <span ref={ref} className={"lic " + (className || "")}
    style={{ width: size, height: size, color, ...style }} />;
}

/* ---- Category metadata (single source of truth) ----
   Expense + income categories. Legacy keys (shop/home/phone/save) are
   kept so existing seed data and budget rows still render. The add
   sheet offers EXPENSE_CATS / INCOME_CATS (ordered) below. */
const CATS = {
  /* ---- expense (required set) ---- */
  food:    { zh: "餐饮",     icon: "utensils",        tint: "var(--orange-50)", fg: "var(--orange-500)" },
  transit: { zh: "交通",     icon: "bus-front",       tint: "var(--blue-50)",   fg: "var(--blue-500)" },
  study:   { zh: "学习",     icon: "book-open",       tint: "var(--blue-50)",   fg: "var(--blue-500)" },
  daily:   { zh: "生活用品", icon: "shopping-basket", tint: "var(--green-50)",  fg: "var(--green-600)" },
  fun:     { zh: "娱乐",     icon: "gamepad-2",       tint: "var(--orange-50)", fg: "var(--orange-600)" },
  medical: { zh: "医疗",     icon: "heart-pulse",     tint: "var(--red-50)",    fg: "var(--red-500)" },
  other:   { zh: "其他",     icon: "shapes",          tint: "var(--surface-2)", fg: "var(--ink-500)" },
  /* ---- legacy expense keys (kept for old data + budgets) ---- */
  shop:    { zh: "购物",     icon: "shopping-bag",    tint: "var(--green-50)",  fg: "var(--green-600)" },
  home:    { zh: "居住",     icon: "house",           tint: "var(--blue-50)",   fg: "var(--blue-600)" },
  phone:   { zh: "话费",     icon: "smartphone",      tint: "var(--green-50)",  fg: "var(--green-600)" },
  save:    { zh: "储蓄",     icon: "piggy-bank",      tint: "var(--green-50)",  fg: "var(--green-600)" },
  /* ---- income (generic + subcategories) ---- */
  income:       { zh: "收入",     icon: "wallet",          tint: "var(--green-50)", fg: "var(--green-600)" },
  allowance:    { zh: "零花钱",   icon: "wallet",          tint: "var(--green-50)", fg: "var(--green-600)" },
  scholarship:  { zh: "奖学金",   icon: "award",           tint: "var(--green-50)", fg: "var(--green-600)" },
  parttime:     { zh: "兼职",     icon: "briefcase",       tint: "var(--green-50)", fg: "var(--green-600)" },
  family:       { zh: "家人转入", icon: "heart-handshake", tint: "var(--green-50)", fg: "var(--green-600)" },
  refund:       { zh: "退款",     icon: "rotate-ccw",      tint: "var(--green-50)", fg: "var(--green-600)" },
  income_other: { zh: "其他",     icon: "ellipsis",        tint: "var(--green-50)", fg: "var(--green-600)" },
};

/* ordered category lists used by the 记一笔 add sheet */
const EXPENSE_CATS = ["food", "transit", "study", "daily", "fun", "medical", "other"];
const INCOME_CATS  = ["allowance", "scholarship", "parttime", "family", "refund", "income_other"];

function CatTile({ cat, lg }) {
  const c = CATS[cat] || CATS.food;
  return <div className={"cat-tile" + (lg ? " lg" : "")} style={{ background: c.tint }}>
    <Icon name={c.icon} color={c.fg} />
  </div>;
}

/* ---- Money formatter ---- */
function Yen({ v, sign, className, style }) {
  const s = sign === "+" ? "+" : sign === "-" ? "−" : "";
  return <span className={className} style={{ fontFamily: "var(--font-num)", ...style }}>
    {s}¥{v}
  </span>;
}

/* ---- Status bar ---- */
function StatusBar() {
  return <div className="statusbar">
    <span>9:41</span>
    <div className="right">
      <Icon name="signal" size={16} />
      <Icon name="wifi" size={16} />
      <Icon name="battery-full" size={20} />
    </div>
  </div>;
}

/* ---- Button ---- */
function Button({ kind = "primary", block, icon, children, onClick, style }) {
  return <button className={`btn btn-${kind}${block ? " btn-block" : ""}`} onClick={onClick} style={style}>
    {icon && <Icon name={icon} size={20} />}{children}
  </button>;
}

/* ---- Progress bar ---- */
function Bar({ label, right, pct, color = "var(--blue-500)" }) {
  const [w, setW] = useState(0);
  useEffect(() => { const t = setTimeout(() => setW(pct), 80); return () => clearTimeout(t); }, [pct]);
  return <div style={{ marginBottom: 0 }}>
    <div className="bar-head"><span className="l">{label}</span><span className="r">{right}</span></div>
    <div className="track"><div className="fill" style={{ width: w + "%", background: color }} /></div>
  </div>;
}

/* ---- Goal ring ---- */
function Ring({ pct, size = 132, stroke = 6, color = "var(--ink-900)", track = "var(--surface-2)", children }) {
  const r = (size - stroke) / 2;
  const C = 2 * Math.PI * r;
  const [off, setOff] = useState(C);
  useEffect(() => { const t = setTimeout(() => setOff(C * (1 - pct / 100)), 120); return () => clearTimeout(t); }, [pct, C]);
  return <div className="ring" style={{ width: size, height: size }}>
    <svg width={size} height={size}>
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={track} strokeWidth={stroke} />
      <circle className="fg" cx={size/2} cy={size/2} r={r} fill="none" stroke={color}
        strokeWidth={stroke} strokeLinecap="round" strokeDasharray={C} strokeDashoffset={off} />
    </svg>
    <div className="center">{children}</div>
  </div>;
}

/* ---- Bottom tab bar (5 main tabs) ---- */
const TABS = [
  { id: "home",  icon: "house",        label: "首页" },
  { id: "learn", icon: "book-open",    label: "故事" },
  { id: "track", icon: "notebook-pen", label: "记账" },
  { id: "ai",    icon: "message-circle", label: "AI搭子" },
  { id: "me",    icon: "user",         label: "我的" },
];
function TabBar({ active, onNav }) {
  return <div className="tabbar">
    {TABS.map((t) => (
      <button key={t.id} className={"tab" + (active === t.id ? " on" : "")} onClick={() => onNav(t.id)}>
        <Icon name={t.icon} /><span>{t.label}</span>
      </button>
    ))}
  </div>;
}

/* ---- Floating 记一笔 quick-add button (replaces the old center FAB) ---- */
function AddFab({ onClick }) {
  return <button className="add-fab" onClick={onClick} aria-label="记录一次选择">
    <Icon name="plus" /><span>记一次选择</span>
  </button>;
}

/* ---- Top bar ---- */
function TopBar({ title, sub, back, onBack, right }) {
  return <div className="topbar">
    {back && <button className="back" onClick={onBack}><Icon name="chevron-left" /></button>}
    <div><h1>{title}</h1>{sub && <div className="sub">{sub}</div>}</div>
    <div className="spacer" />
    {right}
  </div>;
}

Object.assign(window, { Icon, CATS, EXPENSE_CATS, INCOME_CATS, CatTile, Yen, StatusBar, Button, Bar, Ring, TabBar, AddFab, TABS, TopBar });
