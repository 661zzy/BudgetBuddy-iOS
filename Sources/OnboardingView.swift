import SwiftUI

// First-run onboarding: a bilingual language picker first, then 3 swipeable slides.

private struct OBSlide {
    let icon: String
    let tint: Color
    let fg: Color
    let title: String
    let body: String
}

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("bb.lang") private var bbLang = "zh"
    @State private var langChosen = BBLang.chosen
    @State private var i = 0

    private let slides: [OBSlide] = [
        OBSlide(icon: "wallet.pass.fill", tint: Color(hex: 0xE5EEF7), fg: Color(hex: 0x3A5A78),
                title: "在真实情境里，练习每一次用钱选择", body: "花了钱就记一下，三秒搞定，慢慢来就好"),
        OBSlide(icon: "target", tint: Color(hex: 0xE4EFE7), fg: Color(hex: 0x3E5F4D),
                title: "存钱目标看得见", body: "设个小目标，进度条一点点涨，存钱也有成就感"),
        OBSlide(icon: "sparkles", tint: Color(hex: 0xFFF4DF), fg: Color(hex: 0x8A5A2B),
                title: "省钱搭子帮你出主意", body: "哪里花多了、怎么省下来，搭子用大白话告诉你"),
    ]
    private var last: Bool { i == slides.count - 1 }

    var body: some View {
        ZStack {
            Color.bbBg.ignoresSafeArea()
            if !langChosen { languagePicker } else { slidesView }
        }
    }

    // Shown in BOTH languages on purpose — the user hasn't picked one yet.
    private var languagePicker: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 36).fill(Color(hex: 0xE4EFE7)).frame(width: 160, height: 160)
                Image(systemName: "globe").font(.system(size: 70)).foregroundColor(Color(hex: 0x3E5F4D))
            }
            .padding(.bottom, 34)
            Text("选择语言").font(.title2.bold()).foregroundColor(.bbInk)
            Text("Choose Your Language").font(.subheadline).foregroundColor(.bbInk2).padding(.top, 4)

            VStack(spacing: 14) {
                langButton("中文", sub: "简体中文", lang: "zh")
                langButton("English", sub: "English (US)", lang: "en")
            }
            .padding(.horizontal, 40).padding(.top, 36)
            Spacer()
            Text("之后可在「我的」里随时切换 · You can change this anytime in Me")
                .font(.caption2).foregroundColor(.bbInk2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30).padding(.bottom, 30)
        }
        .bbPageWidth(520)
    }

    private func langButton(_ title: String, sub: String, lang: String) -> some View {
        Button {
            BBLang.set(lang)
            bbLang = lang           // triggers RootView .id rebuild
            langChosen = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.bbInk)
                    Text(sub).font(.caption).foregroundColor(.bbInk2)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill").font(.system(size: 24)).foregroundColor(.bbGreen)
            }
            .padding(18)
            .background(Color.bbSurface)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bbLine))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private var slidesView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("跳过".tr) { store.finishOnboarding() }
                    .foregroundColor(.bbInk2).padding(.horizontal, 18).padding(.top, 10)
            }

            Spacer()

            TabView(selection: $i) {
                ForEach(slides.indices, id: \.self) { idx in
                    slideView(slides[idx]).tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 380)

            HStack(spacing: 8) {
                ForEach(slides.indices, id: \.self) { k in
                    Circle().fill(k == i ? Color.bbGreen : Color.bbLine)
                        .frame(width: k == i ? 9 : 7, height: k == i ? 9 : 7)
                }
            }
            .padding(.top, 6)

            Spacer()

            Button {
                if last { store.finishOnboarding() } else { withAnimation { i += 1 } }
            } label: {
                Text(last ? "开始体验".tr : "下一步".tr).font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .duoPrimary()
            }
            .padding(.horizontal, 28).padding(.bottom, 34)
        }
        .bbPageWidth(520)
    }

    private func slideView(_ s: OBSlide) -> some View {
        VStack(spacing: 30) {
            ZStack {
                RoundedRectangle(cornerRadius: 36).fill(s.tint).frame(width: 200, height: 200)
                Image(systemName: s.icon).font(.system(size: 86)).foregroundColor(s.fg)
            }
            VStack(spacing: 12) {
                Text(s.title.tr).font(.title2.bold()).foregroundColor(.bbInk)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                Text(s.body.tr).font(.body).foregroundColor(.bbInk2)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
        }
    }
}
