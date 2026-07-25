# 省钱搭子 BudgetBuddy — iOS 上架清单 (Launch Checklist)

**状态：代码 / 后端 / 法务 / 素材 / 账号 全部就绪 —— 只剩在 Xcode + App Store Connect 走一遍"提交"。**

- ✅ Apple Developer 账号：**已过审（个人 / 陈明明）**
- ✅ 后端 **4.8 已上线** budgetbuddy.cn：注册/登录、删除账号、AI、`version.json`、**邮箱验证码**、**短信验证码（号码认证）** 全部实测可用
- ✅ 法务页：App 内 + 线上 `privacy.html`/`terms.html` 均显示「由个人开发者**陈明明**开发并运营」，联系邮箱 support@budgetbuddy.cn
- ✅ App：**build 9**（v1.0），含登录强化（邮箱/手机验证码 + 找回密码）、删除账号、引导页、崩溃诊断、自动更新检查
- ✅ 工程已设 `ITSAppUsesNonExemptEncryption = NO`（导出合规豁免，免反复询问）；iPhone-only
- ✅ 上架素材全备：见 `APP-STORE-LISTING.md`（中英文案/关键词/隐私标签答案/审核备注）+ 演示账号 `review@budgetbuddy.cn / ***SCRUBBED***` + 6 张 1320×2868 截图（`BudgetBuddy-iOS-TestScreenshots/appstore-69/`）

> **策略：美区先上**（个人账号即可，无需 ICP / 公司）。中国区随后另走 ICP 备案。

---

# 🚀 提交流程（照着做，约 30–60 分钟）

## Step 1 · 生成工程 + 配签名
```bash
cd "/Users/chenmingming/Documents/Claude code/BudgetBuddy-iOS"
xcodegen generate
open BudgetBuddy.xcodeproj
```
- 选中 **BudgetBuddy** target → **Signing & Capabilities** → 勾 **Automatically manage signing** → **Team** 选「陈明明 (Personal Team / 个人)」。
- Xcode 会自动注册 App ID `cn.budgetbuddy.BudgetBuddy`。无报红即可。

## Step 2 · Archive（打包真机包）
- 顶部设备选 **Any iOS Device (arm64)**（**不是**模拟器，否则没有 Archive）。
- 菜单 **Product → Archive**。编译完 Organizer 自动弹出。

## Step 3 · 上传到 App Store Connect
- Organizer 里选中刚 archive 的包 → **Distribute App** → **App Store Connect** → **Upload** → 一路 Next（自动签名）→ Upload。
- 等 5–15 分钟，构建会出现在 App Store Connect（状态先"处理中"）。

## Step 4 · 建 App 记录
- 浏览器 → [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **My Apps → ➕ → New App**。
- 平台 **iOS**；名称 **省钱搭子**；主语言 **简体中文**；Bundle ID 选 `cn.budgetbuddy.BudgetBuddy`；SKU 随便填（如 `budgetbuddy2026`）。

## Step 5 · 填商品页（内容全在 `APP-STORE-LISTING.md`，复制粘贴）
- **副标题 / 描述 / 关键词 / 宣传文本 / What's New** ← 从 `APP-STORE-LISTING.md` 复制。
- **截图**：传 `BudgetBuddy-iOS-TestScreenshots/appstore-69/` 那 6 张（6.9"，1320×2868）。
- **支持网址**：`https://budgetbuddy.cn`　**隐私政策网址**：`https://budgetbuddy.cn/privacy.html`
- **分类**：主 **教育**，次 **财务**。
- **年龄分级**：填问卷，无不良内容 → 一般 **4+**。

## Step 6 · App 隐私（App Privacy）
按 `APP-STORE-LISTING.md` 的隐私标签如实勾：
- 收集：**联系信息**（手机号/邮箱，作账号标识）· **用户内容**（记账/反思/进度/AI对话）· **标识符**（账号ID）
- 用途：**App 功能**；与用户身份**关联**；**不用于追踪**、不用于广告。

## Step 7 · App 审核信息（给审核员）
- **演示账号**：`review@budgetbuddy.cn` / `***SCRUBBED***`
- **备注**（从 `APP-STORE-LISTING.md` 的"审核备注"复制）：
  - 删除账号路径：**我的 → 账户 → 删除账号**，输入当前密码确认（Guideline 5.1.1(v)）
  - AI 回复经服务器代理第三方模型生成，不收集敏感信息
  - 界面为中文；注册可用邮箱或中国手机号收验证码
- 联系人信息填你自己的电话/邮箱。

## Step 8 · 选构建 + 提交
- 版本页 **Build** 处选刚上传处理完的 **build 9**。
- **导出合规**：工程已设 `ITSAppUsesNonExemptEncryption=NO`，一般不再询问；若问，选「不含豁免外加密」。
- 点 **Add for Review → Submit for Review**。

---

## 提交之后
- 审核一般 **1–3 个工作日**。被拒就把拒信原文发我，一起改后重传（build 号 +1）。
- 通过后可选 **手动发布** 或自动发布。

## 以后再做（不挡美区）
- **中国区**：ICP 备案（个人主体 + 已备案域名 budgetbuddy.cn）→ 拿到备案号告诉我，App 内/网页加展示位 → 中国区上架。
- **短信对真实用户**：已实测可达；留意阿里云号码认证免费额度用尽后充值。
- **邮件进 Inbox**：SPF/DKIM 已配，DMARC 可选加（`_dmarc` TXT `v=DMARC1; p=none; rua=mailto:support@budgetbuddy.cn`）。

## ✅ 已完成（无需再担心）
- 全部页面原生、与网页一致；多设备账号同步且不互相覆盖；会话跨启动保持。
- 删除账号（接口+UI，需当前密码）、真实隐私/协议（App+网页，主体陈明明、联系邮箱已填）、引导页。
- 登录强化：邮箱/手机身份限定 + 注册验证码 + 找回密码（邮箱走企业邮 SMTP，手机走阿里云号码认证），均**线上实测通过**。
- AI 搭子 + 记账总结真实接入并抗抖动；自动更新检查；崩溃诊断/问题反馈；课程视频含 UP主署名；App 图标。
- build 9 typecheck 通过；多轮 soak + AI 压测无崩溃/不掉登录/不丢数据。
- App Store 素材 + 演示账号 + 6 张截图全备。
