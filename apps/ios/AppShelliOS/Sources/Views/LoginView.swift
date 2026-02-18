import SwiftUI

struct LoginView: View {
    @ObservedObject var sessionStore: SessionStore
    @ObservedObject var uiStore: UIStore

    @State private var passkeyLogsVisible = false
    @State private var passkeySignUpVisible = false
    @State private var passkeySignUpName = ""

    var body: some View {
        NavigationStack {
            AdaptiveReader { widthClass in
                FullscreenScaffold(backgroundStyle: .globalImage) {
                    ScrollView {
                        VStack(spacing: 0) {
                            brandHeader
                                .padding(.top, widthClass == .compact ? 32 : 48)
                                .padding(.bottom, 32)

                            loginButtons
                                .padding(.horizontal, widthClass.horizontalPadding)

                            debugInfoSection
                                .padding(.top, 24)
                                .padding(.horizontal, widthClass.horizontalPadding)
                                .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle("登录")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $passkeyLogsVisible) {
                passkeyLogsSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $passkeySignUpVisible) {
                passkeySignUpSheet
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                sessionStore.refreshPasskeyAccounts()
            }
        }
    }

    private var brandHeader: some View {
        VStack(spacing: 12) {
            Image("login_cp_brand")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            Text("CPcash Wallet")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(ThemeTokens.title)
        }
    }

    private var loginButtons: some View {
        VStack(spacing: 14) {
            Button {
                passkeyLogsVisible = true
            } label: {
                HStack(spacing: 10) {
                    Image("login_passkey")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    Text("使用通行密钥登录")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(ThemeTokens.cpPrimary, in: Capsule())
            }
            .disabled(uiStore.loginBusy)
            .opacity(uiStore.loginBusy ? 0.65 : 1)

            HStack(spacing: 8) {
                Text("没有 Passkey 账号？")
                    .foregroundStyle(ThemeTokens.secondary)
                Button("注册") {
                    passkeySignUpVisible = true
                }
                .foregroundStyle(ThemeTokens.cpPrimary)
            }
            .font(.system(size: 14))
            .padding(.top, 6)
        }
    }

    private var debugInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            infoRow("当前地址", sessionStore.activeAddress)
            infoRow("ENV", "\(sessionStore.environment.tag.rawValue) / \(sessionStore.environment.baseURL.host ?? "-")")
            if uiStore.loginBusy {
                Text("登录处理中...")
                    .font(.system(size: 12))
                    .foregroundStyle(ThemeTokens.tertiary)
            }
            #if DEBUG
                Button("切换环境（Debug）") {
                    sessionStore.cycleEnvironmentForDebug()
                }
                .font(.system(size: 13))
                .foregroundStyle(ThemeTokens.cpPrimary)
            #endif
        }
        .padding(14)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var passkeyLogsSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("最近登录")
                    .font(.system(size: 16, weight: .medium))
                    .padding(.top, 6)

                if sessionStore.passkeyAccounts.isEmpty {
                    Text("暂无 Passkey 账户")
                        .font(.system(size: 13))
                        .foregroundStyle(ThemeTokens.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(sessionStore.passkeyAccounts) { account in
                        passkeyAccountButton(
                            title: account.displayName,
                            subtitle: shortAddress(account.address)
                        ) {
                            passkeyLogsVisible = false
                            Task { await sessionStore.loginWithPasskey(rawId: account.rawId) }
                        }
                    }
                }

                passkeyAccountButton(title: "其他账户", subtitle: "使用系统认证选择账号") {
                    passkeyLogsVisible = false
                    Task { await sessionStore.loginWithPasskey(rawId: nil) }
                }

                HStack(spacing: 6) {
                    Text("没有账户？")
                        .foregroundStyle(ThemeTokens.secondary)
                    Button("注册") {
                        passkeyLogsVisible = false
                        passkeySignUpVisible = true
                    }
                    .foregroundStyle(ThemeTokens.cpPrimary)
                }
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

                Spacer()
            }
            .padding(.horizontal, 16)
            .background(ThemeTokens.pageBackground)
            .navigationTitle("Passkey")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var passkeySignUpSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("请输入 1-12 位用户名")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ThemeTokens.title)

                TextField("请输入用户名", text: $passkeySignUpName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
                    .frame(height: 46)
                    .background(ThemeTokens.inputBackground, in: RoundedRectangle(cornerRadius: 12))
                    .onChange(of: passkeySignUpName) { _, newValue in
                        if newValue.count > 12 {
                            passkeySignUpName = String(newValue.prefix(12))
                        }
                    }

                Button {
                    let value = passkeySignUpName.trimmingCharacters(in: .whitespacesAndNewlines)
                    Task {
                        await sessionStore.registerPasskey(displayName: value)
                        if sessionStore.isAuthenticated {
                            passkeySignUpVisible = false
                        }
                    }
                } label: {
                    Text("下一步")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            (passkeySignUpName.isEmpty || uiStore.loginBusy ? Color.gray.opacity(0.35) : ThemeTokens.cpPrimary),
                            in: Capsule()
                        )
                }
                .disabled(passkeySignUpName.isEmpty || uiStore.loginBusy)
                .padding(.top, 8)

                Spacer()

                HStack {
                    Spacer()
                    Text("什么是 Passkey")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeTokens.cpPrimary)
                    Spacer()
                }
            }
            .padding(16)
            .background(ThemeTokens.groupBackground)
            .navigationTitle("注册")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") {
                        passkeySignUpVisible = false
                    }
                }
            }
        }
    }

    private func passkeyAccountButton(title: String, subtitle: String, onTap: @escaping () -> Void) -> some View {
        Button {
            onTap()
        } label: {
            HStack {
                Image("passkey_local")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ThemeTokens.title)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(ThemeTokens.tertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(ThemeTokens.tertiary)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(ThemeTokens.divider, lineWidth: 1)
            )
        }
        .disabled(uiStore.loginBusy)
        .opacity(uiStore.loginBusy ? 0.65 : 1)
    }

    private func infoRow(_ name: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.caption)
                .foregroundStyle(ThemeTokens.tertiary)
            Text(value)
                .font(.body.monospaced())
                .textSelection(.enabled)
                .lineLimit(2)
                .truncationMode(.middle)
                .foregroundStyle(ThemeTokens.title)
        }
    }

    private func shortAddress(_ value: String) -> String {
        AddressFormatter.shortened(value, leading: 6, trailing: 4, threshold: 12)
    }
}
