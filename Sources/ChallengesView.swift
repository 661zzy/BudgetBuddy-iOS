import SwiftUI

// MARK: - 我的挑战 (Challenges)

struct ChallengesView: View {
    @EnvironmentObject var store: AppStore
    @State private var checkInMessage: String?

    private var savedEst: Int {
        store.completedChallenges.reduce(0) { $0 + (ChallengeDefStore.find($1.defId)?.est ?? 0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 0) {
                    summaryCol("\(store.activeChallenges.count)", "进行中")
                    Rectangle().fill(Color.bbLine).frame(width: 1, height: 36)
                    summaryCol("\(store.completedChallenges.count)", "已完成")
                    Rectangle().fill(Color.bbLine).frame(width: 1, height: 36)
                    summaryCol("¥\(savedEst)", "累计省下")
                }
                .padding(.vertical, 16)
                .background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
                sectionTitle("进行中")
                if store.activeChallenges.isEmpty {
                    emptyCard("flag", "还没有进行中的挑战，下面挑一个开始吧")
                } else {
                    ForEach(store.activeChallenges) { inst in instanceCard(inst) }
                }

                if !store.recommendedDefs.isEmpty {
                    sectionTitle("推荐挑战")
                    ForEach(store.recommendedDefs) { def in recommendCard(def) }
                }

                sectionTitle("已完成")
                if store.completedChallenges.isEmpty {
                    emptyCard("trophy", "还没有完成的挑战，坚持打卡就能拿到第一个")
                } else {
                    ForEach(store.completedChallenges) { inst in instanceCard(inst) }
                }
            }
            .padding(16)
        }
        .background(Color.bbBg)
        .overlay(alignment: .top) {
            if let checkInMessage {
                checkInBanner(checkInMessage)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: checkInMessage)
        .navigationTitle("我的挑战")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func summaryCol(_ value: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.system(size: 22, weight: .semibold)).foregroundColor(.bbInk)
            Text(label).font(.caption).foregroundColor(.bbInk2)
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionTitle(_ t: String) -> some View {
        Text(t).font(.subheadline.weight(.semibold)).foregroundColor(.bbInk).padding(.top, 6)
    }

    private func checkInBanner(_ message: String) -> some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.bbGreen)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(hex: 0xE4EFE7))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbGreen.opacity(0.2)))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
            .accessibilityIdentifier("challenge.checkin.confirmation")
    }

    private func emptyCard(_ icon: String, _ text: String) -> some View {
        VStack(spacing: 9) {
            Image(systemName: icon).font(.system(size: 28)).foregroundColor(.bbInk2)
            Text(text).font(.subheadline).foregroundColor(.bbInk2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 22)
        .background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
    }

    private func instanceCard(_ inst: ChallengeInstance) -> some View {
        let def = ChallengeDefStore.find(inst.defId)
        let total = def?.days ?? 1
        let progress = inst.checkDays.count
        let pct = total > 0 ? Int(Double(min(progress, total)) / Double(total) * 100) : 0
        let done = inst.status == "done"
        let checkedToday = store.challengeCheckedToday(inst)
        return VStack(alignment: .leading, spacing: 12) {
            if checkedToday || done {
                Text(done ? "挑战完成" : "今天已打卡")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(done ? .bbGreen : .bbInk2)
                    .accessibilityIdentifier("challenge.checkin.state.\(inst.id)")
            }
            HStack(spacing: 13) {
                RoundedRectangle(cornerRadius: 10).fill(done ? Color(hex: 0xE4EFE7) : Color(hex: 0xFFF4DF))
                    .frame(width: 46, height: 46)
                    .overlay(Image(systemName: done ? "party.popper.fill" : challengeSymbol(def?.icon))
                        .foregroundColor(done ? .bbGreen : Color(hex: 0x8A5A2B)))
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(def?.title ?? "挑战").font(.headline).foregroundColor(.bbInk)
                        Spacer(minLength: 0)
                        statusBadge(done)
                    }
                    if let d = def?.desc { Text(d).font(.caption).foregroundColor(.bbInk2) }
                }
            }
            metaRow(def)
            VStack(spacing: 7) {
                HStack {
                    Text("已坚持 \(progress) / \(total) 天").font(.caption).foregroundColor(.bbInk2)
                    Spacer()
                    Text("\(pct)%").font(.caption.weight(.semibold)).foregroundColor(done ? .bbGreen : Color(hex: 0xC9772B))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.bbLine.opacity(0.5)).frame(height: 7)
                        Capsule().fill(done ? Color.bbGreen : Color(hex: 0xE0915A))
                            .frame(width: geo.size.width * CGFloat(min(progress, total)) / CGFloat(max(total, 1)), height: 7)
                    }
                }
                .frame(height: 7)
            }
            if !done, let tip = def?.tip {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb").font(.caption).foregroundColor(Color(hex: 0xC9772B))
                    Text(tip).font(.caption).foregroundColor(Color(hex: 0x8A5A2B)).fixedSize(horizontal: false, vertical: true)
                }
                .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: 0xFFF4DF)).cornerRadius(10)
            }
            if done {
                Label("已坚持 \(total) 天，太棒了", systemImage: "checkmark")
                    .font(.caption).foregroundColor(.bbGreen)
                    .accessibilityIdentifier("challenge.completed.\(inst.id)")
            } else if checkedToday {
                Label("今天已打卡", systemImage: "checkmark")
                    .font(.subheadline).foregroundColor(.bbInk2)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Color.bbBg).cornerRadius(12)
                    .accessibilityIdentifier("challenge.checkedToday.\(inst.id)")
            } else {
                Button {
                    store.checkInChallenge(inst.id)
                    checkInMessage = "今天已打卡"
                } label: {
                    Label("今日打卡", systemImage: "checkmark.circle")
                        .font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .duoPrimary()
                }
                .accessibilityIdentifier("challenge.checkin.button.\(inst.id)")
            }
        }
        .padding(16)
        .background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bbLine)).cornerRadius(14)
    }

    private func recommendCard(_ def: ChallengeDef) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 13) {
                RoundedRectangle(cornerRadius: 10).fill(Color.bbBg)
                    .frame(width: 46, height: 46)
                    .overlay(Image(systemName: challengeSymbol(def.icon)).foregroundColor(.bbInk))
                VStack(alignment: .leading, spacing: 3) {
                    Text(def.title).font(.headline).foregroundColor(.bbInk)
                    if let d = def.desc { Text(d).font(.caption).foregroundColor(.bbInk2).fixedSize(horizontal: false, vertical: true) }
                }
                Spacer(minLength: 0)
                Button { store.startChallenge(def.id) } label: {
                    Text("开始").font(.system(.subheadline, design: .rounded).weight(.bold)).foregroundColor(.white)
                        .padding(.horizontal, 18).padding(.vertical, 10).duoPrimary(12)
                }
                .accessibilityIdentifier("challenge.start.button.\(def.id)")
            }
            metaRow(def)
        }
        .padding(16)
        .background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bbLine)).cornerRadius(14)
    }

    private func metaRow(_ def: ChallengeDef?) -> some View {
        HStack(spacing: 8) {
            if let lv = def?.level { levelBadge(lv) }
            if let days = def?.days {
                HStack(spacing: 3) { Image(systemName: "calendar"); Text("\(days) 天") }.font(.caption2).foregroundColor(.bbInk2)
            }
            if let est = def?.est, est > 0 {
                HStack(spacing: 3) { Image(systemName: "yensign.circle"); Text("约省 ¥\(est)") }.font(.caption2).foregroundColor(.bbGreen)
            }
        }
    }

    private func statusBadge(_ done: Bool) -> some View {
        Text(done ? "挑战完成" : "进行中").font(.caption2)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill((done ? Color.bbGreen : Color(hex: 0xC9772B)).opacity(0.14)))
            .foregroundColor(done ? .bbGreen : Color(hex: 0xC9772B))
    }
}
