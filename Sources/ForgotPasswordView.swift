import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var identifier = ""
    @State private var code = ""
    @State private var password = ""
    @State private var busy = false
    @State private var sending = false
    @State private var cooldown = 0
    @State private var err = ""
    @State private var hint = ""
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("用注册时的手机号或邮箱接收验证码，设置新密码。")
                        .font(.subheadline).foregroundColor(.bbInk2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    authField(icon: "envelope", placeholder: "手机号或邮箱", text: $identifier, secure: false)

                    HStack(spacing: 10) {
                        authField(icon: "checkmark.shield", placeholder: "验证码", text: $code, secure: false, numpad: true)
                        Button { send() } label: {
                            Text(cooldown > 0 ? "\(cooldown)s" : (sending ? "发送中" : "发送验证码"))
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundColor(cooldown > 0 ? .bbInk2 : .white)
                                .padding(.horizontal, 12).frame(height: 50)
                                .background(cooldown > 0 || sending ? Color.bbLine : Color.bbGreen)
                                .cornerRadius(10)
                        }
                        .disabled(cooldown > 0 || sending)
                    }

                    authField(icon: "lock", placeholder: "新密码（至少 6 位）", text: $password, secure: true)

                    if !hint.isEmpty {
                        Text(hint).font(.footnote).foregroundColor(.bbGreen)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !err.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle"); Text(err)
                        }
                        .font(.footnote).foregroundColor(.bbRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: reset) {
                        Text(busy ? "请稍候…" : "重置密码并登录")
                            .font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .duoPrimary()
                    }
                    .disabled(busy).opacity(busy ? 0.6 : 1).padding(.top, 4)
                    Spacer()
                }
                .padding(24)
            }
            .background(Color.bbBg)
            .navigationTitle("找回密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
            .onReceive(tick) { _ in if cooldown > 0 { cooldown -= 1 } }
        }
    }

    private func send() {
        let id = identifier.trimmingCharacters(in: .whitespaces)
        guard bbIdentifierType(id) != nil else { err = "请输入有效的手机号或邮箱"; return }
        guard !sending, cooldown == 0 else { return }
        sending = true; err = ""; hint = ""
        Task {
            if let res = await store.sendCode(identifier: id, purpose: "reset") {
                if let dev = res.devCode, !dev.isEmpty {
                    code = dev; hint = "测试模式：验证码已自动填入（\(dev)）"
                } else {
                    hint = res.channel == "phone" ? "验证码短信已发送，请查收" : "验证码邮件已发送，请查收"
                }
                cooldown = 60
            } else {
                err = store.errorMessage ?? "验证码发送失败"
            }
            sending = false
        }
    }

    private func reset() {
        let id = identifier.trimmingCharacters(in: .whitespaces)
        guard bbIdentifierType(id) != nil else { err = "请输入有效的手机号或邮箱"; return }
        guard !code.isEmpty else { err = "请填写验证码"; return }
        guard password.count >= 6 else { err = "新密码至少 6 位"; return }
        busy = true; err = ""
        Task {
            let ok = await store.resetPassword(identifier: id, code: code, password: password)
            if ok { dismiss() } else { err = store.errorMessage ?? "重置失败，请重试" }
            busy = false
        }
    }

    @ViewBuilder
    private func authField(icon: String, placeholder: String, text: Binding<String>, secure: Bool, numpad: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(.bbInk2).frame(width: 20)
            if secure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(numpad ? .numberPad : .default)
            }
        }
        .padding(14)
        .background(Color.bbSurface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bbLine))
        .cornerRadius(10)
    }
}
