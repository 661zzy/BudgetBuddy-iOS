/* app.jsx — app shell + router for the 省钱搭子 mobile web app */
const { useState: useStateApp } = React;

// routes that map to a main bottom tab (vs. a stacked detail screen)
const TAB_ROUTES = { home: 1, track: 1, ai: 1, learn: 1, me: 1 };

function Phone() {
  const { startChallenge, addSavingsGoal, currentUser, authChecked, logout } = useStore();
  // phase is driven by the real session now (currentUser comes from GET /api/auth/me).
  // boot → while verifying the cookie · then app / auth / onboarding.
  const [phase, setPhase] = useStateApp(() => currentUser ? "app" : "boot"); // boot | onboarding | auth | app
  React.useEffect(() => {
    if (currentUser) { setPhase("app"); return; }
    if (!authChecked) { setPhase("boot"); return; }
    setPhase(hasOnboarded() ? "auth" : "onboarding");
  }, [currentUser, authChecked]);
  const [tab, setTab] = useStateApp("home");            // home | track | ai | learn | me
  const [detail, setDetail] = useStateApp(null);        // budget | warning | report | goal | challenges
  const [lesson, setLesson] = useStateApp(null);        // 小课堂 lesson id (overlay)
  const [game, setGame] = useStateApp(null);            // 小课堂·游戏 game id (overlay)
  const [add, setAdd] = useStateApp(false);
  const [goalSheet, setGoalSheet] = useStateApp(null);  // null | { name } — lifted 新建目标 sheet

  // single open() API:
  //   "lesson:<id>" → lesson overlay · a main-tab id → switch tab · anything else → stacked detail
  const open = (r) => {
    if (typeof r === "string" && r.indexOf("lesson:") === 0) { setLesson(r.slice(7)); return; }
    if (typeof r === "string" && r.indexOf("game:") === 0) { setGame(r.slice(5)); return; }
    if (r === "add") { setAdd(true); return; }              // 记一笔 quick-add sheet
    if (TAB_ROUTES[r]) { setTab(r); setDetail(null); setLesson(null); setGame(null); return; }
    setDetail(r);
  };
  const openLesson = (id) => setLesson(id);
  const back = () => setDetail(null);

  // route a lesson "今天的小任务" action to the right app behavior
  const doAction = (type, arg) => {
    setLesson(null);
    setGame(null);
    if (type === "budget") setDetail("budget");
    else if (type === "add") { setDetail(null); setAdd(true); }
    else if (type === "goalTab") { setDetail("goal"); }
    else if (type === "newGoal") { setDetail("goal"); setGoalSheet({ name: "" }); }
    else if (type === "newGoalNamed") { setDetail("goal"); setGoalSheet({ name: arg || "" }); }
    else if (type === "challenge") { startChallenge(arg); setDetail("challenges"); }
  };

  let body;
  if (phase === "boot") body = <BootSplash />;
  else if (phase === "onboarding") body = <Onboarding onDone={() => { setOnboarded(); setPhase("auth"); }} />;
  else if (phase === "auth") body = <Auth onDone={() => { /* session set in store → phase effect moves to app */ }} />;
  else if (lesson) body = <LessonDetail id={lesson} onBack={() => setLesson(null)} onAction={doAction} />;
  else if (game) body = <GameDetail id={game} onBack={() => setGame(null)} />;
  // stacked detail screens (with a back arrow, tab bar hidden)
  else if (detail === "challenges") body = <Challenges onBack={back} />;
  else if (detail === "codex") body = <Codex onBack={back} onGame={(gid) => setGame(gid)} />;
  else if (detail === "budget") body = <BudgetCategory onBack={back} />;
  else if (detail === "warning") body = <Warning onBack={back} />;
  else if (detail === "report") body = <MonthlyReport onBack={back} />;
  else if (detail === "goal") body = <Savings onBack={back} onOpen={open} onNewGoal={() => setGoalSheet({ name: "" })} />;
  // main tabs
  else if (tab === "home") body = <Home onOpen={open} />;
  else if (tab === "track") body = <Tracker onOpen={open} />;
  else if (tab === "ai") body = <AIAssistant onOpen={open} />;
  else if (tab === "learn") body = <Learning onLesson={openLesson} onGame={(gid) => setGame(gid)} onOpen={open} />;
  else body = <Profile onOpen={open} onLogout={() => { logout(); setTab("home"); setDetail(null); setLesson(null); }} />;

  const showTabs = phase === "app" && !detail && !lesson && !game;
  // quick-add 记一笔 floating pill on the 记账 tab (首页 has its own quick action)
  const showAdd = showTabs && tab === "track";

  return <div className="app">
    <div className="app-main">
      {body}
      {showAdd && <AddFab onClick={() => setAdd(true)} />}
    </div>
    {showTabs && <TabBar active={tab} onNav={(t) => { setTab(t); setDetail(null); setLesson(null); setGame(null); }} />}
    {phase === "app" && <AddSheet show={add} onClose={() => setAdd(false)} />}
    {phase === "app" && <NewGoalSheet show={!!goalSheet} presetName={goalSheet ? goalSheet.name : ""}
      onClose={() => setGoalSheet(null)} onSave={(g) => { if (addSavingsGoal(g)) setGoalSheet(null); }} />}
  </div>;
}

/* tiny boot splash while we verify the PHP session (GET /api/auth/me) */
function BootSplash() {
  return <div style={{ height: "100%", display: "grid", placeItems: "center", background: "var(--bg)" }}>
    <div style={{ textAlign: "center" }}>
      <div style={{ font: "600 22px/1 var(--font-sans)", letterSpacing: ".22em", color: "var(--ink-900)", paddingLeft: ".22em" }}>省钱搭子</div>
      <div className="muted" style={{ font: "var(--t-caption)", marginTop: 12 }}>正在连接…</div>
    </div>
  </div>;
}

ReactDOM.createRoot(document.getElementById("root")).render(
  <StoreProvider><Phone /></StoreProvider>
);
