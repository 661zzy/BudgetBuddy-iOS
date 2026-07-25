/* screens_detail.jsx — Budget category, AI assistant, Warning, Monthly report, AddSheet (live-state) */
const { useState: useStateD } = React;

/* ---------- BUDGET PAGE (预算) ---------- */
function BudgetCategory({ onBack }) {
  const { state, updateBudget, updateMonthlyBudget } = useStore();
  const rows = selectBudgetRows(state);
  const [editing, setEditing] = useStateD(null);   // category row being edited
  const [editTotal, setEditTotal] = useStateD(false);
  const s = selectStats(state);
  const used = s.monthOut, total = s.monthBudget, left = total - used;
  const pct = total ? Math.round(used / total * 100) : 0;
  const hasBudget = total > 0;
  const daysLeft = new Date(NOW.getFullYear(), NOW.getMonth() + 1, 0).getDate() - NOW.getDate();
  const perDay = daysLeft > 0 ? Math.max(0, Math.round(left / daysLeft)) : Math.max(0, left);
  const overCount = rows.filter(r => r.status === "over").length;
  const fmt = (n) => (n || 0).toLocaleString("en-US");
  const tStatus = pct > 100 ? "over" : pct >= 70 ? "near" : "safe";
  const tMeta = { safe: { zh: "正常", bg: "var(--green-50)", fg: "var(--green-700)", bar: "var(--green-500)" },
    near: { zh: "接近上限", bg: "var(--orange-50)", fg: "var(--orange-700)", bar: "var(--orange-500)" },
    over: { zh: "已超支", bg: "var(--red-50)", fg: "var(--red-600)", bar: "var(--red-500)" } }[tStatus];

  return <div className="screen"><div className="pad">
    <TopBar title="预算" back onBack={onBack} right={hasBudget ? <button className="iconbtn" onClick={() => setEditTotal(true)}><Icon name="pencil" /></button> : null} />

    {!hasBudget ? <div className="card center" style={{ padding: "34px 18px" }}>
      <div className="cat-tile lg" style={{ background: "var(--orange-50)", margin: "0 auto" }}><Icon name="wallet" color="var(--orange-500)" size={26} /></div>
      <div style={{ font: "var(--t-h3)", marginTop: 12 }}>还没有设置预算</div>
      <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 4 }}>设个本月总预算，我来帮你盯着花销</div>
      <Button block icon="wallet" style={{ marginTop: 16 }} onClick={() => setEditTotal(true)}>设置本月预算</Button>
    </div> : <React.Fragment>
      {/* total hero */}
      <div className="card" style={{ background: tStatus === "over" ? "var(--red-50)" : "#fff", borderColor: tStatus === "over" ? "var(--red-100)" : "var(--line)" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
          <div><div style={{ font: "var(--t-body-sm)", color: "var(--fg2)" }}>本月已用 / 总预算</div>
            <div style={{ font: "800 30px/1.1 var(--font-num)", marginTop: 6 }}>
              ¥{fmt(used)} <span style={{ font: "var(--t-body)", color: "var(--fg3)" }}>/ {fmt(total)}</span></div></div>
          <span className="tag" style={{ background: tMeta.bg, color: tMeta.fg }}>{tMeta.zh}</span>
        </div>
        <div className="track" style={{ marginTop: 14, height: 12 }}>
          <div className="fill" style={{ width: Math.min(pct, 100) + "%", background: tMeta.bar }} /></div>
        <div style={{ display: "flex", justifyContent: "space-between", font: "var(--t-caption)", color: "var(--fg2)", marginTop: 10, gap: 8 }}>
          <span style={{ color: left < 0 ? "var(--red-500)" : "var(--green-600)", whiteSpace: "nowrap" }}>{left < 0 ? "已超 ¥" + fmt(-left) : "剩 ¥" + fmt(left)}</span>
          <span style={{ whiteSpace: "nowrap" }}>还剩 {daysLeft} 天 · 约 ¥{fmt(perDay)}/天</span>
        </div>
      </div>

      {overCount > 0 && <div className="alert" style={{ background: "var(--red-50)", color: "var(--red-600)", marginTop: 14 }}>
        <Icon name="triangle-alert" /><span>有 <b>{overCount}</b> 个分类超预算了，下面标红的可以留意一下</span></div>}

      <div className="sec-title">分类预算 <a onClick={() => setEditTotal(true)}>改总额 <Icon name="chevron-right" /></a></div>
      <div className="stack" style={{ gap: 12 }}>
        {rows.map((b) => {
          const meta = b.status === "over" ? { zh: "已超支", bg: "var(--red-50)", fg: "var(--red-600)", bar: "var(--red-500)" }
            : b.status === "near" ? { zh: "接近上限", bg: "var(--orange-50)", fg: "var(--orange-700)", bar: "var(--orange-500)" }
            : b.status === "unset" ? { zh: "未设置", bg: "var(--surface-2)", fg: "var(--ink-500)", bar: "var(--line-strong)" }
            : { zh: "正常", bg: "var(--green-50)", fg: "var(--green-700)", bar: CATS[b.cat].fg };
          return <div className="card" key={b.cat} onClick={() => setEditing(b)} style={{ display: "flex", gap: 13, alignItems: "center", cursor: "pointer" }}>
            <CatTile cat={b.cat} lg />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8, alignItems: "center", gap: 8 }}>
                <span style={{ font: "var(--t-h3)", display: "flex", alignItems: "center", gap: 8, minWidth: 0, whiteSpace: "nowrap" }}>{CATS[b.cat].zh}
                  <span className="tag" style={{ background: meta.bg, color: meta.fg, padding: "3px 8px", flex: "none" }}>{meta.zh}</span></span>
                <span style={{ display: "flex", alignItems: "center", gap: 6, flex: "none" }}>
                  <span style={{ font: "var(--t-caption)", color: b.status === "over" ? "var(--red-500)" : "var(--fg3)", whiteSpace: "nowrap" }}>
                    {b.status === "unset" ? "已用 ¥" + fmt(b.spent) : b.over ? "超 ¥" + fmt(b.spent - b.total) : "¥" + fmt(b.spent) + " / " + fmt(b.total)}</span>
                  <Icon name="pencil" size={14} color="var(--ink-300)" />
                </span>
              </div>
              <div className="track"><div className="fill" style={{ width: Math.min(b.pct, 100) + "%", background: meta.bar }} /></div>
            </div>
          </div>;
        })}
      </div>
    </React.Fragment>}

    <EditBudgetSheet row={editing} onClose={() => setEditing(null)}
      onSave={(cat, total) => { if (updateBudget(cat, total)) setEditing(null); }} />
    <EditTotalSheet show={editTotal} current={total} onClose={() => setEditTotal(false)}
      onSave={(v) => { if (updateMonthlyBudget(v)) setEditTotal(false); }} />
  </div></div>;
}

/* set-the-monthly-total-budget bottom sheet */
function EditTotalSheet({ show, current, onClose, onSave }) {
  const [val, setVal] = useStateD("");
  const [err, setErr] = useStateD("");
  React.useEffect(() => { if (show) { setVal(current ? String(current) : ""); setErr(""); } }, [show]);
  const submit = () => { const t = parseFloat(val) || 0; if (t <= 0) return setErr("预算需要大于 0"); onSave(t); };
  return <>
    <div className={"scrim" + (show ? " show" : "")} onClick={onClose} />
    <div className={"sheet" + (show ? " show" : "")} style={{ paddingBottom: 24 }}>
      <div className="grab" />
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 18 }}>
        <div style={{ font: "var(--t-h2)" }}>本月总预算</div>
        <button className="iconbtn" onClick={onClose}><Icon name="x" /></button>
      </div>
      <div className="label-input">
        <label>这个月计划一共花多少</label>
        <div className="input"><span style={{ font: "700 17px/1 var(--font-num)", color: "var(--ink-500)" }}>¥</span>
          <input inputMode="numeric" pattern="[0-9]*" value={val} onChange={(e) => { setVal(e.target.value.replace(/[^0-9.]/g, "")); setErr(""); }} placeholder="2000" /></div>
      </div>
      {err && <div style={{ display: "flex", alignItems: "center", gap: 6, color: "var(--red-500)", font: "var(--t-body-sm)", marginTop: 12 }}>
        <Icon name="circle-alert" size={16} />{err}</div>}
      <Button block style={{ marginTop: 20 }} icon="check" onClick={submit}>保存</Button>
    </div>
  </>;
}

/* edit-category-budget bottom sheet (read-only category + monthly amount) */
function EditBudgetSheet({ row, onClose, onSave }) {
  const [val, setVal] = useStateD("");
  const [err, setErr] = useStateD("");
  React.useEffect(() => { if (row) { setVal(String(row.total)); setErr(""); } }, [row]);
  if (!row) return null;
  const c = CATS[row.cat];
  const t = parseFloat(val) || 0;
  // live status preview against the typed amount
  const status = t > 0 && row.spent > t ? "over" : t > 0 && row.spent >= t * 0.7 ? "near" : "ok";
  const submit = () => {
    if (t <= 0) return setErr("预算需要大于 0");
    onSave(row.cat, t);
  };
  return <>
    <div className="scrim show" onClick={onClose} />
    <div className="sheet show" style={{ paddingBottom: 24 }}>
      <div className="grab" />
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 18 }}>
        <div style={{ font: "var(--t-h2)" }}>编辑预算</div>
        <button className="iconbtn" onClick={onClose}><Icon name="x" /></button>
      </div>
      <div className="stack" style={{ gap: 14 }}>
        <div className="label-input">
          <label>分类名称</label>
          <div className="input" style={{ background: "var(--surface-2)", borderColor: "var(--line)" }}>
            <div className="cat-tile" style={{ background: c.tint, width: 30, height: 30 }}><Icon name={c.icon} color={c.fg} size={17} /></div>
            <span style={{ font: "var(--t-body)" }}>{c.zh}</span>
            <span style={{ flex: 1 }} />
            <span style={{ font: "var(--t-caption)", color: "var(--fg3)" }}>本月已用 ¥{row.spent}</span>
          </div>
        </div>
        <div className="label-input">
          <label>每月预算</label>
          <div className="input"><span style={{ font: "700 17px/1 var(--font-num)", color: "var(--ink-500)" }}>¥</span>
            <input inputMode="numeric" pattern="[0-9]*" value={val}
              onChange={(e) => { setVal(e.target.value.replace(/[^0-9.]/g, "")); setErr(""); }} placeholder="800" />
            {status === "over" && <span className="tag" style={{ background: "var(--red-50)", color: "var(--red-600)" }}>已超支</span>}
            {status === "near" && <span className="tag" style={{ background: "var(--orange-50)", color: "var(--orange-700)" }}>接近上限</span>}
          </div>
        </div>
      </div>
      {err && <div style={{ display: "flex", alignItems: "center", gap: 6, color: "var(--red-500)", font: "var(--t-body-sm)", marginTop: 12 }}>
        <Icon name="circle-alert" size={16} />{err}</div>}
      <Button block style={{ marginTop: 20 }} icon="check" onClick={submit}>保存预算</Button>
    </div>
  </>;
}

/* ---------- SPENDING WARNING ---------- */
function Warning({ onBack }) {
  const { state } = useStore();
  const s = selectStats(state);
  const over = s.todayOut - s.daily;             // +ve = 今天超支
  const todayByCat = spendByCat(selectTodayTx(state));
  const cats = Object.keys(todayByCat).map(c => ({ cat: c, v: todayByCat[c] })).sort((a, b) => b.v - a.v);
  const maxV = cats.length ? cats[0].v : 1;
  const overBudget = selectBudgetRows(state).filter(r => r.status === "over");
  const isOver = over > 0;

  return <div className="screen"><div className="pad">
    <TopBar title="支出提醒" back onBack={onBack} />
    <div className="card center" style={{ background: isOver ? "var(--red-50)" : "var(--green-50)", boxShadow: "none", paddingTop: 26, paddingBottom: 24 }}>
      <div style={{ width: 64, height: 64, borderRadius: 8, background: "#fff", border: "1px solid var(--line)", display: "grid", placeItems: "center", margin: "0 auto" }}>
        <Icon name={isOver ? "triangle-alert" : "circle-check"} size={34} color={isOver ? "var(--red-500)" : "var(--ink-900)"} />
      </div>
      <div style={{ font: "var(--t-h1)", color: isOver ? "var(--red-600)" : "var(--green-600)", marginTop: 16 }}>
        {isOver ? "今天超支 ¥" + over : "今天还在预算内"}</div>
      <div style={{ font: "var(--t-body)", color: "var(--ink-700)", marginTop: 8, padding: "0 10px" }}>
        {isOver ? "没关系，明天我们慢慢调整就好" : "今天还可以花 ¥" + s.todayRemaining + "，继续保持"}</div>
    </div>

    <div className="card" style={{ marginTop: 14 }}>
      <div style={{ font: "var(--t-h3)", marginBottom: 14 }}>今天花在哪了</div>
      {cats.length === 0
        ? <div style={{ font: "var(--t-body-sm)", color: "var(--fg3)" }}>今天还没有支出记录</div>
        : <div className="stack" style={{ gap: 16 }}>
            {cats.map((c, i) => <Bar key={i} label={CATS[c.cat].zh} right={"¥" + c.v} pct={Math.round(c.v / maxV * 100)}
              color={i === 0 ? "var(--red-500)" : i === 1 ? "var(--orange-500)" : "var(--blue-500)"} />)}
          </div>}
    </div>

    {overBudget.length > 0 && <div className="alert" style={{ background: "var(--orange-50)", color: "var(--orange-700)", marginTop: 14 }}>
      <Icon name="sparkles" />
      <span>本月 <b>{overBudget.map(r => CATS[r.cat].zh).join("、")}</b> 已超预算，明天少花一点就能慢慢补回来。</span>
    </div>}

    <Button block style={{ marginTop: 18 }} icon="check" onClick={onBack}>知道了，明天加油</Button>
    <Button block kind="ghost" style={{ marginTop: 10 }}>调整本月预算</Button>
  </div></div>;
}

/* ---------- MONTHLY REPORT ---------- */
function MonthlyReport({ onBack }) {
  const { state } = useStore();
  const r = selectMonthReport(state);
  const less = r.delta >= 0;
  const topZh = r.topCat ? CATS[r.topCat].zh : null;

  return <div className="screen"><div className="pad">
    <TopBar title="本月报告" sub={NOW.getFullYear() + " 年 " + (NOW.getMonth() + 1) + " 月"} back onBack={onBack} right={<button className="iconbtn"><Icon name="share-2" /></button>} />

    <div className="card" style={{ background: "var(--ink-900)", color: "#fff", border: "none" }}>
      <div style={{ font: "var(--t-body-sm)", opacity: .7 }}>{(NOW.getMonth() + 1)} 月总支出</div>
      <div style={{ font: "600 32px/1.1 var(--font-num)", margin: "8px 0 16px", letterSpacing: "-.01em" }}>¥{r.total.toLocaleString("en-US")}</div>
      <div style={{ display: "flex", gap: 10 }}>
        <div style={{ flex: 1, background: "rgba(255,255,255,.1)", borderRadius: 8, padding: "12px 14px" }}>
          <div style={{ font: "var(--t-caption)", opacity: .7 }}>总收入</div>
          <div style={{ font: "600 17px/1 var(--font-num)", marginTop: 6 }}>¥{r.income.toLocaleString("en-US")}</div></div>
        <div style={{ flex: 1, background: "rgba(255,255,255,.1)", borderRadius: 8, padding: "12px 14px" }}>
          <div style={{ font: "var(--t-caption)", opacity: .7 }}>结余存下</div>
          <div style={{ font: "600 17px/1 var(--font-num)", marginTop: 6 }}>+¥{r.saved.toLocaleString("en-US")}</div></div>
      </div>
    </div>

    <div className="alert" style={{ background: less ? "var(--green-50)" : "var(--orange-50)", color: less ? "var(--green-700)" : "var(--orange-700)", marginTop: 14 }}>
      <Icon name={less ? "trending-down" : "trending-up"} />
      <span>{less
        ? <span>比上个月<b>少花了 ¥{r.delta}</b>，储蓄习惯越来越好啦</span>
        : <span>比上个月<b>多花了 ¥{-r.delta}</b>，下个月我们一起收一收</span>}</span>
    </div>

    <div className="sec-title">支出构成</div>
    <div className="card stack" style={{ gap: 15 }}>
      {r.rows.length === 0 && <div style={{ font: "var(--t-body-sm)", color: "var(--fg3)" }}>本月还没有支出</div>}
      {r.rows.map((row, i) => <div key={i} style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <CatTile cat={row.cat} />
        <div style={{ flex: 1 }}>
          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 7 }}>
            <span style={{ font: "var(--t-body-sm)" }}>{CATS[row.cat].zh}</span>
            <span style={{ font: "var(--t-caption)", color: "var(--fg3)" }}>¥{row.v} · {row.pct}%</span></div>
          <div className="track" style={{ height: 8 }}><div className="fill" style={{ width: row.pct + "%", background: CATS[row.cat].fg }} /></div>
        </div>
      </div>)}
    </div>

    {topZh && <div className="card" style={{ marginTop: 14, display: "flex", alignItems: "center", gap: 12 }}>
      <div className="cat-tile lg" style={{ background: CATS[r.topCat].tint }}><Icon name={CATS[r.topCat].icon} color={CATS[r.topCat].fg} size={26} /></div>
      <div style={{ flex: 1 }}><div style={{ font: "var(--t-h3)" }}>{topZh}是最大支出</div>
        <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 3 }}>
          {r.topCat === "food" ? "占了将近一半，建议减少外卖和奶茶" : "占比最高，下月可以小小控制一下"}</div></div>
    </div>}
  </div></div>;
}

/* ---------- ADD TRANSACTION SHEET (记一笔) — writes to the store ---------- */
/* ---------- 记录一次选择 SHEET (记账) — writes to the store ---------- */
const REFLECT_NEED = ["需要", "想要", "不确定"];
const REFLECT_PLAN = ["计划内", "计划外"];
const REFLECT_INFLUENCE = ["同学", "平台广告", "限时优惠", "情绪", "家庭需要", "其他"];
const REFLECT_FEELING = ["值得", "一般", "后悔"];

function ReflectRow({ label, options, value, onPick }) {
  return <div style={{ marginTop: 14 }}>
    <div style={{ font: "var(--t-caption)", color: "var(--ink-700)", marginBottom: 8 }}>{label}</div>
    <div className="chips">
      {options.map(o => <button key={o} className={"chip" + (value === o ? " on" : "")}
        onClick={() => onPick(value === o ? null : o)}>{o}</button>)}
    </div>
  </div>;
}

function AddSheet({ show, onClose }) {
  const { addTransaction } = useStore();
  const [amt, setAmt] = useStateD("0");
  const [kind, setKind] = useStateD("out");
  const [cat, setCat] = useStateD(EXPENSE_CATS[0]);
  const [note, setNote] = useStateD("");
  const [date, setDate] = useStateD(() => new Date(NOW));   // default = 今天
  const [err, setErr] = useStateD("");
  // reflection (expenses only) — the "记录一次选择" layer
  const [need, setNeed] = useStateD(null);
  const [plan, setPlan] = useStateD(null);
  const [influence, setInfluence] = useStateD(null);
  const [feeling, setFeeling] = useStateD(null);

  const keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "del"];
  const press = (k) => {
    setErr("");
    if (k === "del") setAmt(a => a.length <= 1 ? "0" : a.slice(0, -1));
    else if (k === ".") setAmt(a => a.includes(".") ? a : a + ".");
    else setAmt(a => a === "0" ? k : (a.replace(".", "").length >= 9 ? a : a + k));
  };

  // switching type resets the selected category to a valid one for that type
  const switchKind = (k) => { setKind(k); setCat(k === "in" ? INCOME_CATS[0] : EXPENSE_CATS[0]); setErr(""); };
  const cats = kind === "in" ? INCOME_CATS : EXPENSE_CATS;

  const ymd = (d) => d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
  const yesterday = new Date(NOW.getTime() - 86400000);
  const isToday = sameDay(date, NOW);
  const isYesterday = sameDay(date, yesterday);

  const reset = () => { setAmt("0"); setNote(""); setKind("out"); setCat(EXPENSE_CATS[0]); setDate(new Date(NOW)); setErr(""); setNeed(null); setPlan(null); setInfluence(null); setFeeling(null); };
  const close = () => { reset(); onClose(); };
  const save = () => {
    if (!(parseFloat(amt) > 0)) return setErr("请输入金额，且需大于 0");
    if (!cat) return setErr("请选择一个分类");
    if (!date) return setErr("请选择日期");
    const reflect = kind === "out" && (need || plan || influence || feeling)
      ? { need, plan, influence, feeling } : null;
    addTransaction({ amount: amt, cat, note: note.trim(), kind, date, reflect });
    reset(); onClose();
  };
  const canSave = parseFloat(amt) > 0 && !!cat && !!date;
  const accent = "var(--accent)";   /* deep green — warm, not cold black */

  return <>
    <div className={"scrim" + (show ? " show" : "")} onClick={close} />
    <div className={"sheet" + (show ? " show" : "")} style={{ maxHeight: "90dvh", overflowY: "auto" }}>
      <div className="grab" />
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
        <div style={{ font: "var(--t-h2)" }}>{kind === "in" ? "记一笔收入" : "记录一次选择"}</div>
        <button className="iconbtn" onClick={close}><Icon name="x" /></button>
      </div>
      <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginBottom: 14 }}>{kind === "in" ? "把收入也记下来" : "每一笔消费，都是一次决定"}</div>

      <div className="seg" style={{ marginBottom: 14 }}>
        <button className={kind === "out" ? "on" : ""} onClick={() => switchKind("out")}>支出</button>
        <button className={kind === "in" ? "on" : ""} onClick={() => switchKind("in")}>收入</button>
      </div>

      {/* amount display */}
      <div style={{ textAlign: "center", padding: "6px 0 14px", borderBottom: "1px solid var(--line)" }}>
        <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginBottom: 6 }}>{kind === "in" ? "这次收入多少？" : "这次花了多少？"}</div>
        <div style={{ font: "600 38px/1 var(--font-num)", color: accent, fontFeatureSettings: '"tnum"', letterSpacing: "-.01em" }}>
          <span style={{ color: accent, fontSize: 24, verticalAlign: 4 }}>{kind === "in" ? "+" : "−"}¥</span>{amt}
          <span style={{ display: "inline-block", width: 2, height: 30, background: "var(--accent)", verticalAlign: -3, marginLeft: 3, animation: "fade 1s infinite alternate" }} />
        </div>
      </div>

      {/* category picker (switches by type) */}
      <div style={{ display: "flex", gap: 10, overflowX: "auto", padding: "14px 0 6px", margin: "0 -4px" }}>
        {cats.map(c => <button key={c} onClick={() => { setCat(c); setErr(""); }} style={{ border: "none", background: "none", cursor: "pointer", display: "flex", flexDirection: "column", alignItems: "center", gap: 6, flex: "0 0 auto", width: 60 }}>
          <div className="cat-tile lg" style={{ background: cat === c ? "var(--accent)" : "var(--surface-2)", borderColor: cat === c ? "var(--accent)" : "var(--line)", transition: "all .2s" }}>
            <Icon name={CATS[c].icon} color={cat === c ? "#fff" : "var(--ink-700)"} size={24} /></div>
          <span style={{ font: "11px/1.2 var(--font-sans)", color: cat === c ? "var(--accent-ink)" : "var(--fg3)", textAlign: "center" }}>{CATS[c].zh}</span>
        </button>)}
      </div>

      {/* date selector — defaults to 今天 */}
      <div style={{ display: "flex", gap: 8, alignItems: "center", margin: "12px 0 2px" }}>
        <Icon name="calendar" size={18} color="var(--ink-500)" />
        <button className={"chip" + (isToday ? " on" : "")} onClick={() => { setDate(new Date(NOW)); setErr(""); }}>今天</button>
        <button className={"chip" + (isYesterday ? " on" : "")} onClick={() => { setDate(new Date(yesterday)); setErr(""); }}>昨天</button>
        <input type="date" value={ymd(date)} max={ymd(NOW)}
          onChange={(e) => { const v = e.target.value; if (v) { const [y, m, d] = v.split("-").map(Number); setDate(new Date(y, m - 1, d, 12, 0)); setErr(""); } }}
          style={{ marginLeft: "auto", border: "1px solid var(--line-strong)", borderRadius: 8, padding: "8px 10px", font: "var(--t-body-sm)", color: "var(--ink-900)", background: "#fff", fontFamily: "var(--font-num)" }} />
      </div>

      {/* note (what happened) */}
      <div className="input" style={{ height: 46, margin: "10px 0 6px", borderRadius: 8 }}>
        <Icon name="pencil-line" />
        <input value={note} onChange={(e) => setNote(e.target.value)} maxLength={24} placeholder={kind === "in" ? "备注（选填），如 生活费 · 妈妈" : "发生了什么？（选填）如 午餐 · 沙县小吃"} />
      </div>

      {/* keypad */}
      <div className="keypad" style={{ marginTop: 8 }}>
        {keys.map(k => <button key={k} onClick={() => press(k)}>{k === "del" ? "⌫" : k}</button>)}
      </div>

      {/* reflection layer (expenses only) — this is the "选择" part */}
      {kind === "out" && <div style={{ marginTop: 18, paddingTop: 16, borderTop: "1px solid var(--line)" }}>
        <div style={{ font: "var(--t-caption)", letterSpacing: ".06em", color: "var(--ink-500)" }}>回顾一下这次选择（选填）</div>
        <ReflectRow label="这是需要，还是想要？" options={REFLECT_NEED} value={need} onPick={setNeed} />
        <ReflectRow label="这笔消费是提前想好的，还是临时决定？" options={REFLECT_PLAN} value={plan} onPick={setPlan} />
        <ReflectRow label="是什么影响了你？" options={REFLECT_INFLUENCE} value={influence} onPick={setInfluence} />
        <ReflectRow label="花完之后感觉怎么样？" options={REFLECT_FEELING} value={feeling} onPick={setFeeling} />
      </div>}

      {err && <div style={{ display: "flex", alignItems: "center", gap: 6, color: "var(--red-500)", font: "var(--t-body-sm)", margin: "12px 2px 2px" }}>
        <Icon name="circle-alert" size={16} />{err}</div>}

      <Button block style={{ marginTop: 16, opacity: canSave ? 1 : .55 }} onClick={save}>{kind === "in" ? "保存这一笔" : "记录这次选择"}</Button>
    </div>
  </>;
}

Object.assign(window, { BudgetCategory, EditTotalSheet, Warning, MonthlyReport, AddSheet, EditBudgetSheet });
