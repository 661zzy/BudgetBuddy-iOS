/* screens_challenges.jsx — 我的挑战: active / completed / recommended.
   Challenge instances live in the store (persisted); defs (title, days,
   level, est, tip…) come from CHALLENGE_DEFS in learning_data.jsx. */
const { useState: useStateC } = React;

/* status badge */
function ChallengeStatus({ status }) {
  if (status === "done") return <span className="tag" style={{ background: "var(--green-50)", color: "var(--green-700)" }}><Icon name="check" size={12} />挑战完成</span>;
  return <span className="tag" style={{ background: "var(--orange-50)", color: "var(--orange-700)" }}>进行中</span>;
}

/* small difficulty + duration + expected-saving meta row */
function ChallengeMeta({ def }) {
  const lvl = { 简单: { bg: "var(--green-50)", fg: "var(--green-700)" }, 中等: { bg: "var(--orange-50)", fg: "var(--orange-700)" } }[def.level] || { bg: "var(--blue-50)", fg: "var(--blue-600)" };
  return <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
    <span className="tag" style={{ background: lvl.bg, color: lvl.fg, padding: "3px 9px" }}>{def.level || "简单"}</span>
    <span style={{ display: "flex", alignItems: "center", gap: 3, font: "var(--t-caption)", color: "var(--fg3)", whiteSpace: "nowrap" }}><Icon name="calendar-days" size={13} />{def.days} 天</span>
    {def.est > 0 && <span style={{ display: "flex", alignItems: "center", gap: 3, font: "var(--t-caption)", color: "var(--green-600)", whiteSpace: "nowrap" }}><Icon name="piggy-bank" size={13} />约省 ¥{def.est}</span>}
  </div>;
}

/* one active/completed challenge card */
function ChallengeCard({ c, onCheckIn }) {
  const done = c.status === "done";
  return <div className="card" style={{ display: "flex", flexDirection: "column", gap: 12 }}>
    <div style={{ display: "flex", gap: 13, alignItems: "center" }}>
      <div className="cat-tile lg" style={{ background: done ? "var(--green-50)" : "var(--orange-50)" }}>
        <Icon name={done ? "party-popper" : (c.icon || "flag")} color={done ? "var(--green-500)" : (c.color || "var(--orange-500)")} size={26} /></div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 8 }}>
          <span style={{ font: "var(--t-h3)", whiteSpace: "nowrap" }}>{c.title}</span><ChallengeStatus status={c.status} />
        </div>
        <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 3 }}>{c.desc}</div>
      </div>
    </div>
    <ChallengeMeta def={c.def || c} />
    <div>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 7 }}>
        <span style={{ font: "var(--t-caption)", color: "var(--fg2)", whiteSpace: "nowrap" }}>已坚持 {c.progress} / {c.total} 天</span>
        <span style={{ font: "var(--t-caption)", color: done ? "var(--green-600)" : "var(--orange-600)", fontWeight: 600 }}>{c.pct}%</span>
      </div>
      <div className="track"><div className="fill" style={{ width: c.pct + "%", background: done ? "var(--green-500)" : (c.color || "var(--orange-500)") }} /></div>
    </div>
    {/* practical tip */}
    {!done && (c.def || c).tip && <div style={{ display: "flex", gap: 8, alignItems: "flex-start", padding: "9px 11px", background: "var(--orange-50)", borderRadius: 12 }}>
      <Icon name="lightbulb" size={15} color="var(--orange-500)" />
      <span style={{ font: "var(--t-caption)", color: "var(--orange-700)", lineHeight: 1.45 }}>{(c.def || c).tip}</span>
    </div>}
    {done
      ? <div className="tag" style={{ background: "var(--green-50)", color: "var(--green-700)", alignSelf: "flex-start" }}><Icon name="check" size={13} />已坚持 {c.total} 天，太棒了</div>
      : (c.checkedToday
        ? <button className="btn btn-secondary btn-block" disabled style={{ opacity: .7 }}><Icon name="check" size={18} />今天已打卡</button>
        : <Button block icon="circle-check-big" onClick={() => onCheckIn(c.id)} style={{ background: "var(--green-500)", boxShadow: "0 6px 16px rgba(47,193,119,.28)" }}>今日打卡</Button>)}
  </div>;
}

/* ---------- MY CHALLENGES SCREEN ---------- */
function Challenges({ onBack }) {
  const { state, startChallenge, checkInChallenge } = useStore();
  const active = selectActiveChallenges(state);
  const completed = selectCompletedChallenges(state);
  const recs = selectRecommendedChallenges(state);
  const everStarted = (state.challenges || []).length > 0;
  const savedEst = completed.reduce((a, c) => a + ((c.def && c.def.est) || 0), 0);

  return <div className="screen"><div className="pad">
    <TopBar title="我的挑战" sub="一次一个小目标，坚持就有进步" back onBack={onBack} />

    {/* summary header */}
    <div className="card" style={{ display: "flex", textAlign: "center", padding: "18px 8px" }}>
      <div style={{ flex: 1 }}><div style={{ font: "600 22px/1 var(--font-num)", color: "var(--ink-900)" }}>{active.length}</div><div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 6 }}>进行中</div></div>
      <div style={{ width: 1, background: "var(--line)" }} />
      <div style={{ flex: 1 }}><div style={{ font: "600 22px/1 var(--font-num)", color: "var(--ink-900)" }}>{completed.length}</div><div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 6 }}>已完成</div></div>
      <div style={{ width: 1, background: "var(--line)" }} />
      <div style={{ flex: 1 }}><div style={{ font: "600 22px/1 var(--font-num)", color: "var(--ink-900)" }}>¥{savedEst}</div><div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 6 }}>累计省下</div></div>
    </div>

    {/* active (with empty state) */}
    <div className="sec-title">进行中</div>
    {active.length > 0
      ? <div className="stack" style={{ gap: 12 }}>{active.map(c => <ChallengeCard key={c.id} c={c} onCheckIn={checkInChallenge} />)}</div>
      : <div className="card center" style={{ padding: "22px 16px", color: "var(--fg3)" }}>
          <Icon name="flag" size={28} color="var(--ink-300)" />
          <div style={{ marginTop: 9, font: "var(--t-body-sm)" }}>还没有进行中的挑战，下面挑一个开始吧</div>
        </div>}

    {/* recommended */}
    {recs.length > 0 && <React.Fragment>
      <div className="sec-title">推荐挑战</div>
      <div className="stack" style={{ gap: 12 }}>
        {recs.map(({ def, reason }) => <div className="card" key={def.id} style={{ display: "flex", flexDirection: "column", gap: 11 }}>
          <div style={{ display: "flex", gap: 13, alignItems: "center" }}>
            <div className="cat-tile lg" style={{ background: "var(--surface-2)" }}><Icon name={def.icon || "flag"} color={def.color || "var(--blue-500)"} size={26} /></div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ font: "var(--t-h3)", whiteSpace: "nowrap" }}>{def.title}</div>
              <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 3 }}>{reason}</div>
            </div>
            <button className="btn btn-primary" style={{ padding: "10px 16px", font: "600 14px/1 var(--font-sans)", flex: "none" }} onClick={() => startChallenge(def.id)}>开始</button>
          </div>
          <ChallengeMeta def={def} />
        </div>)}
      </div>
    </React.Fragment>}

    {/* completed (with empty state, shown once the user has started anything) */}
    <div className="sec-title">已完成</div>
    {completed.length > 0
      ? <div className="stack" style={{ gap: 12 }}>{completed.map(c => <ChallengeCard key={c.id} c={c} onCheckIn={checkInChallenge} />)}</div>
      : <div className="card center" style={{ padding: "22px 16px", color: "var(--fg3)" }}>
          <Icon name="trophy" size={28} color="var(--ink-300)" />
          <div style={{ marginTop: 9, font: "var(--t-body-sm)" }}>还没有完成的挑战，坚持打卡就能拿到第一个</div>
        </div>}
  </div></div>;
}

Object.assign(window, { Challenges, ChallengeCard, ChallengeStatus, ChallengeMeta });
