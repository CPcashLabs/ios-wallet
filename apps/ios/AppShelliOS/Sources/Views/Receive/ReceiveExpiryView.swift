import SwiftUI

struct ReceiveExpiryView: View {
    @ObservedObject var receiveStore: ReceiveStore

    @State private var selectedDuration: Int?
    @State private var initialDuration: Int?
    @State private var saving = false

    var body: some View {
        AdaptiveReader { widthClass in
            SafeAreaScreen(backgroundStyle: .globalImage) {
                ScrollView {
                    VStack(spacing: 10) {
                        VStack(spacing: 0) {
                            ForEach(receiveStore.receiveExpiryConfig.durations, id: \.self) { duration in
                                Button {
                                    selectedDuration = duration
                                } label: {
                                    HStack {
                                        Text(durationTitle(duration))
                                            .font(.system(size: widthClass.bodySize + 2))
                                            .foregroundStyle(ThemeTokens.title)
                                        Spacer()
                                        if selectedDuration == duration {
                                            Image("settings_radio_checked")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, minHeight: widthClass.metrics.listRowMinHeight, alignment: .leading)
                                    .padding(.horizontal, 14)
                                }
                                .buttonStyle(.plain)

                                if duration != receiveStore.receiveExpiryConfig.durations.last {
                                    Divider()
                                        .padding(.leading, 14)
                                }
                            }
                        }
                        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous))

                        Text("设置后会自动应用到新生成的收款地址")
                            .font(.system(size: widthClass.footnoteSize))
                            .foregroundStyle(ThemeTokens.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, widthClass.horizontalPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 110)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomButton(widthClass: widthClass)
            }
            .navigationTitle("Expiry Date")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await receiveStore.loadReceiveExpiryConfig()
                syncFromState()
            }
            .onChange(of: receiveStore.receiveExpiryConfig) { _, _ in
                syncFromState()
            }
        }
    }

    private func bottomButton(widthClass: DeviceWidthClass) -> some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                guard let selectedDuration else { return }
                guard !saving else { return }
                saving = true
                Task {
                    await receiveStore.updateReceiveExpiry(duration: selectedDuration)
                    saving = false
                    initialDuration = selectedDuration
                }
            } label: {
                HStack {
                    Spacer()
                    if saving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Confirm")
                            .font(.system(size: widthClass.bodySize + 2, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .frame(height: widthClass.metrics.buttonHeight)
                .background(canSubmit ? ThemeTokens.cpPrimary : ThemeTokens.cpPrimary.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: widthClass.metrics.buttonHeight / 2, style: .continuous))
                .padding(.horizontal, widthClass.horizontalPadding)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .background(.ultraThinMaterial)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit || saving)
        }
    }

    private var canSubmit: Bool {
        guard let selectedDuration else { return false }
        return selectedDuration != initialDuration
    }

    private func syncFromState() {
        let selected = receiveStore.receiveExpiryConfig.selectedDuration ?? receiveStore.receiveExpiryConfig.durations.first
        if initialDuration == nil {
            initialDuration = selected
        } else if selected == initialDuration {
            initialDuration = selected
        }
        if selectedDuration == nil {
            selectedDuration = selected
        }
    }

    private func durationTitle(_ value: Int) -> String {
        if value >= 3_600 {
            if value >= 2_592_000 {
                return "\(value / 2_592_000) 月"
            }
            if value >= 604_800 {
                return "\(value / 604_800) 周"
            }
            if value >= 86_400 {
                return "\(value / 86_400) 天"
            }
            return "\(value / 3_600) 小时"
        }
        if value >= 24, value % 24 == 0 {
            return "\(value / 24) 天"
        }
        return "\(value) 小时"
    }
}
