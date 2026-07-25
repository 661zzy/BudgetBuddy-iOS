/* ============================================================
   store.jsx — 省钱搭子 BudgetBuddy 中央数据层 (single source of truth)
   ------------------------------------------------------------
   All app data lives here. Screens read derived numbers through
   `useStore()` and the pure `select*` helpers below. Nothing is
   hard-coded in the screens anymore.

   ▶ BACKEND-READY MAP (replace these with API calls later):
     - seed()                → GET /me, /transactions, /budgets, /goals
     - addTransaction(tx)    → POST /transactions
     - depositToGoal(id,amt) → POST /goals/:id/deposit
     - The select*() pure functions are client-side derivations of
       the kind a backend could also expose as /summary endpoints.
   The shape (transactions / budgets / savingsGoals / userProfile /
   derived monthlyReport) is intentionally flat & serializable.
   ============================================================ */

const { useState: useStoreState, useContext, createContext: createCtx } = React;

/* ---- App "now": the LIVE current time (evaluated at page load). Real users'
        transactions and ALL 今日/本月/本周 math use this. The demo seed data
        (seedTransactions/t) is fixed to Dec 2025 and is dev-only — real accounts
        start blank (BB_BLANK_NEW_USERS), so those dates never reach a real user. ---- */
const NOW = new Date();

/* ---- App version (bump on every change — see CLAUDE.md) ---- */
const APP_VERSION = "v4.4";

/* ---- date helpers ---------------------------------------------------- */
const DAY = 86400000;
function sameDay(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate(); }
function sameMonth(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth(); }
function weekStart(d) { const x = new Date(d); const wd = (x.getDay() + 6) % 7; x.setDate(x.getDate() - wd); x.setHours(0, 0, 0, 0); return x; } // Monday
function inThisWeek(d) { const s = weekStart(NOW); return d >= s && d < new Date(s.getTime() + 7 * DAY); }
function pad2(n) { return n < 10 ? "0" + n : "" + n; }
function fmtTime(d) { return pad2(d.getHours()) + ":" + pad2(d.getMinutes()); }
const WEEK_ZH = ["日", "一", "二", "三", "四", "五", "六"];
function fmtDateLong(d) { return (d.getMonth() + 1) + " 月 " + d.getDate() + " 日 · 周" + WEEK_ZH[d.getDay()]; }
function dayLabel(d) {
  if (sameDay(d, NOW)) return "今天";
  if (sameDay(d, new Date(NOW.getTime() - DAY))) return "昨天";
  return (d.getMonth() + 1) + " 月 " + d.getDate() + " 日";
}

/* ---- id factory — collision-proof across reloads. (Was a counter that reset
        to 2000 on every page load and collided with ids already saved in MySQL,
        so deleting one tx could silently delete another.) ------------------- */
const rid = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
const uid = () => "tx" + rid();

/* ---- palette cycled for new user-created goals ---------------------- */
const GOAL_PALETTE = [
  { color: "var(--blue-500)", track: "var(--blue-100)", tint: "var(--blue-50)", icon: "target" },
  { color: "var(--orange-500)", track: "var(--orange-100)", tint: "var(--orange-50)", icon: "piggy-bank" },
  { color: "var(--green-500)", track: "var(--green-100)", tint: "var(--green-50)", icon: "sprout" },
];

/* ---- seed transactions ----------------------------------------------
   ~30 records across December so months/weeks/categories all have data.
   t(day, hh, mm, cat, note, amount, kind='out')
---------------------------------------------------------------------- */
function t(day, hh, mm, cat, note, amount, kind) {
  return { id: uid(), kind: kind || "out", cat, note, amount, ts: new Date(2025, 11, day, hh, mm) };
}
function seedTransactions() {
  return [
    /* ---- this week (Mon 15 – Thu 18) ---- */
    t(18, 12, 30, "food", "午餐 · 黄焖鸡", 21),
    t(18, 15, 10, "fun", "奶茶 · 蜜雪冰城", 9),
    t(18, 8, 10, "transit", "地铁 · 上学", 4),
    t(17, 18, 40, "food", "外卖 · 麦当劳", 30),
    t(17, 14, 0, "study", "二手教材", 26),
    t(17, 9, 0, "transit", "公交", 2),
    t(16, 18, 30, "food", "晚餐 · 食堂", 15),
    t(16, 19, 0, "daily", "文具 · 笔记本", 23),
    t(15, 12, 20, "food", "午餐 · 沙县小吃", 18),
    t(15, 15, 20, "fun", "奶茶 · 益禾堂", 8),
    t(15, 8, 5, "transit", "地铁 · 上学", 4),
    /* ---- earlier this month ---- */
    t(14, 12, 30, "food", "午餐 · 兰州拉面", 18),
    t(14, 8, 10, "transit", "地铁", 4),
    t(13, 9, 0, "food", "早餐 · 包子豆浆", 7),
    t(13, 16, 0, "daily", "日用品 · 牙膏纸巾", 33),
    t(12, 12, 0, "food", "午餐 · 食堂", 15),
    t(12, 21, 0, "fun", "游戏充值", 30),
    t(11, 18, 0, "food", "晚餐 · 麻辣烫", 19),
    t(11, 15, 0, "study", "打印资料", 12),
    t(10, 12, 30, "food", "外卖 · 黄焖鸡", 24),
    t(10, 20, 0, "other", "话费充值", 30),
    t(9, 13, 0, "food", "午餐 · 盖饭", 16),
    t(9, 15, 30, "fun", "奶茶 · 一点点", 14),
    t(7, 19, 0, "food", "火锅 · 室友聚餐", 45),
    t(6, 14, 0, "daily", "卫衣 · 优衣库", 89),
    t(5, 20, 0, "fun", "电影票", 35),
    t(4, 15, 0, "study", "网课资料", 39),
    t(2, 12, 0, "food", "午餐 · 黄焖鸡", 18),
    t(1, 8, 0, "food", "早餐", 6),
    /* ---- income ---- */
    t(16, 10, 0, "income", "兼职 · 家教", 300, "in"),
    t(1, 9, 0, "income", "生活费 · 妈妈", 1200, "in"),
  ].sort((a, b) => b.ts - a.ts);
}

/* ---- initial state (the whole serializable app DB) ------------------ */
function seed() {
  return {
    userProfile: { name: "小林同学", greet: "小林", joinDays: 28 },
    settings: { dailyBudget: 65, monthlyBudget: 2000 },   // monthlyBudget = 本月总预算 (editable in 预算 screen)
    budgets: [                                // 分类月预算 (per-category caps — the 7 expense categories)
      { cat: "food", total: 800 },
      { cat: "transit", total: 200 },
      { cat: "study", total: 300 },
      { cat: "daily", total: 300 },
      { cat: "fun", total: 150 },
      { cat: "medical", total: 100 },
      { cat: "other", total: 150 },
    ],
    savingsGoals: [
      { id: "g1", name: "新手机", icon: "smartphone", color: "var(--blue-500)", track: "var(--blue-100)", tint: "var(--blue-50)", saved: 1200, total: 2000 },
      { id: "g2", name: "回家路费", icon: "train-front", color: "var(--orange-500)", track: "var(--orange-100)", tint: "var(--orange-50)", saved: 360, total: 600 },
      { id: "g3", name: "应急金", icon: "shield-check", color: "var(--green-500)", track: "var(--green-100)", tint: "var(--green-50)", saved: 480, total: 1000 },
    ],
    prevMonth: { total: 920 },                // 上月支出基线 (for 报告对比)
    transactions: seedTransactions(),
    lessonProgress: [],                       // 理财小课堂: completed lesson ids (user data)
    gameProgress: [],                         // 理财小课堂·游戏: completed game ids (user data)
    challenges: [],                           // 省钱挑战: user challenge instances (user data)
  };
}

/* ---- blank starting state for REAL new users (no demo data) ----------
   Same shape as seed() but with no sample transactions/goals and zeroed
   budgets — a valid, UI-safe empty app. Used for new accounts when the
   blank-start switch is on (see startStateForNewUser / __BB_BLANK_NEW_USERS__). */
function emptyState() {
  return {
    userProfile: { name: "同学", greet: "同学", joinDays: 0 },
    settings: { dailyBudget: 0, monthlyBudget: 0 },
    budgets: [                                // keep the 7 categories so 预算 screen is complete, caps = 0 (未设置)
      { cat: "food", total: 0 }, { cat: "transit", total: 0 }, { cat: "study", total: 0 },
      { cat: "daily", total: 0 }, { cat: "fun", total: 0 }, { cat: "medical", total: 0 }, { cat: "other", total: 0 },
    ],
    savingsGoals: [],
    prevMonth: { total: 0 },
    transactions: [],
    lessonProgress: [],
    gameProgress: [],
    challenges: [],
  };
}

/* Which starting state a brand-new account gets. Production ships with
   `window.BB_BLANK_NEW_USERS = true` (in index.html) so REAL users start blank —
   no fake transactions/goals/budgets. Set it to false (or remove it) to get the
   demo seed for local development. Only affects NEW accounts; existing users
   always load their own saved data. (`__BB_BLANK_NEW_USERS__` is accepted too.) */
function startStateForNewUser() {
  const blank = (typeof window !== "undefined") &&
    (window.BB_BLANK_NEW_USERS === true || window.__BB_BLANK_NEW_USERS__ === true);
  return blank ? emptyState() : seed();
}

/* ============================================================
   PURE SELECTORS — derive everything from state. A backend could
   expose these same shapes; keep them pure (no React).
   ============================================================ */
const sum = (arr, f) => arr.reduce((a, x) => a + f(x), 0);
const out = (list) => list.filter(x => x.kind === "out");
const inc = (list) => list.filter(x => x.kind === "in");

function selectMonthTx(s) { return s.transactions.filter(x => sameMonth(x.ts, NOW)); }
function selectTodayTx(s) { return s.transactions.filter(x => sameDay(x.ts, NOW)); }
function selectWeekTx(s) { return s.transactions.filter(x => inThisWeek(x.ts)); }

/* spend grouped by category over a tx list → { food: 356, ... } */
function spendByCat(list) {
  const m = {};
  out(list).forEach(x => { m[x.cat] = (m[x.cat] || 0) + x.amount; });
  return m;
}

/* top-line dashboard numbers */
function selectStats(s) {
  const month = selectMonthTx(s), today = selectTodayTx(s), week = selectWeekTx(s);
  const monthOut = sum(out(month), x => x.amount);
  const monthIn = sum(inc(month), x => x.amount);
  const todayOut = sum(out(today), x => x.amount);
  const weekOut = sum(out(week), x => x.amount);
  const monthBudget = s.settings.monthlyBudget || sum(s.budgets, b => b.total);
  const daily = s.settings.dailyBudget;
  return {
    daily,
    todayOut,
    todayRemaining: daily - todayOut,
    weekOut,
    monthOut,
    monthIn,
    monthBalance: monthIn - monthOut,        // 本月结余 (signed)
    monthBudget,
    monthRemaining: monthBudget - monthOut,
    saved: Math.max(0, monthIn - monthOut),   // 这个月已省下
    recordDays: new Set(s.transactions.map(x => x.ts.toDateString())).size,
  };
}

/* per-category budget rows w/ live spend + status.
   Driven by the 7 expense categories (EXPENSE_CATS) so all show even
   when unset. status: unset (no budget) | ok (正常 <70%) | near (接近上限 70–100%) | over (已超支 >100%) */
function selectBudgetRows(s) {
  const byCat = spendByCat(selectMonthTx(s));
  const map = {};
  (s.budgets || []).forEach(b => { map[b.cat] = b.total; });
  return EXPENSE_CATS.map(cat => {
    const total = map[cat] || 0;
    const spent = byCat[cat] || 0;
    const pct = total ? Math.round(spent / total * 100) : 0;
    const status = !total ? "unset" : spent > total ? "over" : pct >= 70 ? "near" : "ok";
    return { cat, spent, total, pct, status, over: total > 0 && spent > total };
  });
}

/* friendly, pure saving suggestion for one goal (deadline-aware) */
function selectGoalSuggestion(g) {
  const remaining = Math.max(0, (g.total || 0) - (g.saved || 0));
  if (remaining <= 0) return "目标已达成，太棒啦";
  if (g.deadline) {
    const days = Math.ceil((new Date(g.deadline) - NOW) / 86400000);
    if (days > 0) {
      const weeks = Math.max(1, Math.ceil(days / 7));
      return "距截止还有 " + days + " 天，每周存 ¥" + Math.ceil(remaining / weeks) + " 就能达成";
    }
    return "截止日已过，加把劲补上这 ¥" + remaining + " 吧";
  }
  return "还差 ¥" + remaining + "，每周存 ¥" + Math.ceil(remaining / 8) + "，约 8 周就能存够";
}

/* monthly report: total, breakdown %, comparison vs prevMonth */
function selectMonthReport(s) {
  const month = selectMonthTx(s);
  const total = sum(out(month), x => x.amount);
  const income = sum(inc(month), x => x.amount);
  const byCat = spendByCat(month);
  const rows = Object.keys(byCat)
    .map(cat => ({ cat, v: byCat[cat], pct: total ? Math.round(byCat[cat] / total * 100) : 0 }))
    .sort((a, b) => b.v - a.v);
  const topCat = rows[0] ? rows[0].cat : null;
  const delta = s.prevMonth.total - total;  // +ve = spent less than last month
  return { total, income, saved: Math.max(0, income - total), rows, topCat, prevTotal: s.prevMonth.total, delta };
}

/* ============================================================
   ADVICE ENGINE — simple, rule-based, data-driven. Returns an
   ordered list of {tone, icon, text}. tone: tip|warn|good.
   ============================================================ */
function selectAdvice(s) {
  const month = selectMonthTx(s);
  const total = sum(out(month), x => x.amount) || 1;
  const byCat = spendByCat(month);
  const rows = selectBudgetRows(s);
  const stats = selectStats(s);
  const adv = [];

  // over-budget categories first (most urgent, friendly red/orange)
  rows.filter(r => r.status === "over").forEach(r => {
    adv.push({ tone: "warn", icon: "triangle-alert", text: (CATS[r.cat].zh) + "已超预算 ¥" + (r.spent - r.total) + "，下周稍微收一收就好" });
  });

  // dominant category guidance
  if ((byCat.food || 0) / total > 0.4) {
    adv.push({ tone: "tip", icon: "utensils", text: "餐饮花得最多，少点几次外卖、奶茶改成一周两杯，能省下不少" });
  }
  if ((byCat.transit || 0) / total > 0.18) {
    adv.push({ tone: "tip", icon: "bus-front", text: "交通有点高，近的路程走一走或坐公交，比打车省一半" });
  }
  if ((byCat.fun || 0) > 0 && rows.find(r => r.cat === "fun" && r.status !== "over")) {
    const funSpent = byCat.fun || 0;
    if (funSpent >= 60) adv.push({ tone: "tip", icon: "gamepad-2", text: "娱乐花了 ¥" + funSpent + "，下周定个小上限，省下的钱可以存进目标" });
  }

  // positive reinforcement
  if (stats.saved > 0) {
    adv.push({ tone: "good", icon: "trending-up", text: "这个月已经省下 ¥" + stats.saved + "，继续保持就能更快攒够目标" });
  }
  if (stats.todayRemaining > 0) {
    adv.push({ tone: "good", icon: "smile", text: "今天还可以花 ¥" + stats.todayRemaining + "，控制得不错，加油" });
  }

  // always have something kind to say
  if (!adv.length) adv.push({ tone: "good", icon: "sparkles", text: "记账习惯保持得很好，花了钱随手记一笔就行" });
  return adv;
}

/* short single-line nudge for the home card (most relevant first) */
function selectNudge(s) {
  const a = selectAdvice(s);
  return a.find(x => x.tone === "warn") || a.find(x => x.tone === "tip") || a[0];
}

/* ============================================================
   HOME DASHBOARD selectors — everything the 首页 cards need.
   Pure derivations of store state; a backend could expose the
   same shapes as a /home/summary endpoint later.
   ============================================================ */

/* time-of-day greeting. Uses NOW (fixed demo clock) — swap for
   `new Date()` in production. */
function selectGreeting(now) {
  const h = (now || NOW).getHours();
  if (h < 11) return "早上好";
  if (h < 18) return "下午好";
  return "晚上好";
}

/* days remaining in the current month, including today */
function daysLeftInMonth(now) {
  const d = now || NOW;
  const lastDay = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
  return Math.max(1, lastDay - d.getDate() + 1);
}

/* the home "today / month budget" block + warning status.
   monthlySpent = month expenses · monthlyBudget = Σ budgets
   remaining = budget − spent · todayAvailable ≈ remaining / daysLeft
   status: none (no budget) | safe (<70%) | close (70–100%) | over (>100%) */
function selectHomeBudget(s) {
  const stats = selectStats(s);
  const monthlyBudget = stats.monthBudget;
  const monthlySpent = stats.monthOut;
  const remaining = monthlyBudget - monthlySpent;
  const daysLeft = daysLeftInMonth(NOW);
  const hasBudget = monthlyBudget > 0;
  const todayAvailable = hasBudget && remaining > 0 ? Math.floor(remaining / daysLeft) : 0;
  const ratio = hasBudget ? monthlySpent / monthlyBudget : 0;
  const status = !hasBudget ? "none" : ratio > 1 ? "over" : ratio >= 0.7 ? "close" : "safe";
  return { hasBudget, monthlyBudget, monthlySpent, remaining, daysLeft, todayAvailable, ratio, pct: Math.round(ratio * 100), status };
}

/* short, data-aware saving reminder for the greeting card */
function selectSavingReminder(s) {
  const stats = selectStats(s);
  const hb = selectHomeBudget(s);
  if (hb.status === "over") return "这个月有点超啦，接下来几天一起省一省";
  if (selectTodayTx(s).length === 0) return "今天还没记账，花了就随手记一笔吧";
  if (stats.saved > 0) return "这个月已经省下 ¥" + stats.saved + "，继续保持～";
  return "记好每一笔，离目标更近一步";
}

/* pick one savings goal to feature on home (first unfinished, else first) */
function selectFeaturedGoal(s) {
  const goals = s.savingsGoals || [];
  if (!goals.length) return null;
  const goal = goals.find(g => g.saved < g.total) || goals[0];
  const pct = goal.total ? Math.min(100, Math.round(goal.saved / goal.total * 100)) : 0;
  return { goal, pct, remaining: Math.max(0, goal.total - goal.saved) };
}

/* home weekly summary — story-led product metrics (no budget framing).
   完成故事 · 记录选择(本周) · 解锁图鉴 · 学完课程 */
function selectWeeklySummary(s) {
  const stories = (s.gameProgress || []).filter(id => (typeof GAMES !== "undefined") && GAMES.some(g => g.id === id)).length;
  const choices = selectWeekTx(s).length;
  const codex = (typeof selectCodex !== "undefined") ? selectCodex(s).unlockedCount : 0;
  const lessons = (s.lessonProgress || []).length;
  return [
    { label: "完成故事", value: stories },
    { label: "记录选择", value: choices },
    { label: "解锁图鉴", value: codex },
    { label: "学完课程", value: lessons },
  ];
}

/* pick the featured story for the home hero: first unfinished game, else first */
function selectFeaturedStory(s) {
  if (typeof GAMES === "undefined" || !GAMES.length) return null;
  const done = new Set(s.gameProgress || []);
  return GAMES.find(g => !done.has(g.id)) || GAMES[0];
}

/* one local "AI tip" for the home tip card, by spending behavior.
   Returns { tone, icon, title, text }. tone: warn | tip | good */
function selectHomeTip(s) {
  const hb = selectHomeBudget(s);
  const report = selectMonthReport(s);
  const total = report.total || 0;
  const byCat = spendByCat(selectMonthTx(s));
  const share = (cat) => total ? (byCat[cat] || 0) / total : 0;

  // 1) overspent → small 3-day recovery plan
  if (hb.status === "over") {
    const over = hb.monthlySpent - hb.monthlyBudget;
    const perDay = Math.max(1, Math.ceil(over / 3));
    return { tone: "warn", icon: "life-buoy", title: "3 天补救小计划",
      text: "本月超了 ¥" + over + "。接下来 3 天每天少花 ¥" + perDay + "，很快就能补回来，别有压力。" };
  }
  // 2) 餐饮 high → reduce 外卖 / 奶茶
  if (share("food") >= 0.4) {
    return { tone: "tip", icon: "utensils", title: "餐饮花得偏多",
      text: "外卖少点几次、奶茶改成一周两杯，省下的钱可以存进目标。" };
  }
  // 3) 交通 high → walk / bike / subway / bus
  if (share("transit") >= 0.18) {
    return { tone: "tip", icon: "bus-front", title: "交通可以省一省",
      text: "近的路程走路或骑车，远一点坐地铁、公交，比打车省一半。" };
  }
  // 4) safe with budget left → encourage saving
  if (hb.status === "safe" && hb.remaining > 0) {
    return { tone: "good", icon: "piggy-bank", title: "花销很健康",
      text: "这个月还剩 ¥" + hb.remaining + "，把一部分存进目标，攒钱更快 🌱" };
  }
  // 5) default — gentle habit nudge
  return { tone: "good", icon: "sparkles", title: "保持记账习惯",
    text: "花了钱随手记一笔，月底就能清楚看到钱去哪了。" };
}

/* ============================================================
   金融小课堂 — learning selectors (read LESSONS constant + progress)
   ============================================================ */
function selectLearningProgress(s) {
  const done = (s.lessonProgress || []);
  const total = LESSONS.length;
  const completed = done.filter(id => LESSONS.some(l => l.id === id)).length;
  return { completed, total, pct: total ? Math.round(completed / total * 100) : 0, doneIds: done };
}

/* 理财小课堂·游戏 — completion progress (reads GAMES constant + progress) */
function selectGameProgress(s) {
  const done = (s.gameProgress || []);
  const total = (typeof GAMES !== "undefined" ? GAMES.length : 0);
  const completed = done.filter(id => (typeof GAMES !== "undefined") && GAMES.some(g => g.id === id)).length;
  return { completed, total, pct: total ? Math.round(completed / total * 100) : 0, doneIds: done };
}

/* recommend lessons based on real spending behavior. Returns
   [{ lesson, reason }] ordered by relevance (most useful first). */
function selectRecommendedLessons(s) {
  const rows = selectBudgetRows(s);
  const report = selectMonthReport(s);
  const done = new Set(s.lessonProgress || []);
  const byId = (id) => LESSONS.find(l => l.id === id);
  const recs = [];
  const push = (id, reason) => { const l = byId(id); if (l && !done.has(id)) recs.push({ lesson: l, reason }); };

  // no transactions yet → learn why to track
  if (s.transactions.length === 0) push("habit-why", "你还没有记录，先看看为什么要记账");
  // 餐饮 over budget or dominant → takeout lesson
  const food = rows.find(r => r.cat === "food");
  if ((food && food.status === "over") || report.topCat === "food") push("spend-takeout", "餐饮花得偏高，看看怎么减少外卖支出");
  // any over-budget → budget basics
  if (rows.some(r => r.status === "over")) push("budget-split", "有分类超预算了，学学怎么分配生活费");
  // no savings goal → small-goal lesson
  if (!s.savingsGoals || s.savingsGoals.length === 0) push("save-smallgoal", "还没有储蓄目标，试试设一个小目标");

  // always offer a gentle default so the slot is never empty
  if (recs.length === 0) push("save-first", "想多存一点？看看「先存后花」");
  if (recs.length === 0) push("budget-what", "花点时间打好理财基础");
  return recs;
}

/* ============================================================
   省钱搭子 AI — local rule-based reply engine.
   ▶ BACKEND: replace generateLocalAIReply() with a call to
       POST /api/ai/chat  { message, context }
     where `context` = the storeData summary below. The async
     boundary is already isolated in the screen (sendMessage),
     so swapping local → remote is a one-function change.
   ---------------------------------------------------------------
   Returns a plain string (simple, supportive, jargon-free Chinese).
   `storeData` is the whole store state.
   ============================================================ */
function generateLocalAIReply(message, storeData) {
  const s = storeData;
  const msg = (message || "").toLowerCase();
  const stats = selectStats(s);
  const report = selectMonthReport(s);
  const rows = selectBudgetRows(s);
  const hb = selectHomeBudget(s);              // status: none|safe|close|over
  const prog = selectLearningProgress(s);
  const topZh = report.topCat ? CATS[report.topCat].zh : "餐饮";
  const goals = s.savingsGoals || [];
  const activeCh = selectActiveChallenges(s);
  const has = (...kw) => kw.some(k => msg.includes(k.toLowerCase()));
  const yuan = (n) => "¥" + (n || 0).toLocaleString("en-US");
  const cat = (k) => rows.find(r => r.cat === k) || { spent: 0, total: 0, status: "unset" };

  // reusable action chips (route strings are handled by the AI screen → open()/startChallenge)
  const A = {
    add:        { label: "去记一笔",   route: "add",        icon: "plus" },
    budget:     { label: "设置预算",   route: "budget",     icon: "sliders-horizontal" },
    goal:       { label: "创建储蓄目标", route: "goal",      icon: "piggy-bank" },
    deposit:    { label: "去存钱",     route: "goal",        icon: "piggy-bank" },
    challenges: { label: "查看挑战",   route: "challenges", icon: "flag" },
    learn:      { label: "去小课堂",   route: "learn",      icon: "graduation-cap" },
  };
  const lesson = (id, label) => ({ label: label || "学一课", route: "lesson:" + id, icon: "graduation-cap" });
  const chal = (id, label) => ({ label: label || "开始挑战", route: "challenge:" + id, icon: "flag" });
  const story = (id, label) => ({ label: label || "进入故事", route: "game:" + id, icon: "book-open" });
  const reply = (text, actions) => ({ text, actions: actions || [] });
  const hasData = s.transactions.length > 0;

  // ---------- 0) no data at all ----------
  if (!hasData && (has("花", "多", "存", "预算", "计划", "怎么", "建议", "搭子") || !msg)) {
    return reply("你还没记过账，我暂时看不到你的花销～先随手记几笔（哪怕 ¥2 的奶茶），我就能帮你分析钱花在哪、怎么省了。", [A.add, lesson("habit-why", "学：为什么要记账")]);
  }

  // ---------- 1) 我还能存多少钱 ----------
  if (has("还能存", "能存多少", "存多少", "可以存")) {
    if (hb.status === "none") return reply("先设一个本月预算，我就能算出大概还能省下多少钱啦。", [A.budget, A.goal]);
    if (hb.remaining <= 0) return reply("这个月预算已经用完了，这个月先别勉强存。下个月发钱当天先存一小笔，会稳很多。", [A.budget, lesson("save-first", "学：先存后花")]);
    const perWeek = Math.max(1, Math.ceil(hb.remaining / Math.max(1, Math.ceil(hb.daysLeft / 7))));
    let t = "按现在的节奏，这个月大概还能省下 " + yuan(hb.remaining) + "（还剩 " + hb.daysLeft + " 天）。每周存 " + yuan(perWeek) + " 就能把它攒下来。";
    if (goals.length) t += "放进「" + goals[0].name + "」里，进度看得见更有动力。";
    return reply(t, goals.length ? [A.deposit] : [A.goal]);
  }

  // ---------- 2) 我这个月花太多了吗 / 算多吗 ----------
  if (has("花太多", "太多", "花多了吗", "算多", "超支", "超了", "超预算")) {
    if (hb.status === "none") return reply("你还没设预算，我没法判断算不算多。先设个本月总预算，我就能帮你盯着了。", [A.budget, A.add]);
    if (hb.status === "over") {
      const over = hb.monthlySpent - hb.monthlyBudget, perDay = Math.max(1, Math.ceil(over / 3));
      const od = rows.filter(r => r.status === "over").map(r => CATS[r.cat].zh);
      return reply("这个月花了 " + yuan(hb.monthlySpent) + "，超过预算 " + yuan(over) + " 了" + (od.length ? "，主要是「" + od.join("、") + "」" : "") + "。别太担心，接下来 3 天每天少花 " + yuan(perDay) + " 就能慢慢补回来。", [A.budget, chal("no-takeout-3", "试试省钱挑战")]);
    }
    if (hb.status === "close") return reply("这个月花了 " + yuan(hb.monthlySpent) + "，预算用了 " + hb.pct + "%，有点接近上限了。重点看看「" + topZh + "」，接下来稍微省一省就好。", [A.budget, lesson("spend-need", "学：想要还是需要")]);
    return reply("还好～这个月花了 " + yuan(hb.monthlySpent) + "，预算才用了 " + hb.pct + "%，控制得不错 剩下的可以存一点进目标。", goals.length ? [A.deposit] : [A.goal]);
  }

  // ---------- 3) 餐饮 / 外卖 / 奶茶 ----------
  if (has("外卖", "奶茶", "餐饮", "吃饭", "吃的")) {
    const f = cat("food");
    return reply("你这个月餐饮花了 " + yuan(f.spent) + "，是不小的一块。不用一下子改很多 —— 试试『3 天不点外卖』，坚持 3 天，省下的钱直接存进目标，很有成就感。", [chal("no-takeout-3", "开始 3 天挑战"), story("want-need", "想要还是需要？")]);
  }

  // ---------- 4) 交通 / 地铁 / 打车 ----------
  if (has("交通", "地铁", "公交", "打车", "路费", "车费")) {
    const tr = cat("transit");
    return reply("交通这个月花了 " + yuan(tr.spent) + "。近的路程走路或骑共享单车，远一点坐地铁、公交，比打车省一半。如果是周末回家的路费，可以单独设一个小目标提前攒。", [A.goal, A.budget]);
  }

  // ---------- 5) 省钱计划 / 怎么省 ----------
  if (has("省钱计划", "省钱方法", "怎么省", "省钱", "计划")) {
    const lines = ["给你一个本周省钱小计划："];
    lines.push("① 每天记账，先看清钱花在哪");
    lines.push("② 重点盯住「" + topZh + "」，这周比上周少花一点");
    lines.push("③ 发钱/有零花当天，先存一小笔再花");
    return reply(lines.join("\n"), [A.add, chal("daily-log", "开始 每天记账"), goals.length ? A.deposit : A.goal]);
  }

  // ---------- 6) 今天还能花多少 ----------
  if (has("今天", "还能花", "还可以花")) {
    if (hb.status === "none") return reply("先设个本月预算，我就能算出你今天大概还能花多少。", [A.budget]);
    return hb.todayAvailable > 0
      ? reply("今天大概还可以花 " + yuan(hb.todayAvailable) + "（本月剩 " + yuan(hb.remaining) + "，还有 " + hb.daysLeft + " 天）。控制在这个数以内，月底会轻松很多", [A.add])
      : reply("这个月预算用得差不多了，今天尽量省一省。明天少花一点慢慢补回来就好，别有压力。", [A.budget]);
  }

  // ---------- 7) 哪里花多了 ----------
  if (has("哪里花", "花得快", "钱去哪", "钱怎么没")) {
    const r0 = report.rows[0];
    if (!r0) return reply("这个月还没什么支出记录，先坚持记几笔，我就能帮你看出钱花在哪了。", [A.add]);
    return reply("这个月花得最多的是「" + CATS[r0.cat].zh + "」，" + yuan(r0.v) + "，占了 " + r0.pct + "%。可以先从这一类想办法省一点。", [A.budget]);
  }

  // ---------- 8) 存不下钱 / 怎么存 ----------
  if (has("存不下", "攒不下", "留不住", "存钱", "攒钱", "想存")) {
    const t = "存不下钱，多半是「月底有剩再存」。换个顺序：发钱当天先存一小笔，剩下的再安排日常，就稳了。哪怕每月只存 ¥50 也是进步。";
    return reply(t, goals.length ? [A.deposit, lesson("save-first", "学：先存后花")] : [A.goal, lesson("save-smallgoal", "学：设个小目标")]);
  }

  // ---------- 9) 做预算 / 怎么规划 ----------
  if (has("做预算", "预算", "规划", "怎么分", "分配")) {
    return reply("学生做预算很简单：先算这个月一共有多少钱，再分给餐饮、交通、学习、娱乐，留一点备用。每周看一眼有没有超支就行。", [A.budget, lesson("budget-split", "学：生活费怎么分")]);
  }

  // ---------- 10) 学习 / 课程 ----------
  if (has("学", "课", "知识")) {
    const tip = prog.completed === 0 ? "你还没学过课程，每节只要 3 分钟，挑一个最想解决的问题开始吧。" : "你已经学完 " + prog.completed + "/" + prog.total + " 节啦，继续保持～";
    return reply(tip, [A.learn]);
  }

  // ---------- 10) 防骗 / 网贷 / 密码 / 投资 ----------
  if (has("骗", "防骗", "网贷", "借钱", "密码", "验证码", "稳赚", "投资")) {
    return reply("记住三句话：陈生链接不点、验证码不给人、「稳赚」一律不信。想练练眼力，去玩一遍「防骗大作战」，看看常见套路你能不能都躲过。", [story("anti-scam", "防骗大作战"), lesson("safety-password", "学：保护密码")]);
  }
  // ---------- 11) 兼职 / 赚钱 / 应急 ----------
  if (has("兼职", "打工", "赚钱", "应急", "护金")) {
    return reply("想自己赚点零花钱是好事，但路上也有坑。玩一遍「爆胎的自行车」，体验一下兼职路上的应急与借款选择，平时攒一笔小应急金。", [story("flat-tire", "爆胎的自行车"), A.goal]);
  }
  // ---------- 12) 相关故事 / 推荐 ----------
  if (has("故事", "情景", "推荐故事")) {
    const fs = selectFeaturedStory(s);
    return reply("故事里做几次选择，比听道理更记得住。要不要试试「" + (fs ? fs.title : "想要还是需要？") + "」？几分钟就能走一遍。", fs ? [story(fs.id, "进入故事")] : []);
  }

  // ---------- 13) default — data-aware overview ----------
  const parts = ["我是省钱搭子，可以帮你看花销、想省钱办法、定存钱计划。"];
  parts.push("这个月你花了 " + yuan(report.total) + "，最多的是「" + topZh + "」。");
  if (hb.status === "over") parts.push("预算有点超了，我们一起慢慢补回来。");
  else if (hb.status === "close") parts.push("预算快到上限了，接下来省一省。");
  const acts = [];
  if (goals.length) { const g = goals[0]; parts.push("目标「" + g.name + "」已存 " + yuan(g.saved) + "/" + g.total + "，加油"); acts.push(A.deposit); }
  else acts.push(A.goal);
  acts.push(A.add);
  if (prog.completed === 0) acts.push(A.learn);
  return reply(parts.join(""), acts);
}

/* ============================================================
   省钱挑战 — challenge selectors (read CHALLENGE_DEFS + instances)
   ============================================================ */
const _todayKey = () => NOW.toDateString();           // "Thu Dec 18 2025"
function _enrichChallenge(c) {
  const def = CHALLENGE_DEFS.find(d => d.id === c.defId) || {};
  const days = (c.checkDays || []).length;
  const checkedToday = (c.checkDays || []).includes(_todayKey());
  return { ...def, ...c, def, progress: days, total: def.days || 1, pct: def.days ? Math.round(days / def.days * 100) : 0, checkedToday };
}
function selectActiveChallenges(s) {
  return (s.challenges || []).filter(c => c.status === "active").map(_enrichChallenge);
}
function selectCompletedChallenges(s) {
  return (s.challenges || []).filter(c => c.status === "done").map(_enrichChallenge);
}
/* recommend challenges from spending behavior (exclude already-started) */
function selectRecommendedChallenges(s) {
  const rows = selectBudgetRows(s);
  const report = selectMonthReport(s);
  const taken = new Set((s.challenges || []).map(c => c.defId));
  const byId = (id) => CHALLENGE_DEFS.find(d => d.id === id);
  const recs = [];
  const push = (id, reason) => { const d = byId(id); if (d && !taken.has(id)) recs.push({ def: d, reason }); };

  if (s.transactions.length === 0) push("daily-log", "先从每天记账开始，看清钱花在哪");
  const food = rows.find(r => r.cat === "food");
  if ((food && food.status === "over") || report.topCat === "food") push("no-takeout-3", "餐饮偏高，试试 3 天不点外卖");
  const transit = rows.find(r => r.cat === "transit");
  if ((transit && (transit.status === "over" || transit.status === "near")) || report.topCat === "transit") push("transit-walk", "交通花得多，能走就走、能骑就骑");
  const fun = rows.find(r => r.cat === "fun");
  if (fun && (fun.status === "over" || fun.status === "near")) push("less-milktea", "娱乐快到上限了，先从奶茶省起");
  push("daily-log", "养成每天记账的习惯");
  push("no-impulse-7", "练习忍住冲动消费");
  return recs;
}

/* ============================================================
   PERSISTENCE — localStorage, versioned. Backend-ready.
   ▶ BACKEND: swap loadState/saveState for GET / PUT to your API
     (e.g. GET /state on boot, debounced PUT /state on change). The
     state object is already flat & JSON-serializable.
   ============================================================ */
const STORAGE_KEY = "budgetbuddy_china_v1";

/* Dates survive JSON as ISO strings — revive transaction timestamps. */
function reviveDates(s) {
  if (s && Array.isArray(s.transactions)) {
    s.transactions = s.transactions.map(t => ({ ...t, ts: new Date(t.ts) }));
  }
  return s;
}
function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);          // ▶ BACKEND: GET /state
    if (!raw) return seed();
    const parsed = JSON.parse(raw);
    // sanity-check the shape; fall back to seed if broken
    if (!parsed || !Array.isArray(parsed.transactions) || !Array.isArray(parsed.budgets) || !Array.isArray(parsed.savingsGoals)) {
      return seed();
    }
    // forward-compat: merge defaults for keys added in later versions
    if (!Array.isArray(parsed.lessonProgress)) parsed.lessonProgress = [];
    if (!Array.isArray(parsed.gameProgress)) parsed.gameProgress = [];
    if (!Array.isArray(parsed.challenges)) parsed.challenges = [];
    return reviveDates(parsed);
  } catch (e) {
    return seed();                                          // corrupt JSON → seed
  }
}
function saveState(s) {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(s)); } catch (e) { /* quota/private mode — ignore */ }
}                                                            // ▶ BACKEND: PUT /state

/* Merge defaults for any missing slices in a state object (forward-compat for
   data coming back from the backend or an older client). Mirrors loadState(). */
function withDefaults(parsed) {
  // Only fill MISSING keys with neutral/empty values — never inject demo data
  // (so a blank real account stays blank after a reload from the backend).
  if (!parsed || typeof parsed !== "object") return emptyState();
  if (!Array.isArray(parsed.transactions)) parsed.transactions = [];
  if (!Array.isArray(parsed.budgets)) parsed.budgets = [];
  if (!Array.isArray(parsed.savingsGoals)) parsed.savingsGoals = [];
  if (!parsed.settings) parsed.settings = { dailyBudget: 0, monthlyBudget: 0 };
  if (!parsed.userProfile) parsed.userProfile = { name: "同学", greet: "同学", joinDays: 0 };
  if (!parsed.prevMonth) parsed.prevMonth = { total: 0 };
  if (!Array.isArray(parsed.lessonProgress)) parsed.lessonProgress = [];
  if (!Array.isArray(parsed.gameProgress)) parsed.gameProgress = [];
  if (!Array.isArray(parsed.challenges)) parsed.challenges = [];
  return parsed;
}

/* ============================================================
   AUTH — local session simulation (student side only, no parent).
   Kept in its OWN localStorage key, separate from app data, so a
   real auth API can replace just this slice without touching the
   transaction/budget store.
   ▶ BACKEND MAP (swap these for real calls, store a token not the
     password list):
       register()  → POST /auth/register
       login()     → POST /auth/login   (returns { token, user })
       logout()    → POST /auth/logout  (or just drop the token)
       loadAuth()  → GET  /auth/me      (resolve token → user)
   ============================================================ */
/* AUTH — now backed by the real PHP API (PHP session in an HttpOnly cookie).
   localStorage holds ONLY a non-sensitive UI cache of the user (so the app
   paints instantly on refresh); the session is always re-verified via
   GET /api/auth/me on boot. No password / token is ever stored here. */
const AUTH_KEY = "budgetbuddy_user_v2";       // { user: {id,identifier,nickname,ageGroup} }
const ONBOARDED_KEY = "budgetbuddy_onboarded_v1";

function loadCachedUser() {
  try {
    const raw = localStorage.getItem(AUTH_KEY);
    if (!raw) return null;
    const a = JSON.parse(raw);
    return (a && a.user && a.user.id) ? a.user : null;
  } catch (e) { return null; }
}
function saveCachedUser(user) {
  try {
    if (user) localStorage.setItem(AUTH_KEY, JSON.stringify({ user }));
    else localStorage.removeItem(AUTH_KEY);
  } catch (e) { /* ignore */ }
}

/* onboarding-seen flag (so we don't replay the intro every logout) */
function hasOnboarded() { try { return !!localStorage.getItem(ONBOARDED_KEY); } catch (e) { return false; } }
function setOnboarded() { try { localStorage.setItem(ONBOARDED_KEY, "1"); } catch (e) { /* ignore */ } }

/* identity helpers */
function normId(v) { return (v || "").trim().toLowerCase().replace(/\s+/g, ""); }
function detectIdType(v) { return (v || "").includes("@") ? "email" : "phone"; }

/* ---- pure validators — return an error string, or "" when valid ---- */
function validateIdentifier(v) { return (v || "").trim() ? "" : "请输入手机号或邮箱"; }
function validatePassword(v) { return (v || "").length < 6 ? "密码至少需要 6 位" : ""; }
function validateNickname(v) { return (v || "").trim() ? "" : "请输入昵称"; }

/* age groups offered at register (student-friendly) */
const AGE_GROUPS = ["14岁以下", "14–17岁", "18–22岁", "23岁以上"];

/* ============================================================
   STORE PROVIDER + hook
   ============================================================ */
const StoreCtx = createCtx(null);

function StoreProvider({ children }) {
  const [state, setState] = useStoreState(loadState);
  const [currentUser, setCurrentUser] = useStoreState(loadCachedUser);  // UI cache, verified via /me
  const [authChecked, setAuthChecked] = useStoreState(false);           // has boot /me resolved?

  // ---- backend sync plumbing -------------------------------------------
  // latest state, readable inside async callbacks without stale closures
  const stateRef = React.useRef(state);
  React.useEffect(() => { stateRef.current = state; }, [state]);
  // true once this user's state has loaded from MySQL, so a debounced change is
  // allowed to PUT (never overwrite the cloud with the seed before we've fetched)
  const syncReadyRef = React.useRef(false);
  const saveTimerRef = React.useRef(null);

  // best-effort PUT of the whole app_state. localStorage already holds it as an
  // offline cache, so a failed save just retries on the next change.
  const saveAppStateNow = async (s) => {
    try { await window.apiClient.saveAppState(s); } catch (e) { /* offline — keep local */ }
  };                                                         // ▶ BACKEND: PUT /api/state

  // load this user's state from MySQL and make it the source of truth. A brand
  // new account (no saved state) starts from a fresh seed() pushed up to MySQL.
  const syncFromBackend = async () => {
    try {
      const data = await window.apiClient.loadAppState();    // GET /api/state → { appState }
      const remote = data && data.appState;
      if (remote && Array.isArray(remote.transactions)) {
        setState(reviveDates(withDefaults(remote)));         // cloud = source of truth
      } else {
        const fresh = startStateForNewUser();                // new account → demo seed (default) or blank
        setState(fresh);
        await saveAppStateNow(fresh);
      }
      syncReadyRef.current = true;
      return true;
    } catch (e) {
      syncReadyRef.current = false;                          // offline → localStorage stays authoritative
      return false;
    }
  };

  // persist on every change: always cache to localStorage (offline fallback);
  // when logged in AND synced, debounce a PUT to the backend (700ms).
  React.useEffect(() => {
    saveState(state);                                        // ▶ offline cache (localStorage)
    if (currentUser && syncReadyRef.current) {
      clearTimeout(saveTimerRef.current);
      saveTimerRef.current = setTimeout(() => { saveAppStateNow(stateRef.current); }, 700);   // ▶ BACKEND: PUT /api/state
    }
    return () => clearTimeout(saveTimerRef.current);
  }, [state, currentUser]);

  React.useEffect(() => { saveCachedUser(currentUser); }, [currentUser]);

  // mirror the logged-in identity into the app's userProfile so every
  // existing screen (Home greeting, Profile) shows the real nickname.
  const applyIdentity = (u) => {
    if (!u) return;
    setState(s => ({ ...s, userProfile: { ...s.userProfile, name: u.nickname, greet: u.nickname, ageGroup: u.ageGroup || "" } }));
  };
  React.useEffect(() => { if (currentUser) applyIdentity(currentUser); }, [currentUser && currentUser.id]);

  // boot: verify the PHP session cookie and hydrate the real user (this is
  // what makes the session persist across refreshes).
  React.useEffect(() => {
    let live = true;
    (async () => {
      try {
        const data = await window.apiClient.authMe();     // GET /api/auth/me → { user|null }
        const user = (data && data.user) || null;
        if (user) { await syncFromBackend(); }            // hydrate this user's app data from MySQL
        if (live) setCurrentUser(user);
      } catch (e) {
        /* backend unreachable → keep cached user + localStorage data so the app still opens offline */
      } finally {
        if (live) setAuthChecked(true);
      }
    })();
    return () => { live = false; };
  }, []);

  /* ---- AUTH writers — async, backed by the PHP API (no plaintext stored) ---- */
  const register = async ({ identifier, password, nickname, ageGroup }) => {
    const err = validateIdentifier(identifier) || validatePassword(password) || validateNickname(nickname);
    if (err) return { ok: false, error: err };
    try {
      const data = await window.apiClient.authRegister({   // POST /api/auth/register (creates user + empty state + session)
        identifier: (identifier || "").trim(), password, nickname: (nickname || "").trim(), ageGroup: ageGroup || "",
      });
      await syncFromBackend();                             // brand-new account → fresh seed pushed to MySQL
      setCurrentUser(data.user);
      return { ok: true, user: data.user };
    } catch (e) { return { ok: false, error: e.message || "注册失败，请稍后再试" }; }
  };

  const login = async ({ identifier, password }) => {
    const err = validateIdentifier(identifier);
    if (err) return { ok: false, error: err };
    if (!password) return { ok: false, error: "请输入密码" };
    try {
      const data = await window.apiClient.authLogin({ identifier: (identifier || "").trim(), password });  // POST /api/auth/login
      await syncFromBackend();                             // load this user's saved data from MySQL
      setCurrentUser(data.user);
      return { ok: true, user: data.user };
    } catch (e) { return { ok: false, error: e.message || "登录失败，请稍后再试" }; }
  };

  const logout = async () => {
    clearTimeout(saveTimerRef.current);                     // cancel any pending save
    syncReadyRef.current = false;
    try { await window.apiClient.authLogout(); } catch (e) { /* ignore network */ }  // POST /api/auth/logout
    setCurrentUser(null);
    try { localStorage.removeItem(STORAGE_KEY); } catch (e) { /* ignore */ }
    setState(startStateForNewUser());                       // clear in-memory data so the next account starts clean
  };

  /* ---- WRITERS (clearly named, the only ways state mutates) ---- */

  const addTransaction = ({ amount, cat, note, kind, date, reflect }) => {
    const amt = Math.round((parseFloat(amount) || 0) * 100) / 100;
    if (amt <= 0) return;
    const ts = date ? new Date(date) : new Date(NOW);   // default = 今天
    const tx = { id: uid(), kind: kind || "out", cat, note: note || CATS[cat].zh, amount: amt, ts, reflect: reflect || null };
    // keep the ledger in reverse-chronological order even for back-dated entries
    setState(s => ({ ...s, transactions: [tx, ...s.transactions].sort((a, b) => b.ts - a.ts) }));   // ▶ BACKEND: POST /transactions
  };

  // delete one transaction (Home + 记账 both re-derive from this live)
  const deleteTransaction = (id) => {
    setState(s => ({ ...s, transactions: s.transactions.filter(t => t.id !== id) }));   // ▶ BACKEND: DELETE /transactions/:id
  };

  const depositToGoal = (goalId, amount) => {
    const amt = Math.round(parseFloat(amount) || 0);
    if (amt <= 0) return;
    setState(s => ({
      ...s,
      savingsGoals: s.savingsGoals.map(g =>
        g.id === goalId ? { ...g, saved: Math.min(g.total, g.saved + amt) } : g),
    }));                                                                  // ▶ BACKEND: POST /goals/:id/deposit
  };

  // add a brand-new savings goal. Returns false if invalid (caller shows error).
  const addSavingsGoal = ({ name, total, saved, deadline }) => {
    const nm = (name || "").trim();
    const t = Math.round(parseFloat(total) || 0);
    const sv = Math.round(parseFloat(saved) || 0);
    if (!nm || t <= 0 || sv < 0 || sv > t) return false;
    setState(s => {
      const pal = GOAL_PALETTE[s.savingsGoals.length % GOAL_PALETTE.length];
      const goal = { id: "g" + rid(), name: nm, total: t, saved: sv, deadline: deadline || null, ...pal };
      return { ...s, savingsGoals: [...s.savingsGoals, goal] };          // ▶ BACKEND: POST /goals
    });
    return true;
  };

  // edit a category's monthly budget (upserts if the category had none). false if invalid.
  const updateBudget = (cat, total) => {
    const t = Math.round(parseFloat(total) || 0);
    if (t <= 0) return false;
    setState(s => {
      const exists = (s.budgets || []).some(b => b.cat === cat);
      const budgets = exists ? s.budgets.map(b => b.cat === cat ? { ...b, total: t } : b)
        : [...(s.budgets || []), { cat, total: t }];
      return { ...s, budgets };
    });                                                                  // ▶ BACKEND: PATCH /budgets/:cat
    return true;
  };

  // set the overall monthly total budget (本月总预算). false if invalid.
  const updateMonthlyBudget = (total) => {
    const t = Math.round(parseFloat(total) || 0);
    if (t <= 0) return false;
    setState(s => ({ ...s, settings: { ...s.settings, monthlyBudget: t } }));   // ▶ BACKEND: PATCH /budget/monthly
    return true;
  };

  // edit an existing savings goal (name/target/saved/deadline). false if invalid.
  const updateGoal = (id, { name, total, saved, deadline }) => {
    const nm = (name || "").trim();
    const t = Math.round(parseFloat(total) || 0);
    const sv = Math.round(parseFloat(saved) || 0);
    if (!nm || t <= 0 || sv < 0 || sv > t) return false;
    setState(s => ({ ...s, savingsGoals: s.savingsGoals.map(g =>
      g.id === id ? { ...g, name: nm, total: t, saved: sv, deadline: deadline || null } : g) }));   // ▶ BACKEND: PATCH /goals/:id
    return true;
  };

  // delete a savings goal
  const deleteGoal = (id) => {
    setState(s => ({ ...s, savingsGoals: s.savingsGoals.filter(g => g.id !== id) }));   // ▶ BACKEND: DELETE /goals/:id
  };

  // settings: 恢复默认数据 — wipe persistence and reset to a fresh new-user state
  // (blank in production, demo seed in dev — same as a brand-new account)
  const resetStore = () => {
    try { localStorage.removeItem(STORAGE_KEY); } catch (e) { /* ignore */ }
    setState(startStateForNewUser());
  };

  // 金融小课堂: toggle a lesson's completed state (idempotent add/remove)
  const markLessonComplete = (lessonId, done = true) => {
    setState(s => {
      const set = new Set(s.lessonProgress || []);
      if (done) set.add(lessonId); else set.delete(lessonId);
      return { ...s, lessonProgress: Array.from(set) };   // ▶ BACKEND: PUT /api/lessons/:id/progress
    });
  };

  // 理财小课堂·游戏: mark a game as completed (idempotent add/remove)
  const markGameComplete = (gameId, done = true) => {
    setState(s => {
      const set = new Set(s.gameProgress || []);
      if (done) set.add(gameId); else set.delete(gameId);
      return { ...s, gameProgress: Array.from(set) };   // ▶ BACKEND: PUT /api/games/:id/progress
    });
  };

  /* ---- 省钱挑战 writers ---- */
  // start a challenge (no-op if one for this def is already active/done)
  const startChallenge = (defId) => {
    setState(s => {
      if ((s.challenges || []).some(c => c.defId === defId && c.status !== "abandoned")) return s;
      const inst = { id: "ch" + Date.now(), defId, status: "active", startDay: NOW.toDateString(), checkDays: [] };
      return { ...s, challenges: [...(s.challenges || []), inst] };   // ▶ BACKEND: POST /api/challenges
    });
  };
  // daily check-in (one per app-day); auto-completes when all days are done
  const checkInChallenge = (instId) => {
    const today = NOW.toDateString();
    setState(s => ({
      ...s,
      challenges: (s.challenges || []).map(c => {
        if (c.id !== instId || c.status !== "active") return c;
        if ((c.checkDays || []).includes(today)) return c;          // already checked in today
        const checkDays = [...(c.checkDays || []), today];
        const def = CHALLENGE_DEFS.find(d => d.id === c.defId);
        const status = def && checkDays.length >= def.days ? "done" : "active";
        return { ...c, checkDays, status };                          // ▶ BACKEND: POST /api/challenges/:id/checkin
      }),
    }));
  };
  // mark a challenge complete manually
  const completeChallenge = (instId) => {
    setState(s => ({ ...s, challenges: (s.challenges || []).map(c => c.id === instId ? { ...c, status: "done" } : c) }));
  };

  // edit the display nickname (updates userProfile + the logged-in auth user). false if empty.
  const updateNickname = (name) => {
    const nm = (name || "").trim();
    if (!nm) return false;
    setState(s => ({ ...s, userProfile: { ...s.userProfile, name: nm, greet: nm } }));
    setCurrentUser(u => (u ? { ...u, nickname: nm } : u));   // local display only (no PATCH /me in scope)
    return true;
  };

  const api = { state, currentUser, authChecked, register, login, logout, addTransaction, deleteTransaction, depositToGoal, addSavingsGoal, updateGoal, deleteGoal, updateBudget, updateMonthlyBudget, updateNickname, resetStore, markLessonComplete, markGameComplete, startChallenge, checkInChallenge, completeChallenge };
  return <StoreCtx.Provider value={api}>{children}</StoreCtx.Provider>;
}
const useStore = () => useContext(StoreCtx);

Object.assign(window, {
  NOW, sameDay, sameMonth, dayLabel, fmtTime, fmtDateLong, APP_VERSION,
  seed, emptyState, startStateForNewUser,
  StoreProvider, useStore, hasOnboarded, setOnboarded, AGE_GROUPS,
  selectStats, selectBudgetRows, selectMonthReport, selectAdvice, selectNudge,
  selectGreeting, daysLeftInMonth, selectHomeBudget, selectSavingReminder, selectFeaturedGoal, selectHomeTip, selectGoalSuggestion,
  selectWeeklySummary, selectFeaturedStory,
  selectMonthTx, selectTodayTx, selectWeekTx, spendByCat,
  selectLearningProgress, selectGameProgress, selectRecommendedLessons, generateLocalAIReply,
  selectActiveChallenges, selectCompletedChallenges, selectRecommendedChallenges,
});
