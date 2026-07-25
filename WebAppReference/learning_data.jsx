/* ============================================================
   learning_data.jsx — 金融小课堂 content (static, not persisted)
   ------------------------------------------------------------
   Lesson content is static product content, so it lives here as
   a constant — NOT in the serializable store. Only the user's
   *progress* (completed lesson ids) is persisted in store state.

   ▶ BACKEND: later this whole array can come from GET /api/lessons.
   Each lesson is flat & serializable; the `video` block already
   matches an external-video schema (provider + url + thumbnail).
   ============================================================ */

/* lesson categories (zh label + icon + brand tint) */
const LEARN_CATS = {
  budget: { zh: "预算入门", icon: "calculator",   tint: "var(--blue-50)",   fg: "var(--blue-500)" },
  habit:  { zh: "记账习惯", icon: "notebook-pen", tint: "var(--green-50)",  fg: "var(--green-600)" },
  save:   { zh: "储蓄目标", icon: "piggy-bank",   tint: "var(--green-50)",  fg: "var(--green-600)" },
  spend:  { zh: "消费提醒", icon: "hand-coins",   tint: "var(--orange-50)", fg: "var(--orange-500)" },
  safety: { zh: "基础金融安全", icon: "shield-check", tint: "var(--red-50)", fg: "var(--red-500)" },
};

/* difficulty levels → small colored badge */
const LEVELS = {
  入门: { bg: "var(--blue-50)", fg: "var(--blue-600)" },
  简单: { bg: "var(--green-50)", fg: "var(--green-700)" },
  重要: { bg: "var(--orange-50)", fg: "var(--orange-700)" },
};

/* video providers → label (for the "来自 …" line) */
const VIDEO_PROVIDERS = {
  bilibili: "Bilibili",
  tencent: "腾讯视频",
  youtube: "YouTube",
  school: "学校自制视频",
  other: "外部链接",
};

/* ---- 12 lessons across 5 categories ---- */
const LESSONS = [
  /* ---------- 预算入门 ---------- */
  {
    id: "budget-what", cat: "budget", title: "什么是预算？", level: "入门", time: "3分钟",
    desc: "花钱之前，先想好每类最多花多少",
    explanation: "预算就是在花钱之前，先想好每一类最多可以花多少钱。它不是限制你，而是帮你避免月底没钱。",
    points: ["先知道自己一共有多少钱", "再分配到餐饮、交通、学习和娱乐", "每周检查一次有没有超支"],
    example: "如果你每月有 ¥1000 生活费，可以先给餐饮 ¥500，交通 ¥150，学习 ¥150，娱乐 ¥100，剩下 ¥100 作为备用。",
    task: "今天设置一个本月餐饮预算。",
    actionType: "budget", actionLabel: "去设置预算",
    video: { videoTitle: "3 分钟看懂什么是预算", videoProvider: "bilibili", videoUrl: "https://www.bilibili.com/", thumbnailUrl: "" },
  },
  {
    id: "budget-split", cat: "budget", title: "每月生活费怎么分？", level: "简单", time: "5分钟",
    desc: "把钱先分成几份，避免一下花光",
    explanation: "拿到生活费先别急着花。把它分成几份，每一份对应一类支出，这样就不会前半个月花太爽、后半个月吃泡面。",
    points: ["固定开支先留出来（话费、交通卡）", "餐饮按天算，别按心情算", "留一小笔备用金应对意外"],
    example: "¥1200 生活费可以这样分：餐饮 ¥600、交通 ¥150、学习 ¥150、娱乐 ¥150，备用 ¥150。",
    task: "把这个月的生活费分成 4 份，写在备忘里。",
    actionType: "budget", actionLabel: "去分配预算",
    video: null,
  },
  /* ---------- 记账习惯 ---------- */
  {
    id: "habit-why", cat: "habit", title: "为什么要记账？", level: "入门", time: "3分钟",
    desc: "记账不是为了省，是为了看清钱去哪了",
    explanation: "很多人月底发现钱没了，却想不起花在哪。记账就是把每一笔花销记下来，过几天回头看，你会很清楚哪类花多了。",
    points: ["看清自己的真实消费习惯", "发现容易忽略的小额支出", "为下个月的预算提供依据"],
    example: "记了一周才发现，光奶茶就花了 ¥48 —— 原来钱是一杯一杯漏掉的。",
    task: "今天把花的每一笔都记下来，哪怕只有 ¥2。",
    actionType: "add", actionLabel: "记一笔",
    video: { videoTitle: "学生记账入门教程", videoProvider: "school", videoUrl: "https://example.edu/video/jizhang", thumbnailUrl: "" },
  },
  {
    id: "habit-keep", cat: "habit", title: "怎么坚持每天记账？", level: "简单", time: "3分钟",
    desc: "三秒记一笔，比记得全更重要",
    explanation: "记账难在坚持。诀窍是把它变简单：花完钱马上记，三秒搞定，别等到晚上再回忆。坚持比完美更重要。",
    points: ["付完款立刻记，趁还没忘", "设一个每天的固定提醒时间", "偶尔忘了也没关系，第二天继续"],
    example: "把记账提醒设在每天 21:00，睡前花十秒补记，慢慢就成习惯了。",
    task: "打开「记账提醒」，设一个你方便的时间。",
    actionType: "challenge", actionArg: "daily-log", actionLabel: "开始 每天记账 挑战",
    video: null,
  },
  /* ---------- 储蓄目标 ---------- */
  {
    id: "save-first", cat: "save", title: "为什么要先存后花？", level: "重要", time: "3分钟",
    desc: "先把要存的钱拿走，剩下的才是能花的",
    explanation: "如果想着「月底有剩再存」，往往一分都剩不下。换个顺序：拿到钱先存一小笔，剩下的再花，存钱就稳了。",
    points: ["发钱当天先存，别等月底", "金额不用大，能坚持最重要", "把存的钱放到不容易动的地方"],
    example: "每月 ¥1200，先存 ¥100 到储蓄目标，剩下 ¥1100 再安排日常，一年就能存下 ¥1200。",
    task: "现在去「目标」页，往任意目标存 ¥10 试试。",
    actionType: "goalTab", actionLabel: "去存钱",
    video: null,
  },
  {
    id: "save-smallgoal", cat: "save", title: "怎么设置一个小目标？", level: "入门", time: "3分钟",
    desc: "目标越具体，越容易坚持",
    explanation: "存钱没动力，常常是因为目标太模糊。把目标变具体：存多少、用来干嘛、什么时候要，进度看得见就有成就感。",
    points: ["给目标起个名字，比如「新手机」", "定一个不太难的金额", "拆成每周的小数额慢慢存"],
    example: "想买 ¥2000 的手机，分 10 个月，每月存 ¥200，每周只要 ¥50。",
    task: "新建一个属于你的储蓄目标。",
    actionType: "newGoal", actionLabel: "新建储蓄目标",
    video: { videoTitle: "怎么定一个能完成的存钱目标", videoProvider: "tencent", videoUrl: "https://v.qq.com/", thumbnailUrl: "" },
  },
  {
    id: "save-emergency", cat: "save", title: "应急备用金是什么？", level: "重要", time: "5分钟",
    desc: "留一笔钱，专门应付意外",
    explanation: "应急备用金是专门留着应对意外的钱，比如生病、手机摔坏。它的作用是：出事时不用借钱，也不用动其他存款。",
    points: ["先攒够一个月生活费就很好", "只在真正紧急时才动用", "用掉之后尽快补回来"],
    example: "每月从生活费里挤 ¥50，半年就有 ¥300 的小应急金，心里踏实很多。",
    task: "为「应急金」目标设一个小数额。",
    actionType: "newGoalNamed", actionArg: "应急备用金", actionLabel: "设置备用金目标",
    video: null,
  },
  /* ---------- 消费提醒 ---------- */
  {
    id: "spend-takeout", cat: "spend", title: "外卖和奶茶为什么容易超支？", level: "入门", time: "3分钟",
    desc: "单笔不贵，加起来很惊人",
    explanation: "外卖和奶茶每次看着不贵，但次数多。一天一杯奶茶，一个月就是几百块。它们最容易在不知不觉中超支。",
    points: ["小额高频的支出最伤预算", "把一个月的奶茶钱加起来看看", "用「次数」给自己定个上限"],
    example: "一杯奶茶 ¥12，一周 4 杯就是 ¥48，一个月接近 ¥200，省一半就能多存 ¥100。",
    task: "给「娱乐」或奶茶定一个每周次数上限。",
    actionType: "challenge", actionArg: "no-takeout-3", actionLabel: "开始 3 天少点外卖挑战",
    video: { videoTitle: "为什么奶茶让你存不下钱", videoProvider: "bilibili", videoUrl: "https://www.bilibili.com/", thumbnailUrl: "" },
  },
  {
    id: "spend-need", cat: "spend", title: "怎么判断「想要」和「需要」？", level: "简单", time: "3分钟",
    desc: "买之前先问自己一句话",
    explanation: "「需要」是没有会影响生活的东西，「想要」是有了更开心但不是必须的。分清这两个，能避免很多冲动消费。",
    points: ["需要：吃饭、交通、学习用品", "想要：第二杯奶茶、新款球鞋", "想要的东西，先等一天再决定"],
    example: "看到一双 ¥300 的鞋很心动，先放进购物车等一天，第二天可能就没那么想要了。",
    task: "下次想买非必需品时，先等 24 小时。",
    actionType: "challenge", actionArg: "no-impulse-7", actionLabel: "开始 不冲动消费 挑战",
    video: null,
  },
  /* ---------- 基础金融安全 ---------- */
  {
    id: "safety-loan", cat: "safety", title: "不要随便借网贷", level: "重要", time: "5分钟",
    desc: "看着方便，利息其实很高",
    explanation: "各种「先用后付」「借钱秒到」看着方便，但利息和手续费往往很高，还不上会越滚越多。学生尽量不要碰网贷。",
    points: ["广告说的「低息」常常不是真的", "借钱要还，还会产生利息", "缺钱先想办法省，别急着借"],
    example: "借 ¥1000 分期，看着每月只还一点，算下来一年可能多还一两百利息。",
    task: "卸载或关闭一个不需要的借贷类 App。",
    video: { videoTitle: "学生为什么要远离网贷", videoProvider: "youtube", videoUrl: "https://www.youtube.com/", thumbnailUrl: "" },
  },
  {
    id: "safety-invest", cat: "safety", title: "不要相信高收益投资", level: "重要", time: "3分钟",
    desc: "承诺稳赚的，多半是骗局",
    explanation: "凡是说「稳赚不赔」「一个月翻倍」的，基本都是骗局。真正的投资都有风险，学生阶段先把钱存好，别想着一夜暴富。",
    points: ["收益越高，风险越大", "「稳赚」「内部消息」都是套路", "先存钱、再慢慢学，别急"],
    example: "同学拉你进「带你赚钱」的群，承诺月入翻倍 —— 这种要直接拒绝。",
    task: "遇到「稳赚」消息时，先和信任的人聊一聊。",
    video: null,
  },
  {
    id: "safety-password", cat: "safety", title: "如何保护支付密码和个人信息？", level: "简单", time: "3分钟",
    desc: "几个小习惯，保住你的钱",
    explanation: "支付密码和验证码就是你钱包的钥匙。养成几个小习惯，就能挡掉大部分骗局和盗刷。",
    points: ["验证码绝不告诉任何人", "支付密码别用生日这种好猜的", "不点陌生短信里的链接"],
    example: "有人发短信说「你的账户异常，点链接验证」—— 这种链接千万别点。",
    task: "检查一下支付密码是不是太好猜，必要时改一下。",
    video: null,
  },
];

/* ============================================================
   省钱挑战 — challenge catalog (static defs; user instances live
   in the store). Each def: id, title, desc, days (duration),
   level (difficulty), est (expected ¥ saved), tip (practical),
   cat (optional), icon, color. ▶ BACKEND: later from GET /api/challenges.
   ============================================================ */
const CHALLENGE_DEFS = [
  { id: "no-takeout-3", title: "3 天不点外卖", desc: "连续 3 天自己吃食堂，省下外卖钱", days: 3, level: "简单", est: 45, cat: "food", icon: "utensils", color: "var(--orange-500)",
    tip: "中午去食堂，晚上煮个面，省下的外卖钱当天就存进目标。" },
  { id: "less-milktea", title: "3 天不买奶茶", desc: "馋的时候先喝口水等十分钟", days: 3, level: "简单", est: 30, cat: "fun", icon: "cup-soda", color: "var(--orange-500)",
    tip: "把奶茶换成自带水或便利店饮料，省下的钱看得见。" },
  { id: "daily-log", title: "7 天记账挑战", desc: "连续 7 天，每天至少记一笔", days: 7, level: "简单", est: 0, icon: "notebook-pen", color: "var(--green-600)",
    tip: "付完款马上记，三秒搞定，别等晚上才回忆。" },
  { id: "transit-walk", title: "交通省钱挑战", desc: "5 天用走路 / 骑车 / 公交代替打车", days: 5, level: "简单", est: 25, cat: "transit", icon: "bus-front", color: "var(--blue-500)",
    tip: "3 公里内走路或骑共享单车，远的坐公交地铁，不打车。" },
  { id: "snack-cap", title: "零食预算挑战", desc: "一周零食花费控制在 ¥30 内", days: 7, level: "简单", est: 35, cat: "fun", icon: "cookie", color: "var(--orange-500)",
    tip: "给零食定个一周上限，买之前先看看还剩多少额度。" },
  { id: "fun-cap-50", title: "本周娱乐 ¥50 挑战", desc: "这一周娱乐花费不超过 ¥50", days: 7, level: "中等", est: 40, cat: "fun", icon: "gamepad-2", color: "var(--blue-500)",
    tip: "把娱乐花费记下来，到 ¥50 就停，剩下的留到下周。" },
  { id: "no-impulse-7", title: "7 天不冲动消费", desc: "想买非必需品先等一天再决定", days: 7, level: "中等", est: 60, icon: "hand-coins", color: "var(--green-600)",
    tip: "想买的非必需品先放购物车，等 24 小时再决定。" },
];

/* ============================================================
   理财小课堂 · 玩游戏 — 像素剧情式财商模拟 (static, frontend-only)
   ------------------------------------------------------------
   每个游戏是一段「轻量视觉小说」：玩家在场景里读剧情、做选择，
   每个选择即时改变状态值并给出后果与理财提示。内容全部静态、
   受控、纯前端 —— 不接入任何 LLM / SillyTavern / 外部 AI / 后端。
   未来若接入叙事 AI，必须经由后端适配层（安全过滤 / 限流 / 提示
   词控制 / 内容审核），前端永不直连。

   数据模型：
     stats     初始状态值（仅出现的键会显示在状态栏）
     statBar   状态栏显示顺序（money/health/credit/risk/mood）
     moneyLabel money 的显示名（默认「余额」）
     goal      可选目标金额
     start     起始场景 id
     scenes[id]= { setting, sceneTitle, emoji, npcName?, npcLine?,
                   narrator, final?, choices:[ {
                     label, hint, effects:{stat:delta},
                     consequence, tip, score?, next? | end? } ] }
       · next  → 跳到下一个场景；end → 直接进入某结局
       · final:true 的场景，选完按累计得分匹配带 min 的结局
     endings[id]= { title, tone:'good'|'caution', did_well,
                    improve, habit, min? }  // min 用于按分匹配
   ▶ BACKEND: 之后可来自 GET /api/games（仅内容；进度才入库）。
   ============================================================ */
const GAMES = [
  /* ===================== 1. 一个月生活费大作战 (money/mood) ===================== */
  {
    id: "month-life", title: "一个月生活费大作战", level: "简单", time: "3分钟",
    cat: "预算管理", icon: "wallet", color: "var(--blue-500)", tint: "var(--blue-50)",
    desc: "这个月有 ¥1000，看看你能不能稳稳花到月底",
    intro: "新的一个月，你拿到了 ¥1000 生活费。接下来每个场景都要做选择，你的「余额」和「心情」会随之变化。月底看看你过得怎么样。",
    stats: { money: 1000, mood: 70 }, statBar: ["money", "mood"], start: "s1",
    scenes: {
      s1: { setting: "食堂", sceneTitle: "开学第一周", emoji: "🍚",
        narrator: "新学期第一周，你站在食堂门口想着这周怎么吃。钱要花，但也不能太省委屈自己。",
        choices: [
          { label: "顿顿食堂，偶尔加个鸡腿", hint: "食堂最划算", effects: { money: -140, mood: 5 }, consequence: "吃得不错又省钱，钱花在了刀刃上。", tip: "食堂是学生最稳的省钱选择。", score: 2, next: "s2" },
          { label: "一半食堂、一半外卖", hint: "方便一些，但更贵", effects: { money: -220, mood: 8 }, consequence: "嘴是爽了，钱包也瘦了一圈。", tip: "外卖偶尔可以，别当成日常。", score: 1, next: "s2" },
          { label: "天天点外卖", hint: "最方便，也最贵", effects: { money: -320, mood: 10 }, consequence: "外卖虽香，一周就花掉了不少。", tip: "小额高频的外卖，最容易掏空预算。", score: 0, next: "s2" },
        ] },
      s2: { setting: "校园操场", sceneTitle: "周末的邀约", emoji: "🏀", npcName: "室友", npcLine: "忙了一周啦，周末出去放松放松呗！",
        narrator: "室友凑过来约你周末一起玩。怎么放松，花多少，由你决定。",
        choices: [
          { label: "在学校打球、散步", hint: "免费的快乐", effects: { mood: 10 }, consequence: "运动出一身汗，心情特别好，一分没花。", tip: "快乐不一定要花钱。", score: 2, next: "s3" },
          { label: "去公园，自带水和零食", hint: "花得少也开心", effects: { money: -15, mood: 12 }, consequence: "逛了一下午，花得不多还很尽兴。", tip: "提前准备，能省下不少冤枉钱。", score: 2, next: "s3" },
          { label: "KTV + 奶茶一整套", hint: "很嗨，但很贵", effects: { money: -90, mood: 15 }, consequence: "玩得很开心，但半周的饭钱没了。", tip: "一次性娱乐花费，记得看看预算还够不够。", score: 0, next: "s3" },
        ] },
      s3: { setting: "商场", sceneTitle: "打折的诱惑", emoji: "👟",
        narrator: "路过商场，一双打折球鞋 ¥260 摆在橱窗里，挺好看。可你脚上的鞋其实还能穿。",
        choices: [
          { label: "不需要，先不买", hint: "忍住冲动", effects: { mood: 5 }, consequence: "你忍住了，钱包稳稳的。", tip: "分清想要和需要，是省钱第一步。", score: 2, next: "s4" },
          { label: "加购物车，等一周再看", hint: "冷静一下", effects: { mood: 3 }, consequence: "放了几天，发现也没那么想要了。", tip: "想买非必需品，先等一等再决定。", score: 2, next: "s4" },
          { label: "限时折扣，马上下单", hint: "一时冲动", effects: { money: -260, mood: 10 }, consequence: "鞋是新的了，预算却一下子告急。", tip: "打折也是花钱，别被「限时」推着走。", score: 0, next: "s4" },
        ] },
      s4: { setting: "营业厅", sceneTitle: "话费用完了", emoji: "📱",
        narrator: "手机弹出停机提醒——这个月话费用完了。得处理一下。",
        choices: [
          { label: "充 ¥30，够用就好", hint: "必要开支", effects: { money: -30, mood: 3 }, consequence: "够用就行，没多花。", tip: "必要的钱该花就花，别硬省。", score: 2, next: "s5" },
          { label: "充 ¥50，多买个流量包", hint: "看用量", effects: { money: -50, mood: 5 }, consequence: "流量是够了，但用不用得完还不一定。", tip: "按需购买，别为「划算」多花。", score: 1, next: "s5" },
          { label: "先蹭 WiFi，不充了", hint: "省钱但不便", effects: { mood: -8 }, consequence: "省是省了，但出门没网耽误了点事。", tip: "省钱也要看场景，别因小失大。", score: 0, next: "s5" },
        ] },
      s5: { setting: "宿舍", sceneTitle: "月底了", emoji: "🛏️", final: true, npcName: "室友", npcLine: "月底啦，最后嗨一次不过分吧？",
        narrator: "月底，账户里还剩一点余额。室友又来约你。这最后一步，你打算怎么收尾？",
        choices: [
          { label: "稳住，把余额存进储蓄目标", hint: "先存后花", effects: { mood: 10 }, consequence: "你把剩下的钱存了起来，月底特别踏实。", tip: "先存后花，是攒钱最稳的顺序。", score: 2 },
          { label: "小小庆祝一下，花 ¥40", hint: "适度奖励", effects: { money: -40, mood: 12 }, consequence: "适度犒劳了自己，也没超支。", tip: "奖励自己可以，控制在预算内就好。", score: 1 },
          { label: "反正剩着也是剩，全花光", hint: "月光警告", effects: { money: -80, mood: 8 }, consequence: "一时痛快，但月底又回到了起点。", tip: "留一点结余，下个月会更从容。", score: 0 },
        ] },
    },
    endings: {
      gold: { min: 80, tone: "good", title: "理财小能手", did_well: "你花得有计划、忍得住诱惑，月底还有结余。", improve: "继续保持，可以试着每月固定存下一小笔。", habit: "开月先做个简单预算，把钱分成几份。" },
      silver: { min: 50, tone: "caution", title: "省钱有一套", did_well: "大方向没问题，日常开销控制得不错。", improve: "个别地方还能更省，比如外卖和娱乐。", habit: "每周回顾一次花销，及时调整。" },
      bronze: { min: 0, tone: "caution", title: "还在练手", did_well: "你已经开始关注自己的钱花在哪了，这很重要。", improve: "这个月花得有点快，下次可以先存后花。", habit: "拿到生活费先存一点点，剩下的再安排。" },
    },
  },

  /* ===================== 2. 想要还是需要？ (money/mood) ===================== */
  {
    id: "want-need", title: "想要还是需要？", level: "入门", time: "2分钟",
    cat: "消费观念", icon: "scale", color: "var(--green-600)", tint: "var(--green-50)",
    desc: "本周可支配 ¥100，练出花钱前的「冷静一秒」",
    intro: "「需要」是没有会影响生活的东西，「想要」是有了更开心但不是必须的。这周你有 ¥100 可支配，看看你能不能分清楚。",
    stats: { money: 100, mood: 60 }, statBar: ["money", "mood"], start: "s1",
    scenes: {
      s1: { setting: "小卖部", sceneTitle: "饭后的零食", emoji: "🍫",
        narrator: "你刚吃饱饭，路过小卖部，看到喜欢的零食正在打折。",
        choices: [
          { label: "走开，现在不需要", hint: "吃饱就不馋", effects: { mood: 5 }, consequence: "吃饱了就不馋了，钱也留住了。", tip: "吃饱后的「想吃」多半是想要，不是需要。", score: 2, next: "s2" },
          { label: "买一点点解解馋", hint: "适度即可", effects: { money: -8, mood: 6 }, consequence: "买了一小包，还算克制。", tip: "偶尔可以，别养成习惯。", score: 1, next: "s2" },
          { label: "打折划算，多囤几包", hint: "囤多会浪费", effects: { money: -25, mood: 8 }, consequence: "囤了一堆，好多最后没吃完。", tip: "打折也是花钱，囤多反而浪费。", score: 0, next: "s2" },
        ] },
      s2: { setting: "鞋店", sceneTitle: "出了新款", emoji: "👟",
        narrator: "经过鞋店，新款很好看。你的旧鞋其实还能穿。",
        choices: [
          { label: "继续穿旧的", hint: "能用就用", effects: { mood: 4 }, consequence: "能用就用，钱包很满意。", tip: "能用就用，是会过日子的体现。", score: 2, next: "s3" },
          { label: "等旧的坏了再换", hint: "理性放下", effects: { mood: 5 }, consequence: "你理性地放下了，没冲动。", tip: "真正需要时再买，最省。", score: 2, next: "s3" },
          { label: "立刻买新款", hint: "想要≠需要", effects: { money: -60, mood: 10 }, consequence: "新鞋很爽，钱包瘪了一大截。", tip: "想要不等于需要，冲动消费最伤钱包。", score: 0, next: "s3" },
        ] },
      s3: { setting: "宿舍", sceneTitle: "同学都买了", emoji: "🎮", npcName: "同学", npcLine: "这个皮肤超好看，大家都入了！",
        narrator: "游戏里出了新皮肤，同学们都买了，气氛上来了。",
        choices: [
          { label: "不跟风，我不需要", hint: "不被带动", effects: { mood: 5 }, consequence: "别人有不代表你需要，你很清醒。", tip: "消费不必跟着别人走。", score: 2, next: "s4" },
          { label: "等有零花钱再说", hint: "延迟决定", effects: { mood: 2 }, consequence: "至少没冲动，挺好。", tip: "延迟决定，能避开很多冲动。", score: 1, next: "s4" },
          { label: "借钱也要买", hint: "为面子借钱不值", effects: { money: -30, mood: 8 }, consequence: "买是买了，但心里还惦记着要还。", tip: "为面子借钱，最不划算。", score: 0, next: "s4" },
        ] },
      s4: { setting: "文具店", sceneTitle: "笔芯用完了", emoji: "✏️",
        narrator: "笔芯用完了，明天还要写作业。",
        choices: [
          { label: "买一支笔芯", hint: "真正的需要", effects: { money: -3, mood: 3 }, consequence: "这是真正的需要，买得值。", tip: "学习必需品，该买就买。", score: 2, next: "s5" },
          { label: "顺手买一整套新文具", hint: "别顺带乱买", effects: { money: -35, mood: 6 }, consequence: "需要的买了，但顺手多买了不少。", tip: "需要的买就好，别顺带乱买。", score: 1, next: "s5" },
          { label: "不买，每天借同学的", hint: "耽误事", effects: { mood: -6 }, consequence: "天天借不方便，也耽误事。", tip: "必要的学习工具，还是备齐更省心。", score: 0, next: "s5" },
        ] },
      s5: { setting: "手机店", sceneTitle: "电池不太耐", emoji: "🔋", final: true,
        narrator: "手机还能用，就是电池有点不耐用了。要怎么处理？",
        choices: [
          { label: "先换个电池", hint: "小修小补", effects: { money: -40, mood: 5 }, consequence: "小修小补，手机又能多用很久。", tip: "小问题小修，比换新省得多。", score: 2 },
          { label: "带个充电宝顶着", hint: "低成本过渡", effects: { money: -25, mood: 3 }, consequence: "充电宝顶着，也能用。", tip: "低成本的过渡办法也不错。", score: 1 },
          { label: "直接换新手机", hint: "为小问题换新太亏", effects: { money: -90, mood: 12 }, consequence: "为个电池换新机，钱包很受伤。", tip: "为小问题换新机，是典型的冲动消费。", score: 0 },
        ] },
    },
    endings: {
      gold: { min: 80, tone: "good", title: "消费明白人", did_well: "你能在花钱前停一秒，分清想要和需要。", improve: "保持下去，偶尔嘴馋也没关系。", habit: "想买非必需品，先问一句：没有它会怎样？" },
      silver: { min: 50, tone: "caution", title: "正在变清醒", did_well: "大部分时候很理性。", improve: "个别时候还会心软，可以再等一等。", habit: "给自己定个「冷静 24 小时」的规矩。" },
      bronze: { min: 0, tone: "caution", title: "容易被种草", did_well: "你愿意来练习分辨想要和需要，这就是进步。", improve: "冲动消费有点多，钱包有点紧。", habit: "购物前列个清单，只买清单上的东西。" },
    },
  },

  /* ===================== 3. 防骗大作战 (credit/risk) ===================== */
  {
    id: "anti-scam", title: "防骗大作战", level: "重要", time: "2分钟",
    cat: "金融安全", icon: "shield-check", color: "var(--red-500)", tint: "var(--red-50)",
    desc: "守住你的钱和信息，看看风险能不能压住",
    intro: "骗局常常伪装得很「贴心」。这一局看「信用」和「风险」两个状态——守得住，风险就低。",
    stats: { credit: 60, risk: 20 }, statBar: ["credit", "risk"], start: "s1",
    scenes: {
      s1: { setting: "手机短信", sceneTitle: "可疑的赔偿", emoji: "📩",
        narrator: "手机收到一条短信：「您的快递丢失，点击链接领取赔偿。」后面跟着一个陌生链接。",
        choices: [
          { label: "不点，去官方 App 自己查", hint: "走官方渠道", effects: { credit: 5, risk: -5 }, consequence: "你没上当，信息很安全。", tip: "陌生链接一律不点，去官方渠道核实。", score: 2, next: "s2" },
          { label: "点进去看看情况", hint: "可能是钓鱼", effects: { risk: 25 }, consequence: "差点就填了银行卡信息，好险。", tip: "这类链接多是钓鱼，点开就有风险。", score: 0, next: "s2" },
          { label: "把验证码发给对方", hint: "验证码=钥匙", effects: { credit: -15, risk: 30 }, consequence: "幸好及时反应过来，验证码差点泄露。", tip: "验证码等于钥匙，绝不能给任何人。", score: 0, next: "s2" },
        ] },
      s2: { setting: "聊天群", sceneTitle: "稳赚的邀请", emoji: "💬", npcName: "陌生群友", npcLine: "带你做投资，一个月翻倍，名额不多了！",
        narrator: "一个陌生群里，有人热情地拉你「一起赚钱」。",
        choices: [
          { label: "直接拒绝", hint: "稳赚=骗局", effects: { credit: 5, risk: -5 }, consequence: "你一眼识破，稳住了。", tip: "「稳赚」「翻倍」基本都是骗局。", score: 2, next: "s3" },
          { label: "先投一点点试试", hint: "试一点也危险", effects: { risk: 20 }, consequence: "投进去就被一步步套住了。", tip: "投一点也会被骗子拿捏，别试。", score: 0, next: "s3" },
          { label: "拉同学一起赚", hint: "别带朋友入坑", effects: { credit: -10, risk: 25 }, consequence: "还好同学提醒你这是套路。", tip: "别把朋友也带进风险里。", score: 0, next: "s3" },
        ] },
      s3: { setting: "手机弹窗", sceneTitle: "0 利息借钱", emoji: "📲",
        narrator: "一个 App 弹出广告：「借钱秒到，0 利息！」",
        choices: [
          { label: "关掉，我不需要借钱", hint: "远离网贷", effects: { credit: 5, risk: -5 }, consequence: "你果断关掉，不给风险机会。", tip: "学生远离网贷，最稳。", score: 2, next: "s4" },
          { label: "先了解一下，不一定借", hint: "了解不等于借", effects: { risk: 5 }, consequence: "了解了一下，没轻易点借。", tip: "了解可以，但别轻易点「借款」。", score: 1, next: "s4" },
          { label: "借一点应应急", hint: "利息藏在后面", effects: { risk: 25, credit: -5 }, consequence: "借是借了，利息却藏在后面。", tip: "「0 利息」常常另有手续费，要看清。", score: 0, next: "s4" },
        ] },
      s4: { setting: "网络游戏", sceneTitle: "免费送装备？", emoji: "🎮", npcName: "网友", npcLine: "你先发个红包，我就送你稀有装备！",
        narrator: "游戏里一个网友说，只要你先发红包，就送你装备。",
        choices: [
          { label: "不理会", hint: "天上不掉馅饼", effects: { credit: 3, risk: -5 }, consequence: "天上不会掉馅饼，你很清醒。", tip: "先让你给钱的「好处」，多半是骗局。", score: 2, next: "s5" },
          { label: "发个小红包试试", hint: "发了会被继续骗", effects: { credit: -5, risk: 20 }, consequence: "发完就被拉黑了，幸好不多。", tip: "一旦发钱，骗子只会要更多。", score: 0, next: "s5" },
        ] },
      s5: { setting: "电话", sceneTitle: "假客服来电", emoji: "☎️", final: true, npcName: "「客服」", npcLine: "为核对身份，请把您的支付密码告诉我。",
        narrator: "电话那头自称是平台客服，要你的支付密码「核对身份」。",
        choices: [
          { label: "拒绝，挂掉电话", hint: "客服不要密码", effects: { credit: 5, risk: -10 }, consequence: "你稳稳守住了密码。", tip: "正规客服永远不会要你的密码。", score: 2 },
          { label: "报给他核对一下", hint: "密码不能说", effects: { credit: -15, risk: 30 }, consequence: "差点出事，幸好后来赶紧改了密码。", tip: "支付密码绝不能告诉任何人。", score: 0 },
          { label: "把密码截图发过去", hint: "更不能截图发", effects: { credit: -15, risk: 30 }, consequence: "好险，发现不对赶紧改了密码。", tip: "密码不能说、不能截图、不能转发。", score: 0 },
        ] },
    },
    endings: {
      gold: { min: 80, tone: "good", title: "防骗高手", did_well: "套路在你这儿都不好使。", improve: "继续保持警惕，也提醒身边的同学。", habit: "记牢：链接不点、验证码不给、稳赚不信。" },
      silver: { min: 50, tone: "caution", title: "警惕性不错", did_well: "大多数坑你都避开了。", improve: "个别地方差点中招，遇事多停一下。", habit: "拿不准时，先问问信任的人再行动。" },
      bronze: { min: 0, tone: "caution", title: "需要更小心", did_well: "你愿意来学防骗，已经是好的开始。", improve: "有些套路差点骗到你，要更警惕。", habit: "凡是要钱、要密码、要验证码的，先怀疑。" },
    },
  },

  /* ===================== 4. 攒钱买耳机 (money=已存/mood) ===================== */
  {
    id: "save-plan", title: "攒钱买耳机", level: "简单", time: "3分钟",
    cat: "储蓄目标", icon: "piggy-bank", color: "var(--green-600)", tint: "var(--green-50)",
    desc: "目标 ¥200，用 4 周一点点攒出来",
    intro: "你想买一副 ¥200 的耳机。不靠借钱、不靠伸手要，看看四周下来你能攒到多少。",
    stats: { money: 0, mood: 60 }, statBar: ["money", "mood"], moneyLabel: "已存", goal: 200, start: "s1",
    scenes: {
      s1: { setting: "宿舍", sceneTitle: "第 1 周 · 零花钱到账", emoji: "🐷",
        narrator: "周一，你收到了 ¥80 零花钱。攒钱计划，从这一周开始。",
        choices: [
          { label: "先存 ¥40，剩下再花", hint: "先存后花", effects: { money: 40, mood: 8 }, consequence: "先存后花，攒钱第一步迈出去了。", tip: "发钱当天先存，是最有效的攒钱法。", score: 2, next: "s2" },
          { label: "先存 ¥20", hint: "存一点也行", effects: { money: 20, mood: 5 }, consequence: "存了一点，也是进步。", tip: "金额不大没关系，能坚持最重要。", score: 1, next: "s2" },
          { label: "这周先不存", hint: "不开始就没进度", effects: { mood: 3 }, consequence: "这周花得开心，但没攒下。", tip: "不开始存，目标就一直在原地。", score: 0, next: "s2" },
        ] },
      s2: { setting: "奶茶店", sceneTitle: "第 2 周 · 奶茶诱惑", emoji: "🧋",
        narrator: "路过奶茶店，香味飘出来。喝，还是存？",
        choices: [
          { label: "戒掉奶茶，省 ¥30 存起来", hint: "省下=攒下", effects: { money: 30, mood: 6 }, consequence: "省下的奶茶钱，变成了存款。", tip: "省下来的，就是攒下来的。", score: 2, next: "s3" },
          { label: "少喝一杯，存 ¥15", hint: "循序渐进", effects: { money: 15, mood: 5 }, consequence: "少喝一杯，存了一点。", tip: "循序渐进，慢慢减少。", score: 1, next: "s3" },
          { label: "照常喝，不存", hint: "钱悄悄溜走", effects: { mood: 6 }, consequence: "奶茶照旧，钱又溜走了。", tip: "小额高频的支出，最容易拖慢攒钱。", score: 0, next: "s3" },
        ] },
      s3: { setting: "信箱", sceneTitle: "第 3 周 · 收到红包", emoji: "🧧",
        narrator: "亲戚发来 ¥50 红包。这笔意外之财，怎么安排？",
        choices: [
          { label: "全部存进目标", hint: "意外之财最该存", effects: { money: 50, mood: 8 }, consequence: "意外之财全存了，进度飞快。", tip: "额外收入最适合直接存起来。", score: 2, next: "s4" },
          { label: "存一半 ¥25", hint: "一半也不错", effects: { money: 25, mood: 6 }, consequence: "存了一半，也不错。", tip: "分一部分给目标，是个好习惯。", score: 1, next: "s4" },
          { label: "红包当然要花掉", hint: "来得快去得快", effects: { mood: 8 }, consequence: "红包一下就花光了。", tip: "红包也是钱，别「来得快去得也快」。", score: 0, next: "s4" },
        ] },
      s4: { setting: "二手平台", sceneTitle: "第 4 周 · 最后一点点", emoji: "📦", final: true,
        narrator: "离目标只差一点点了。最后冲刺，你怎么凑齐？",
        choices: [
          { label: "卖掉闲置旧书，凑 ¥35", hint: "闲置变现", effects: { money: 35, mood: 8 }, consequence: "把闲置变成了钱，离目标更近。", tip: "把用不到的东西变现，是聪明的攒钱方式。", score: 2 },
          { label: "走路上学，省 ¥20 车费", hint: "省日常开销", effects: { money: 20, mood: 5 }, consequence: "省下车费，完成最后冲刺。", tip: "省下的日常开销，也能补上缺口。", score: 2 },
          { label: "算了，下个月再说", hint: "差一步可惜", effects: { mood: 3 }, consequence: "差一步停下了，有点可惜。", tip: "快到目标时更要坚持，别功亏一篑。", score: 0 },
        ] },
    },
    endings: {
      gold: { min: 80, tone: "good", title: "目标达成在望", did_well: "你靠一周一周的坚持，攒下了一大笔。", improve: "保持节奏，耳机很快就能拿下。", habit: "每周固定存一笔，目标拆小就不难。" },
      silver: { min: 50, tone: "caution", title: "攒钱进行中", did_well: "你已经攒下不少，方向很对。", improve: "有几周松了劲，可以更稳定一些。", habit: "把「发钱先存」变成固定动作。" },
      bronze: { min: 0, tone: "caution", title: "刚刚起步", did_well: "你愿意为目标攒钱，这一步最难也最棒。", improve: "这次攒得少了点，别灰心。", habit: "哪怕每周存 ¥5，坚持下来也有惊喜。" },
    },
  },

  /* ===================== 5. 爆胎的自行车 (NEW · 分支 · money/health/credit/risk) ===================== */
  {
    id: "flat-tire", title: "爆胎的自行车", level: "进阶", time: "5分钟",
    cat: "应急与借款", icon: "bike", color: "var(--orange-500)", tint: "var(--orange-50)",
    desc: "一次去兼职路上的紧急选择",
    intro: "你骑着二手自行车去兼职，距离打工地点还有五公里。车胎突然爆了。修理费要 ¥30，迟到可能被扣半天工资。修车铺老板说可以先帮你修，但明天要还 ¥45。你口袋里只有 ¥15——接下来怎么办？",
    stats: { money: 15, health: 70, credit: 60, risk: 20 },
    statBar: ["money", "health", "credit", "risk"], start: "s1",
    scenes: {
      s1: { setting: "校外公路", sceneTitle: "车胎爆了", emoji: "🚲",
        narrator: "「砰」的一声，后轮爆胎了。离兼职地点还有五公里，迟到可能被扣半天工资。你摸了摸口袋，只有 ¥15。先做点什么？",
        choices: [
          { label: "推车去前面的修车铺问问", hint: "先弄清楚要花多少钱", effects: {}, consequence: "你推着车，朝路边的修车铺走去。", tip: "遇事先了解情况，再做决定。", next: "s2" },
          { label: "先给兼职老板打个电话说明情况", hint: "主动沟通，争取理解", effects: { credit: 5, risk: -5 }, consequence: "你打了电话，老板说：路上注意安全，晚到十几分钟没关系。", tip: "遇到突发情况，第一时间沟通，常常能争取到理解。", next: "s3" },
          { label: "不管车了，锁好直接赶路", hint: "省下修车钱，但路还得赶", effects: { risk: 10 }, consequence: "你把车锁在路边，决定先赶去上班再说。", tip: "省钱的同时，也要想清楚后面的麻烦。", next: "s4" },
        ] },
      s2: { setting: "修车铺", sceneTitle: "修车铺报价", emoji: "🔧", npcName: "修车铺老板", npcLine: "补这胎要 ¥30。看你是学生，我先帮你修，明天拿 ¥45 来也行。",
        narrator: "老板报了价，可你口袋里只有 ¥15。他给了两个办法——也许还有别的路。",
        choices: [
          { label: "接受：先修，明天还 ¥45", hint: "今天解决，但要多付 ¥15", effects: { credit: -10, risk: 15 }, consequence: "车修好了，但明天要还 ¥45，比原价多了 ¥15。", tip: "临时借款要看清「总成本」，不能只看今天能不能解决。", end: "high-interest" },
          { label: "跟老板坦白，问有没有更省的办法", hint: "诚实沟通，常有转机", effects: { money: -12, credit: 5 }, consequence: "老板说旧胎可以先打个补丁，只收 ¥12，先凑合用着。", tip: "把真实情况说清楚，常常能找到更省的办法。", next: "s5" },
          { label: "太贵了，不修，自己想办法赶路", hint: "省下修车钱，但要安排交通", effects: { risk: 10 }, consequence: "你谢过老板，决定先解决眼前的赶路问题。", tip: "暂时不修也行，但要安排好怎么过去。", next: "s4" },
        ] },
      s3: { setting: "公交站", sceneTitle: "快迟到了", emoji: "⏰", npcName: "兼职老板", npcLine: "路上小心，安全第一，别着急。",
        narrator: "电话里老板很通情达理。但时间一分一分过去，再不出发就真要迟到了。",
        choices: [
          { label: "坐公交过去，车明天再修", hint: "花一点点，保住时间和安全", effects: { money: -2, risk: -10 }, consequence: "你坐公交准时到岗，因为提前说明了情况，老板也很理解你。", tip: "提前沟通 + 花小钱坐公交，是性价比很高的组合。", next: "s5" },
          { label: "跑步赶过去，省下车费", hint: "不花钱，但很累、有风险", effects: { health: -15, risk: 5 }, consequence: "你一路小跑赶到，没迟到，但累得气喘吁吁，腿也磨疼了。", tip: "省下的 ¥2，有时不如保护好身体来得值。", next: "s5" },
        ] },
      s4: { setting: "公交站", sceneTitle: "交通选择", emoji: "🚌",
        narrator: "车留在了原地，你得想办法走完这五公里。",
        choices: [
          { label: "坐公交，¥2", hint: "花最少的钱按时到", effects: { money: -2, risk: -5 }, consequence: "公交很快就来，你按时到了岗位。", tip: "应急时，公交往往是最稳的低成本选择。", next: "s5" },
          { label: "硬着头皮走五公里", hint: "不花钱，但会迟到、很累", effects: { health: -20, risk: 10 }, consequence: "你走到时还是迟到了，被扣了一点工资，人也累坏了。", tip: "全靠硬扛省钱，代价可能落在身体和工资上。", end: "tough" },
        ] },
      s5: { setting: "宿舍", sceneTitle: "当天结束", emoji: "🛏️",
        narrator: "忙完一天兼职，你回到宿舍。今天这场突发状况，让你想了很多。",
        choices: [
          { label: "决定以后每周存 ¥5 当应急金", hint: "小钱也能救急", effects: { credit: 5 }, consequence: "你把今天剩下的几块钱单独放好，作为应急金的开始。", tip: "应急金不用多，¥5、¥10 攒起来，关键时刻就不慌。", next: "s6" },
          { label: "太累了，钱的事明天再想", hint: "先休息也没关系", effects: { health: 5 }, consequence: "你先好好睡了一觉，养足精神再说。", tip: "累了就歇歇，有空再规划，也不迟。", next: "s6" },
        ] },
      s6: { setting: "学校门口", sceneTitle: "第二天选择", emoji: "🌅",
        narrator: "第二天，你回想起昨天的经历，决定做点小改变。",
        choices: [
          { label: "把「每周存一点应急金」坚持下去", hint: "给自己留条后路", effects: { credit: 5 }, consequence: "你认真记下「每周存 ¥5」，给自己留了一条后路。", tip: "应急金不用大，长期坚持最重要。", end: "emergency" },
          { label: "谢谢帮过你的人，约定互相帮忙", hint: "珍惜信任的关系", effects: { credit: 5 }, consequence: "你谢过帮你的人，也约定以后互相照应。", tip: "靠谱的关系，是应急时的另一种「储蓄」。", end: "communicate" },
        ] },
    },
    endings: {
      communicate: { tone: "good", title: "主动沟通，化解危机", did_well: "你主动说明情况、借助信任的人，把一次突发状况稳稳化解。", improve: "可以再提前准备一点应急金，遇事更从容。", habit: "遇到突发情况，先冷静沟通，往往能找到更省、更安全的办法。" },
      emergency: { tone: "good", title: "你发现了应急金的力量", did_well: "你冷静处理了状况，还决定开始攒应急金。", improve: "继续保持，让这笔应急金慢慢长大。", habit: "每周固定存 ¥5–¥10，攒一笔小应急金，关键时刻不慌。" },
      "high-interest": { tone: "caution", title: "解决了今天，多付了明天", did_well: "你没有让自己迟到，及时解决了眼前的难题。", improve: "¥45 比原价多了 ¥15，下次可以先比较有没有更省的办法。", habit: "临时借钱前，先算清要还的总数，别只看今天能不能解决。" },
      tough: { tone: "caution", title: "全靠硬扛，也辛苦了自己", did_well: "你想尽量不花钱、不欠人情，这份独立很难得。", improve: "这次硬扛让身体和工资都受了点损失，必要时接受帮助会更轻松。", habit: "省钱很好，但别让代价落在健康上；关键时刻花点小钱反而更值。" },
    },
  },
];

Object.assign(window, { LEARN_CATS, LEVELS, VIDEO_PROVIDERS, LESSONS, CHALLENGE_DEFS, GAMES });
