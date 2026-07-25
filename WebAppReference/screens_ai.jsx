/* screens_ai.jsx — 省钱搭子 AI: local rule-based chat assistant.
   The async boundary is isolated in sendMessage() so swapping the
   local engine for POST /api/ai/chat is a one-spot change.
   Replies are { text, actions:[{label,route,icon}] }; action chips
   route through the same open()/startChallenge system as the app. */
const { useState: useStateAI } = React;

function AIAssistant({ onBack, onOpen }) {
  const { state, startChallenge, currentUser } = useStore();
  const report = selectMonthReport(state);
  const topZh = report.topCat ? CATS[report.topCat].zh : "餐饮";
  const hasData = state.transactions.length > 0;

  // chat history (local session). First message greets with live data.
  const [msgs, setMsgs] = useStateAI(() => ([
    {
      who: "ai",
      text: hasData
        ? "我是你的决策复盘搭子。这个月你记下了 ¥" + report.total.toLocaleString("en-US") + " 的消费，最多的是「" + topZh + "」。想复盘哪笔选择，或者问问怎么花得更值，都可以告诉我。"
        : "我是你的决策复盘搭子。先去记下几次消费选择，我就能陪你复盘「这笔值不值」、下次可以怎么选。",
      actions: hasData ? [] : [{ label: "去记一笔", route: "add", icon: "plus" }],
    },
  ]));
  const [text, setText] = useStateAI("");
  const [typing, setTyping] = useStateAI(false);
  const [conn, setConn] = useStateAI(null);   // null | "ai" (connected) | "offline" (local fallback)
  const scrollRef = React.useRef(null);

  // keep the conversation pinned to the latest message
  React.useEffect(() => {
    const el = scrollRef.current;
    if (el) el.scrollTop = el.scrollHeight;
  }, [msgs, typing]);

  // route an action chip → existing open()/startChallenge system
  const runAction = (route) => {
    if (!route) return;
    if (route.indexOf("challenge:") === 0) { startChallenge(route.slice(10)); onOpen && onOpen("challenges"); return; }
    onOpen && onOpen(route);   // "add" | "budget" | "goal" | "challenges" | "learn" | "lesson:<id>"
  };

  // a small, safe context summary from the user's OWN store data
  const buildContext = () => {
    const report = selectMonthReport(state);
    const recent = (state.transactions || []).slice(0, 5).map(t => ({ note: t.note, cat: t.cat, amount: t.amount, kind: t.kind }));
    return {
      summary: "记账 " + (state.transactions || []).length + " 笔，累计支出约 ¥" + Math.round(report.total || 0),
      recentTransactions: recent,
      storyProgress: state.gameProgress || [],
      codexUnlocked: state.unlockedCards || [],
    };
  };

  // local rule-based fallback (offline / not logged in / AI unavailable)
  const replyLocally = (q) => {
    const reply = generateLocalAIReply(q, state);   // { text, actions }
    setMsgs(m => [...m, { who: "ai", text: reply.text, actions: reply.actions || [] }]);
  };

  /* ---- send: PHP AI proxy first (POST /api/ai/chat), local fallback if
         offline / not logged in / AI unavailable. Never breaks the app. ---- */
  const sendMessage = async (raw) => {
    const q = (raw == null ? text : raw).trim();
    if (!q || typing) return;
    setMsgs(m => [...m, { who: "me", text: q }]);
    setText("");
    setTyping(true);
    try {
      if (currentUser) {
        const data = await window.apiClient.aiChat(q, buildContext());   // { reply, source }
        setConn(data && data.source === "ai" ? "ai" : "offline");
        setMsgs(m => [...m, { who: "ai", text: (data && data.reply) || "", actions: [] }]);
      } else {
        setConn("offline");                                              // not logged in → local engine
        replyLocally(q);
      }
    } catch (e) {
      setConn("offline");                                                // network/server down → local engine
      replyLocally(q);
    } finally {
      setTyping(false);
    }
  };

  // review prompts (shown as a 你想复盘什么？ menu before chatting)
  const chips = [
    "复盘我最近的消费",
    "我这个月花太多了吗？",
    "怎么少花点外卖钱？",
    "帮我制定本周省钱计划",
    "推荐一个故事给我",
  ];
  const hasChatted = msgs.some(m => m.who === "me");

  return <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
    <TopBar title="AI搭子" sub="决策复盘 · 安静的小助手" back={!!onBack} onBack={onBack} />

    {/* chat scroll area */}
    <div className="screen" style={{ padding: "14px 16px 8px" }} ref={scrollRef}>
      <div className="stack" style={{ gap: 14 }}>
        {msgs.map((m, i) => m.who === "ai"
          ? <div className="ai-row" key={i}>
              <div className="ai-av"><Icon name="message-circle" /></div>
              <div style={{ maxWidth: "84%" }}>
                <div className="bubble ai" style={{ whiteSpace: "pre-line" }}>{m.text}</div>
                {m.actions && m.actions.length > 0 && <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: 8 }}>
                  {m.actions.map((a, ai) => <button key={ai} className="ai-action" onClick={() => runAction(a.route)}>
                    <Icon name={a.icon || "arrow-right"} size={15} />{a.label}</button>)}
                </div>}
              </div>
            </div>
          : <div className="bubble me" key={i} style={{ alignSelf: "flex-end" }}>{m.text}</div>)}
        {typing && <div className="ai-row"><div className="ai-av"><Icon name="message-circle" /></div>
          <div className="bubble ai typing"><span /><span /><span /></div></div>}
      </div>

      {/* 你想复盘什么？ menu — calm, panel-based, not a flashy chatbot */}
      {!hasChatted && <div style={{ marginTop: 22 }}>
        <div style={{ font: "var(--t-caption)", letterSpacing: ".1em", color: "var(--ink-500)", padding: "0 2px 10px", borderBottom: "1px solid var(--line)" }}>你 想 复 盘 什 么 ？</div>
        <div className="stack">
          {chips.map((c, i) => <button key={i} onClick={() => sendMessage(c)} style={{ width: "100%", textAlign: "left", background: "#fff", border: "none", borderBottom: "1px solid var(--line)", padding: "15px 2px", cursor: "pointer", display: "flex", alignItems: "center", gap: 11 }}>
            <Icon name="corner-down-right" size={16} color="var(--accent)" />
            <span style={{ flex: 1, font: "var(--t-body)", color: "var(--ink-900)" }}>{c}</span>
            <Icon name="arrow-right" size={15} color="var(--ink-300)" /></button>)}
        </div>
      </div>}
    </div>

    {/* input bar (sits directly above the bottom tab bar) */}
    <div style={{ flex: "0 0 auto", padding: "10px 14px 12px", borderTop: "1px solid var(--line)", background: "var(--bg)" }}>
      {conn && <div style={{ display: "flex", alignItems: "center", gap: 5, font: "var(--t-caption)", color: conn === "ai" ? "var(--accent)" : "var(--ink-500)", padding: "0 2px 8px" }}>
        <Icon name={conn === "ai" ? "sparkles" : "cloud-off"} size={13} />{conn === "ai" ? "AI 已连接" : "离线复盘模式"}</div>}
      <div className="input" style={{ borderRadius: 999 }}>
        <input value={text} placeholder="说说你的一次选择…"
          onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => { if (e.key === "Enter") sendMessage(); }} />
        <button style={{ width: 36, height: 36, margin: 0, border: "none", borderRadius: 999, background: "var(--accent)", color: "#fff", display: "grid", placeItems: "center", cursor: "pointer", opacity: text.trim() && !typing ? 1 : .4 }}
          onClick={() => sendMessage()}><Icon name="arrow-up" size={19} color="#fff" /></button>
      </div>
    </div>
  </div>;
}

Object.assign(window, { AIAssistant });
