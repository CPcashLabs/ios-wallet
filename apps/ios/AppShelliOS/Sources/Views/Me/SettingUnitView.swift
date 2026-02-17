import SwiftUI

struct SettingUnitView: View {
    @ObservedObject var state: AppState

    @State private var currentCurrency = ""

    var body: some View {
        AdaptiveReader { widthClass in
            Group {
                if state.isLoading("me.settings.rates") {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        SectionCard {
                            ForEach(Array(state.exchangeRates.enumerated()), id: \.offset) { index, item in
                                Button {
                                    currentCurrency = item.currency ?? ""
                                } label: {
                                    HStack {
                                        Text(item.currency ?? "-")
                                            .font(.system(size: widthClass.bodySize + 1))
                                            .foregroundStyle(ThemeTokens.title)
                                        Spacer()
                                        if currentCurrency == item.currency {
                                            Image("settings_radio_checked")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                    .frame(minHeight: widthClass.metrics.listRowMinHeight)
                                    .padding(.horizontal, 14)
                                }
                                .buttonStyle(.plain)

                                if index < state.exchangeRates.count - 1 {
                                    Divider().padding(.leading, 14)
                                }
                            }
                        }
                        .padding(.horizontal, widthClass.horizontalPadding)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(Color.clear)
            .navigationTitle("货币单位")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        if !currentCurrency.isEmpty {
                            state.saveCurrencyUnit(currency: currentCurrency)
                        }
                    }
                }
            }
            .task {
                await state.loadExchangeRates()
                if currentCurrency.isEmpty {
                    currentCurrency = state.selectedCurrency
                }
            }
        }
    }
}
