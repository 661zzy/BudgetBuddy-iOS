/* screens_auth.jsx — Onboarding + Login/Signup */
const { useState: useStateA } = React;

const OB_SLIDES = [
  { icon: "wallet", tint: "var(--blue-50)", fg: "var(--blue-500)",
    title: "在真实情境里，练习每一次用钱选择", body: "花了钱就记一下，三秒搞定，慢慢来就好" },
  { icon: "target", tint: "var(--green-50)", fg: "var(--green-600)",
    title: "存钱目标看得见", body: "设个小目标，进度条一点点涨，存钱也有成就感" },
  { icon: "sparkles", tint: "var(--orange-50)", fg: "var(--orange-500)",
    title: "省钱搭子帮你出主意", body: "哪里花多了、怎么省下来，搭子用大白话告诉你" },
];

function Onboarding({ onDone }) {
  const [i, setI] = useStateA(0);
  const s = OB_SLIDES[i];
  const last = i === OB_SLIDES.length - 1;
  return <div className="ob">
    <div style={{ display: "flex", justifyContent: "flex-end", paddingTop: 8 }}>
      <button className="btn btn-ghost" style={{ padding: "8px 14px", border: "none", color: "var(--ink-500)" }}
        onClick={onDone}>跳过</button>
    </div>
    <div className="ob-art">
      <div className="fadein" key={i} style={{ textAlign: "center" }}>
        <div className="ob-illus" style={{ background: s.tint, margin: "0 auto" }}>
          <Icon name={s.icon} size={104} color={s.fg} />
          <div style={{ position: "absolute", top: 22, right: 26 }}><Icon name="sparkle" size={22} color={s.fg} /></div>
          <div style={{ position: "absolute", bottom: 30, left: 24 }}><Icon name="circle" size={14} color={s.fg} /></div>
        </div>
      </div>
    </div>
    <div className="dots">
      {OB_SLIDES.map((_, k) => <i key={k} className={k === i ? "on" : ""} />)}
    </div>
    <h1 className="center" style={{ font: "var(--t-h1)", marginBottom: 10 }}>{s.title}</h1>
    <p className="center muted" style={{ font: "var(--t-body)", marginBottom: 26, padding: "0 6px" }}>{s.body}</p>
    <Button block onClick={() => last ? onDone() : setI(i + 1)}>{last ? "开始体验" : "下一步"}</Button>
  </div>;
}

function Auth({ onDone }) {
  const { login, register } = useStore();
  const [mode, setMode] = useStateA("login");   // login | signup
  const [focus, setFocus] = useStateA("");
  const [id, setId] = useStateA("");
  const [pw, setPw] = useStateA("");
  const [nick, setNick] = useStateA("");
  const [age, setAge] = useStateA("");
  const [showPw, setShowPw] = useStateA(false);
  const [err, setErr] = useStateA("");
  const [busy, setBusy] = useStateA(false);   // awaiting the PHP API

  const switchMode = (m) => { setMode(m); setErr(""); };

  const submit = async () => {
    if (busy) return;
    setBusy(true); setErr("");
    try {
      const r = mode === "login"
        ? await login({ identifier: id, password: pw })
        : await register({ identifier: id, password: pw, nickname: nick, ageGroup: age });
      if (!r.ok) { setErr(r.error); return; }
      onDone();   // session is set in the store → app moves to the main tabs
    } finally { setBusy(false); }
  };

  const idIcon = id.includes("@") ? "at-sign" : "smartphone";

  return <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
    <div className="screen" style={{ padding: "0 28px 32px" }}>
      <div style={{ paddingTop: 30, textAlign: "center" }}>
        <img src="assets/logo-mark.svg" width="60" height="60" alt="省钱搭子" style={{ borderRadius: 8 }} />
        <h1 style={{ font: "var(--t-h1)", marginTop: 16 }}>{mode === "login" ? "欢迎回来" : "创建账号"}</h1>
        <p className="muted" style={{ font: "var(--t-body-sm)", marginTop: 6 }}>记好每一笔，存下每一分</p>
      </div>

      <div className="seg" style={{ margin: "24px 0 20px" }}>
        <button className={mode === "login" ? "on" : ""} onClick={() => switchMode("login")}>登录</button>
        <button className={mode === "signup" ? "on" : ""} onClick={() => switchMode("signup")}>注册</button>
      </div>

      <div className="stack" style={{ gap: 14 }}>
        <div className="label-input">
          <label>手机号 / 邮箱</label>
          <div className={"input" + (focus === "id" ? " focus" : "")}>
            <Icon name={idIcon} />
            <input value={id} placeholder="请输入手机号或邮箱"
              onChange={(e) => { setId(e.target.value); setErr(""); }}
              onFocus={() => setFocus("id")} onBlur={() => setFocus("")} />
          </div>
        </div>

        <div className="label-input">
          <label>{mode === "login" ? "密码" : "设置密码（至少 6 位）"}</label>
          <div className={"input" + (focus === "pw" ? " focus" : "")}>
            <Icon name="lock" />
            <input type={showPw ? "text" : "password"} value={pw} placeholder="请输入密码"
              onChange={(e) => { setPw(e.target.value); setErr(""); }}
              onFocus={() => setFocus("pw")} onBlur={() => setFocus("")}
              onKeyDown={(e) => { if (e.key === "Enter") submit(); }} />
            <button onClick={() => setShowPw(v => !v)} aria-label="显示密码"
              style={{ background: "none", border: "none", cursor: "pointer", color: "var(--ink-500)", display: "inline-flex", padding: 0 }}>
              <Icon name={showPw ? "eye" : "eye-off"} />
            </button>
          </div>
        </div>

        {mode === "signup" && <div className="label-input">
          <label>昵称</label>
          <div className={"input" + (focus === "nk" ? " focus" : "")}>
            <Icon name="smile" />
            <input value={nick} maxLength={16} placeholder="给自己起个名字吧"
              onChange={(e) => { setNick(e.target.value); setErr(""); }}
              onFocus={() => setFocus("nk")} onBlur={() => setFocus("")} />
          </div>
        </div>}

        {mode === "signup" && <div className="label-input">
          <label>你的年龄段（选填）</label>
          <div className="chips">
            {AGE_GROUPS.map((g) => <span key={g} className={"chip" + (age === g ? " on" : "")}
              onClick={() => setAge(age === g ? "" : g)}>{g}</span>)}
          </div>
        </div>}
      </div>

      {err && <div style={{ display: "flex", alignItems: "center", gap: 6, color: "var(--red-500)", font: "var(--t-body-sm)", marginTop: 14 }}>
        <Icon name="circle-alert" size={16} />{err}</div>}

      <Button block onClick={submit} style={{ marginTop: 22, marginBottom: 14, opacity: busy ? .6 : 1 }}>
        {busy ? "请稍候…" : (mode === "login" ? "登录" : "注册并登录")}</Button>

      <p className="center muted" style={{ font: "10px/1.5 var(--font-sans)", marginTop: 18 }}>登录即代表同意《用户协议》和《隐私政策》</p>
    </div>
  </div>;
}

Object.assign(window, { Onboarding, Auth });
