import SwiftUI
import UIKit

struct MeView: View {
    @ObservedObject var sessionStore: SessionStore
    @ObservedObject var meStore: MeStore
    let uiStore: UIStore
    let navigate: (MeRoute) -> Void

    var body: some View {
        AdaptiveReader { widthClass in
            TopSafeAreaHeaderScaffold(
                backgroundStyle: .globalImage,
                headerBackground: ThemeTokens.groupBackground.opacity(0.94)
            ) {
                topHeader
            } content: {
                ScrollView {
                    VStack(spacing: 14) {
                        headerCard

                        SectionCard {
                            menuButton(icon: "me_bill", title: "账单") { navigate(.billList) }
                            divider
                            menuButton(icon: "me_addressbook", title: "地址簿") { navigate(.addressBookList) }
                            divider
                            menuButton(icon: "me_total_assets", title: "全部资产") { navigate(.totalAssets) }
                        }

                        SectionCard {
                            menuButton(icon: "me_invite", title: "邀请好友") { navigate(.invite) }
                            divider
                            menuButton(icon: "me_invite_code", title: "邀请码") { navigate(.inviteCode) }
                        }

                        SectionCard {
                            menuButton(icon: "me_user_guide", title: "用户指南") { navigate(.userGuide) }
                            divider
                            menuButton(icon: "me_about", title: "关于 CPcash") { navigate(.about) }
                        }
                    }
                    .padding(.horizontal, widthClass.horizontalPadding)
                    .padding(.top, 12)
                    .padding(.bottom, widthClass == .max ? 28 : 20)
                }
                .background(Color.clear)
                .task {
                    await meStore.loadMeRootData()
                }
                .refreshable {
                    await meStore.loadMeRootData()
                }
            }
        }
    }

    private var topHeader: some View {
        ZStack {
            Text("我的")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(ThemeTokens.title)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .overlay(alignment: .trailing) {
            Button {
                navigate(.settings)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(ThemeTokens.title)
                    .frame(width: 44, height: 44)
                    .background(ThemeTokens.cardBackground, in: Circle())
            }
            .buttonStyle(.pressFeedback)
        }
    }

    private var headerCard: some View {
        Button {
            navigate(.personal)
        } label: {
            HStack(spacing: 12) {
                avatar
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(displayName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(ThemeTokens.title)
                        levelBadge
                    }
                    HStack(spacing: 8) {
                        Text(shortAddress)
                            .font(.system(size: 13))
                            .foregroundStyle(ThemeTokens.secondary)
                        Button {
                            UIPasteboard.general.string = sessionStore.activeAddress
                            uiStore.showInfoToast("地址已复制")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ThemeTokens.cpPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ThemeTokens.tertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.pressFeedback)
    }

    private var avatar: some View {
        RemoteImageView(
            rawURL: meStore.profile?.avatar,
            baseURL: sessionStore.environment.baseURL,
            contentMode: .fill
        ) {
            avatarFallback
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
    }

    private var avatarFallback: some View {
        Circle()
            .fill(LinearGradient(colors: [ThemeTokens.cpPrimary.opacity(0.85), ThemeTokens.cpPrimary], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Text(String(displayName.prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
    }

    private var levelBadge: some View {
        Text("Lv1")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(ThemeTokens.cpPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .overlay(
                Capsule().stroke(ThemeTokens.cpPrimary, lineWidth: 1)
            )
    }

    private var displayName: String {
        let raw = meStore.profile?.nickname?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let raw, !raw.isEmpty {
            return raw
        }
        return "账户"
    }

    private var shortAddress: String {
        let value = sessionStore.activeAddress
        guard value.count > 12 else { return value }
        return "\(value.prefix(6))...\(value.suffix(4))"
    }

    private var divider: some View {
        Divider().padding(.leading, 48)
    }

    private func menuButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            CellRow(icon: icon, title: title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressFeedback)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

#Preview("MeView") {
    let appState = AppState()
    MeView(
        sessionStore: SessionStore(appState: appState),
        meStore: MeStore(appState: appState),
        uiStore: UIStore(appState: appState)
    ) { _ in }
}
