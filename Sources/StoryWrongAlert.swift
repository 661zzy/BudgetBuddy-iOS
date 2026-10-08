import SwiftUI
import UIKit

// MARK: - How a story choice is judged
//
// stories.json scores every choice 2 (the move we teach), 1 (half right) or 0
// (the trap). A few scenes have no right answer at all (every choice scores 0);
// those are judged "neutral" so nobody is told off for a coin-toss scene.

enum ChoiceVerdict { case best, okay, wrong, neutral }

extension StoryScene {
    var bestScore: Int { choices.map { $0.score ?? 0 }.max() ?? 0 }

    func verdict(for choice: Choice) -> ChoiceVerdict {
        let best = bestScore
        guard best > 0 else { return .neutral }
        let s = choice.score ?? 0
        if s >= best { return .best }
        return s <= 0 ? .wrong : .okay
    }

    /// The choices worth showing as "a better move" after a wrong pick.
    var bestChoices: [Choice] {
        let best = bestScore
        return best > 0 ? choices.filter { ($0.score ?? 0) == best } : []
    }
}

/// Everything the red alert needs, captured at the moment of the wrong pick.
struct StoryWrongPick: Identifiable {
    let id = UUID()
    let choice: Choice
    let betterMoves: [String]   // already translated
    let effectChips: [String]   // already formatted, e.g. "Risk +20"
    var sceneImage: String? = nil   // the scene's own pixel art, used as the error illustration
}

// MARK: - The big red "wrong move" sheet
//
// Motion language (owner's references: XTB "xStation pop-up", "Set Default Bank Card",
// Dribbble error illustrations):
//   1. a floating sheet shoots up from the bottom and decelerates long, no bounce
//   2. the scene's illustration rises into the red header like a card from a stack
//   3. a ✕ badge lands on it — error haptic, a small particle burst, one damped shake
//   4. the words arrive one row after another; the button grows out of a small pill
//   5. leaving plays it backwards: the button folds, the sheet drops, the backdrop clears,
//      and the 「这步有坑」 mark then appears on the choice the player picked
// Reduce Motion: every step becomes a short fade; the haptic stays.

struct StoryWrongAlert: View {
    let pick: StoryWrongPick
    let onClose: () -> Void

    init(pick: StoryWrongPick, onClose: @escaping () -> Void) {
        self.pick = pick
        self.onClose = onClose
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dimmed = false
    @State private var sheetIn = false
    @State private var artIn = false
    @State private var badgeIn = false
    @State private var headerStep = 0      // title, subtitle, chips
    @State private var bodyStep = 0        // you chose, result, why, better
    @State private var ctaIn = false
    @State private var shakes: CGFloat = 0
    @State private var burst = false
    @State private var closing = false

    static let alarm = Color(hex: 0xD32F2F)
    static let alarmDeep = Color(hex: 0xA51F1F)
    private static let alarmEdge = Color(hex: 0x7F1515)

    var body: some View {
        ZStack {
            // A dark red wash over the whole screen, tab bar included. Tapping it does
            // nothing: the point is that the player stops and reads.
            Color(hex: 0x2A0606).opacity(dimmed ? 0.62 : 0)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {}
                .accessibilityHidden(true)

            GeometryReader { geo in
                ViewThatFits(in: .vertical) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        sheet
                    }
                    ScrollView(showsIndicators: false) {      // very large text: the sheet scrolls
                        sheet.padding(.top, 24)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
                .offset(y: sheetIn || reduceMotion ? 0 : geo.size.height + 40)
                .opacity(reduceMotion ? (sheetIn ? 1 : 0) : 1)
            }
        }
        .onAppear(perform: appear)
        .accessibilityAction(.escape) { close() }
    }

    // MARK: Sheet

    private var sheet: some View {
        VStack(spacing: 0) {
            header
            VStack(alignment: .leading, spacing: 14) {
                block("你选的是".tr, quoted(pick.choice.label.tr), weight: .semibold)
                    .modifier(BBRise(visible: bodyStep >= 1))
                if let cons = pick.choice.consequence {
                    block("接下来会发生什么".tr, cons.tr)
                        .modifier(BBRise(visible: bodyStep >= 2))
                }
                if let tip = pick.choice.tip {
                    callout(icon: "exclamationmark.bubble.fill", title: "为什么要小心".tr, lines: [tip.tr],
                            tint: Self.alarm, titleColor: Self.alarmDeep)
                        .modifier(BBRise(visible: bodyStep >= 3))
                }
                if !pick.betterMoves.isEmpty {
                    callout(icon: "checkmark.circle.fill", title: "下次可以这样做".tr, lines: pick.betterMoves,
                            tint: .bbGreen, titleColor: .bbGreen)
                        .modifier(BBRise(visible: bodyStep >= 4))
                }
                Button(action: close) {
                    Text("我记住了".tr).font(.headline).foregroundColor(.white)
                        .opacity(ctaIn ? 1 : 0)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .duo(Self.alarm, Self.alarmEdge)
                }
                .buttonStyle(.plain)
                .scaleEffect(x: ctaIn || reduceMotion ? 1 : 0.32, y: ctaIn || reduceMotion ? 1 : 0.86)
                .opacity(ctaIn ? 1 : 0)
                .padding(.top, 2)
                .accessibilityIdentifier("story.wrong.ok")
            }
            .padding(18)
            .background(Color.bbSurface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.32), radius: 28, y: 12)
        .frame(maxWidth: 520)
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("story.wrong.alert")
    }

    private var header: some View {
        VStack(spacing: 8) {
            illustration
                .padding(.bottom, 6)
            Text("这一步有坑".tr)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .accessibilityAddTraits(.isHeader)
                .modifier(BBRise(visible: headerStep >= 1, distance: 10))
            Text("没关系，看清楚了下次就能躲开".tr)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.92))
                .modifier(BBRise(visible: headerStep >= 2, distance: 10))
            if !pick.effectChips.isEmpty {
                HStack(spacing: 6) {
                    ForEach(pick.effectChips, id: \.self) { chip in
                        Text(chip).font(.caption.weight(.bold)).foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(Color.black.opacity(0.22)))
                    }
                }
                .padding(.top, 2)
                .modifier(BBRise(visible: headerStep >= 3, distance: 10))
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 22).padding(.bottom, 22).padding(.horizontal, 18)
        .background(LinearGradient(colors: [Color(hex: 0xE53935), Self.alarmDeep], startPoint: .top, endPoint: .bottom))
    }

    /// The scene's own picture, framed like a card, with a red ✕ badge that lands on it.
    /// Scenes without art fall back to the large symbol.
    @ViewBuilder private var illustration: some View {
        if let name = pick.sceneImage, UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 210, height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                .overlay(alignment: .topTrailing) { badge.offset(x: 16, y: -16) }
                .modifier(BBShake(animatableData: shakes))
                .scaleEffect(artIn || reduceMotion ? 1 : 0.9)
                .offset(y: artIn || reduceMotion ? 0 : 36)
                .opacity(artIn ? 1 : 0)
                .accessibilityHidden(true)
        } else {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 66, weight: .bold))
                .foregroundColor(.white)
                .overlay { BBParticleBurst(trigger: burst) }
                .modifier(BBShake(animatableData: shakes))
                .scaleEffect(badgeIn || reduceMotion ? 1 : 0.4)
                .opacity(badgeIn ? 1 : 0)
                .accessibilityHidden(true)
        }
    }

    private var badge: some View {
        ZStack {
            Circle().fill(Self.alarm)
            Circle().stroke(Color.white, lineWidth: 3)
            Image(systemName: "xmark").font(.system(size: 19, weight: .heavy)).foregroundColor(.white)
        }
        .frame(width: 44, height: 44)
        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
        .background(BBParticleBurst(trigger: burst))
        .scaleEffect(badgeIn || reduceMotion ? 1 : 0.2)
        .opacity(badgeIn ? 1 : 0)
    }

    private func block(_ label: String, _ text: String, weight: Font.Weight = .regular) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption.weight(.semibold)).foregroundColor(.bbInk2)
            Text(text).font(.body.weight(weight)).foregroundColor(.bbInk).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func callout(icon: String, title: String, lines: [String], tint: Color, titleColor: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).font(.subheadline).foregroundColor(tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption.weight(.bold)).foregroundColor(titleColor)
                ForEach(lines, id: \.self) { line in
                    Text(line).font(.subheadline).foregroundColor(.bbInk).fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tint.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(tint.opacity(0.3)))
    }

    private func quoted(_ s: String) -> String { BBLang.isEN ? "“\(s)”" : "「\(s)」" }

    // MARK: Timeline

    private func appear() {
        let haptic = UINotificationFeedbackGenerator()
        haptic.prepare()
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.2)) {
                dimmed = true; sheetIn = true; artIn = true; badgeIn = true
                headerStep = 3; bodyStep = 4; ctaIn = true
            }
            haptic.notificationOccurred(.error)
            return
        }
        withAnimation(.easeOut(duration: 0.3)) { dimmed = true }
        withAnimation(BBMotion.sheet) { sheetIn = true }
        at(0.20, BBMotion.rise) { artIn = true }
        for i in 1...3 { at(0.24 + 0.05 * Double(i - 1), BBMotion.fadeUp) { headerStep = i } }
        at(0.44, BBMotion.pop) {
            badgeIn = true
        } then: {
            haptic.notificationOccurred(.error)
            burst.toggle()
            withAnimation(.linear(duration: BBShake.duration)) { shakes = 1 }
        }
        for i in 1...4 { at(0.36 + 0.06 * Double(i - 1), BBMotion.fadeUp) { bodyStep = i } }
        at(0.62, BBMotion.grow) { ctaIn = true }
    }

    /// Backwards: the button folds, the sheet drops, the backdrop clears.
    private func close() {
        guard !closing else { return }
        closing = true
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.2)) { sheetIn = false; dimmed = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onClose() }
            return
        }
        withAnimation(.easeIn(duration: 0.14)) { ctaIn = false }
        at(0.06, .easeIn(duration: 0.26)) { sheetIn = false }
        at(0.06, .easeOut(duration: 0.3)) { dimmed = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) { onClose() }
    }

    private func at(_ delay: Double, _ animation: Animation, _ change: @escaping () -> Void,
                    then after: (() -> Void)? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(animation, change)
            after?()
        }
    }
}

/// Fades a row in while it rises a few points into place.
struct BBRise: ViewModifier {
    let visible: Bool
    var distance: CGFloat = 12
    func body(content: Content) -> some View {
        content.opacity(visible ? 1 : 0).offset(y: visible ? 0 : distance)
    }
}

/// A one-off burst of small confetti pieces flying out from the centre and fading.
/// Decorative only; nothing happens with Reduce Motion.
struct BBParticleBurst: View {
    let trigger: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var armed = false
    @State private var flown = false

    private static let colors: [Color] = [.white, Color(hex: 0xFFCDD2), Color(hex: 0xFFE082)]
    private static let pieces: [(angle: Double, distance: CGFloat, size: CGFloat, spin: Double, color: Int)] =
        (0..<16).map { i in
            let angle = Double(i) / 16 * 2 * .pi + (i.isMultiple(of: 2) ? 0.15 : -0.1)
            return (angle, CGFloat(44 + (i * 29) % 40), CGFloat(4 + (i * 3) % 4), Double((i * 53) % 200) - 100, i % 3)
        }

    var body: some View {
        ZStack {
            ForEach(0..<Self.pieces.count, id: \.self) { i in
                let p = Self.pieces[i]
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Self.colors[p.color])
                    .frame(width: p.size, height: p.size * 1.7)
                    .rotationEffect(.degrees(flown ? p.spin : 0))
                    .scaleEffect(flown ? 0.5 : 1)
                    .offset(x: flown ? cos(p.angle) * p.distance : 0, y: flown ? sin(p.angle) * p.distance : 0)
                    .opacity(armed ? (flown ? 0 : 1) : 0)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: trigger) {
            guard trigger, !reduceMotion else { return }
            armed = true
            flown = false
            withAnimation(.easeOut(duration: 0.75)) { flown = true }
        }
    }
}

/// One damped side-to-side shake, the gesture iOS uses for a wrong passcode.
/// `animatableData` runs 0 → 1 linearly; the offset is a decaying sine, so it starts
/// firm, dies away like a real spring and ends exactly at rest.
struct BBShake: GeometryEffect {
    static let duration: Double = 0.5
    var amount: CGFloat = 10
    var cycles: CGFloat = 3.5
    var decay: CGFloat = 4.2
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        let t = animatableData
        let x = amount * exp(-decay * t) * sin(2 * .pi * cycles * t)
        return ProjectionTransform(CGAffineTransform(translationX: x, y: 0))
    }
}

/// Shared springs, matching SwiftUI's system presets (iOS 17's `.smooth` / `.snappy`)
/// and falling back to equivalent spring parameters on iOS 16.
enum BBMotion {
    static let settleTime: Double = 0.3

    /// Critically damped: arrives quickly and stops without overshoot.
    static var settle: Animation {
        if #available(iOS 17.0, *) { return .smooth(duration: settleTime) }
        return .spring(response: settleTime, dampingFraction: 1)
    }

    /// Floating sheet: shoots up and decelerates long; no visible bounce.
    static var sheet: Animation { .spring(response: 0.5, dampingFraction: 0.88) }
    /// An element rising into place (the illustration card): a little give at the end.
    static var rise: Animation { .spring(response: 0.42, dampingFraction: 0.8) }
    /// Text rows arriving one after another.
    static var fadeUp: Animation { .easeOut(duration: 0.32) }
    /// A small badge landing: the one deliberately springy beat.
    static var pop: Animation { .spring(response: 0.32, dampingFraction: 0.55) }
    /// The button growing out of a pill.
    static var grow: Animation { .spring(response: 0.42, dampingFraction: 0.74) }
    /// One scene handing over to the next, like swapping the top card of a stack.
    static var swap: Animation { .spring(response: 0.45, dampingFraction: 0.9) }

    /// For content changing in place (a card opening, a bar filling): fast, a hint of give.
    static var snappy: Animation {
        if #available(iOS 17.0, *) { return .snappy(duration: 0.3) }
        return .spring(response: 0.3, dampingFraction: 0.86)
    }
}

/// The SF Symbol's built-in bounce (iOS 17+). Off with Reduce Motion and on iOS 16.
struct BBSymbolBounce: ViewModifier {
    let trigger: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *), !reduceMotion {
            content.symbolEffect(.bounce, value: trigger)
        } else {
            content
        }
    }
}

/// Bounces a symbol once when it first appears (a verdict label, the ending badge).
struct BBBounceOnAppear: ViewModifier {
    @State private var pulse = false
    func body(content: Content) -> some View {
        content
            .modifier(BBSymbolBounce(trigger: pulse))
            .onAppear { DispatchQueue.main.async { pulse.toggle() } }
    }
}

// MARK: - A full-screen cover whose own background is transparent

private struct BBClearPresentationBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async { view.superview?.superview?.backgroundColor = .clear }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension View {
    /// Lets a `.fullScreenCover` draw its own dimmed backdrop over the screen it covers.
    @ViewBuilder func bbTransparentCover() -> some View {
        if #available(iOS 16.4, *) {
            presentationBackground(Color.clear)
        } else {
            background(BBClearPresentationBackground())
        }
    }
}
