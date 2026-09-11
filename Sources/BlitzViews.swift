import SwiftUI

// MARK: - Entry points

struct BlitzLaunch: Identifiable {
    let id = UUID()
    let mode: BlitzMode
}

/// Home / hub card for today's five questions.
struct BlitzDailyCard: View {
    let onStart: () -> Void

    var body: some View {
        let done = BlitzProgress.doneToday
        let streak = BlitzProgress.dailyStreak
        Button(action: onStart) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0xFFF4DF)).frame(width: 46, height: 46)
                    .overlay(Image(systemName: "bolt.fill").font(.title3).foregroundColor(Color(hex: 0x8A5A2B)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("5 道题 · 约 2 分钟".tr).font(.headline).foregroundColor(.bbInk).lineLimit(1).minimumScaleFactor(0.8)
                    Text(subtitle(done: done, streak: streak)).font(.caption).foregroundColor(.bbInk2)
                }
                Spacer(minLength: 0)
                Text(done ? "再玩一次".tr : "开始".tr)
                    .font(.subheadline.weight(.bold)).foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .duoPrimary(10)
            }
            .padding(14)
            .background(Color.bbSurface)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.bbLine))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("blitz.daily")
    }

    private func subtitle(done: Bool, streak: Int) -> String {
        if done {
            return BBLang.isEN ? "Today \(BlitzProgress.todayScore) pts · streak \(streak)"
                               : "今天得分 \(BlitzProgress.todayScore) · 连续 \(streak) 天"
        }
        if streak > 0 { return BBLang.isEN ? "Streak \(streak), keep it going" : "已连续 \(streak) 天，别断了" }
        return "限时抢答，答得越快分越高".tr
    }
}

/// All packs + today's set + the mistake bank.
struct BlitzHubView: View {
    @State private var launch: BlitzLaunch?
    @State private var refresh = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("限时作答，越快分越高；连对有奖励。每道题答完，都会告诉你为什么。".tr)
                    .font(.subheadline).foregroundColor(.bbInk2).fixedSize(horizontal: false, vertical: true)
                BlitzDailyCard { launch = BlitzLaunch(mode: .daily) }
                let misses = BlitzProgress.mistakes.count
                if misses > 0 {
                    Button { launch = BlitzLaunch(mode: .review) } label: {
                        HStack(spacing: 13) {
                            Image(systemName: "arrow.counterclockwise").font(.body.weight(.semibold))
                                .foregroundColor(.bbInk).frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("错题重练".tr).font(.headline).foregroundColor(.bbInk)
                                Text(BBLang.isEN ? "\(misses) to review · answer right to clear them" : "\(misses) 道待复习 · 答对就会移出")
                                    .font(.caption).foregroundColor(.bbInk2)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.bbInk2)
                        }
                        .padding(14).background(Color.bbSurface)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.bbLine)).cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("blitz.review")
                }
                HStack {
                    Text("题 包".tr).font(.caption).tracking(2).foregroundColor(.bbInk2)
                    Spacer()
                    Text(BBLang.isEN ? "\(BlitzStore.packs.count) packs · \(BlitzStore.bank.questions.count) questions"
                                     : "\(BlitzStore.packs.count) 个题包 · \(BlitzStore.bank.questions.count) 题")
                        .font(.caption).foregroundColor(.bbInk2)
                }
                .padding(.top, 8).padding(.bottom, 10)
                .overlay(Rectangle().fill(Color.bbLine).frame(height: 1), alignment: .bottom)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(BlitzStore.packs) { p in packCard(p) }
                }
            }
            .id(refresh)
            .padding(16)
            .bbPageWidth()
        }
        .background(Color.bbBg)
        .navigationTitle("快答挑战".tr)
        .fullScreenCover(item: $launch, onDismiss: { refresh += 1 }) { BlitzGameContainer(mode: $0.mode) }
    }

    private func packCard(_ p: BlitzPack) -> some View {
        let best = BlitzProgress.best(p.id)
        return Button { launch = BlitzLaunch(mode: .pack(p.id)) } label: {
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 10).fill(p.tintColor).frame(width: 42, height: 42)
                    .overlay(Image(systemName: p.icon).foregroundColor(p.fgColor))
                Text(p.name).font(.headline).foregroundColor(.bbInk).lineLimit(2).minimumScaleFactor(0.85)
                let n = BlitzStore.questions(in: p.id).count
                Text(best > 0 ? (BBLang.isEN ? "\(n) Qs · best \(best)" : "\(n) 题 · 最高 \(best) 分")
                              : (BBLang.isEN ? "\(n) Qs · not played yet" : "\(n) 题 · 还没挑战"))
                    .font(.caption).foregroundColor(best > 0 ? p.fgColor : .bbInk2)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(14)
            .background(Color.bbSurface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("blitz.pack.\(p.id)")
    }
}

/// Rebuilds the game (fresh state object) when the player taps 再来一局.
struct BlitzGameContainer: View {
    let mode: BlitzMode
    @State private var run = 0
    var body: some View {
        BlitzGameView(mode: mode, onRestart: { run += 1 }).id(run)
    }
}

// MARK: - Game

private enum BlitzTileStyle {
    static let colors: [UInt] = [0x3E5F4D, 0x3A5A78, 0x9C5B2A, 0x7A4A6E]
    static let symbols = ["star.fill", "leaf.fill", "bolt.fill", "moon.fill"]
    static let tfSymbols = ["hand.thumbsup.fill", "hand.thumbsdown.fill"]
}

struct BlitzGameView: View {
    @StateObject private var game: BlitzGame
    @Environment(\.dismiss) private var dismiss
    @State private var confirmQuit = false
    @State private var lastWholeSecond = -1
    let onRestart: () -> Void
    private let clock = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    init(mode: BlitzMode, onRestart: @escaping () -> Void) {
        _game = StateObject(wrappedValue: BlitzGame(mode: mode))
        self.onRestart = onRestart
    }

    var body: some View {
        ZStack {
            Color.bbBg.ignoresSafeArea()
            if game.questions.isEmpty {
                emptyState
            } else {
                switch game.phase {
                case .ready: readyView
                case .reading, .answering, .reveal: playView
                case .podium: podiumView
                case .summary: summaryView
                }
            }
        }
        .onReceive(clock) { now in
            game.tick(now)
            if game.phase == .answering {
                let s = Int(game.remaining(now).rounded(.up))
                if s != lastWholeSecond { lastWholeSecond = s; if s <= 5 && s > 0 { BBHaptics.tick() } }
            }
        }
        .confirmationDialog("退出这一局？".tr, isPresented: $confirmQuit, titleVisibility: .visible) {
            Button("退出".tr, role: .destructive) { dismiss() }
            Button("继续答题".tr, role: .cancel) {}
        } message: {
            Text("这一局的分数不会保存。".tr)
        }
    }

    // MARK: ready — the lobby: who you're up against, then 3·2·1

    private var readyView: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { ctx in
            let t = ctx.date.timeIntervalSince(game.phaseStart)
            let n = max(1, 3 - Int(t / max(game.readyDuration / 3, 0.05)))
            VStack(spacing: 22) {
                Spacer()
                Text(game.mode.title).font(.system(.title2, design: .rounded).weight(.bold)).foregroundColor(.bbInk)
                Text(BBLang.isEN ? "\(game.questions.count) questions" : "共 \(game.questions.count) 题")
                    .font(.subheadline).foregroundColor(.bbInk2)
                Text("\(n)")
                    .font(.system(size: 96, weight: .heavy, design: .rounded)).foregroundColor(.bbGreen)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("blitz.countdown")
                VStack(spacing: 8) {
                    Text("本 局 对 手".tr).font(.caption).tracking(2).foregroundColor(.bbInk2)
                    HStack(spacing: 10) {
                        if !game.ghost.isEmpty { opponentChip("👻", "上次的你".tr, "幽灵".tr) }
                        ForEach(BlitzRival.all) { r in opponentChip(r.emoji, r.displayName, r.displayStyle) }
                    }
                }
                Spacer()
            }
            .padding(24)
            .bbPageWidth()
        }
    }

    private func opponentChip(_ emoji: String, _ name: String, _ style: String) -> some View {
        VStack(spacing: 4) {
            Text(emoji).font(.title2)
                .frame(width: 48, height: 48).background(Color.bbSurface)
                .overlay(Circle().stroke(Color.bbLine)).clipShape(Circle())
            Text(name).font(.caption.weight(.semibold)).foregroundColor(.bbInk)
            Text(style).font(.caption2).foregroundColor(.bbInk2)
        }
        .frame(minWidth: 64)
    }

    // MARK: play — read, answer, reveal

    private var playView: some View {
        let q = game.questions[game.index]
        return VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(spacing: 14) {
                    if game.phase == .reading {
                        readingCard(q)
                    } else {
                        questionCard(q, big: false)
                        if game.phase == .answering {
                            timerBar(q)
                        } else {
                            resultBanner
                        }
                        if q.isSlider { sliderArea(q) } else { tiles(q) }
                        if game.phase == .reveal {
                            whyCard(q)
                            standingsList
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 24)
                .bbPageWidth()
            }
            .scrollDisabled(game.phase != .reveal)
            if game.phase == .reveal {
                Button { game.next() } label: {
                    Text(game.isLast ? "看结果".tr : "下一题".tr)
                        .font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 15).duoPrimary()
                }
                .accessibilityIdentifier("blitz.next")
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
                .bbPageWidth()
                .background(Color.bbBg)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button { confirmQuit = true } label: {
                Image(systemName: "xmark").font(.body.weight(.semibold)).foregroundColor(.bbInk2)
                    .frame(width: 36, height: 36).background(Color.bbSurface)
                    .overlay(Circle().stroke(Color.bbLine)).clipShape(Circle())
            }
            .accessibilityLabel("退出".tr)
            .accessibilityIdentifier("blitz.close")
            Spacer()
            Text("\(game.index + 1) / \(game.questions.count)")
                .font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(.bbInk2)
            Spacer()
            HStack(spacing: 4) {
                if game.streak >= 2 {
                    Image(systemName: "flame.fill").foregroundColor(Color(hex: 0xC9772A))
                    Text("\(game.streak)").foregroundColor(Color(hex: 0xC9772A))
                }
                Text("\(game.total)").foregroundColor(.bbInk).contentTransition(.numericText())
            }
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Color.bbSurface).overlay(Capsule().stroke(Color.bbLine)).clipShape(Capsule())
            .accessibilityIdentifier("blitz.score")
        }
        .padding(.horizontal, 16).padding(.top, 8)
        .bbPageWidth()
    }

    private func readingCard(_ q: BlitzQuestion) -> some View {
        VStack(spacing: 22) {
            Spacer(minLength: 60)
            packChip(q)
            Text(q.text)
                .font(.system(.title2, design: .rounded).weight(.bold)).foregroundColor(.bbInk)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            TimelineView(.animation) { ctx in
                let f = min(1, ctx.date.timeIntervalSince(game.phaseStart) / game.readingDuration)
                GeometryReader { g in
                    Capsule().fill(Color.bbLine)
                        .overlay(alignment: .leading) { Capsule().fill(Color.bbGreen).frame(width: g.size.width * f) }
                }
                .frame(width: 140, height: 6)
            }
            Text("先看题…".tr).font(.caption).foregroundColor(.bbInk2)
        }
        .padding(.horizontal, 8)
    }

    private func packChip(_ q: BlitzQuestion) -> some View {
        let p = BlitzStore.pack(q.pack)
        return Text(p?.name ?? "")
            .font(.caption.weight(.semibold)).foregroundColor(p?.fgColor ?? .bbInk2)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(p?.tintColor ?? Color.bbLine).clipShape(Capsule())
    }

    private func questionCard(_ q: BlitzQuestion, big: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            packChip(q)
            Text(q.text)
                .font(.system(big ? .title2 : .title3, design: .rounded).weight(.bold)).foregroundColor(.bbInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.bbSurface)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bbLine))
        .cornerRadius(14)
        .accessibilityIdentifier("blitz.question")
    }

    private func timerBar(_ q: BlitzQuestion) -> some View {
        TimelineView(.animation) { ctx in
            let left = game.remaining(ctx.date)
            let f = left / q.limit
            let color: Color = f > 0.4 ? .bbGreen : (f > 0.2 ? Color(hex: 0xC9A227) : Color(hex: 0xC0584A))
            HStack(spacing: 10) {
                GeometryReader { g in
                    Capsule().fill(Color.bbLine)
                        .overlay(alignment: .leading) { Capsule().fill(color).frame(width: max(0, g.size.width * f)) }
                }
                .frame(height: 10)
                Text("\(Int(left.rounded(.up)))")
                    .font(.system(.headline, design: .rounded).weight(.heavy)).foregroundColor(color)
                    .monospacedDigit().frame(width: 30, alignment: .trailing)
            }
        }
        .accessibilityIdentifier("blitz.timer")
    }

    private func tiles(_ q: BlitzQuestion) -> some View {
        let items = game.displayChoices(game.index)
        let correct = game.correctSlot(game.index)
        let pair = items.count <= 2
        let tall: CGFloat = pair ? 150 : 92
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(items.indices, id: \.self) { slot in
                let revealed = game.phase == .reveal
                let isCorrect = slot == correct
                let isPicked = slot == game.pickedSlot
                let symbol = q.isTrueFalse ? BlitzTileStyle.tfSymbols[slot % 2] : BlitzTileStyle.symbols[slot % 4]
                let color = Color(hex: BlitzTileStyle.colors[q.isTrueFalse ? (slot == 0 ? 0 : 3) : slot % 4])
                Button {
                    BBHaptics.tap()
                    game.pick(slot)
                } label: {
                    if pair {
                        VStack(spacing: 10) {
                            Image(systemName: symbol).font(.title).foregroundColor(.white.opacity(0.9))
                            Text(items[slot]).font(.system(.title2, design: .rounded).weight(.heavy)).foregroundColor(.white)
                                .multilineTextAlignment(.center).minimumScaleFactor(0.7)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: tall)
                        .background(color)
                        .cornerRadius(12)
                        .overlay(alignment: .topTrailing) {
                            if revealed && (isCorrect || isPicked) {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.title3).foregroundColor(.white).padding(10)
                            }
                        }
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: revealed && isPicked ? 3 : 0))
                        .opacity(revealed && !isCorrect && !isPicked ? 0.3 : 1)
                    } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: symbol).font(.subheadline).foregroundColor(.white.opacity(0.85))
                            Spacer()
                            if revealed && isCorrect {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.white)
                            } else if revealed && isPicked {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.white)
                            }
                        }
                        Text(items[slot])
                            .font(.system(.headline, design: .rounded)).foregroundColor(.white)
                            .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, minHeight: tall, alignment: .topLeading)
                    .background(color)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: revealed && isPicked ? 3 : 0))
                    .opacity(revealed && !isCorrect && !isPicked ? 0.3 : 1)
                    }
                }
                .buttonStyle(.plain)
                .allowsHitTesting(game.phase == .answering)   // not .disabled: that greys the answer out on reveal
                .accessibilityLabel(Text((BBLang.isEN ? "Option \(slot + 1): " : "选项 \(slot + 1)：") + items[slot]))
                .accessibilityIdentifier("blitz.tile.\(slot)")
            }
        }
    }

    private func sliderArea(_ q: BlitzQuestion) -> some View {
        let lo = q.min ?? 0, hi = q.max ?? 100, st = q.step ?? 1
        let answering = game.phase == .answering
        return VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(BlitzFormat.number(game.sliderValue))
                    .font(.system(size: 52, weight: .heavy, design: .rounded)).foregroundColor(.bbInk)
                    .monospacedDigit().contentTransition(.numericText())
                Text(q.unitLabel).font(.title3.weight(.semibold)).foregroundColor(.bbInk2)
            }
            .accessibilityIdentifier("blitz.slider.value")
            Slider(value: $game.sliderValue, in: lo...hi, step: st)
                .tint(.bbGreen)
                .disabled(!answering)
                .accessibilityIdentifier("blitz.slider")
            HStack(spacing: 10) {
                stepButton("minus") { game.sliderValue = max(lo, game.sliderValue - st) }
                Button { game.submitSlider() } label: {
                    Text("确定".tr).font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 13).duoPrimary(12)
                }
                .disabled(!answering)
                .opacity(answering ? 1 : 0.4)
                .accessibilityIdentifier("blitz.slider.submit")
                stepButton("plus") { game.sliderValue = min(hi, game.sliderValue + st) }
            }
            if game.phase == .reveal {
                Text((BBLang.isEN ? "Answer: " : "正确答案：") + q.correctText)
                    .font(.headline).foregroundColor(.bbGreen)
            }
        }
        .padding(16)
        .background(Color.bbSurface)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bbLine))
        .cornerRadius(14)
    }

    private func stepButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.headline).foregroundColor(.bbInk)
                .frame(width: 48, height: 48).background(Color.bbBg)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
        }
        .disabled(game.phase != .answering)
    }

    private var resultBanner: some View {
        let ok = game.lastCorrect
        let title = ok ? "答对了".tr : (game.timedOut ? "时间到".tr : "答错了".tr)
        return HStack(spacing: 10) {
            Image(systemName: ok ? "checkmark.seal.fill" : (game.timedOut ? "hourglass" : "xmark.octagon.fill"))
                .font(.title3)
            Text(title).font(.system(.headline, design: .rounded).weight(.bold))
            Spacer(minLength: 0)
            if ok {
                Text("+\(game.lastPoints)").font(.system(.headline, design: .rounded).weight(.heavy))
                if game.lastBonus > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                        Text(BBLang.isEN ? "\(game.streak) in a row +\(game.lastBonus)" : "连对 \(game.streak) +\(game.lastBonus)")
                    }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.white.opacity(0.2)).clipShape(Capsule())
                }
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(ok ? Color.bbGreen : Color(hex: 0xB5574A))
        .cornerRadius(12)
        .accessibilityIdentifier("blitz.result")
    }

    private func whyCard(_ q: BlitzQuestion) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if !game.lastCorrect && !q.isSlider {
                Text((BBLang.isEN ? "Answer: " : "正确答案：") + q.correctText)
                    .font(.subheadline.weight(.semibold)).foregroundColor(.bbGreen)
            }
            Text("为 什 么".tr).font(.caption).tracking(2).foregroundColor(.bbInk2)
            Text(q.explanation).font(.body).foregroundColor(.bbInk).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(hex: 0xFFF8EA))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xEADBB8)))
        .cornerRadius(12)
        .accessibilityIdentifier("blitz.why")
    }

    private var standingsList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("排 行".tr).font(.caption).tracking(2).foregroundColor(.bbInk2)
                Spacer()
            }
            .padding(.bottom, 8)
            ForEach(Array(game.standings.enumerated()), id: \.element.id) { i, s in
                standingRow(rank: i + 1, s, change: game.index == 0 ? 0 : game.rankChange(s.id))
            }
        }
        .accessibilityIdentifier("blitz.standings")
    }

    private func standingRow(rank: Int, _ s: BlitzStanding, change: Int) -> some View {
        HStack(spacing: 10) {
            Text("\(rank)").font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundColor(.bbInk2).frame(width: 18)
            Text(s.emoji).frame(width: 34, height: 34).background(Color.bbBg).clipShape(Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(s.name).font(.subheadline.weight(s.isYou ? .bold : .semibold)).foregroundColor(.bbInk)
                if let tag = s.tag { Text(tag).font(.caption2).foregroundColor(.bbInk2) }
            }
            if change > 0 {
                Image(systemName: "arrowtriangle.up.fill").font(.caption2).foregroundColor(.bbGreen)
            }
            Spacer(minLength: 0)
            if s.gained > 0 {
                Text("+\(s.gained)").font(.caption.weight(.semibold)).foregroundColor(.bbGreen)
            }
            Text("\(s.score)").font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundColor(.bbInk).monospacedDigit().frame(minWidth: 52, alignment: .trailing)
        }
        .padding(.vertical, 8).padding(.horizontal, 10)
        .background(s.isYou ? Color.bbGreen.opacity(0.08) : Color.clear)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(s.isYou ? Color.bbGreen.opacity(0.35) : Color.clear))
        .cornerRadius(10)
    }

    // MARK: podium — 2nd, 1st, 3rd

    @State private var podiumUp = false

    private var podiumView: some View {
        let top = Array(game.standings.prefix(3))
        let order = top.count == 3 ? [top[1], top[0], top[2]] : top
        let heights: [CGFloat] = top.count == 3 ? [110, 150, 80] : [150, 110, 80]
        let ranks = top.count == 3 ? [2, 1, 3] : Array(1...top.count)
        let tints: [UInt] = [0xC9A227, 0xA7A9AC, 0xB07A4A]   // by rank: 1 gold, 2 silver, 3 bronze
        return VStack(spacing: 18) {
            Spacer()
            Text("颁 奖 台".tr).font(.caption).tracking(3).foregroundColor(.bbInk2)
            Text(game.yourRank == 1 ? "你拿了第一！".tr : (BBLang.isEN ? "You finished #\(game.yourRank)" : "你是第 \(game.yourRank) 名"))
                .font(.system(.title, design: .rounded).weight(.heavy)).foregroundColor(.bbInk)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(order.enumerated()), id: \.element.id) { i, s in
                    VStack(spacing: 6) {
                        Text(s.emoji).font(.title)
                            .frame(width: 56, height: 56).background(Color.bbSurface)
                            .overlay(Circle().stroke(s.isYou ? Color.bbGreen : Color.bbLine, lineWidth: s.isYou ? 3 : 1))
                            .clipShape(Circle())
                        Text(s.name).font(.subheadline.weight(.bold)).foregroundColor(.bbInk).lineLimit(1)
                        Text("\(s.score)").font(.caption.weight(.semibold)).foregroundColor(.bbInk2).monospacedDigit()
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: tints[(ranks[i] - 1) % 3]))
                            .frame(height: podiumUp ? heights[i] : 12)
                            .overlay(alignment: .top) {
                                Text("\(ranks[i])").font(.system(.title, design: .rounded).weight(.heavy))
                                    .foregroundColor(.white).padding(.top, 10)
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 290, alignment: .bottom)
            .accessibilityIdentifier("blitz.podium")
            if game.yourRank > 3, let you = game.standings.first(where: \.isYou) {
                standingRow(rank: game.yourRank, you, change: 0)
            }
            Spacer()
            Button { game.toSummary() } label: {
                Text("看成绩单".tr).font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 15).duoPrimary()
            }
            .accessibilityIdentifier("blitz.podium.continue")
        }
        .padding(24)
        .bbPageWidth(520)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72).delay(0.15)) { podiumUp = true }
            BBHaptics.result(game.yourRank <= 3)
        }
    }

    // MARK: summary — score, stats, mistakes with the why

    private var summaryView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(game.mode.title).font(.subheadline.weight(.semibold)).foregroundColor(.bbInk2).padding(.top, 24)
                Text("\(game.total)")
                    .font(.system(size: 60, weight: .heavy, design: .rounded)).foregroundColor(.bbInk).monospacedDigit()
                if game.firstPlay {
                    Label("首次挑战完成".tr, systemImage: "flag.checkered")
                        .font(.subheadline.weight(.bold)).foregroundColor(.bbGreen)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.bbGreen.opacity(0.1)).clipShape(Capsule())
                } else if game.newRecord {
                    Label("新纪录".tr, systemImage: "trophy.fill")
                        .font(.subheadline.weight(.bold)).foregroundColor(Color(hex: 0x8A5A2B))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color(hex: 0xFFF4DF)).clipShape(Capsule())
                }
                HStack(spacing: 0) {
                    stat("\(game.correctCount)/\(game.questions.count)", "答对".tr)
                    stat("\(game.bestStreak)", "最高连对".tr)
                    stat("#\(game.yourRank)", "排名".tr)
                    if game.mode == .daily { stat("\(BlitzProgress.dailyStreak)", "连续天数".tr) }
                }
                .padding(.vertical, 6)
                .background(Color.bbSurface)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
                .accessibilityIdentifier("blitz.summary")

                if game.misses.isEmpty {
                    Text("全部答对，这一包你已经会了。".tr)
                        .font(.headline).foregroundColor(.bbGreen).padding(.top, 6)
                } else {
                    HStack {
                        Text("错 题 回 顾".tr).font(.caption).tracking(2).foregroundColor(.bbInk2)
                        Spacer()
                        Text("已加入错题本".tr).font(.caption).foregroundColor(.bbInk2)
                    }
                    .padding(.top, 8)
                    ForEach(game.misses) { m in missCard(m) }
                }
            }
            .padding(16)
            .bbPageWidth()
        }
        .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    Button(action: onRestart) {
                        Text("再来一局".tr).font(.headline).foregroundColor(.bbInk)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine))
                            .cornerRadius(12)
                    }
                    .accessibilityIdentifier("blitz.again")
                    Button { dismiss() } label: {
                        Text("完成".tr).font(.headline).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14).duoPrimary(12)
                    }
                    .accessibilityIdentifier("blitz.done")
                }
                .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 8)
                .bbPageWidth()
                .background(Color.bbBg)
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(.bbInk).monospacedDigit()
            Text(label).font(.caption).foregroundColor(.bbInk2)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
    }

    private func missCard(_ m: BlitzAnswerLog) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(m.question.text).font(.subheadline.weight(.semibold)).foregroundColor(.bbInk)
                .fixedSize(horizontal: false, vertical: true)
            Text((BBLang.isEN ? "You: " : "你的答案：") + m.yourAnswer).font(.caption).foregroundColor(Color(hex: 0xB5574A))
            Text((BBLang.isEN ? "Answer: " : "正确答案：") + m.question.correctText).font(.caption.weight(.semibold)).foregroundColor(.bbGreen)
            Text(m.question.explanation).font(.caption).foregroundColor(.bbInk2).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.bbSurface)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal").font(.largeTitle).foregroundColor(.bbGreen)
            Text("错题本是空的，没有要复习的题。".tr).font(.headline).foregroundColor(.bbInk)
            Button("完成".tr) { dismiss() }.accessibilityIdentifier("blitz.done")
        }
        .padding(24)
    }
}
