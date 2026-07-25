/* screens_learning.jsx — 金融小课堂: lesson list, lesson detail, video cards.
   Lesson content comes from the LESSONS constant (learning_data.jsx);
   only completion progress lives in the store. */
const { useState: useStateL, useEffect: useEffectL } = React;

/* small difficulty badge */
function LevelTag({ level }) {
  const c = LEVELS[level] || LEVELS["入门"];
  return <span className="tag" style={{ background: c.bg, color: c.fg }}>{level}</span>;
}

/* ---------- LEARNING HOME (学习中心: 看视频 / 玩游戏) ---------- */
function Learning({ onBack, onLesson, onGame, onOpen }) {
  const [mode, setMode] = useStateL("game");   // game | video — stories lead

  return <div className="screen"><div className="pad">
    <TopBar title="故事" sub="在真实情景里做选择，把管钱的小本事练起来" back={!!onBack} onBack={onBack} />

    {/* two-mode segmented switch */}
    <div style={{ display: "flex", gap: 10, marginBottom: 4 }}>
      <ModeCard active={mode === "game"} onClick={() => setMode("game")}
        icon="book-open" color="var(--ink-900)" tint="var(--surface-2)" title="互动故事" sub="情景里做决定" />
      <ModeCard active={mode === "video"} onClick={() => setMode("video")}
        icon="play-circle" color="var(--ink-900)" tint="var(--surface-2)" title="理财课程" sub="跟着课程学" />
    </div>

    {mode === "video" ? <VideoMode onLesson={onLesson} /> : <GameMode onGame={onGame} onOpen={onOpen} />}
  </div></div>;
}

/* big friendly mode toggle card */
function ModeCard({ active, onClick, icon, color, tint, title, sub }) {
  return <button onClick={onClick} style={{
    flex: 1, textAlign: "left", cursor: "pointer", border: "1px solid " + (active ? "var(--accent)" : "var(--line)"),
    background: active ? "var(--accent)" : "#fff", borderRadius: "var(--r-md)", padding: "13px 14px", display: "flex",
    alignItems: "center", gap: 11, transition: "all .15s",
  }}>
    <Icon name={icon} size={20} color={active ? "#fff" : "var(--ink-900)"} />
    <div>
      <div style={{ font: "var(--t-h3)", color: active ? "#fff" : "var(--ink-900)" }}>{title}</div>
      <div style={{ font: "var(--t-caption)", color: active ? "rgba(255,255,255,.6)" : "var(--fg3)", marginTop: 2 }}>{sub}</div>
    </div>
  </button>;
}

/* ---------- VIDEO MODE (课程 + 配套视频 list) ---------- */
function VideoMode({ onLesson }) {
  const { state } = useStore();
  const prog = selectLearningProgress(state);
  const recs = selectRecommendedLessons(state);
  const done = new Set(prog.doneIds);
  const catKeys = Object.keys(LEARN_CATS);

  return <div>
    {/* progress header */}
    <div className="card" style={{ display: "flex", alignItems: "center", gap: 16 }}>
      <Ring pct={prog.pct} size={66} stroke={4} color="var(--ink-900)" track="var(--surface-2)">
        <span style={{ font: "600 15px/1 var(--font-num)", color: "var(--ink-900)" }}>{prog.pct}%</span>
      </Ring>
      <div style={{ flex: 1 }}>
        <div style={{ font: "var(--t-h3)" }}>学习进度</div>
        <div style={{ font: "var(--t-body-sm)", color: "var(--fg2)", marginTop: 4 }}>
          已完成 <b style={{ fontFamily: "var(--font-num)", color: "var(--green-600)" }}>{prog.completed}</b> / {prog.total} 节，继续学习吧</div>
      </div>
    </div>

    {/* behavior-based recommendation */}
    {recs[0] && <div className="card" style={{ marginTop: 14, background: "var(--orange-50)", boxShadow: "none", padding: 14, display: "flex", gap: 12, alignItems: "center", cursor: "pointer" }}
      onClick={() => onLesson(recs[0].lesson.id)}>
      <div className="cat-tile lg" style={{ background: "#fff" }}><Icon name="lightbulb" color="var(--orange-500)" size={24} /></div>
      <div style={{ flex: 1 }}>
        <div style={{ font: "var(--t-caption)", color: "var(--orange-700)", fontWeight: 600 }}>根据你的花销，建议学习</div>
        <div style={{ font: "var(--t-h3)", color: "var(--orange-700)", marginTop: 2 }}>{recs[0].lesson.title}</div>
        <div style={{ font: "var(--t-caption)", color: "var(--orange-600)", marginTop: 3 }}>{recs[0].reason}</div>
      </div>
      <Icon name="chevron-right" size={20} color="var(--orange-600)" />
    </div>}

    {/* lessons grouped by category */}
    {catKeys.map(ck => {
      const cat = LEARN_CATS[ck];
      const items = LESSONS.filter(l => l.cat === ck);
      if (!items.length) return null;
      return <div key={ck}>
        <div className="sec-title"><span style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <div className="cat-tile" style={{ background: cat.tint, width: 30, height: 30 }}><Icon name={cat.icon} color={cat.fg} size={17} /></div>
          {cat.zh}</span></div>
        <div className="stack" style={{ gap: 12 }}>
          {items.map(l => <div className="card" key={l.id} onClick={() => onLesson(l.id)}
            style={{ display: "flex", gap: 13, alignItems: "center", cursor: "pointer" }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <span style={{ font: "var(--t-h3)" }}>{l.title}</span>
                {done.has(l.id) && <Icon name="circle-check-big" size={17} color="var(--green-500)" />}
              </div>
              <div style={{ font: "var(--t-body-sm)", color: "var(--fg2)", marginTop: 4 }}>{l.desc}</div>
              <div style={{ display: "flex", alignItems: "center", gap: 8, marginTop: 9, flexWrap: "wrap" }}>
                <LevelTag level={l.level} />
                <span style={{ display: "flex", alignItems: "center", gap: 3, font: "var(--t-caption)", color: "var(--fg3)" }}>
                  <Icon name="clock" size={13} />{l.time}</span>
                {l.video && <span style={{ display: "flex", alignItems: "center", gap: 3, font: "var(--t-caption)", color: "var(--blue-500)" }}>
                  <Icon name="play-circle" size={13} />配套视频</span>}
              </div>
            </div>
            <Icon name="chevron-right" size={20} color="var(--ink-300)" />
          </div>)}
        </div>
      </div>;
    })}
  </div>;
}

/* ---------- GAME MODE (财务情景小游戏 list) ---------- */
function GameMode({ onGame, onOpen }) {
  const { state } = useStore();
  const prog = selectGameProgress(state);
  const cdx = selectCodex(state);
  const done = new Set(prog.doneIds);

  return <div>
    {/* progress line */}
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", padding: "2px 2px 12px", borderBottom: "1px solid var(--line)" }}>
      <span style={{ font: "var(--t-caption)", letterSpacing: ".14em", color: "var(--ink-500)", whiteSpace: "nowrap" }}>互 动 故 事</span>
      <span style={{ font: "var(--t-caption)", color: "var(--fg3)", whiteSpace: "nowrap" }}>已通关 {prog.completed} / {prog.total}</span>
    </div>

    {/* editorial story cards */}
    <div className="stack" style={{ gap: 16, marginTop: 16 }}>
      {GAMES.map(g => <div key={g.id} onClick={() => onGame(g.id)}
        style={{ border: "1px solid var(--line)", borderRadius: 8, overflow: "hidden", cursor: "pointer" }}>
        <SceneBlock story={g} height={150} />
        <div style={{ padding: "16px 16px 18px" }}>
          <div style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 10, flexWrap: "wrap" }}>
            {g.cat && <span className="tag">{g.cat}</span>}
            <LevelTag level={g.level} />
            <span style={{ display: "flex", alignItems: "center", gap: 3, font: "var(--t-caption)", color: "var(--fg3)", whiteSpace: "nowrap" }}><Icon name="clock" size={12} />{g.time}</span>
            {done.has(g.id) && <span style={{ display: "flex", alignItems: "center", gap: 3, font: "var(--t-caption)", color: "var(--safe)", marginLeft: "auto", whiteSpace: "nowrap" }}><Icon name="check" size={13} color="var(--safe)" />已通关</span>}
          </div>
          <div style={{ font: "600 18px/1.4 var(--font-sans)", color: "var(--ink-900)" }}>{g.title}</div>
          <div style={{ font: "var(--t-body)", color: "var(--fg2)", marginTop: 7, textWrap: "pretty" }}>{g.desc}</div>
          <div style={{ display: "flex", alignItems: "center", gap: 5, marginTop: 14, font: "600 13px/1 var(--font-sans)", color: "var(--ink-900)" }}>
            {done.has(g.id) ? "再玩一遍" : "进入故事"} <Icon name="arrow-right" size={15} /></div>
        </div>
      </div>)}
    </div>

    {/* internal features: 认知图鉴 + 练习沙盘 */}
    <div style={{ font: "var(--t-caption)", letterSpacing: ".14em", color: "var(--ink-500)", padding: "0 2px 12px", borderBottom: "1px solid var(--line)", margin: "28px 0 0" }}>更 多</div>
    <button onClick={() => onOpen("codex")} style={{ width: "100%", textAlign: "left", background: "#fff", border: "none", borderBottom: "1px solid var(--line)", padding: "16px 2px", cursor: "pointer", display: "flex", alignItems: "center", gap: 13 }}>
      <Icon name="layers" size={20} color="var(--ink-900)" />
      <div style={{ flex: 1 }}><div style={{ font: "var(--t-h3)" }}>认知图鉴</div>
        <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 2 }}>已解锁 {cdx.unlockedCount} / {cdx.total} · 识破常见财务套路</div></div>
      <Icon name="chevron-right" size={19} color="var(--ink-300)" />
    </button>
    <button onClick={() => onGame("want-need")} style={{ width: "100%", textAlign: "left", background: "#fff", border: "none", borderBottom: "1px solid var(--line)", padding: "16px 2px", cursor: "pointer", display: "flex", alignItems: "center", gap: 13 }}>
      <Icon name="dumbbell" size={20} color="var(--ink-900)" />
      <div style={{ flex: 1 }}><div style={{ font: "var(--t-h3)" }}>练习沙盘</div>
        <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 2 }}>反复练「想要还是需要」的冷静一秒</div></div>
      <Icon name="chevron-right" size={19} color="var(--ink-300)" />
    </button>

    <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 18, padding: "0 2px", textWrap: "pretty" }}>故事里的钱都是模拟的，放心大胆做选择，做错了也只是长经验。</div>
  </div>;
}

/* ---------- VN ENGINE HELPERS ---------- */
/* a status value → { label, value, color } for the status bar */
function vnStat(key, val, game) {
  if (key === "money") return { label: (game && game.moneyLabel) || "余额", value: "¥" + val, color: val < 0 ? "var(--red-500)" : "var(--ink-900)" };
  if (key === "health") return { label: "健康", value: val + "%", color: val >= 50 ? "var(--green-600)" : "var(--orange-600)" };
  if (key === "credit") { const n = Math.max(0, Math.min(5, Math.round(val / 20))); return { label: "信用", value: "★★★★★".slice(0, n) + "☆☆☆☆☆".slice(0, 5 - n), color: "var(--blue-500)" }; }
  if (key === "risk") { const lv = val < 34 ? "低" : val < 67 ? "中" : "高"; return { label: "风险", value: lv, color: val < 34 ? "var(--green-600)" : val < 67 ? "var(--orange-500)" : "var(--red-500)" }; }
  if (key === "mood") { const e = val >= 67 ? "好" : val >= 34 ? "一般" : "低落"; return { label: "心情", value: e, color: "var(--ink-700)" }; }
  return { label: key, value: String(val), color: "var(--ink-700)" };
}
const VN_LABEL = { money: "余额", health: "健康", credit: "信用", risk: "风险", mood: "心情" };
function vnEffStr(key, delta, game) {
  const lbl = key === "money" ? ((game && game.moneyLabel) || "余额") : (VN_LABEL[key] || key);
  const num = key === "money" ? ("¥" + Math.abs(delta)) : Math.abs(delta);
  return lbl + " " + (delta > 0 ? "+" : "−") + num;
}
function vnEffGood(key, delta) { return key === "risk" ? delta < 0 : delta > 0; }
function vnApply(stats, effects) {
  const out = Object.assign({}, stats);
  Object.keys(effects || {}).forEach(k => {
    let v = (out[k] || 0) + effects[k];
    if (k !== "money") v = Math.max(0, Math.min(100, v));
    out[k] = v;
  });
  return out;
}

/* typewriter: reveals `text` char-by-char; tap to reveal in full */
function Typewriter({ text, sceneKey, speed = 16 }) {
  const [n, setN] = useStateL(0);
  const [done, setDone] = useStateL(false);
  useEffectL(() => { setN(0); setDone(false); }, [sceneKey]);
  useEffectL(() => {
    if (done || n >= text.length) return;
    const t = setTimeout(() => setN(x => x + 1), speed);
    return () => clearTimeout(t);
  }, [n, done, text, sceneKey]);
  const shown = done ? text : text.slice(0, n);
  const finished = shown.length >= text.length;
  return <div onClick={() => setDone(true)} style={{ cursor: finished ? "default" : "pointer" }}>
    <span style={{ font: "var(--t-body)", color: "var(--ink-900)", lineHeight: 1.75, textWrap: "pretty" }}>{shown}</span>
    {!finished && <span className="tw-cursor">▍</span>}
  </div>;
}

/* compact status bar (pills) */
function VNStatusBar({ game, stats }) {
  return <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
    {(game.statBar || []).map(k => {
      const st = vnStat(k, stats[k], game);
      return <span key={k} style={{ display: "inline-flex", alignItems: "center", gap: 5, background: "#fff", border: "1px solid var(--line)", borderRadius: 8, padding: "5px 11px" }}>
        <span style={{ font: "var(--t-caption)", color: "var(--fg3)" }}>{st.label}</span>
        <b style={{ font: "700 13px/1 var(--font-num)", color: st.color }}>{st.value}</b>
      </span>;
    })}
  </div>;
}

/* ---------- GAME DETAIL (像素剧情式财商模拟引擎) ---------- */
function GameDetail({ id, onBack }) {
  const { state, markGameComplete } = useStore();
  const game = GAMES.find(g => g.id === id);
  const [phase, setPhase] = useStateL("intro");          // intro | play | done
  const [sceneId, setSceneId] = useStateL(game ? game.start : null);
  const [stepNum, setStepNum] = useStateL(1);
  const [picked, setPicked] = useStateL(null);
  const [stats, setStats] = useStateL(game ? Object.assign({}, game.stats) : {});
  const [score, setScore] = useStateL(0);
  const [ending, setEnding] = useStateL(null);
  const alreadyDone = (state.gameProgress || []).includes(id);

  if (!game) return <div className="screen"><div className="pad"><TopBar title="理财小课堂" back onBack={onBack} /></div></div>;

  const sceneCount = Object.keys(game.scenes).length;
  const scene = game.scenes[sceneId];
  const accent = game.color;

  const start = () => { setPhase("play"); setSceneId(game.start); setStepNum(1); setPicked(null); setStats(Object.assign({}, game.stats)); setScore(0); setEnding(null); };

  const pickByScore = (sc) => {
    let max = 0;
    Object.values(game.scenes).forEach(s2 => { max += Math.max.apply(null, [0].concat(s2.choices.map(c => c.score || 0))); });
    const pct = max ? Math.round(sc / max * 100) : 0;
    const list = Object.keys(game.endings).map(k => Object.assign({ id: k }, game.endings[k])).filter(e => typeof e.min === "number").sort((a, b) => b.min - a.min);
    return list.find(e => pct >= e.min) || list[list.length - 1];
  };

  const finish = (endObj) => { markGameComplete(id, true); setEnding(endObj); setPhase("done"); };

  const choose = (c) => {
    if (picked) return;
    setPicked(c);
    setStats(s => vnApply(s, c.effects));
    setScore(s => s + (c.score || 0));
  };

  const proceed = () => {
    const c = picked;
    setPicked(null);
    if (c.end && game.endings[c.end]) { finish(Object.assign({ id: c.end }, game.endings[c.end])); return; }
    if (scene.final) { finish(pickByScore(score)); return; }
    setSceneId(c.next); setStepNum(n => n + 1);
  };

  return <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
    <TopBar title={game.title} back onBack={onBack}
      right={phase === "play" ? <span style={{ font: "var(--t-caption)", color: "var(--fg3)" }}>第 {stepNum} / {sceneCount} 关</span> : null} />

    {/* ===== INTRO ===== */}
    {phase === "intro" && <div className="screen"><div className="pad">
      <div className="px-grid" style={{ borderRadius: 8, background: "var(--surface-2)", border: "1px solid var(--line)", textAlign: "center", padding: "28px 20px" }}>
        <div style={{ width: 64, height: 64, borderRadius: 8, background: "#fff", display: "grid", placeItems: "center", margin: "0 auto 14px", border: "1px solid var(--line)" }}>
          <Icon name={game.icon} size={32} color="var(--ink-900)" />
        </div>
        <h1 style={{ font: "var(--t-h1)" }}>{game.title}</h1>
        {game.desc && <div style={{ font: "var(--t-body-sm)", color: "var(--fg2)", marginTop: 6 }}>{game.desc}</div>}
        <div style={{ display: "flex", gap: 8, justifyContent: "center", marginTop: 12, flexWrap: "wrap" }}>
          <LevelTag level={game.level} />
          {game.cat && <span className="tag" style={{ background: "#fff", color: accent }}>{game.cat}</span>}
          <span style={{ display: "flex", alignItems: "center", gap: 3, font: "var(--t-caption)", color: "var(--fg3)", whiteSpace: "nowrap" }}>
            <Icon name="clock" size={13} />{game.time}</span>
          <span style={{ display: "flex", alignItems: "center", gap: 3, font: "var(--t-caption)", color: "var(--fg3)", whiteSpace: "nowrap" }}>
            <Icon name="layers" size={13} />{sceneCount} 个场景</span>
        </div>
      </div>
      <div className="card" style={{ marginTop: 14 }}>
        <p style={{ font: "var(--t-body)", color: "var(--ink-900)", lineHeight: 1.75 }}>{game.intro}</p>
      </div>
      {alreadyDone && <div className="alert" style={{ background: "var(--green-50)", color: "var(--green-700)", marginTop: 12 }}>
        <Icon name="circle-check-big" color="var(--green-500)" /><span>你已经通关过这个故事，想再玩一次、试试别的选择也可以。</span>
      </div>}
      <Button block icon="play" onClick={start} style={{ marginTop: 16 }}>开始游戏</Button>
    </div></div>}

    {/* ===== PLAY ===== */}
    {phase === "play" && scene && <React.Fragment>
      <div className="screen"><div className="pad" style={{ paddingBottom: 120 }}>
        {/* progress */}
        <div style={{ height: 7, borderRadius: 99, background: "var(--surface-2)", overflow: "hidden", marginBottom: 14 }}>
          <div style={{ height: "100%", width: Math.round((stepNum - (picked ? 0 : 0.4)) / sceneCount * 100) + "%", background: accent, borderRadius: 99, transition: "width .3s" }} />
        </div>

        {/* status bar */}
        <VNStatusBar game={game} stats={stats} />

        {/* pixel scene header */}
        <div className="px-grid" style={{ marginTop: 14, borderRadius: 8, background: "var(--surface-2)", border: "1px solid var(--line)", padding: 13, display: "flex", gap: 12, alignItems: "center" }}>
          <div style={{ width: 50, height: 50, borderRadius: 8, background: "#fff", display: "grid", placeItems: "center", fontSize: 26, flex: "none", border: "1px solid var(--line)" }}>{scene.emoji}</div>
          <div style={{ minWidth: 0 }}>
            <div style={{ font: "var(--t-caption)", color: "var(--ink-700)", fontWeight: 600, display: "flex", alignItems: "center", gap: 3 }}><Icon name="map-pin" size={12} color="var(--ink-700)" />{scene.setting}</div>
            <div style={{ font: "var(--t-h3)", marginTop: 2 }}>{scene.sceneTitle}</div>
          </div>
        </div>

        {/* NPC dialogue bubble */}
        {scene.npcName && <div style={{ display: "flex", gap: 10, marginTop: 13, alignItems: "flex-start" }}>
          <div style={{ width: 38, height: 38, borderRadius: 8, background: "var(--ink-900)", display: "grid", placeItems: "center", flex: "none", font: "600 15px/1 var(--font-sans)", color: "#fff" }}>{scene.npcName.slice(0, 1)}</div>
          <div style={{ flex: 1, background: "#fff", border: "1px solid var(--line)", borderRadius: 8, padding: "10px 13px" }}>
            <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginBottom: 3 }}>{scene.npcName}</div>
            <div style={{ font: "var(--t-body)", color: "var(--ink-900)", lineHeight: 1.6 }}>{scene.npcLine}</div>
          </div>
        </div>}

        {/* narrator (typewriter) */}
        <div className="card" style={{ marginTop: 13 }}>
          <Typewriter text={scene.narrator} sceneKey={sceneId} />
          <div style={{ font: "var(--t-caption)", color: "var(--ink-300)", marginTop: 8, display: "flex", alignItems: "center", gap: 4 }}>
            <Icon name="hand" size={11} color="var(--ink-300)" />轻触文字可跳过</div>
        </div>

        {/* choices */}
        <div className="stack" style={{ gap: 11, marginTop: 14 }}>
          {scene.choices.map((c, idx) => {
            const isPicked = picked === c;
            const dim = picked && !isPicked;
            const effs = Object.keys(c.effects || {});
            return <button key={idx} className="vn-choice" onClick={() => choose(c)} disabled={!!picked} style={{
              textAlign: "left", width: "100%", cursor: picked ? "default" : "pointer",
              border: "1px solid " + (isPicked ? "var(--ink-900)" : "var(--line-strong)"),
              background: isPicked ? "var(--surface-2)" : "#fff", opacity: dim ? 0.45 : 1,
              borderRadius: 8, padding: "14px 15px", display: "flex", alignItems: "flex-start", gap: 10,
            }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ font: "var(--t-body)", color: "var(--ink-900)", fontWeight: 700, textWrap: "pretty" }}>{c.label}</div>
                {c.hint && <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 4 }}>提示：{c.hint}</div>}
                {effs.length > 0 && <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 3 }}>影响：{effs.map(k => vnEffStr(k, c.effects[k], game)).join(" · ")}</div>}
              </div>
              {isPicked && <Icon name="check" size={18} color={accent} />}
            </button>;
          })}
        </div>

        {/* result feedback panel */}
        {picked && <div className="card" style={{ marginTop: 14 }}>
          <div style={{ font: "var(--t-caption)", color: "var(--fg3)" }}>你选择了</div>
          <div style={{ font: "var(--t-h3)", color: accent, marginTop: 2 }}>{picked.label}</div>
          <p style={{ font: "var(--t-body)", color: "var(--ink-900)", marginTop: 8, lineHeight: 1.7 }}>{picked.consequence}</p>
          {Object.keys(picked.effects || {}).length > 0 && <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: 10 }}>
            {Object.keys(picked.effects).map(k => {
              const good = vnEffGood(k, picked.effects[k]);
              return <span key={k} style={{ display: "inline-flex", alignItems: "center", gap: 3, font: "600 12px/1 var(--font-sans)", color: good ? "var(--safe)" : "var(--red-500)", background: "#fff", border: "1px solid " + (good ? "var(--safe)" : "var(--red-500)"), padding: "5px 9px", borderRadius: 8 }}>
                {vnEffStr(k, picked.effects[k], game)}<Icon name={picked.effects[k] > 0 ? "arrow-up" : "arrow-down"} size={11} /></span>;
            })}
          </div>}
          <div style={{ marginTop: 12, background: "var(--surface-2)", border: "1px solid var(--line)", borderRadius: 8, padding: "12px 14px" }}>
            <div style={{ font: "var(--t-caption)", letterSpacing: ".06em", color: "var(--ink-500)", marginBottom: 5, display: "flex", alignItems: "center", gap: 5 }}><Icon name="key-round" size={13} color="var(--ink-700)" />背后的规则</div>
            <span style={{ font: "var(--t-body-sm)", color: "var(--ink-900)", lineHeight: 1.65 }}>{picked.tip}</span>
          </div>
        </div>}
      </div></div>

      {/* sticky continue (only after a choice) */}
      {picked && <div style={{ flex: "0 0 auto", padding: "10px 20px 16px", borderTop: "1px solid var(--line)", background: "var(--bg)" }}>
        <Button block icon={picked.end || scene.final ? "flag" : "arrow-right"} onClick={proceed}>{picked.end || scene.final ? "看结果" : "继续"}</Button>
      </div>}
    </React.Fragment>}

    {/* ===== DONE (ending) ===== */}
    {phase === "done" && ending && (() => {
      const good = ending.tone === "good";
      const tc = good ? "var(--green-600)" : "var(--orange-600)";
      const tbg = good ? "var(--green-50)" : "var(--orange-50)";
      return <React.Fragment>
        <div className="screen"><div className="pad" style={{ paddingBottom: 150 }}>
          <div style={{ borderRadius: 8, background: "var(--surface-2)", border: "1px solid var(--line)", textAlign: "center", padding: "28px 20px" }}>
            <div style={{ width: 60, height: 60, borderRadius: 8, background: "#fff", display: "grid", placeItems: "center", margin: "0 auto 12px", border: "1px solid var(--line)" }}>
              <Icon name={good ? "check" : "compass"} size={30} color="var(--ink-900)" /></div>
            <div style={{ font: "var(--t-caption)", color: "var(--ink-700)", fontWeight: 600, letterSpacing: ".06em" }}>本次结局</div>
            <h1 style={{ font: "var(--t-h1)", marginTop: 4 }}>{ending.title}</h1>
          </div>

          {/* final status summary */}
          <div className="sec-title">最终状态</div>
          <div className="card"><VNStatusBar game={game} stats={stats} /></div>

          {/* did well */}
          {ending.did_well && <div className="card" style={{ marginTop: 12, display: "flex", gap: 11, alignItems: "flex-start", background: "var(--green-50)", boxShadow: "none" }}>
            <Icon name="circle-check-big" size={20} color="var(--green-600)" />
            <div><div style={{ font: "var(--t-body-sm)", color: "var(--green-700)", fontWeight: 700 }}>你做得好的地方</div>
              <div style={{ font: "var(--t-body-sm)", color: "var(--green-700)", marginTop: 3, lineHeight: 1.6 }}>{ending.did_well}</div></div>
          </div>}

          {/* improve */}
          {ending.improve && <div className="card" style={{ marginTop: 12, display: "flex", gap: 11, alignItems: "flex-start", background: "var(--orange-50)", boxShadow: "none" }}>
            <Icon name="trending-up" size={20} color="var(--orange-600)" />
            <div><div style={{ font: "var(--t-body-sm)", color: "var(--orange-700)", fontWeight: 700 }}>下次可以更好</div>
              <div style={{ font: "var(--t-body-sm)", color: "var(--orange-700)", marginTop: 3, lineHeight: 1.6 }}>{ending.improve}</div></div>
          </div>}

          {/* habit */}
          {ending.habit && <div className="card" style={{ marginTop: 12, display: "flex", gap: 11, alignItems: "flex-start", background: "var(--blue-50)", boxShadow: "none" }}>
            <Icon name="sparkles" size={20} color="var(--blue-600)" />
            <div><div style={{ font: "var(--t-body-sm)", color: "var(--blue-700)", fontWeight: 700 }}>一个可以带走的小习惯</div>
              <div style={{ font: "var(--t-body-sm)", color: "var(--blue-700)", marginTop: 3, lineHeight: 1.6 }}>{ending.habit}</div></div>
          </div>}

          <div className="alert" style={{ marginTop: 12 }}>
            <Icon name="check" color="var(--ink-900)" /><span>已记入「已通关」，把学到的用到真实生活里吧。</span>
          </div>
          {(() => { const cc = (typeof CODEX !== "undefined") && CODEX.find(c => c.story === id); return cc
            ? <div className="alert" style={{ marginTop: 12 }}><Icon name="layers" color="var(--ink-900)" /><span>解锁认知图鉴·<b>{cc.title}</b> — 可在「故事 › 认知图鉴」查看。</span></div>
            : null; })()}
        </div></div>

        <div style={{ flex: "0 0 auto", padding: "10px 20px 16px", borderTop: "1px solid var(--line)", background: "var(--bg)" }}>
          <Button block icon="check" onClick={onBack}>完成学习</Button>
          <div style={{ display: "flex", gap: 10, marginTop: 10 }}>
            <Button kind="secondary" icon="rotate-ccw" onClick={start} style={{ flex: 1 }}>再玩一次</Button>
            <Button kind="secondary" icon="arrow-left" onClick={onBack} style={{ flex: 1 }}>返回故事</Button>
          </div>
        </div>
      </React.Fragment>;
    })()}
  </div>;
}

/* ---------- VIDEO CARD (external link) ---------- */
function VideoCard({ video }) {
  if (!video) return null;
  const provider = VIDEO_PROVIDERS[video.videoProvider] || "外部链接";
  // ▶ BACKEND/EMBED: for safe providers you could swap this for an <iframe>.
  //   For now we open the external URL in a new tab to avoid player issues.
  const open = () => { try { window.open(video.videoUrl, "_blank", "noopener"); } catch (e) {} };
  return <div>
    <div className="sec-title">配套视频</div>
    <div className="card" style={{ padding: 0, overflow: "hidden", cursor: "pointer" }} onClick={open}>
      {/* thumbnail placeholder (no real image needed) */}
      <div style={{ position: "relative", height: 150, background: "repeating-linear-gradient(135deg, var(--blue-50), var(--blue-50) 12px, var(--surface-2) 12px, var(--surface-2) 24px)", display: "grid", placeItems: "center" }}>
        <div style={{ width: 56, height: 56, borderRadius: "50%", background: "rgba(255,255,255,.92)", display: "grid", placeItems: "center", boxShadow: "var(--shadow-card)" }}>
          <Icon name="play" size={26} color="var(--blue-500)" /></div>
        <span className="tag" style={{ position: "absolute", top: 10, left: 10, background: "rgba(43,42,49,.55)", color: "#fff" }}>来自 {provider}</span>
      </div>
      <div style={{ padding: "13px 15px", display: "flex", alignItems: "center", gap: 10 }}>
        <div style={{ flex: 1 }}>
          <div style={{ font: "var(--t-h3)" }}>{video.videoTitle}</div>
          <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 3 }}>外部视频将在新页面打开</div>
        </div>
        <span className="btn btn-secondary" style={{ padding: "9px 14px", font: "600 14px/1 var(--font-sans)" }}>
          <Icon name="external-link" size={16} />点击观看</span>
      </div>
    </div>
  </div>;
}

/* ---------- LESSON DETAIL ---------- */
function LessonDetail({ id, onBack, onAction }) {
  const { state, markLessonComplete } = useStore();
  const lesson = LESSONS.find(l => l.id === id);
  const cat = lesson ? LEARN_CATS[lesson.cat] : null;
  const isDone = (state.lessonProgress || []).includes(id);
  const [justDone, setJustDone] = useStateL(false);
  if (!lesson) return <div className="screen"><div className="pad"><TopBar title="理财小课堂" back onBack={onBack} /></div></div>;

  return <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
    <TopBar title={cat.zh} back onBack={onBack} />
    <div className="screen"><div className="pad" style={{ paddingBottom: 110 }}>
      {/* title block */}
      <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 6 }}>
        <LevelTag level={lesson.level} />
        <span style={{ display: "flex", alignItems: "center", gap: 3, font: "var(--t-caption)", color: "var(--fg3)" }}>
          <Icon name="clock" size={13} />{lesson.time}</span>
        {isDone && <span className="tag" style={{ background: "var(--green-50)", color: "var(--green-700)" }}>
          <Icon name="check" size={12} />已完成</span>}
      </div>
      <h1 style={{ font: "var(--t-h1)", marginBottom: 14 }}>{lesson.title}</h1>

      {/* completion feedback — suggests a related action / challenge */}
      {justDone && <div className="card" style={{ background: "var(--green-50)", boxShadow: "none", marginBottom: 4, display: "flex", gap: 11, alignItems: "center" }}>
        <Icon name="party-popper" color="var(--green-500)" size={24} />
        <div style={{ flex: 1 }}>
          <div style={{ font: "var(--t-body-sm)", color: "var(--green-700)", fontWeight: 600 }}>已完成学习</div>
          <div style={{ font: "var(--t-caption)", color: "var(--green-700)", marginTop: 2 }}>
            {lesson.actionType ? "趁热打铁，现在就去试试 ↓" : "现在可以试试『每天记账 1 次』挑战"}</div>
        </div>
        {!lesson.actionType && <button className="btn btn-secondary" style={{ padding: "9px 13px", font: "600 13px/1 var(--font-sans)", flex: "none" }}
          onClick={() => onAction && onAction("challenge", "daily-log")}>去挑战</button>}
      </div>}

      {/* explanation */}
      <div className="card"><p style={{ font: "var(--t-body)", color: "var(--ink-900)" }}>{lesson.explanation}</p></div>

      {/* key points */}
      <div className="sec-title">重点</div>
      <div className="card stack" style={{ gap: 13 }}>
        {lesson.points.map((p, i) => <div key={i} style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
          <div style={{ width: 22, height: 22, borderRadius: 8, border: "1px solid var(--line-strong)", background: "#fff", color: "var(--ink-900)", font: "600 12px/22px var(--font-num)", textAlign: "center", flex: "none" }}>{i + 1}</div>
          <span style={{ font: "var(--t-body)", color: "var(--ink-900)" }}>{p}</span>
        </div>)}
      </div>

      {/* student-life example */}
      <div className="sec-title">学生例子</div>
      <div className="alert" style={{ background: "var(--blue-50)", color: "var(--ink-700)" }}>
        <Icon name="quote" color="var(--blue-500)" /><span>{lesson.example}</span>
      </div>

      {/* action task */}
      <div className="sec-title">今天的小任务</div>
      <div className="card" style={{ display: "flex", gap: 12, alignItems: "center", background: "var(--green-50)", boxShadow: "none" }}>
        <div className="cat-tile" style={{ background: "#fff", width: 40, height: 40 }}><Icon name="circle-check-big" color="var(--green-500)" size={22} /></div>
        <span style={{ font: "var(--t-body)", color: "var(--green-700)", fontWeight: 600 }}>{lesson.task}</span>
      </div>
      {lesson.actionType && <Button block icon="arrow-right" onClick={() => onAction && onAction(lesson.actionType, lesson.actionArg)} style={{ marginTop: 12 }}>{lesson.actionLabel}</Button>}

      {/* optional video */}
      {lesson.video && <VideoCard video={lesson.video} />}
    </div></div>

    {/* sticky complete button */}
    <div style={{ flex: "0 0 auto", padding: "10px 20px 16px", borderTop: "1px solid var(--line)", background: "var(--bg)" }}>
      {isDone
        ? <Button block kind="secondary" icon="rotate-ccw" onClick={() => { markLessonComplete(id, false); setJustDone(false); }}>已完成 · 取消标记</Button>
        : <Button block icon="check" onClick={() => { markLessonComplete(id, true); setJustDone(true); }}>标记完成</Button>}
    </div>
  </div>;
}

/* ---------- 认知图鉴 (cognitive codex) ---------- */
function Codex({ onBack, onGame }) {
  const { state } = useStore();
  const cdx = selectCodex(state);

  const Card = ({ c }) => <div style={{ border: "1px solid var(--line)", borderRadius: 8, padding: "18px", marginTop: 14 }}>
    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 10 }}>
      <span className="tag">{c.category}</span>
      <span style={{ font: "var(--t-caption)", color: "var(--safe)", display: "flex", alignItems: "center", gap: 3 }}><Icon name="check" size={13} color="var(--safe)" />已解锁</span>
    </div>
    <div style={{ font: "600 19px/1.4 var(--font-sans)", color: "var(--ink-900)", marginTop: 12 }}>{c.title}</div>
    <div style={{ font: "var(--t-caption)", letterSpacing: ".06em", color: "var(--ink-500)", margin: "18px 0 9px" }}>识别信号</div>
    <div className="stack" style={{ gap: 8 }}>
      {c.signs.map((s, i) => <div key={i} style={{ display: "flex", gap: 9, alignItems: "flex-start" }}>
        <Icon name="triangle-alert" size={15} color="var(--red-500)" style={{ marginTop: 2, flex: "none" }} />
        <span style={{ font: "var(--t-body-sm)", color: "var(--ink-900)", textWrap: "pretty" }}>{s}</span></div>)}
    </div>
    <div style={{ font: "var(--t-caption)", letterSpacing: ".06em", color: "var(--ink-500)", margin: "18px 0 9px" }}>应对动作</div>
    <div className="stack" style={{ gap: 8 }}>
      {c.defense.map((s, i) => <div key={i} style={{ display: "flex", gap: 9, alignItems: "flex-start" }}>
        <Icon name="shield-check" size={15} color="var(--safe)" style={{ marginTop: 2, flex: "none" }} />
        <span style={{ font: "var(--t-body-sm)", color: "var(--ink-900)", textWrap: "pretty" }}>{s}</span></div>)}
    </div>
    <button onClick={() => onGame(c.story)} style={{ width: "100%", textAlign: "left", marginTop: 18, paddingTop: 14, borderTop: "1px solid var(--line)", background: "none", border: "none", borderTopLeftRadius: 0, cursor: "pointer", display: "flex", alignItems: "center", gap: 7 }}>
      <Icon name="book-open" size={15} color="var(--ink-700)" />
      <span style={{ font: "var(--t-caption)", color: "var(--ink-700)" }}>相关故事 · {c.storyTitle}</span>
      <Icon name="arrow-right" size={14} color="var(--ink-500)" style={{ marginLeft: "auto" }} />
    </button>
  </div>;

  return <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
    <TopBar title="认知图鉴" sub={"已解锁 " + cdx.unlockedCount + " / " + cdx.total + " · 通关故事即可解锁"} back onBack={onBack} />
    <div className="screen"><div className="pad">
      {cdx.unlocked.length === 0 && <div style={{ textAlign: "center", padding: "48px 24px" }}>
        <Icon name="layers" size={34} color="var(--ink-300)" />
        <div style={{ font: "var(--t-h3)", marginTop: 14 }}>还没有解锁图鉴</div>
        <div style={{ font: "var(--t-body-sm)", color: "var(--fg2)", marginTop: 6, textWrap: "pretty" }}>去玩一个互动故事，通关后就能解锁对应的认知图鉴。</div>
        <Button block onClick={onBack} style={{ marginTop: 20 }}>去看故事</Button>
      </div>}
      {cdx.unlocked.map(c => <Card key={c.id} c={c} />)}

      {cdx.locked.length > 0 && <React.Fragment>
        <div style={{ font: "var(--t-caption)", letterSpacing: ".14em", color: "var(--ink-500)", padding: "0 2px 12px", borderBottom: "1px solid var(--line)", margin: "28px 0 0" }}>未 解 锁</div>
        {cdx.locked.map(c => <button key={c.id} onClick={() => onGame(c.story)} style={{ width: "100%", textAlign: "left", background: "#fff", border: "none", borderBottom: "1px solid var(--line)", padding: "16px 2px", cursor: "pointer", display: "flex", alignItems: "center", gap: 13 }}>
          <Icon name="lock" size={18} color="var(--ink-300)" />
          <div style={{ flex: 1 }}><div style={{ font: "var(--t-h3)", color: "var(--ink-500)" }}>{c.title}</div>
            <div style={{ font: "var(--t-caption)", color: "var(--fg3)", marginTop: 2 }}>通关「{c.storyTitle}」解锁</div></div>
          <Icon name="chevron-right" size={19} color="var(--ink-300)" />
        </button>)}
      </React.Fragment>}
    </div></div>
  </div>;
}

Object.assign(window, { Learning, LessonDetail, VideoCard, LevelTag, VideoMode, GameMode, ModeCard, GameDetail, Codex });
