import SwiftUI
import UIKit

// Auto update-check: on launch the app fetches a static version.json from the web root and,
// if a newer build is available, shows a prompt. minBuild lets us force-update if ever needed.
// Fails silently (no prompt) if the file is unreachable — never blocks a normal launch.

struct AppVersionInfo: Codable {
    let latest: String?
    let latestBuild: Int?
    let minBuild: Int?
    let url: String?
    let note: String?
}

struct UpdatePrompt: Identifiable {
    let id = UUID()
    let note: String
    let url: String
    let force: Bool        // true = blocking (current build < minBuild)
}

struct UpdateSheet: View {
    let prompt: UpdatePrompt
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "arrow.down.circle.fill").font(.system(size: 58)).foregroundColor(.bbGreen)
            Text(prompt.force ? "需要更新".tr : "有新版本".tr)
                .font(.system(.title2, design: .rounded).weight(.bold)).foregroundColor(.bbInk)
            Text(prompt.note)
                .font(.system(.body, design: .rounded)).foregroundColor(.bbInk2)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button {
                if let u = URL(string: prompt.url) { UIApplication.shared.open(u) }
            } label: {
                Text("去更新".tr).font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16).duoPrimary()
            }
            if !prompt.force {
                Button { dismiss() } label: {
                    Text("稍后再说".tr).font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(.bbInk2)
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bbBg)
        .interactiveDismissDisabled(prompt.force)
    }
}
