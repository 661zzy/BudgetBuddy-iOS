# 故事场景配图 · 生成提示词 (25 scenes) — for Codex / GPT Image

Generate ONE image per story scene with these prompts. The hand-drawn `pixelScene()` becomes a
**fallback**; a generated image, when present, takes priority (see "Wiring" at the bottom).

## LOCKED art direction — append to EVERY prompt (keep identical for all 25 so they look cohesive)
> STYLE: detailed retro pixel-art game scene, 16:9 side-view banner composition, one bright warm
> cohesive palette and the same pixel scale across all scenes, soft daylight, clean readable shapes,
> contemporary Chinese campus / student daily-life setting. NO text, NO UI overlays, NO logos or
> real brands, NO copyrighted characters or mascots (this is original art, not Mario). Calm, friendly,
> non-scary tone even for the scam scenes.

## SIZE / FORMAT
- 16:9, high-res. Save as PNG.

---

## 一个月生活费大作战 (month-life)
- **s1 食堂·开学第一周** — A bright school cafeteria; a student holding a meal tray choosing dishes at the counter; lively first week of a new semester.
- **s2 校园操场·周末的邀约** — A sunny campus outdoor basketball court / sports ground on a weekend; a friend waving to invite the student out to relax.
- **s3 商场·打折的诱惑** — A shopping-mall storefront; a pair of discounted sneakers spotlighted in the display window; a student pausing, tempted.
- **s4 营业厅·话费用完了** — A phone-carrier service-hall counter; a smartphone on a stand showing an "out of credit / suspended" alert (no readable text); needs a top-up.
- **s5 宿舍·月底了** — A cozy dorm room in evening light at month's end; a piggy bank and a few coins on the desk; a calm "I made it" mood.

## 想要还是需要？(want-need)
- **s1 小卖部·饭后的零食** — A tiny campus convenience store; shelves of snacks with a small discount sign (no text); a just-fed student eyeing them.
- **s2 鞋店·出了新款** — A sneaker-store interior; a brand-new sneaker model on a lit display pedestal.
- **s3 宿舍·同学都买了** — A dorm room; roommates excitedly using a new handheld game gadget; one student watching, feeling left out.
- **s4 文具店·笔芯用完了** — A small stationery shop; close-up of a ballpoint pen that has run out of ink; a genuine everyday need.
- **s5 手机店·电池不太耐** — A phone-shop counter; a smartphone on a stand with a nearly-empty draining battery icon.

## 防骗大作战 (anti-scam)  —  keep these friendly/cautionary, not frightening
- **s1 手机短信·可疑的赔偿** — A smartphone on a desk showing a suspicious SMS about a surprise "refund/compensation" with a sketchy link; gentle warning mood.
- **s2 聊天群·稳赚的邀请** — A phone/laptop group-chat; messages hyping a "guaranteed profit" money-making invitation; too-good-to-be-true vibe.
- **s3 手机弹窗·0利息借钱** — A smartphone with a popup ad offering a "0% interest instant loan"; tempting but risky.
- **s4 网络游戏·免费送装备？** — A cartoon game screen offering "free rare equipment" via an external link; a lure/trap feeling.
- **s5 电话·假客服来电** — A student answering a phone call from a fake "customer service" caller; suspicious, slightly tense but safe.

## 攒钱买耳机 (save-plan)
- **s1 宿舍·第1周·零花钱到账** — A dorm desk in week one; pocket money just arrived; a piggy bank and a small notebook; a hopeful saving start.
- **s2 奶茶店·第2周·奶茶诱惑** — A bubble-tea shop counter; a colorful cup of milk tea tempting the saver.
- **s3 信箱·第3周·收到红包** — A mailbox / mail slot; a red envelope (hongbao) just received; a happy surprise.
- **s4 二手平台·第4周·最后一点点** — A phone showing a second-hand-marketplace listing for headphones; almost enough money saved; the final stretch.

## 爆胎的自行车 (flat-tire)  —  s1 already generated ✓
- **s1 校外公路·车胎爆了** — DONE (the bike with a flat front tire by the school gate).
- **s2 修车铺·修车铺报价** — A small roadside bike-repair stall; a mechanic gesturing a price; a wrench and a tire tube nearby.
- **s3 公交站·快迟到了** — A bus stop with a large street clock showing it's getting late; an anxious student checking the time, in a hurry.
- **s4 公交站·交通选择** — A city bus pulling up to a bus stop; the student about to hop on; a bus-stop sign pole.
- **s5 宿舍·当天结束** — A dorm room at night, end of a long day; a crescent moon through the window; resting.
- **s6 学校门口·第二天选择** — A school front gate at sunrise, warm golden light; a fresh, hopeful new morning.

---

## Wiring (SwiftUI) — for Codex
1. Save each PNG into `Assets.xcassets` as an image set named **`scene_<storyId-with-hyphens→underscores>_<sceneId>`**, e.g. `scene_flat_tire_s1`, `scene_month_life_s3`, `scene_want_need_s2`.
2. In `Sources/StoryView.swift`, in `playView`, make the banner prefer a generated image and fall back to the pixel art:
   ```swift
   // at top of file: import UIKit
   let imgName = "scene_" + story.id.replacingOccurrences(of: "-", with: "_") + "_" + sceneId
   if UIImage(named: imgName) != nil {
       Image(imgName).resizable().aspectRatio(contentMode: .fill)
           .frame(height: 170).frame(maxWidth: .infinity).clipped()
           .clipShape(RoundedRectangle(cornerRadius: 12))
           .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine))
   } else if let grid = pixelScene(story.id, sceneId) {
       // (existing pixel-art banner)
   }
   ```
3. Keep `Sources/PixelArt.swift` as the graceful fallback for any scene not yet generated.
4. After wiring: `xcodegen generate` (new assets) → rebuild → screenshot each story's scenes.
