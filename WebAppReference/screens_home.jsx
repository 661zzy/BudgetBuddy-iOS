/* screens_home.jsx — Home, Tracker, Savings goal, Profile (live-state) */
const { useState: useStateH } = React;

/* shared transaction row (icon + note + time/cat + amount [+ delete]) */
function TxRow({ t, onDelete }) {
  const isIn = t.kind === "in";
  const catZh = CATS[t.cat] ? CATS[t.cat].zh : "";
  const r = t.reflect;
  const rtags = r ? [r.need, r.feeling, r.plan === "计划外" ? "计划外" : null].filter(Boolean) : [];
  return <div className="row">
    <CatTile cat={t.cat} />
    <div className="grow">
      <div className="t1">{t.note || catZh}</div>
      <div className="t2">{fmtTime(t.ts)} · {catZh}</div>
      {rtags.length > 0 && <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginTop: 6 }}>
        {rtags.map((x, i) => <span key={i} style={{ font: "11px/1 var(--font-sans)", color: x === "后悔" ? "var(--red-600)" : "var(--ink-700)", border: "1px solid " + (x === "后悔" ? "var(--red-100)" : "var(--line)"), borderRadius: 8, padding: "3px 7px" }}>{x}</span>)}
      </div>}
    </div>
    <Yen className={"amt" + (isIn ? " in" : "")} v={t.amount} sign={isIn ? "+" : "-"} />
    {onDelete && <button onClick={() => onDelete(t)} aria-label="删除"
      style={{ border: "none", background: "none", cursor: "pointer", color: "var(--ink-300)", padding: 4, marginLeft: 2, display: "inline-flex", flex: "none", alignSelf: "flex-start" }}>
      <Icon name="trash-2" size={16} /></button>}
  </div>;
}

/* ---------- HOME (首页 — story-led brand landing) ---------- */
function Home({ onOpen }) {
  const { state } = useStore();
  const story = selectFeaturedStory(state);        // featured interactive story
  const summary = selectWeeklySummary(state);      // 完成故事 / 记录选择 / 解锁图鉴 / 学完课程
  const tip = selectHomeTip(state);                // calm AI decision tip
  const hb = selectHomeBudget(state);              // budget — demoted to one small line
  const fmt = (n) => (n || 0).toLocaleString("en-US");
  const choicesThisWeek = selectWeekTx(state).length;

  return <div className="screen"><div className="pad" style={{ paddingTop: 4 }}>
    {/* 1 — centered wordmark */}
    <div style={{ textAlign: "center", padding: "26px 0 22px" }}>
      <div style={{ font: "600 23px/1 var(--font-sans)", letterSpacing: ".22em", color: "var(--ink-900)", paddingLeft: ".22em" }}>省钱搭子</div>
      <div style={{ font: "400 10px/1 var(--font-sans)", letterSpacing: ".46em", color: "var(--ink-500)", marginTop: 9, paddingLeft: ".46em" }}>BUDGETBUDDY</div>
    </div>

    {/* 2 — 今日故事 hero (editorial feature card) */}
    <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", padding: "0 2px 10px", borderBottom: "1px solid var(--line)", marginBottom: 16 }}>
      <span style={{ font: "var(--t-caption)", letterSpacing: ".14em", color: "var(--ink-500)", whiteSpace: "nowrap" }}>今 日 故 事</span>
      <a onClick={() => onOpen("learn")} style={{ font: "var(--t-caption)", color: "var(--ink-700)", cursor: "pointer", display: "flex", alignItems: "center", gap: 2 }}>全部故事 <Icon name="chevron-right" size={13} /></a>
    </div>
    {story && <div style={{ border: "1px solid var(--line)", borderRadius: 8, overflow: "hidden", cursor: "pointer" }} onClick={() => onOpen("game:" + story.id)}>
      <SceneBlock story={story} height={176} />
      <div style={{ padding: "18px 18px 20px" }}>
        <div style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 11 }}>
          {story.cat && <span className="tag">{story.cat}</span>}
          <span style={{ display: "flex", alignItems: "center", gap: 4, font: "var(--t-caption)", color: "var(--fg3)", whiteSpace: "nowrap" }}><Icon name="clock" size={12} />{story.time}</span>
        </div>
        <div style={{ font: "600 20px/1.4 var(--font-sans)", color: "var(--ink-900)" }}>{story.title}</div>
        <div style={{ font: "var(--t-body)", color: "var(--fg2)", marginTop: 8, textWrap: "pretty" }}>{story.desc}</div>
        <button className="btn btn-primary btn-block" style={{ marginTop: 18 }} onClick={(e) => { e.stopPropagation(); onOpen("game:" + story.id); }}>进入故事</button>
      </div>
    </div>}

    {/* 3 — 记录一次选择 entry (secondary card) */}
    <button onClick={() => onOpen("add")} style={{ width: "100%", marginTop: 14, textAlign: "left", background: "#fff", border: "1px solid var(--line)", borderRadius: 8, padding: "16px 18px", cursor: "pointer", display: "flex", alignItems: "center", gap: 14 }}>
      <div style={{ width: 38, height: 38, borderRadius: 8, border: "1px solid var(--line-strong)", display: "grid", placeItems: "center", flex: "none" }}><Icon name="plus" size={19} color="var(--ink-900)" /></div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ font: "var(--t-h3)" }}>记录一次选择</div>
        <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 3 }}>每一笔消费，都是一次决定</div>
      </div>
      <Icon name="arrow-right" size={17} color="var(--ink-500)" />
    </button>
    {hb.hasBudget && <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 9, padding: "0 2px", textAlign: "center" }}>
      本月已记 ¥{fmt(hb.monthlySpent)}{hb.remaining >= 0 ? " · 预算还剩 ¥" + fmt(hb.remaining) : " · 已超预算 ¥" + fmt(-hb.remaining)} · <a onClick={() => onOpen("track")} style={{ color: "var(--ink-700)", cursor: "pointer" }}>查看记账</a>
    </div>}

    {/* 4 — weekly summary */}
    <div style={{ font: "var(--t-caption)", letterSpacing: ".14em", color: "var(--ink-500)", padding: "0 2px 12px", borderBottom: "1px solid var(--line)", margin: "26px 0 0", whiteSpace: "nowrap" }}>本 周 概 览</div>
    <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)" }}>
      {summary.map((m, i) => <div key={m.label} style={{ textAlign: "center", padding: "18px 4px", borderRight: i < 3 ? "1px solid var(--line)" : "none", borderBottom: "1px solid var(--line)" }}>
        <div style={{ font: "600 24px/1 var(--font-num)", color: "var(--ink-900)" }}>{m.value}</div>
        <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 8 }}>{m.label}</div>
      </div>)}
    </div>

    {/* 5 — calm AI decision tip */}
    <div style={{ font: "var(--t-caption)", letterSpacing: ".14em", color: "var(--ink-500)", padding: "0 2px 12px", borderBottom: "1px solid var(--line)", margin: "26px 0 16px", whiteSpace: "nowrap" }}>搭 子 说</div>
    <button onClick={() => onOpen("ai")} style={{ width: "100%", textAlign: "left", border: "1px solid var(--line)", borderRadius: 8, padding: "18px", cursor: "pointer", background: "#fff" }}>
      <div style={{ font: "var(--t-h3)", color: tip.tone === "warn" ? "var(--red-600)" : "var(--ink-900)" }}>{tip.title}</div>
      <div style={{ font: "var(--t-body)", color: "var(--fg2)", marginTop: 7, textWrap: "pretty" }}>{tip.text}</div>
      <div style={{ display: "flex", alignItems: "center", gap: 5, marginTop: 14, font: "var(--t-caption)", color: "var(--ink-700)" }}>找搭子复盘一下 <Icon name="arrow-right" size={14} /></div>
    </button>
  </div></div>;
}

/* Warm situational scene block — a soft, colored "where you are" header
   keyed to the story's mood (school gate / phone pop-up / group chat /
   supermarket shelf / bus stop / everyday). A tasteful line icon on a
   warm tint + a location label — a real scene, never a gray placeholder. */
function sceneMood(story) {
  const key = ((story.id || "") + " " + (story.cat || "") + " " + (story.title || "")).toLowerCase();
  const has = (...ws) => ws.some((w) => key.includes(w));
  // by specific situation first…
  if (has("奶茶", "milktea", "milk-tea")) return { cls: "scene--orange", ink: "var(--on-orange)", where: "校门口" };
  if (has("会员", "订阅", "subscription", "member", "1元", "1块", "续费")) return { cls: "scene--blue", ink: "var(--on-blue)", where: "手机弹窗" };
  if (has("兼职", "刷单", "part-time", "parttime", "诈骗", "防骗", "金融安全", "安全")) return { cls: "scene--red", ink: "var(--on-red)", where: "班级群消息" };
  if (has("超市", "购物", "比价", "supermarket", "便利店")) return { cls: "scene--green", ink: "var(--on-green)", where: "超市货架前" };
  if (has("交通", "公交", "地铁", "打车", "transport", "车费")) return { cls: "scene--beige", ink: "var(--on-cream)", where: "公交站" };
  // …then by theme/category, so every story still gets a fitting mood
  if (has("消费观念", "想要", "需要", "冲动", "种草")) return { cls: "scene--orange", ink: "var(--on-orange)", where: "商店里" };
  if (has("储蓄", "攒", "目标", "存钱")) return { cls: "scene--green", ink: "var(--on-green)", where: "攒钱中" };
  if (has("借", "贷", "网贷", "还钱")) return { cls: "scene--red", ink: "var(--on-red)", where: "要做决定" };
  return { cls: "scene--cream", ink: "var(--on-cream)", where: "今天" };
}
function SceneBlock({ story, height = 160 }) {
  const m = sceneMood(story);
  return <div className={"scene " + m.cls} style={{ height, borderRadius: 0, border: "none", borderBottom: "1px solid var(--line)", position: "relative", display: "grid", placeItems: "center" }}>
    <span className="scene-where" style={{ position: "absolute", left: 16, top: 14, color: m.ink, opacity: .9 }}>
      <Icon name="map-pin" size={12} color={m.ink} />{m.where}
    </span>
    <div style={{ width: 64, height: 64, borderRadius: 18, background: "rgba(255,255,255,.62)", border: "1px solid rgba(255,255,255,.85)", display: "grid", placeItems: "center", boxShadow: "var(--shadow-card)" }}>
      <Icon name={story.icon} size={30} color={m.ink} />
    </div>
    {story.cat && <span style={{ position: "absolute", left: 16, bottom: 13, font: "var(--t-caption)", color: m.ink, opacity: .8 }}>{story.cat}</span>}
  </div>;
}

/* ---------- TRACKER (记账) ---------- */
const TRACK_FILTERS = [
  { id: "all", label: "全部" },
  { id: "out", label: "支出" },
  { id: "in", label: "收入" },
  { id: "today", label: "今日" },
  { id: "month", label: "本月" },
];
function Tracker({ onOpen }) {
  const { state, deleteTransaction } = useStore();
  const s = selectStats(state);
  const [filter, setFilter] = useStateH("all");
  const fmt = (n) => (n || 0).toLocaleString("en-US");

  // apply the active filter
  const match = (t) => filter === "all" ? true
    : filter === "out" ? t.kind === "out"
    : filter === "in" ? t.kind === "in"
    : filter === "today" ? sameDay(t.ts, NOW)
    : sameMonth(t.ts, NOW);   // 本月
  const list = state.transactions.filter(match);   // store keeps it reverse-chronological

  // group by day label
  const groups = [];
  list.forEach(t => {
    const lbl = dayLabel(t.ts);
    let g = groups.find(x => x.lbl === lbl);
    if (!g) { g = { lbl, items: [], out: 0, in: 0 }; groups.push(g); }
    g.items.push(t); if (t.kind === "in") g.in += t.amount; else g.out += t.amount;
  });

  // delete with confirm — Home + 记账 both re-derive from the store live
  const onDelete = (t) => {
    if (window.confirm("删除「" + (t.note || (CATS[t.cat] ? CATS[t.cat].zh : "")) + "」这一笔（" + (t.kind === "in" ? "+" : "−") + "¥" + t.amount + "）吗？")) {
      deleteTransaction(t.id);
    }
  };

  const stat = (label, val, color, sign) => <div className="card" style={{ padding: "13px 14px" }}>
    <div style={{ font: "var(--t-caption)", color: "var(--fg3)" }}>{label}</div>
    <div style={{ font: "600 20px/1.1 var(--font-num)", marginTop: 6, color, fontFeatureSettings: '"tnum"' }}>{sign}¥{fmt(val)}</div>
  </div>;

  const monthCount = state.transactions.filter(x => sameMonth(x.ts, NOW)).length;

  return <div className="screen"><div className="pad">
    <TopBar title="记账" sub="记录每一次消费选择" />

    {/* quiet summary line (no dashboard / ring) */}
    <div style={{ display: "flex", border: "1px solid var(--line)", borderRadius: 8 }}>
      <div style={{ flex: 1, padding: "16px 14px", borderRight: "1px solid var(--line)" }}>
        <div style={{ font: "var(--t-caption)", color: "var(--fg3)" }}>本月支出</div>
        <div style={{ font: "600 22px/1.1 var(--font-num)", marginTop: 6, fontFeatureSettings: '"tnum"' }}>¥{fmt(s.monthOut)}</div>
      </div>
      <div style={{ flex: 1, padding: "16px 14px", borderRight: "1px solid var(--line)" }}>
        <div style={{ font: "var(--t-caption)", color: "var(--fg3)" }}>今日支出</div>
        <div style={{ font: "600 22px/1.1 var(--font-num)", marginTop: 6, fontFeatureSettings: '"tnum"' }}>¥{fmt(s.todayOut)}</div>
      </div>
      <div style={{ flex: 1, padding: "16px 14px" }}>
        <div style={{ font: "var(--t-caption)", color: "var(--fg3)" }}>本月记录</div>
        <div style={{ font: "600 22px/1.1 var(--font-num)", marginTop: 6, fontFeatureSettings: '"tnum"', whiteSpace: "nowrap" }}>{monthCount} <span style={{ font: "var(--t-caption)", color: "var(--fg3)" }}>笔</span></div>
      </div>
    </div>

    {/* filters */}
    <div style={{ display: "flex", gap: 8, overflowX: "auto", padding: "16px 2px 8px", margin: "0 -2px" }}>
      {TRACK_FILTERS.map(f => <button key={f.id} className={"chip" + (filter === f.id ? " on" : "")} style={{ flex: "0 0 auto" }} onClick={() => setFilter(f.id)}>{f.label}</button>)}
    </div>

    {/* list / empty state */}
    {state.transactions.length === 0 ? <div style={{ marginTop: 6 }}>
      {/* real new user: no transactions yet */}
      <div className="card center" style={{ padding: "34px 18px" }}>
        <Icon name="receipt-text" size={36} color="var(--ink-300)" />
        <div style={{ marginTop: 14, font: "600 17px/1.4 var(--font-sans)", color: "var(--ink-900)" }}>还没有记录</div>
        <div style={{ marginTop: 6, font: "var(--t-body-sm)", color: "var(--fg3)", maxWidth: 240 }}>从今天开始，记录一次真实的消费选择。</div>
        <Button icon="plus" style={{ marginTop: 18 }} onClick={() => onOpen("add")}>记录第一次选择</Button>
      </div>
      {/* EXAMPLE only — never saved, never affects totals / reports / AI / database */}
      <div style={{ marginTop: 16, font: "var(--t-caption)", color: "var(--fg3)", padding: "0 2px 8px" }}>示例，不会计入你的数据</div>
      <div className="card" style={{ padding: "14px 16px", border: "1px dashed var(--line-strong)", background: "transparent" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 10 }}>
          <div style={{ font: "var(--t-body)", color: "var(--ink-700)" }}>示例：放学后买了一杯奶茶 ¥12</div>
          <span style={{ flex: "none", font: "var(--t-caption)", color: "var(--ink-500)", border: "1px solid var(--line-strong)", borderRadius: 999, padding: "2px 9px" }}>示例</span>
        </div>
        <div style={{ marginTop: 10, display: "flex", flexWrap: "wrap", gap: "4px 16px", font: "var(--t-caption)", color: "var(--fg3)" }}>
          <span>影响来源：同学邀请</span>
          <span>花完感觉：一般</span>
        </div>
      </div>
    </div> : groups.length === 0 ? <div className="card center" style={{ marginTop: 6, padding: "36px 16px", color: "var(--fg3)" }}>
      <Icon name="receipt-text" size={34} color="var(--ink-300)" />
      <div style={{ marginTop: 12, font: "var(--t-body-sm)" }}>{filter === "in" ? "还没有收入记录" : filter === "out" ? "还没有消费记录" : "这个筛选下还没有记录"}</div>
    </div> : groups.map((g, gi) => <div key={gi}>
      <div className="sec-title" style={{ fontSize: 14, color: "var(--fg3)", fontWeight: 400 }}>
        <span>{g.lbl}</span>
        <span style={{ font: "var(--t-caption)", color: "var(--fg3)" }}>
          {g.out > 0 ? "支出 ¥" + fmt(g.out) : ""}{g.out > 0 && g.in > 0 ? " · " : ""}{g.in > 0 ? "收入 ¥" + fmt(g.in) : ""}</span></div>
      <div className="card list">
        {g.items.map((t) => <TxRow t={t} key={t.id} onDelete={onDelete} />)}
      </div>
    </div>)}
  </div></div>;
}

/* ---------- SAVINGS GOAL (储蓄目标) ---------- */
const fmtGoalDate = (d) => { const x = new Date(d); return (x.getMonth() + 1) + "月" + x.getDate() + "日"; };
function Savings({ onBack, onOpen, onNewGoal }) {
  const { state, depositToGoal, updateGoal, deleteGoal } = useStore();
  const goals = state.savingsGoals;
  const totalSaved = goals.reduce((a, g) => a + g.saved, 0);
  const totalTarget = goals.reduce((a, g) => a + g.total, 0);
  const pct = totalTarget ? Math.round(totalSaved / totalTarget * 100) : 0;
  const [dep, setDep] = useStateH(null);     // goal being deposited into
  const [edit, setEdit] = useStateH(null);   // goal being edited
  const fmt = (n) => (n || 0).toLocaleString("en-US");

  const onDelete = (g) => { if (window.confirm("删除目标「" + g.name + "」吗？该目标和已存进度会一起移除。")) deleteGoal(g.id); };

  return <div className="screen"><div className="pad">
    <TopBar title="储蓄目标" back={!!onBack} onBack={onBack} right={<button className="iconbtn" onClick={onNewGoal}><Icon name="plus" /></button>} />

    {goals.length === 0 ? <div className="card center" style={{ padding: "38px 18px" }}>
      <div className="cat-tile lg" style={{ background: "var(--green-50)", margin: "0 auto" }}><Icon name="piggy-bank" color="var(--green-600)" size={26} /></div>
      <div style={{ font: "var(--t-h3)", marginTop: 12 }}>还没有储蓄目标</div>
      <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 4 }}>设个小目标，存钱更有动力</div>
      <Button block icon="plus" style={{ marginTop: 16, background: "var(--green-500)", boxShadow: "0 6px 16px rgba(47,193,119,.28)" }} onClick={onNewGoal}>创建目标</Button>
    </div> : <React.Fragment>
      <div className="card center" style={{ paddingTop: 22, paddingBottom: 22 }}>
        <Ring pct={pct} size={150}>
          <div><div style={{ font: "800 34px/1 var(--font-num)", color: "var(--green-600)" }}>{pct}%</div>
            <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 4 }}>总进度</div></div>
        </Ring>
        <div style={{ font: "var(--t-body)", marginTop: 16 }}>你已经存下 <b style={{ fontFamily: "var(--font-num)", color: "var(--green-600)" }}>¥{fmt(totalSaved)}</b> / {fmt(totalTarget)}</div>
        <div className="tag" style={{ background: "var(--green-50)", color: "var(--green-700)", marginTop: 12 }}>
          <Icon name="party-popper" />做得很棒，继续加油</div>
      </div>

      <div className="sec-title">我的目标 <span style={{ font: "var(--t-caption)", color: "var(--fg3)", fontWeight: 400 }}>{goals.length} 个</span></div>
      <div className="stack" style={{ gap: 12 }}>
        {goals.map((g) => {
          const gp = Math.min(100, Math.round(g.saved / g.total * 100));
          const done = g.saved >= g.total;
          const remaining = Math.max(0, g.total - g.saved);
          return <div className="card" key={g.id}>
            <div style={{ display: "flex", gap: 13, alignItems: "center" }}>
              <div className="cat-tile lg" style={{ background: g.tint }}><Icon name={g.icon} color={g.color} size={26} /></div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", gap: 8 }}>
                  <span style={{ font: "var(--t-h3)", whiteSpace: "nowrap" }}>{g.name}{done ? "" : ""}</span>
                  <span style={{ font: "var(--t-caption)", color: done ? "var(--green-600)" : "var(--fg3)", whiteSpace: "nowrap", flex: "none" }}>{done ? "已完成" : "还差 ¥" + fmt(remaining)}</span>
                </div>
                <div className="track" style={{ marginTop: 8 }}><div className="fill" style={{ width: gp + "%", background: g.color }} /></div>
                <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 7 }}>已存 ¥{fmt(g.saved)} / {fmt(g.total)} · {gp}%{g.deadline ? " · 截止 " + fmtGoalDate(g.deadline) : ""}</div>
              </div>
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 7, marginTop: 12, padding: "9px 11px", background: "var(--green-50)", borderRadius: 12 }}>
              <Icon name="lightbulb" size={15} color="var(--green-600)" />
              <span style={{ font: "var(--t-caption)", color: "var(--green-700)", lineHeight: 1.45 }}>{selectGoalSuggestion(g)}</span>
            </div>
            <div style={{ display: "flex", gap: 8, marginTop: 12 }}>
              <button className="btn btn-primary" style={{ flex: 1, padding: "11px 0", font: "600 14px/1 var(--font-sans)", background: "var(--green-500)", boxShadow: "none", opacity: done ? .5 : 1 }} onClick={() => setDep(g)} disabled={done}><Icon name="piggy-bank" size={18} />存入</button>
              <button className="btn btn-secondary" style={{ flex: "none", padding: "11px 16px", font: "600 14px/1 var(--font-sans)" }} onClick={() => setEdit(g)}><Icon name="pencil" size={16} />编辑</button>
              <button className="iconbtn" style={{ color: "var(--red-500)", border: "none", flex: "none" }} onClick={() => onDelete(g)} aria-label="删除"><Icon name="trash-2" size={18} /></button>
            </div>
          </div>;
        })}
      </div>
      <Button block kind="secondary" icon="plus" style={{ marginTop: 16 }} onClick={onNewGoal}>新建一个目标</Button>
    </React.Fragment>}

    <DepositSheet goal={dep} onClose={() => setDep(null)} onDeposit={(amt) => { depositToGoal(dep.id, amt); setDep(null); }} />
    <EditGoalSheet goal={edit} onClose={() => setEdit(null)} onSave={(patch) => { if (updateGoal(edit.id, patch)) setEdit(null); }} />
  </div></div>;
}

/* edit-savings-goal bottom sheet (name + target + saved + optional deadline) */
function EditGoalSheet({ goal, onClose, onSave }) {
  const [name, setName] = useStateH("");
  const [total, setTotal] = useStateH("");
  const [saved, setSaved] = useStateH("");
  const [deadline, setDeadline] = useStateH("");
  const [err, setErr] = useStateH("");
  React.useEffect(() => {
    if (goal) { setName(goal.name || ""); setTotal(String(goal.total || "")); setSaved(String(goal.saved || "")); setDeadline(goal.deadline ? String(goal.deadline).slice(0, 10) : ""); setErr(""); }
  }, [goal]);
  if (!goal) return null;
  const numProps = { inputMode: "numeric", pattern: "[0-9]*" };
  const submit = () => {
    const t = parseFloat(total) || 0, sv = parseFloat(saved) || 0;
    if (!name.trim()) return setErr("请输入目标名称");
    if (t <= 0) return setErr("目标金额需大于 0");
    if (sv < 0) return setErr("已存金额不能为负");
    if (sv > t) return setErr("已存金额不能超过目标金额");
    onSave({ name, total, saved, deadline: deadline || null });
  };
  return <>
    <div className="scrim show" onClick={onClose} />
    <div className="sheet show" style={{ paddingBottom: 24 }}>
      <div className="grab" />
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 18 }}>
        <div style={{ font: "var(--t-h2)" }}>编辑目标</div>
        <button className="iconbtn" onClick={onClose}><Icon name="x" /></button>
      </div>
      <div className="stack" style={{ gap: 14 }}>
        <div className="label-input">
          <label>目标名称</label>
          <div className="input"><Icon name="target" />
            <input value={name} maxLength={12} onChange={(e) => { setName(e.target.value); setErr(""); }} placeholder="例如 新手机、回家路费" /></div>
        </div>
        <div className="label-input">
          <label>目标金额</label>
          <div className="input"><span style={{ font: "700 17px/1 var(--font-num)", color: "var(--ink-500)" }}>¥</span>
            <input {...numProps} value={total} onChange={(e) => { setTotal(e.target.value.replace(/[^0-9.]/g, "")); setErr(""); }} placeholder="2000" /></div>
        </div>
        <div className="label-input">
          <label>已存金额</label>
          <div className="input"><span style={{ font: "700 17px/1 var(--font-num)", color: "var(--ink-500)" }}>¥</span>
            <input {...numProps} value={saved} onChange={(e) => { setSaved(e.target.value.replace(/[^0-9.]/g, "")); setErr(""); }} placeholder="0" /></div>
        </div>
        <div className="label-input">
          <label>截止日期（选填）</label>
          <div className="input"><Icon name="calendar" />
            <input type="date" value={deadline} onChange={(e) => { setDeadline(e.target.value); setErr(""); }} style={{ fontFamily: "var(--font-num)" }} /></div>
        </div>
      </div>
      {err && <div style={{ display: "flex", alignItems: "center", gap: 6, color: "var(--red-500)", font: "var(--t-body-sm)", marginTop: 12 }}>
        <Icon name="circle-alert" size={16} />{err}</div>}
      <Button block style={{ marginTop: 20 }} icon="check" onClick={submit}>保存修改</Button>
    </div>
  </>;
}

/* new-savings-goal bottom sheet (name + target + saved, validated).
   Lifted to Phone level so lesson actions can open it cross-screen. */
function NewGoalSheet({ show, presetName, onClose, onSave }) {
  const [name, setName] = useStateH("");
  const [total, setTotal] = useStateH("");
  const [saved, setSaved] = useStateH("");
  const [deadline, setDeadline] = useStateH("");
  const [err, setErr] = useStateH("");
  // prefill the name when opened (e.g. “应急备用金” from a lesson action)
  React.useEffect(() => { if (show) { setName(presetName || ""); setTotal(""); setSaved(""); setDeadline(""); setErr(""); } }, [show]);
  const reset = () => { setName(""); setTotal(""); setSaved(""); setDeadline(""); setErr(""); };
  const close = () => { reset(); onClose(); };
  const submit = () => {
    const t = parseFloat(total) || 0, sv = parseFloat(saved) || 0;
    if (!name.trim()) return setErr("请输入目标名称");
    if (t <= 0) return setErr("金额需要大于 0");
    if (sv < 0) return setErr("已存金额不能为负");
    if (sv > t) return setErr("已存金额不能超过目标金额");
    onSave({ name, total, saved: saved || 0, deadline: deadline || null }); reset();
  };
  const numProps = { inputMode: "numeric", pattern: "[0-9]*" };
  return <>
    <div className={"scrim" + (show ? " show" : "")} onClick={close} />
    <div className={"sheet" + (show ? " show" : "")} style={{ paddingBottom: 24 }}>
      <div className="grab" />
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 18 }}>
        <div style={{ font: "var(--t-h2)" }}>新建储蓄目标</div>
        <button className="iconbtn" onClick={close}><Icon name="x" /></button>
      </div>
      <div className="stack" style={{ gap: 14 }}>
        <div className="label-input">
          <label>目标名称</label>
          <div className="input"><Icon name="target" />
            <input value={name} maxLength={12} onChange={(e) => { setName(e.target.value); setErr(""); }} placeholder="例如 新手机、回家路费" /></div>
        </div>
        <div className="label-input">
          <label>目标金额</label>
          <div className="input"><span style={{ font: "700 17px/1 var(--font-num)", color: "var(--ink-500)" }}>¥</span>
            <input {...numProps} value={total} onChange={(e) => { setTotal(e.target.value.replace(/[^0-9.]/g, "")); setErr(""); }} placeholder="2000" /></div>
        </div>
        <div className="label-input">
          <label>已存金额（选填）</label>
          <div className="input"><span style={{ font: "700 17px/1 var(--font-num)", color: "var(--ink-500)" }}>¥</span>
            <input {...numProps} value={saved} onChange={(e) => { setSaved(e.target.value.replace(/[^0-9.]/g, "")); setErr(""); }} placeholder="0" /></div>
        </div>
        <div className="label-input">
          <label>截止日期（选填）</label>
          <div className="input"><Icon name="calendar" />
            <input type="date" value={deadline} onChange={(e) => { setDeadline(e.target.value); setErr(""); }} style={{ fontFamily: "var(--font-num)" }} /></div>
        </div>
      </div>
      {err && <div style={{ display: "flex", alignItems: "center", gap: 6, color: "var(--red-500)", font: "var(--t-body-sm)", marginTop: 12 }}>
        <Icon name="circle-alert" size={16} />{err}</div>}
      <Button block style={{ marginTop: 20 }} icon="check" onClick={submit}>保存目标</Button>
    </div>
  </>;
}

/* deposit-into-goal bottom sheet (quick amounts) */
function DepositSheet({ goal, onClose, onDeposit }) {
  const [amt, setAmt] = useStateH(50);
  const quick = [10, 50, 100, 200];
  if (!goal) return null;
  return <>
    <div className="scrim show" onClick={onClose} />
    <div className="sheet show" style={{ paddingBottom: 24 }}>
      <div className="grab" />
      <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16 }}>
        <div className="cat-tile lg" style={{ background: goal.tint }}><Icon name={goal.icon} color={goal.color} size={26} /></div>
        <div style={{ flex: 1 }}>
          <div style={{ font: "var(--t-h3)" }}>存入「{goal.name}」</div>
          <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 2 }}>还差 ¥{(goal.total - goal.saved).toLocaleString("en-US")} 就完成啦</div>
        </div>
        <button className="iconbtn" onClick={onClose}><Icon name="x" /></button>
      </div>
      <div style={{ textAlign: "center", padding: "8px 0 16px" }}>
        <span style={{ font: "800 40px/1 var(--font-num)", color: "var(--green-600)" }}>
          <span style={{ fontSize: 26, verticalAlign: 3 }}>¥</span>{amt}</span>
      </div>
      <div className="chips" style={{ justifyContent: "center", marginBottom: 18 }}>
        {quick.map(q => <span key={q} className={"chip" + (amt === q ? " on" : "")} onClick={() => setAmt(q)} style={{ padding: "11px 18px" }}>¥{q}</span>)}
      </div>
      <Button block kind="primary" icon="piggy-bank" onClick={() => onDeposit(amt)} style={{ background: "var(--green-500)", boxShadow: "0 6px 16px rgba(47,193,119,.28)" }}>存入 ¥{amt}</Button>
    </div>
  </>;
}

/* ---------- PROFILE (我的) ---------- */
function Profile({ onOpen, onLogout }) {
  const { state, resetStore, updateNickname } = useStore();
  const s = selectStats(state);
  const prog = selectLearningProgress(state);
  const activeCh = selectActiveChallenges(state);
  const totalSaved = state.savingsGoals.reduce((a, g) => a + g.saved, 0);
  const p = state.userProfile;
  const [editNick, setEditNick] = useStateH(false);
  const fmt = (n) => (n || 0).toLocaleString("en-US");

  // export the whole app state as a downloadable JSON file (frontend-only)
  const exportJSON = () => {
    try {
      const data = JSON.stringify(state, null, 2);   // ▶ BACKEND: GET /me/export
      const blob = new Blob([data], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url; a.download = "budgetbuddy-data.json";
      document.body.appendChild(a); a.click(); document.body.removeChild(a);
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    } catch (e) { window.alert("导出失败，请稍后再试"); }
  };

  const gprog = selectGameProgress(state);
  const cdx = selectCodex(state);
  const recordCount = state.transactions.filter(x => x.kind === "out").length;

  // story-led overview (three quiet figures, no budget dashboard)
  const overview = [
    { label: "完成故事", val: gprog.completed },
    { label: "解锁图鉴", val: cdx.unlockedCount },
    { label: "记账天数", val: s.recordDays },
  ];

  // account list rows — minimal, monochrome, thin dividers
  const storyRows = [
    { icon: "book-open", t: "已通关故事", right: gprog.completed + " / " + gprog.total, action: () => onOpen && onOpen("learn") },
    { icon: "layers", t: "已解锁图鉴", right: cdx.unlockedCount + " / " + cdx.total, action: () => onOpen && onOpen("codex") },
    { icon: "play-circle", t: "理财课程", right: "已完成 " + prog.completed + "/" + prog.total, action: () => onOpen && onOpen("learn") },
    { icon: "flag", t: "我的挑战", right: activeCh.length ? activeCh.length + " 个进行中" : "去看看", action: () => onOpen && onOpen("challenges") },
  ];
  // 我的记录 — story/decision-led. Old budgeting identity (储蓄目标 / 预算设置 /
  // 月度报告) is intentionally demoted out of the profile so the app reads as a
  // decision-habit product, not an expense tracker. (Those screens still exist
  // in code, just not surfaced here.)
  const recordRows = [
    { icon: "notebook-pen", t: "消费选择记录", right: recordCount + " 次", action: () => onOpen && onOpen("track") },
  ];
  const accountRows = [
    { icon: "cloud", t: "云端同步", right: "已开启", action: () => window.alert("你的数据已安全保存到你的账号，换个设备登录也能看到自己的记录。") },
    { icon: "pencil", t: "编辑昵称", action: () => setEditNick(true) },
    { icon: "download", t: "导出数据", action: exportJSON },
    { icon: "rotate-ccw", t: "恢复默认数据", action: () => { if (window.confirm("恢复默认数据？你记的账和目标会被清空。")) resetStore(); } },
    { icon: "log-out", t: "退出登录", action: onLogout },
  ];

  const Row = (it) => <div className="row" style={{ cursor: "pointer", padding: "15px 2px" }} onClick={it.action}>
    <Icon name={it.icon} color="var(--ink-700)" size={19} style={{ flex: "none" }} />
    <div className="grow"><div className="t1" style={{ fontSize: 15 }}>{it.t}</div></div>
    {it.right && <span style={{ font: "var(--t-caption)", color: "var(--fg3)", whiteSpace: "nowrap" }}>{it.right}</span>}
    <Icon name="chevron-right" size={17} color="var(--ink-300)" />
  </div>;
  const Section = ({ title, rows }) => <React.Fragment>
    <div style={{ font: "var(--t-caption)", letterSpacing: ".14em", color: "var(--ink-500)", padding: "0 2px 4px", margin: "26px 0 0" }}>{title}</div>
    <div className="list">{rows.map((it, i) => <Row key={i} {...it} />)}</div>
  </React.Fragment>;

  return <div className="screen"><div className="pad">
    <TopBar title="我的" />

    {/* user identity — minimal, monochrome */}
    <div style={{ display: "flex", gap: 14, alignItems: "center", cursor: "pointer", padding: "8px 2px 20px", borderBottom: "1px solid var(--line)" }} onClick={() => setEditNick(true)}>
      <div style={{ width: 52, height: 52, borderRadius: 8, border: "1px solid var(--line-strong)", display: "grid", placeItems: "center", flex: "none" }}><Icon name="user" color="var(--ink-900)" size={26} /></div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ font: "var(--t-h2)" }}>{p.name}</div>
        <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 4 }}>
          <span style={{ whiteSpace: "nowrap" }}>{[p.ageGroup, p.city].filter(Boolean).join(" · ") || "学生"} · 已坚持 {p.joinDays} 天</span></div>
      </div>
      <Icon name="pencil" size={17} color="var(--ink-300)" />
    </div>

    {/* soft summary cards — growth (green) · codex (blue) · records (beige) */}
    <div style={{ display: "flex", gap: 10, padding: "18px 0 2px" }}>
      {[
        { label: "完成故事", val: gprog.completed, bg: "var(--tint-green)", ink: "var(--on-green)", bd: "#CADBCB" },
        { label: "解锁图鉴", val: cdx.unlockedCount, bg: "var(--tint-blue)", ink: "var(--on-blue)", bd: "#D2E0EE" },
        { label: "记账天数", val: s.recordDays, bg: "var(--tint-beige)", ink: "var(--on-cream)", bd: "#E6DCC8" },
      ].map((m) => <div key={m.label} style={{ flex: 1, textAlign: "center", background: m.bg, border: "1px solid " + m.bd, borderRadius: "var(--r-md)", padding: "16px 6px" }}>
        <div style={{ font: "600 24px/1 var(--font-num)", color: m.ink }}>{m.val}</div>
        <div style={{ font: "var(--t-caption)", color: m.ink, opacity: .85, marginTop: 7 }}>{m.label}</div>
      </div>)}
    </div>

    <Section title="故 事 与 学 习" rows={storyRows} />
    <Section title="我 的 记 录" rows={recordRows} />
    <Section title="账 户" rows={accountRows} />

    {/* legal placeholders */}
    <div className="center" style={{ display: "flex", justifyContent: "center", gap: 6, marginTop: 24, font: "var(--t-caption)", color: "var(--fg3)" }}>
      <a style={{ color: "var(--ink-700)", cursor: "pointer" }} onClick={() => window.alert("《用户协议》占位页 —— 正式版本将在这里展示完整条款。")}>用户协议</a>
      <span>·</span>
      <a style={{ color: "var(--ink-700)", cursor: "pointer" }} onClick={() => window.alert("《隐私政策》占位页 —— 我们会把你的数据安全保存到你的账号，方便你换设备继续使用。")}>隐私政策</a>
    </div>

    {/* app info */}
    <div className="center" style={{ marginTop: 12 }}>
      <div style={{ font: "var(--t-body-sm)", color: "var(--ink-500)", fontWeight: 600 }}>省钱搭子 BudgetBuddy</div>
      <div style={{ font: "var(--t-caption)", color: "var(--ink-300)", marginTop: 3 }}>{APP_VERSION} · 陪你把每一次选择，变成更好的决定</div>
    </div>

    <EditNicknameSheet show={editNick} current={p.name} onClose={() => setEditNick(false)}
      onSave={(nm) => { if (updateNickname(nm)) setEditNick(false); }} />
  </div></div>;
}

/* edit-nickname bottom sheet */
function EditNicknameSheet({ show, current, onClose, onSave }) {
  const [val, setVal] = useStateH("");
  const [err, setErr] = useStateH("");
  React.useEffect(() => { if (show) { setVal(current || ""); setErr(""); } }, [show]);
  const submit = () => { if (!val.trim()) return setErr("昵称不能为空"); onSave(val.trim()); };
  return <>
    <div className={"scrim" + (show ? " show" : "")} onClick={onClose} />
    <div className={"sheet" + (show ? " show" : "")} style={{ paddingBottom: 24 }}>
      <div className="grab" />
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 18 }}>
        <div style={{ font: "var(--t-h2)", whiteSpace: "nowrap" }}>编辑昵称</div>
        <button className="iconbtn" onClick={onClose}><Icon name="x" /></button>
      </div>
      <div className="label-input">
        <label>你的昵称</label>
        <div className="input"><Icon name="user" />
          <input value={val} maxLength={12} onChange={(e) => { setVal(e.target.value); setErr(""); }} placeholder="给自己起个名字" /></div>
      </div>
      {err && <div style={{ display: "flex", alignItems: "center", gap: 6, color: "var(--red-500)", font: "var(--t-body-sm)", marginTop: 12 }}>
        <Icon name="circle-alert" size={16} />{err}</div>}
      <Button block style={{ marginTop: 20 }} icon="check" onClick={submit}>保存</Button>
    </div>
  </>;
}

Object.assign(window, { Home, SceneBlock, Tracker, Savings, Profile, EditNicknameSheet, TxRow, DepositSheet, NewGoalSheet, EditGoalSheet });
