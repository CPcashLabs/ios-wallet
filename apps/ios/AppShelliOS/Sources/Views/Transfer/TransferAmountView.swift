import SwiftUI

struct TransferAmountView: View {
    private enum InputField: Hashable {
        case amount
        case note
    }

    @ObservedObject var transferStore: TransferStore
    let onNext: () -> Void

    @State private var amountText = ""
    @State private var noteText = ""
    @State private var showPairPicker = false
    @State private var showCoinPicker = false
    @State private var nextTriggered = false
    @FocusState private var focusedField: InputField?

    var body: some View {
        AdaptiveReader { widthClass in
            SafeAreaScreen(backgroundStyle: .globalImage) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        addressCard(widthClass: widthClass)
                        amountCard(widthClass: widthClass)
                        noteCard(widthClass: widthClass)
                    }
                    .padding(.horizontal, widthClass.horizontalPadding)
                    .padding(.top, 14)
                    .padding(.bottom, 16)
                }
            } bottomInset: {
                bottomButton(widthClass: widthClass)
            }
            .navigationTitle("Send")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .task {
                if amountText.isEmpty {
                    amountText = transferStore.transferDraft.amountText
                }
                if noteText.isEmpty {
                    noteText = transferStore.transferDraft.note
                }
            }
            .confirmationDialog("Select Coin", isPresented: $showCoinPicker, titleVisibility: .visible) {
                ForEach(transferStore.transferDomainState.availableNormalCoins, id: \.coinCode) { coin in
                    let title = coin.coinSymbol ?? coin.coinName ?? coin.coinCode ?? "-"
                    Button(title) {
                        if let coinCode = coin.coinCode {
                            Task { await transferStore.selectTransferNormalCoin(coinCode: coinCode) }
                        }
                    }
                }
            }
            .confirmationDialog("Select Trading Pair", isPresented: $showPairPicker, titleVisibility: .visible) {
                ForEach(pairOptions, id: \.id) { option in
                    Button(option.title) {
                        transferStore.selectTransferPair(sendCoinCode: option.sendCoinCode, recvCoinCode: option.recvCoinCode)
                    }
                }
            }
        }
    }

    private func addressCard(widthClass: DeviceWidthClass) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(transferStore.transferDomainState.selectedPayChain)
                .font(.system(size: widthClass.bodySize + 1, weight: .semibold))
                .foregroundStyle(ThemeTokens.title)
            Text(shortAddress(transferStore.transferDraft.recipientAddress))
                .font(.system(size: widthClass.bodySize))
                .foregroundStyle(ThemeTokens.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous))
    }

    private func amountCard(widthClass: DeviceWidthClass) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Transfer Amount")
                .font(.system(size: widthClass.bodySize + 1, weight: .medium))
                .foregroundStyle(ThemeTokens.title)

            HStack(spacing: 8) {
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
                    .font(.system(size: widthClass.titleSize + 8, weight: .semibold))
                    .foregroundStyle(ThemeTokens.title)
                    .accessibilityIdentifier(A11yID.Transfer.amountInput)
                Text(transferStore.transferDomainState.selectedCoinSymbol)
                    .font(.system(size: widthClass.bodySize + 1, weight: .medium))
                    .foregroundStyle(ThemeTokens.secondary)
            }

            Divider()

            if transferStore.transferDomainState.selectedIsNormalChannel {
                Button {
                    showCoinPicker = true
                } label: {
                    pickerRow(title: "Coin", value: transferStore.transferDomainState.selectedCoinSymbol)
                }
                .buttonStyle(.plain)
            } else if !pairOptions.isEmpty {
                Button {
                    showPairPicker = true
                } label: {
                    pickerRow(title: "Pair", value: transferStore.transferDomainState.selectedPairLabel)
                }
                .buttonStyle(.plain)
            }

            Text(minimumHint)
                .font(.system(size: widthClass.footnoteSize))
                .foregroundStyle(ThemeTokens.secondary)
        }
        .padding(12)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous))
    }

    private func noteCard(widthClass: DeviceWidthClass) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transfer Note")
                .font(.system(size: widthClass.bodySize + 1, weight: .medium))
                .foregroundStyle(ThemeTokens.title)
            TextField("add note", text: $noteText, axis: .vertical)
                .lineLimit(3)
                .focused($focusedField, equals: .note)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: widthClass.bodySize))
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(12)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous))
    }

    private func bottomButton(widthClass: DeviceWidthClass) -> some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                focusedField = nil
                guard !nextTriggered else { return }
                nextTriggered = true
                Task {
                    let ok = await transferStore.prepareTransferPayment(amountText: amountText, note: noteText)
                    if ok {
                        await MainActor.run {
                            onNext()
                        }
                    }
                    await MainActor.run {
                        nextTriggered = false
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    if transferStore.isLoading(.transferPrepare) {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Next")
                            .font(.system(size: widthClass.bodySize + 2, weight: .semibold))
                            .foregroundStyle(Color.white)
                    }
                    Spacer()
                }
                .frame(height: widthClass.metrics.buttonHeight)
                .background(canSubmit ? ThemeTokens.cpPrimary : ThemeTokens.cpPrimary.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: widthClass.metrics.buttonHeight / 2, style: .continuous))
                .padding(.horizontal, widthClass.horizontalPadding)
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
            .buttonStyle(.pressFeedback)
            .disabled(!canSubmit || transferStore.isLoading(.transferPrepare) || nextTriggered)
            .accessibilityIdentifier(A11yID.Transfer.amountNextButton)
        }
        .frame(maxWidth: .infinity)
        .background(ThemeTokens.groupBackground.opacity(0.95))
    }

    private var pairOptions: [(id: String, title: String, sendCoinCode: String, recvCoinCode: String)] {
        var seen = Set<String>()
        var result: [(id: String, title: String, sendCoinCode: String, recvCoinCode: String)] = []
        for pair in transferStore.transferDomainState.availablePairs {
            let sendCode = pair.sendCoinCode ?? ""
            let recvCode = pair.recvCoinCode ?? ""
            guard !sendCode.isEmpty, !recvCode.isEmpty else { continue }
            let key = "\(sendCode)->\(recvCode)"
            if seen.contains(key) { continue }
            seen.insert(key)
            let sendName = pair.sendCoinSymbol ?? pair.sendCoinName ?? sendCode
            let recvName = pair.recvCoinSymbol ?? pair.recvCoinName ?? recvCode
            result.append((id: key, title: "\(sendName) / \(recvName)", sendCoinCode: sendCode, recvCoinCode: recvCode))
        }
        return result
    }

    private var minimumHint: String {
        if let order = transferStore.transferDraft.orderDetail,
           let min = order.sendAmount?.stringValue, !min.isEmpty {
            return "Current amount: \(min) \(transferStore.transferDomainState.selectedCoinSymbol)"
        }
        return "Please confirm the amount matches the network"
    }

    private var canSubmit: Bool {
        let text = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let value = Decimal(string: text), value > 0 else {
            return false
        }
        return !transferStore.transferDraft.recipientAddress.isEmpty
    }

    private func pickerRow(title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(ThemeTokens.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ThemeTokens.title)
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ThemeTokens.tertiary)
        }
    }

    private func shortAddress(_ value: String) -> String {
        AddressFormatter.shortened(value, leading: 8, trailing: 6, threshold: 14)
    }
}
