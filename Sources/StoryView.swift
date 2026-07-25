import SwiftUI
import StoreKit
import UIKit

// MARK: - 故事 (Learning) — two modes: 互动故事 (games + 图鉴 + 沙盘) / 理财课程 (lessons)

struct StoryView: View {
    @EnvironmentObject var store: AppStore
    @State private var mode = "game"   // game | video

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        modeCard("互动故事".tr, "情景里做决定".tr, "book", "game")
                        modeCard("理财课程".tr, "跟着课程学".tr, "play.circle", "video")
                    }
                    if mode == "game" { gameMode } else { videoMode }
                }
                .padding(16)
                .bbPageWidth()
            }
            .background(Color.bbBg)
            .navigationTitle("故事".tr)
        }
    }

    private func modeCard(_ title: String, _ sub: String, _ icon: String, _ key: String) -> some View {
        let active = mode == key
        return Button { mode = key } label: {
            HStack(spacing: 11) {
                Image(systemName: icon).font(.system(size: 20)).foregroundColor(active ? .white : .bbInk)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundColor(active ? .white : .bbInk)
                    Text(sub).font(.caption2).foregroundColor(active ? .white.opacity(0.75) : .bbInk2)
                }
                Spacer(minLength: 0)
            }
            .padding(13)
            .background(active ? Color.bbGreen : Color.bbSurface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(active ? Color.bbGreen : Color.bbLine))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var gameMode: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLine("互 动 故 事".tr, trailing: "已通关".tr + " \(store.storiesCompleted) / \(StoryStore.all.count)")
            storyPath
            sectionLine("更 多".tr, trailing: nil)
            NavigationLink { CodexView() } label: {
                moreRow("rectangle.stack", "认知图鉴".tr, BBLang.isEN ? "Spot common money traps · \(CodexStore.all.count) cards" : "识破常见财务套路 · 共 \(CodexStore.all.count) 张")
            }.buttonStyle(.plain)
            if let wn = StoryStore.find("want-need") {
                NavigationLink { GameDetailView(story: wn) } label: {
                    moreRow("dumbbell", "练习沙盘".tr, "反复练「想要还是需要」的冷静一秒".tr)
                }.buttonStyle(.plain)
            }
            Text("故事里的钱都是模拟的，放心大胆做选择，做错了也只是长经验。".tr)
                .font(.caption).foregroundColor(.bbInk2).padding(.top, 4)
        }
    }

    private var videoMode: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(LessonStore.catOrder, id: \.self) { ck in
                let items = LessonStore.inCat(ck)
                if !items.isEmpty, let cat = LEARN_CATS[ck] {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: cat.icon).font(.caption).foregroundColor(cat.fg)
                                .frame(width: 28, height: 28).background(cat.tint).cornerRadius(8)
                            Text(cat.zh.tr).font(.subheadline.weight(.semibold)).foregroundColor(.bbInk)
                        }
                        ForEach(items) { lesson in
                            NavigationLink { LessonDetailView(lesson: lesson) } label: { LessonCard(lesson: lesson) }.buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func sectionLine(_ title: String, trailing: String?) -> some View {
        HStack {
            Text(title).font(.caption).tracking(2).foregroundColor(.bbInk2)
            Spacer()
            if let trailing { Text(trailing).font(.caption).foregroundColor(.bbInk2) }
        }
        .padding(.bottom, 10).padding(.top, 8)
        .overlay(Rectangle().fill(Color.bbLine).frame(height: 1), alignment: .bottom)
    }

    private func moreRow(_ icon: String, _ title: String, _ sub: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon).font(.system(size: 19)).foregroundColor(.bbInk).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundColor(.bbInk)
                Text(sub).font(.caption).foregroundColor(.bbInk2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.bbInk2)
        }
        .padding(.vertical, 14).padding(.horizontal, 2)
        .overlay(Rectangle().fill(Color.bbLine).frame(height: 1), alignment: .bottom)
    }

    // MARK: Duolingo-style story path
    private var storyPath: some View {
        let stories = StoryStore.all
        let spacing: CGFloat = 132
        let amp: CGFloat = 66
        func off(_ i: Int) -> CGFloat { [0.0, 1.0, 0.0, -1.0][i % 4] }
        return GeometryReader { geo in
            let cx = geo.size.width / 2
            ZStack {
                Path { p in
                    for i in 0..<max(stories.count - 1, 0) {
                        p.move(to: CGPoint(x: cx + off(i) * amp, y: 60 + CGFloat(i) * spacing))
                        p.addLine(to: CGPoint(x: cx + off(i + 1) * amp, y: 60 + CGFloat(i + 1) * spacing))
                    }
                }
                .stroke(Color.bbLine, style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [1, 12]))
                ForEach(Array(stories.enumerated()), id: \.offset) { i, story in
                    storyNode(story).position(x: cx + off(i) * amp, y: 60 + CGFloat(i) * spacing)
                    storyLabel(story).position(x: cx + off(i) * amp, y: 60 + CGFloat(i) * spacing + 64)
                }
            }
        }
        .frame(height: 60 + CGFloat(max(stories.count - 1, 0)) * spacing + 120)
    }

    private func storyNode(_ story: Story) -> some View {
        let done = store.isGameDone(story.id)
        let img = "scene_" + story.id.replacingOccurrences(of: "-", with: "_") + "_s1"
        return NavigationLink { GameDetailView(story: story) } label: {
            ZStack {
                Circle().fill(Color.bbSurface).frame(width: 92, height: 92)
                if UIImage(named: img) != nil {
                    Image(img).resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 84, height: 84).clipShape(Circle())
                } else {
                    // Stories without scene art yet fall back to the first scene's emoji.
                    Circle().fill(Color(hex: 0xEFF3EE)).frame(width: 84, height: 84)
                    Text(story.scenes[story.start]?.emoji ?? "📖").font(.system(size: 38))
                }
                Circle().stroke(done ? Color.bbGreen : Color.bbLine, lineWidth: 4).frame(width: 92, height: 92)
            }
            .overlay(alignment: .bottomTrailing) {
                if done {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 22))
                        .foregroundColor(.bbGreen).background(Circle().fill(.white)).offset(x: 4, y: 4)
                }
            }
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("story-node-\(story.id)")
        .accessibilityLabel(story.title.tr)
    }

    private func storyLabel(_ story: Story) -> some View {
        Text(story.title.tr).font(.caption.weight(.semibold)).foregroundColor(.bbInk).lineLimit(1)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Capsule().fill(Color.bbBg))
    }
}

// MARK: - Cards

private struct StoryCard: View {
    let story: Story
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10).fill(Color.bbBlue)
                .frame(width: 52, height: 52)
                .overlay(Image(systemName: storySymbol(story.icon)).font(.system(size: 24)).foregroundColor(Color(hex: 0x3A5A78)))
            VStack(alignment: .leading, spacing: 5) {
                Text(story.title.tr).font(.headline).foregroundColor(.bbInk)
                if let d = story.desc {
                    Text(d.tr).font(.caption).foregroundColor(.bbInk2).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 6) {
                    if let lv = story.level { levelBadge(lv.tr) }
                    if let c = story.cat { miniTag(c.tr) }
                    if let t = story.time { miniTag(t.tr) }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.bbInk2)
        }
        .padding(14).background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
    }
    private func miniTag(_ s: String) -> some View {
        Text(s).font(.caption2).foregroundColor(.bbInk2)
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(Capsule().fill(Color.bbBg)).overlay(Capsule().stroke(Color.bbLine))
    }
}

private struct LessonCard: View {
    let lesson: Lesson
    var body: some View {
        HStack(spacing: 13) {
            VStack(alignment: .leading, spacing: 5) {
                Text(lesson.title.tr).font(.subheadline.weight(.semibold)).foregroundColor(.bbInk)
                if let d = lesson.desc {
                    Text(d.tr).font(.caption).foregroundColor(.bbInk2).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 8) {
                    if let lv = lesson.level { levelBadge(lv.tr) }
                    if let t = lesson.time { HStack(spacing: 3) { Image(systemName: "clock"); Text(t.tr) }.font(.caption2).foregroundColor(.bbInk2) }
                    if lesson.video != nil { HStack(spacing: 3) { Image(systemName: "play.circle"); Text("配套视频".tr) }.font(.caption2).foregroundColor(Color(hex: 0x3A5A78)) }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.bbInk2)
        }
        .padding(14).background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
    }
}

// global so multiple views share it
func levelBadge(_ level: String) -> some View {
    let c = levelColors(level)
    return Text(level).font(.caption2).padding(.horizontal, 8).padding(.vertical, 3)
        .background(Capsule().fill(c.bg)).foregroundColor(c.fg)
}

// MARK: - 认知图鉴 (Codex)

struct CodexView: View {
    @EnvironmentObject var store: AppStore
    private var unlocked: [CodexEntry] { CodexStore.all.filter { store.state.gameProgress.contains($0.story ?? "") } }
    private var locked: [CodexEntry] { CodexStore.all.filter { !store.state.gameProgress.contains($0.story ?? "") } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if unlocked.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "rectangle.stack").font(.system(size: 34)).foregroundColor(.bbInk2)
                        Text("还没有解锁图鉴".tr).font(.headline).foregroundColor(.bbInk)
                        Text("去玩一个互动故事，通关后就能解锁对应的认知图鉴。".tr)
                            .font(.subheadline).foregroundColor(.bbInk2).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 40)
                }
                ForEach(unlocked) { c in CodexCard(c: c) }
                if !locked.isEmpty {
                    Text("未 解 锁".tr).font(.caption).tracking(2).foregroundColor(.bbInk2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12).padding(.bottom, 6)
                        .overlay(Rectangle().fill(Color.bbLine).frame(height: 1), alignment: .bottom)
                    ForEach(locked) { c in
                        HStack(spacing: 13) {
                            Image(systemName: "lock").foregroundColor(.bbInk2).frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(c.title.tr).font(.subheadline.weight(.semibold)).foregroundColor(.bbInk2)
                                if let st = c.storyTitle { Text("通关".tr + "「\(st.tr)」" + "解锁".tr).font(.caption).foregroundColor(.bbInk2) }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 12)
                        .overlay(Rectangle().fill(Color.bbLine).frame(height: 1), alignment: .bottom)
                    }
                }
            }
            .padding(16)
            .bbPageWidth()
        }
        .background(Color.bbBg)
        .navigationTitle("认知图鉴".tr)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CodexCard: View {
    let c: CodexEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(c.category.tr).font(.caption2).padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color.bbBg)).overlay(Capsule().stroke(Color.bbLine)).foregroundColor(.bbInk2)
                Spacer()
                HStack(spacing: 3) { Image(systemName: "checkmark"); Text("已解锁".tr) }.font(.caption2).foregroundColor(.bbGreen)
            }
            Text(c.title.tr).font(.title3.bold()).foregroundColor(.bbInk).padding(.top, 12)
            list("识别信号".tr, c.signs, "exclamationmark.triangle.fill", .bbRed)
            list("应对动作".tr, c.defense, "checkmark.shield.fill", .bbGreen)
            if let st = c.storyTitle {
                Divider().background(Color.bbLine).padding(.top, 14)
                HStack(spacing: 7) {
                    Image(systemName: "book"); Text("相关故事".tr + " · \(st.tr)").font(.caption); Spacer(minLength: 0)
                }
                .foregroundColor(.bbInk2).padding(.top, 12)
            }
        }
        .padding(18).background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
    }
    private func list(_ title: String, _ items: [String], _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).tracking(1).foregroundColor(.bbInk2).padding(.top, 16)
            ForEach(Array(items.enumerated()), id: \.offset) { _, s in
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: icon).font(.caption).foregroundColor(color)
                    Text(s.tr).font(.subheadline).foregroundColor(.bbInk).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

// MARK: - 小课堂 (Lesson detail)

struct LessonDetailView: View {
    let lesson: Lesson
    @EnvironmentObject var store: AppStore
    @State private var done = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    if let lv = lesson.level { levelBadge(lv.tr) }
                    if let t = lesson.time { HStack(spacing: 3) { Image(systemName: "clock"); Text(t.tr) }.font(.caption).foregroundColor(.bbInk2) }
                    if done { HStack(spacing: 3) { Image(systemName: "checkmark"); Text("已完成".tr) }.font(.caption).foregroundColor(.bbGreen) }
                }
                Text(lesson.title.tr).font(.title2.bold()).foregroundColor(.bbInk)

                if let ex = lesson.explanation { card(ex.tr) }

                if let pts = lesson.points, !pts.isEmpty {
                    sectionTitle("重点".tr)
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(pts.enumerated()), id: \.offset) { i, p in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(i + 1)").font(.caption.weight(.semibold)).foregroundColor(.bbInk)
                                    .frame(width: 22, height: 22).overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.bbLine))
                                Text(p.tr).font(.body).foregroundColor(.bbInk).fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
                }

                if let ex = lesson.example {
                    sectionTitle("学生例子".tr)
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: "quote.opening").foregroundColor(Color(hex: 0x3A5A78))
                        Text(ex.tr).font(.subheadline).foregroundColor(.bbInk).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Color.bbBlue).cornerRadius(12)
                }

                if let task = lesson.task {
                    sectionTitle("今天的小任务".tr)
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill").font(.title3).foregroundColor(.bbGreen)
                        Text(task.tr).font(.body.weight(.medium)).foregroundColor(Color(hex: 0x35583F))
                        Spacer(minLength: 0)
                    }
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Color(hex: 0xE4EFE7)).cornerRadius(12)
                }

                if let v = lesson.video, let s = v.videoUrl, let url = URL(string: s) {
                    Link(destination: url) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.circle.fill").font(.title2).foregroundColor(.bbGreen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(v.videoTitle ?? "配套视频".tr).font(.subheadline.weight(.semibold)).foregroundColor(.bbInk)
                                Text("来自".tr + " \(v.videoProvider ?? "视频".tr)" + (v.author.map { BBLang.isEN ? " · by \($0)" : " · UP主：\($0)" } ?? ""))
                                    .font(.caption2).foregroundColor(.bbInk2)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right").font(.caption).foregroundColor(.bbInk2)
                        }
                        .padding(14).background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
                    }
                }

                Button { done.toggle(); store.setLessonDone(lesson.id, done) } label: {
                    Label(done ? "已完成 · 取消标记".tr : "标记完成".tr, systemImage: done ? "arrow.uturn.left" : "checkmark")
                        .font(.headline).foregroundColor(done ? .bbInk : .white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(done ? Color.bbSurface : Color.bbGreen)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(done ? Color.bbLine : Color.clear))
                        .cornerRadius(12)
                }
                .padding(.top, 6)
            }
            .padding(16)
            .bbPageWidth()
        }
        .background(Color.bbBg)
        .navigationTitle(LEARN_CATS[lesson.cat]?.zh.tr ?? "理财课程".tr)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { done = store.isLessonDone(lesson.id) }
    }

    private func card(_ text: String) -> some View {
        Text(text).font(.body).foregroundColor(.bbInk).fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading).padding(16)
            .background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
    }
    private func sectionTitle(_ t: String) -> some View {
        Text(t).font(.caption).tracking(2).foregroundColor(.bbInk2).padding(.top, 4)
    }
}

// MARK: - GameDetail (the branching story player)

struct GameDetailView: View {
    let story: Story
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    enum Phase { case intro, play, done }
    @State private var phase: Phase = .intro
    @State private var sceneId: String
    @State private var step = 1
    @State private var picked: Choice?
    @State private var stats: [String: Double]
    @State private var score = 0
    @State private var ending: Ending?

    init(story: Story) {
        self.story = story
        _sceneId = State(initialValue: story.start)
        _stats = State(initialValue: story.stats)
    }

    private var scene: StoryScene? { story.scenes[sceneId] }
    private var sceneCount: Int { story.scenes.count }

    var body: some View {
        ScrollView {
            Group {
                switch phase {
                case .intro: introView
                case .play: if let scene { playView(scene) }
                case .done: if let ending { doneView(ending) }
                }
            }
            .bbPageWidth()
        }
        .background(Color.bbBg)
        .navigationTitle(story.title.tr)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if phase == .play {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text(BBLang.isEN ? "Scene \(step) / \(sceneCount)" : "第 \(step) / \(sceneCount) 关").font(.caption).foregroundColor(.bbInk2)
                }
            }
        }
    }

    private var introView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10).fill(Color.bbSurface)
                    .frame(width: 64, height: 64)
                    .overlay(Image(systemName: storySymbol(story.icon)).font(.system(size: 28)).foregroundColor(.bbInk))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bbLine))
                Text(story.title.tr).font(.title2.bold()).foregroundColor(.bbInk)
                if let d = story.desc {
                    Text(d.tr).font(.subheadline).foregroundColor(.bbInk2).multilineTextAlignment(.center)
                }
                HStack(spacing: 8) {
                    if let lv = story.level { levelBadge(lv.tr) }
                    if let c = story.cat { tag(c.tr) }
                    if let t = story.time { tag(t.tr) }
                    tag((BBLang.isEN ? "\(sceneCount) scenes" : "\(sceneCount) 个场景"))
                }
                if store.isGameDone(story.id) {
                    HStack(spacing: 4) { Image(systemName: "checkmark.circle.fill"); Text("已通关".tr) }
                        .font(.caption).foregroundColor(.bbGreen)
                }
            }
            .frame(maxWidth: .infinity).padding(28)
            .background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)

            if let intro = story.intro {
                Text(intro.tr).font(.body).foregroundColor(.bbInk).lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                    .background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
            }
            Button { start() } label: {
                Label("开始游戏".tr, systemImage: "play.fill").font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14).duoPrimary()
            }
        }
        .padding(16)
    }

    private func playView(_ scene: StoryScene) -> some View {
        let imgName = "scene_" + story.id.replacingOccurrences(of: "-", with: "_") + "_" + sceneId

        return VStack(alignment: .leading, spacing: 14) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.bbLine.opacity(0.5)).frame(height: 7)
                    Capsule().fill(Color.bbGreen)
                        .frame(width: geo.size.width * CGFloat(step) / CGFloat(max(sceneCount, 1)), height: 7)
                }
            }
            .frame(height: 7)

            statusBar

            if UIImage(named: imgName) != nil {
                Image(imgName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 170)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine))
            } else if let grid = pixelScene(story.id, sceneId) {
                PixelArtView(grid: grid)
                    .frame(height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine))
                    .frame(maxWidth: .infinity)
            }

            HStack(spacing: 12) {
                Text(scene.emoji ?? "📍").font(.system(size: 26))
                    .frame(width: 50, height: 50).background(Color.bbBg).cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.bbLine))
                VStack(alignment: .leading, spacing: 2) {
                    if let setting = scene.setting {
                        HStack(spacing: 3) { Image(systemName: "mappin"); Text(setting.tr) }
                            .font(.caption.weight(.semibold)).foregroundColor(.bbInk)
                    }
                    if let st = scene.sceneTitle { Text(st.tr).font(.headline).foregroundColor(.bbInk) }
                }
                Spacer()
            }
            .padding(13).background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bbLine)).cornerRadius(10)

            if let npc = scene.npcName, let line = scene.npcLine {
                HStack(alignment: .top, spacing: 10) {
                    Text(String(npc.tr.prefix(1))).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                        .frame(width: 38, height: 38).background(Color.bbInk).cornerRadius(8)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(npc.tr).font(.caption).foregroundColor(.bbInk2)
                        Text(line.tr).font(.body).foregroundColor(.bbInk).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12).background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bbLine)).cornerRadius(10)
            }

            Text(scene.narrator.tr).font(.body).foregroundColor(.bbInk).lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                .background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)

            ForEach(scene.choices) { c in choiceButton(c) }

            if picked != nil {
                Button { proceed() } label: {
                    Text(scene.isFinal == true ? "看看结果".tr : "继续".tr).font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14).duoPrimary()
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
    }

    private var statusBar: some View {
        HStack(spacing: 10) {
            ForEach(story.statBar, id: \.self) { key in
                VStack(spacing: 3) {
                    Text(statLabel(key)).font(.caption2).foregroundColor(.bbInk2)
                    Text(statValue(key)).font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(.bbInk)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 8)
                .background(Color.bbSurface).cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bbLine))
            }
        }
    }

    private func choiceButton(_ c: Choice) -> some View {
        let isPicked = picked?.id == c.id
        let dim = picked != nil && !isPicked
        return Button { choose(c) } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(c.label.tr).font(.body.weight(.medium)).foregroundColor(.bbInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let hint = c.hint, !isPicked { Text(hint.tr).font(.caption).foregroundColor(.bbInk2) }
                if isPicked {
                    if let cons = c.consequence {
                        Text(cons.tr).font(.subheadline).foregroundColor(.bbInk).fixedSize(horizontal: false, vertical: true).padding(.top, 2)
                    }
                    if let effs = c.effects, !effs.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(effs.sorted(by: { $0.key < $1.key }), id: \.key) { k, v in
                                let good = (k == "risk") ? v < 0 : v > 0
                                Text(effLabel(k, v))
                                    .font(.caption2).padding(.horizontal, 7).padding(.vertical, 2)
                                    .background(Capsule().fill((good ? Color.bbGreen : Color.bbRed).opacity(0.14)))
                                    .foregroundColor(good ? .bbGreen : .bbRed)
                            }
                        }
                        .padding(.top, 2)
                    }
                    if let tip = c.tip {
                        HStack(alignment: .top, spacing: 5) {
                            Image(systemName: "lightbulb").font(.caption)
                            Text(tip.tr).font(.caption).fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundColor(.bbGreen).padding(.top, 2)
                    }
                }
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.bbSurface)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isPicked ? Color.bbInk : Color.bbLine, lineWidth: isPicked ? 1.5 : 1))
            .cornerRadius(10)
            .opacity(dim ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(picked != nil)
    }

    private func doneView(_ ending: Ending) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                Image(systemName: ending.tone == "good" ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 46)).foregroundColor(ending.tone == "good" ? .bbGreen : Color(hex: 0xC9A227))
                Text(ending.title.tr).font(.title2.bold()).foregroundColor(.bbInk)
            }
            .padding(.top, 24)
            resultCard("做得好".tr, ending.did_well?.tr, .bbGreen)
            resultCard("可以更好".tr, ending.improve?.tr, Color(hex: 0xC9A227))
            resultCard("养成习惯".tr, ending.habit?.tr, .bbInk)
            HStack(spacing: 10) {
                Button { start() } label: {
                    Text("再玩一次".tr).font(.headline).foregroundColor(.bbInk)
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
                }
                Button { dismiss() } label: {
                    Text("完成".tr).font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 13).duoPrimary()
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .onAppear {
            // A finished story with a good ending is the one happy moment we ask
            // for a rating — once per install, and Apple caps the prompt anyway.
            if ending.tone == "good", BBRating.consumeStoryDonePrompt() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { requestReview() }
            }
        }
    }

    @ViewBuilder
    private func resultCard(_ label: String, _ text: String?, _ color: Color) -> some View {
        if let text {
            VStack(alignment: .leading, spacing: 5) {
                Text(label).font(.caption.weight(.semibold)).foregroundColor(color)
                Text(text).font(.body).foregroundColor(.bbInk).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(14)
            .background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
        }
    }

    private func tag(_ s: String) -> some View {
        Text(s).font(.caption2).foregroundColor(.bbInk2)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(Capsule().fill(Color.bbBg)).overlay(Capsule().stroke(Color.bbLine))
    }

    // MARK: Stats + logic (mirrors the web's vnStat / vnEffStr / vnApply)
    private func statLabel(_ key: String) -> String {
        switch key {
        case "money":  return (story.moneyLabel ?? "余额").tr
        case "mood":   return "心情".tr
        case "health": return "健康".tr
        case "credit": return "信用".tr
        case "risk":   return "风险".tr
        default:       return key
        }
    }
    private func statValue(_ key: String) -> String {
        let v = stats[key] ?? 0
        switch key {
        case "money":  return "¥\(Int(v))"
        case "health": return "\(Int(v))%"
        case "mood":   return v >= 67 ? "好".tr : (v >= 34 ? "一般".tr : "低落".tr)
        case "risk":   return v < 34 ? "低".tr : (v < 67 ? "中".tr : "高".tr)
        case "credit":
            let n = max(0, min(5, Int((v / 20).rounded())))
            return String(repeating: "★", count: n) + String(repeating: "☆", count: 5 - n)
        default:       return "\(Int(v))"
        }
    }
    private func effLabel(_ key: String, _ delta: Double) -> String {
        let sign = delta > 0 ? "+" : "−"
        let n = Int(abs(delta))
        return key == "money" ? "\(statLabel(key)) \(sign)¥\(n)" : "\(statLabel(key)) \(sign)\(n)"
    }

    private func start() {
        phase = .play; sceneId = story.start; step = 1; picked = nil
        stats = story.stats; score = 0; ending = nil
    }
    private func choose(_ c: Choice) {
        guard picked == nil else { return }
        picked = c
        if let effs = c.effects {
            for (k, v) in effs {
                var nv = (stats[k] ?? 0) + v
                if k != "money" { nv = max(0, min(100, nv)) }
                stats[k] = nv
            }
        }
        score += c.score ?? 0
    }
    private func proceed() {
        guard let c = picked else { return }
        picked = nil
        if let endId = c.end, let e = story.endings[endId] { finish(e); return }
        if scene?.isFinal == true { finish(pickByScore()); return }
        if let nx = c.next { sceneId = nx; step += 1 }
    }
    private func pickByScore() -> Ending {
        var maxScore = 0
        for (_, s) in story.scenes { maxScore += s.choices.map { $0.score ?? 0 }.max() ?? 0 }
        let pct = maxScore > 0 ? Int(Double(score) / Double(maxScore) * 100) : 0
        let ranked = story.endings.values.filter { $0.min != nil }.sorted { ($0.min ?? 0) > ($1.min ?? 0) }
        return ranked.first { pct >= ($0.min ?? 0) } ?? ranked.last
            ?? Ending(title: "完成".tr, tone: "good", did_well: nil, improve: nil, habit: nil, min: 0)
    }
    private func finish(_ e: Ending) { store.markGameComplete(story.id); ending = e; phase = .done }
}
