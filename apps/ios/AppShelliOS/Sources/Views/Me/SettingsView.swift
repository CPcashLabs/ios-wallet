import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var meStore: MeStore
    @ObservedObject var sessionStore: SessionStore
    @ObservedObject var uiStore: UIStore
    let navigate: (MeRoute) -> Void

    @AppStorage("settings.darkMode") private var darkMode = false
    @State private var transferNotify = false
    @State private var rewardNotify = false
    @State private var receiptNotify = false
    @State private var backupNotify = false
    @State private var networkSheetVisible = false
    @State private var didSyncNotifyToggles = false
    @State private var transferNotifyTask: Task<Void, Never>?
    @State private var rewardNotifyTask: Task<Void, Never>?
    @State private var receiptNotifyTask: Task<Void, Never>?
    @State private var backupNotifyTask: Task<Void, Never>?

    var body: some View {
        AdaptiveReader { widthClass in
            FullscreenScaffold(backgroundStyle: .globalImage) {
                ScrollView {
                    VStack(spacing: 14) {
                        SectionCard {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(ThemeTokens.cpPrimary)
                                Text("Dark Mode")
                                    .font(.system(size: widthClass.bodySize))
                                    .foregroundStyle(ThemeTokens.title)
                                Spacer()
                                Toggle("", isOn: $darkMode)
                                    .labelsHidden()
                            }
                            .frame(minHeight: widthClass.metrics.listRowMinHeight)
                            .padding(.horizontal, 14)

                            Divider().padding(.leading, 48)

                            navRow(icon: "globe", title: "Language", note: "Simplified Chinese") { uiStore.showInfoToast("Language switch in development") }
                            Divider().padding(.leading, 48)
                            navRow(icon: "slider.horizontal.3", title: "Node") { uiStore.showInfoToast("Node settings in development") }
                            Divider().padding(.leading, 48)
                            navRow(icon: "settings_network", title: "Network", note: sessionStore.selectedChainName) {
                                networkSheetVisible = true
                            }
                            Divider().padding(.leading, 48)
                            toggleRow(icon: "settings_email_notify", title: "Transfernotification", isOn: $transferNotify)
                            Divider().padding(.leading, 48)
                            toggleRow(icon: "settings_email_notify", title: "Reward notification", isOn: $rewardNotify)
                            Divider().padding(.leading, 48)
                            toggleRow(icon: "settings_email_notify", title: "Receivenotification", isOn: $receiptNotify)
                            Divider().padding(.leading, 48)
                            toggleRow(icon: "me_wallet_backup", title: "Backup notification", isOn: $backupNotify)
                            Divider().padding(.leading, 48)
                            navRow(icon: "dollarsign.circle", title: "Currency Unit", note: meStore.selectedCurrency) { navigate(.settingUnit) }
                                .accessibilityIdentifier(A11yID.Me.settingsCurrencyRow)
                        }
                    }
                    .padding(.horizontal, widthClass.horizontalPadding)
                    .padding(.top, 12)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    sessionStore.signOutToLogin()
                } label: {
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundStyle(ThemeTokens.cpPrimary)
                        .overlay(
                            Capsule().stroke(ThemeTokens.cpPrimary, lineWidth: 1)
                        )
                        .padding(.horizontal, widthClass.horizontalPadding)
                        .padding(.top, 10)
                        .padding(.bottom, 6)
                        .background(ThemeTokens.groupBackground)
                }
                .buttonStyle(.pressFeedback)
            }
            .sheet(isPresented: $networkSheetVisible) {
                networkSheet
                    .presentationDetents([.medium])
            }
            .task {
                didSyncNotifyToggles = false
                await meStore.loadExchangeRates()
                await sessionStore.refreshNetworkOptions()
                transferNotify = meStore.transferEmailNotify
                rewardNotify = meStore.rewardEmailNotify
                receiptNotify = meStore.receiptEmailNotify
                backupNotify = meStore.backupWalletNotify
                didSyncNotifyToggles = true
            }
            .onChange(of: transferNotify) { _, value in
                guard didSyncNotifyToggles else { return }
                transferNotifyTask?.cancel()
                transferNotifyTask = Task {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    guard !Task.isCancelled else { return }
                    await meStore.setTransferEmailNotify(value)
                }
            }
            .onChange(of: rewardNotify) { _, value in
                guard didSyncNotifyToggles else { return }
                rewardNotifyTask?.cancel()
                rewardNotifyTask = Task {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    guard !Task.isCancelled else { return }
                    await meStore.setRewardEmailNotify(value)
                }
            }
            .onChange(of: receiptNotify) { _, value in
                guard didSyncNotifyToggles else { return }
                receiptNotifyTask?.cancel()
                receiptNotifyTask = Task {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    guard !Task.isCancelled else { return }
                    await meStore.setReceiptEmailNotify(value)
                }
            }
            .onChange(of: backupNotify) { _, value in
                guard didSyncNotifyToggles else { return }
                backupNotifyTask?.cancel()
                backupNotifyTask = Task {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    guard !Task.isCancelled else { return }
                    await meStore.setBackupWalletNotify(value)
                }
            }
            .onDisappear {
                transferNotifyTask?.cancel()
                rewardNotifyTask?.cancel()
                receiptNotifyTask?.cancel()
                backupNotifyTask?.cancel()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var networkSheet: some View {
        NavigationStack {
            List {
                ForEach(sessionStore.networkOptions) { option in
                    Button {
                        sessionStore.selectNetwork(chainId: option.chainId)
                        networkSheetVisible = false
                    } label: {
                        HStack(spacing: 12) {
                            Image("settings_network_btt")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.chainName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(ThemeTokens.title)
                                Text(option.chainFullName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(ThemeTokens.secondary)
                            }

                            Spacer()

                            if option.chainId == sessionStore.selectedChainId {
                                Image("settings_radio_checked")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressFeedback)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ThemeTokens.groupBackground)
            .listStyle(.plain)
            .navigationTitle("Select Network")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func navRow(icon: String, title: String, note: String? = nil, onTap: @escaping () -> Void) -> some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                if UIImage(named: icon) != nil {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(ThemeTokens.cpPrimary)
                        .frame(width: 22, height: 22)
                }

                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(ThemeTokens.title)
                Spacer()
                if let note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 13))
                        .foregroundStyle(ThemeTokens.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ThemeTokens.tertiary)
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressFeedback)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            if UIImage(named: icon) != nil {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            } else {
                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .foregroundStyle(ThemeTokens.cpPrimary)
                    .frame(width: 22, height: 22)
            }

            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(ThemeTokens.title)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .frame(minHeight: 64)
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
    }
}

#Preview("SettingsView") {
    NavigationStack {
        let appState = AppState()
        SettingsView(
            meStore: MeStore(appState: appState),
            sessionStore: SessionStore(appState: appState),
            uiStore: UIStore(appState: appState)
        ) { _ in }
    }
}
