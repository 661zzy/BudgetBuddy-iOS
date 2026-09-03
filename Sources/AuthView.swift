import SwiftUI

// Presented as an OPTIONAL sheet (from 我的 / anywhere) — never a launch gate.
// Guests can close it and keep using the app (App Store Guideline 5.1.1(v)).
struct AuthView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var mode = 0            // 0 = 登录, 1 = 注册
    @State private var identifier = ""
    @State private var password = ""
    @State private var nickname = ""
    @State private var code = ""
    @State private var busy = false
    @State private var sending = false
    @State private var cooldown = 0
    @State private var err = ""
    @State private var hint = ""
    @State private var showForgot = false
    @State private var under14 = false          // v1.5.3: PIPL — under-14s need a guardian's consent
    @State private var guardianOK = false
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.bbBg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Spacer().frame(height: 24)
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.bbGreen)
                        .frame(width: 64, height: 64)
                        .overlay(Text("省").font(.system(size: 30, weight: .bold)).foregroundColor(.white))
                    Text(mode == 0 ? "欢迎回来".tr : "创建账号".tr)
                        .font(.title.bold()).foregroundColor(.bbInk)
                    Text("记好每一笔，存下每一分".tr)
                        .font(.subheadline).foregroundColor(.bbInk2)

                    Picker("", selection: $mode) {
                        Text("登录".tr).tag(0); Text("注册".tr).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                    .onChange(of: mode) { _ in err = ""; hint = "" }

                    field(icon: "envelope", placeholder: "手机号或邮箱".tr, text: $identifier, secure: false)
                    field(icon: "lock", placeholder: (mode == 0 ? "密码".tr : "密码（≥8位，含大小写字母）".tr), text: $password, secure: true)
                    if mode == 1 {
                        field(icon: "face.smiling", placeholder: "昵称".tr, text: $nickname, secure: false)
                        codeRow(purpose: "register")
                        ageRow
                    }

                    if !hint.isEmpty {
                        Text(hint).font(.footnote).foregroundColor(.bbGreen)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !err.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle")
                            Text(err)
                        }
                        .font(.footnote).foregroundColor(.bbRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: submit) {
                        Text(busy ? "请稍候…".tr : (mode == 0 ? "登录".tr : "注册并登录".tr))
                            .font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .duoPrimary()
                    }
                    .disabled(busy)
                    .opacity(busy ? 0.6 : 1)
                    .padding(.top, 4)

                    if mode == 0 {
                        Button("忘记密码？".tr) { showForgot = true }
                            .font(.footnote).foregroundColor(.bbGreen)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    Text("登录即代表同意《用户协议》和《隐私政策》".tr)
                        .font(.caption2).foregroundColor(.bbInk2)

                    Button("暂不登录，先逛逛".tr) { dismiss() }
                        .font(.footnote).foregroundColor(.bbInk2)
                        .padding(.top, 2)
                    Spacer()
                }
                .padding(.horizontal, 28)
                .bbPageWidth()
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.bbInk2.opacity(0.55))
                    .padding(14)
            }
            .accessibilityLabel("关闭")
        }
        .onReceive(tick) { _ in if cooldown > 0 { cooldown -= 1 } }
        .onChange(of: store.user?.id) { _ in
            if store.user != nil { dismiss() }   // logged in — close the sheet
        }
        .sheet(isPresented: $showForgot) { ForgotPasswordView().environmentObject(store) }
    }

    // identifier + numpad code field with an inline 发送验证码 button
    private func codeRow(purpose: String) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield").foregroundColor(.bbInk2).frame(width: 20)
                TextField("验证码".tr, text: $code).keyboardType(.numberPad)
            }
            .padding(14)
            .background(Color.bbSurface)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bbLine))
            .cornerRadius(10)

            Button { sendCode(purpose: purpose) } label: {
                Text(cooldown > 0 ? "\(cooldown)s" : (sending ? "发送中".tr : "发送验证码".tr))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(cooldown > 0 ? .bbInk2 : .white)
                    .padding(.horizontal, 12).frame(height: 50)
                    .background(cooldown > 0 || sending ? Color.bbLine : Color.bbGreen)
                    .cornerRadius(10)
            }
            .disabled(cooldown > 0 || sending)
        }
    }

    @ViewBuilder
    private func field(icon: String, placeholder: String, text: Binding<String>, secure: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(.bbInk2).frame(width: 20)
            if secure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding(14)
        .background(Color.bbSurface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bbLine))
        .cornerRadius(10)
    }

    private func sendCode(purpose: String) {
        let id = identifier.trimmingCharacters(in: .whitespaces)
        guard bbIdentifierType(id) != nil else { err = "请输入有效的手机号或邮箱".tr; return }
        // Check the password BEFORE spending a code (codes are rate-limited 1/min, 10/day).
        guard bbPasswordOK(password) else { err = "密码至少 8 位，且需同时包含大写和小写字母".tr; return }
        guard !sending, cooldown == 0 else { return }
        sending = true; err = ""; hint = ""
        Task {
            if let res = await store.sendCode(identifier: id, purpose: purpose) {
                if let dev = res.devCode, !dev.isEmpty {
                    code = dev
                    hint = "测试模式：验证码已自动填入".tr + "（\(dev)）"
                } else {
                    hint = res.channel == "phone" ? "验证码短信已发送，请查收".tr : "验证码邮件已发送，请查收".tr
                }
                cooldown = 60
            } else {
                err = store.errorMessage ?? "验证码发送失败".tr
            }
            sending = false
        }
    }

    // Asked once, at sign-up, because that is the only moment the app collects
    // personal data (guests never send any). Under 14 → a guardian must agree.
    private var ageRow: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.questionmark").foregroundColor(.bbInk2).frame(width: 20)
                Text("年龄".tr).foregroundColor(.bbInk)
                Spacer()
                Picker("", selection: $under14) {
                    Text("14 岁及以上".tr).tag(false)
                    Text("未满 14 岁".tr).tag(true)
                }
                .pickerStyle(.segmented).frame(maxWidth: 220)
                .accessibilityIdentifier("auth.age")
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
            if under14 {
                Toggle(isOn: $guardianOK) {
                    Text("我的监护人已同意我注册并使用".tr).font(.footnote).foregroundColor(.bbInk)
                }
                .tint(.bbGreen)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Color.bbSurface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
                .accessibilityIdentifier("auth.guardian")
            }
        }
    }

    private func submit() {
        guard !busy else { return }
        let id = identifier.trimmingCharacters(in: .whitespaces)
        if mode == 1 {
            guard bbIdentifierType(id) != nil else { err = "请输入有效的手机号或邮箱".tr; return }
            guard bbPasswordOK(password) else { err = "密码至少 8 位，且需同时包含大写和小写字母".tr; return }
            guard nickname.trimmingCharacters(in: .whitespaces).count > 0 else { err = "请填写昵称".tr; return }
            guard !code.isEmpty else { err = "请先获取并填写验证码".tr; return }
            guard !under14 || guardianOK else { err = "未满 14 岁需要监护人同意后才能注册".tr; return }
        }
        busy = true; err = ""
        Task {
            let ok = (mode == 0)
                ? await store.login(identifier: id, password: password)
                : await store.register(identifier: id, password: password, nickname: nickname, code: code,
                                       ageGroup: under14 ? "u14-guardian" : "14+")
            if !ok { err = store.errorMessage ?? "出错了，请重试".tr }
            busy = false
        }
    }
}
