import BackendAPI
import SwiftUI

private enum TransferAddressTab: String, CaseIterable {
    case recent = "最近"
    case addressBook = "地址簿"
}

struct TransferAddressView: View {
    @ObservedObject var transferStore: TransferStore
    let onNext: () -> Void

    @State private var addressInput = ""
    @State private var selectedTab: TransferAddressTab = .recent
    @State private var scannerPresented = false
    @State private var nextTriggered = false
    @State private var nextResetTask: Task<Void, Never>?

    private var validationMessage: String? {
        transferStore.transferAddressValidationMessage(addressInput)
    }

    private var nextDisabled: Bool {
        let trimmed = addressInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        return !transferStore.isValidTransferAddress(trimmed) || nextTriggered
    }

    private var keyword: String {
        addressInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var addressBookCandidates: [AddressBookItem] {
        transferStore.transferAddressBookCandidates()
    }

    private var addressBookAliasByAddress: [String: String] {
        addressBookCandidates.reduce(into: [:]) { partial, item in
            let address = (item.walletAddress ?? "").lowercased()
            let alias = (item.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !address.isEmpty, !alias.isEmpty else { return }
            if partial[address] == nil {
                partial[address] = alias
            }
        }
    }

    private var filteredAddressBooks: [AddressBookItem] {
        guard !keyword.isEmpty else { return addressBookCandidates }
        return addressBookCandidates.filter { item in
            let name = (item.name ?? "").lowercased()
            let address = (item.walletAddress ?? "").lowercased()
            return name.contains(keyword) || address.contains(keyword)
        }
    }

    private var filteredRecentContacts: [TransferReceiveContact] {
        let deduped = Dictionary(grouping: transferStore.transferRecentContacts) { item in
            (item.address ?? "").lowercased()
        }.compactMap(\.value.first)

        let valid = deduped.filter { item in
            guard let address = item.address?.trimmingCharacters(in: .whitespacesAndNewlines), !address.isEmpty else {
                return false
            }
            return transferStore.isValidTransferAddress(address)
        }

        guard !keyword.isEmpty else { return valid }
        return valid.filter { item in
            let address = (item.address ?? "").lowercased()
            let alias = (addressBookAliasByAddress[address] ?? "").lowercased()
            return address.contains(keyword) || alias.contains(keyword)
        }
    }

    var body: some View {
        AdaptiveReader { widthClass in
            FullscreenScaffold(backgroundStyle: .globalImage) {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            addressInputSection(widthClass: widthClass)
                            validationSection(widthClass: widthClass)
                            addAddressBookSection(widthClass: widthClass)
                            tabSection(widthClass: widthClass)
                            contentSection(widthClass: widthClass)
                        }
                        .padding(.horizontal, widthClass.horizontalPadding)
                        .padding(.top, 14)
                        .padding(.bottom, 16)
                    }

                    bottomButton(widthClass: widthClass)
                }
            }
            .navigationTitle("Send")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .sheet(isPresented: $scannerPresented) {
                QRCodeScannerSheet { scannedValue in
                    let normalized = normalizeScannedAddress(scannedValue)
                    guard !normalized.isEmpty else {
                        transferStore.showInfoToast("未识别到有效地址")
                        return
                    }
                    addressInput = normalized
                    transferStore.updateTransferRecipientAddress(normalized)
                }
            }
            .task {
                if addressInput.isEmpty {
                    addressInput = transferStore.transferDraft.recipientAddress
                }
                if transferStore.addressBooks.isEmpty {
                    await transferStore.loadAddressBooks()
                }
                await transferStore.loadTransferAddressCandidates()
                if transferStore.transferRecentContacts.isEmpty {
                    selectedTab = .addressBook
                }
            }
            .onChange(of: addressInput) { _, value in
                let sanitized = AddressInputParser.sanitize(value)
                if sanitized != value {
                    addressInput = sanitized
                }
                transferStore.updateTransferRecipientAddress(sanitized)
            }
            .onDisappear {
                nextResetTask?.cancel()
            }
        }
    }

    private func addressInputSection(widthClass: DeviceWidthClass) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Receiving address")
                .font(.system(size: widthClass.bodySize + 2, weight: .medium))
                .foregroundStyle(ThemeTokens.title)

            HStack(alignment: .top, spacing: 8) {
                TextField("Enter wallet address", text: $addressInput)
                    .lineLimit(1)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.asciiCapable)
                    .submitLabel(.done)
                    .autocorrectionDisabled()
                    .font(.system(size: widthClass.bodySize + 2))
                    .accessibilityIdentifier(A11yID.Transfer.addressInput)

                Button {
                    scannerPresented = true
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(ThemeTokens.cpPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressFeedback)
            }
            .padding(12)
            .background(ThemeTokens.inputBackground, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous))
        }
    }

    @ViewBuilder
    private func validationSection(widthClass: DeviceWidthClass) -> some View {
        if let validationMessage {
            Text(validationMessage)
                .font(.system(size: widthClass.footnoteSize))
                .foregroundStyle(ThemeTokens.danger)
        } else {
            Text("请仔细核对地址与网络，错误网络可能导致资产丢失")
                .font(.system(size: widthClass.footnoteSize))
                .foregroundStyle(ThemeTokens.secondary)
        }
    }

    @ViewBuilder
    private func addAddressBookSection(widthClass: DeviceWidthClass) -> some View {
        if shouldShowAddAddressBook {
            Button {
                transferStore.showInfoToast("请前往“我的-地址簿”添加")
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                    Text("添加到地址簿")
                        .font(.system(size: widthClass.bodySize, weight: .medium))
                }
                .foregroundStyle(ThemeTokens.cpPrimary)
                .frame(maxWidth: .infinity, minHeight: 32)
            }
            .buttonStyle(.pressFeedback)
        }
    }

    private func tabSection(widthClass: DeviceWidthClass) -> some View {
        HStack(spacing: 8) {
            ForEach(TransferAddressTab.allCases, id: \.rawValue) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: widthClass.bodySize, weight: .medium))
                        .foregroundStyle(selectedTab == tab ? Color.white : ThemeTokens.title)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(
                            Capsule().fill(selectedTab == tab ? ThemeTokens.cpPrimary : ThemeTokens.cardBackground)
                        )
                }
                .buttonStyle(.pressFeedback)
            }
        }
    }

    @ViewBuilder
    private func contentSection(widthClass: DeviceWidthClass) -> some View {
        switch selectedTab {
        case .recent:
            if transferStore.isLoading(.transferAddressCandidates), filteredRecentContacts.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else if filteredRecentContacts.isEmpty {
                EmptyStateView(asset: "bill_no_data", title: "暂无交易记录")
                    .padding(.top, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(recentContactRows) { row in
                        recentRow(row.item, widthClass: widthClass)
                        if row.index < recentContactRows.count - 1 {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                }
                .padding(12)
                .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous))
            }
        case .addressBook:
            if filteredAddressBooks.isEmpty {
                EmptyStateView(asset: "bill_no_data", title: "暂无地址簿")
                    .padding(.top, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(addressBookRows) { row in
                        addressBookRow(row.item, widthClass: widthClass)
                        if row.index < addressBookRows.count - 1 {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                }
                .padding(12)
                .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous))
            }
        }
    }

    private func recentRow(_ item: TransferReceiveContact, widthClass: DeviceWidthClass) -> some View {
        let address = item.address ?? ""
        let bookName = addressBookAliasByAddress[address.lowercased()]
        return Button {
            addressInput = address
            transferStore.updateTransferRecipientAddress(address)
            triggerNext()
        } label: {
            HStack(spacing: 10) {
                Image(chainIconName(address))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 3) {
                    Text(displayAddressTitle(bookName: bookName, address: address))
                        .font(.system(size: widthClass.bodySize + 1, weight: .semibold))
                        .foregroundStyle(ThemeTokens.title)
                        .lineLimit(1)
                    Text(shortAddress(address))
                        .font(.system(size: widthClass.footnoteSize))
                        .foregroundStyle(ThemeTokens.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(recentMeta(item))
                        .font(.system(size: widthClass.footnoteSize))
                        .foregroundStyle(ThemeTokens.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ThemeTokens.tertiary)
            }
            .frame(maxWidth: .infinity, minHeight: widthClass.metrics.listRowMinHeight + 10, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressFeedback)
        .accessibilityIdentifier(A11yID.Transfer.addressRecentPrefix + address.lowercased())
    }

    private func addressBookRow(_ item: AddressBookItem, widthClass: DeviceWidthClass) -> some View {
        let walletAddress = item.walletAddress ?? ""
        return Button {
            addressInput = walletAddress
            transferStore.updateTransferRecipientAddress(walletAddress)
            triggerNext()
        } label: {
            HStack(spacing: 10) {
                Image(chainIconName(walletAddress))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name ?? "Unknown")
                        .font(.system(size: widthClass.bodySize + 1, weight: .medium))
                        .foregroundStyle(ThemeTokens.title)
                    Text(shortAddress(walletAddress))
                        .font(.system(size: widthClass.footnoteSize))
                        .foregroundStyle(ThemeTokens.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ThemeTokens.tertiary)
            }
            .frame(maxWidth: .infinity, minHeight: widthClass.metrics.listRowMinHeight + 10, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressFeedback)
    }

    private func bottomButton(widthClass: DeviceWidthClass) -> some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                transferStore.updateTransferRecipientAddress(addressInput)
                triggerNext()
            } label: {
                HStack {
                    Spacer()
                    Text("Next")
                        .font(.system(size: widthClass.bodySize + 2, weight: .semibold))
                        .foregroundStyle(Color.white)
                    Spacer()
                }
                .frame(height: widthClass.metrics.buttonHeight)
                .background(nextDisabled ? ThemeTokens.cpPrimary.opacity(0.45) : ThemeTokens.cpPrimary)
                .clipShape(RoundedRectangle(cornerRadius: widthClass.metrics.buttonHeight / 2, style: .continuous))
                .padding(.horizontal, widthClass.horizontalPadding)
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
            .buttonStyle(.pressFeedback)
            .disabled(nextDisabled)
            .accessibilityIdentifier(A11yID.Transfer.addressNextButton)
        }
        .frame(maxWidth: .infinity)
        .background(ThemeTokens.groupBackground.opacity(0.95))
    }

    private func triggerNext() {
        guard !nextTriggered else { return }
        nextTriggered = true
        onNext()
        nextResetTask?.cancel()
        nextResetTask = Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }
            nextTriggered = false
        }
    }

    private var shouldShowAddAddressBook: Bool {
        let trimmed = addressInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, transferStore.isValidTransferAddress(trimmed) else { return false }
        let exists = addressBookCandidates.contains {
            ($0.walletAddress ?? "").caseInsensitiveCompare(trimmed) == .orderedSame
        }
        return !exists
    }

    private var recentContactRows: [TransferRecentRow] {
        let seeds = filteredRecentContacts.map { item in
            StableRowID.make(
                item.address,
                item.walletAddress,
                item.createdAt.map(String.init),
                fallback: "recent"
            )
        }
        let ids = StableRowID.uniqued(seeds)
        return Array(zip(filteredRecentContacts, ids).enumerated()).map { index, pair in
            TransferRecentRow(id: pair.1, index: index, item: pair.0)
        }
    }

    private var addressBookRows: [TransferAddressBookRow] {
        let seeds = filteredAddressBooks.map { item in
            StableRowID.make(
                item.id.map(String.init),
                item.walletAddress,
                item.name,
                fallback: "book"
            )
        }
        let ids = StableRowID.uniqued(seeds)
        return Array(zip(filteredAddressBooks, ids).enumerated()).map { index, pair in
            TransferAddressBookRow(id: pair.1, index: index, item: pair.0)
        }
    }

    private func chainIconName(_ address: String) -> String {
        address.uppercased().hasPrefix("T") ? "chain_tron" : "chain_evm"
    }

    private func normalizeScannedAddress(_ raw: String) -> String {
        AddressInputParser.normalizeScannedAddress(raw) { candidate in
            transferStore.isValidTransferAddress(candidate) || transferStore.detectAddressChainType(candidate) != nil
        }
    }

    private func displayAddressTitle(bookName: String?, address: String) -> String {
        if let bookName, !bookName.isEmpty {
            return bookName
        }
        return shortAddress(address)
    }

    private func shortAddress(_ value: String) -> String {
        AddressFormatter.shortened(value, leading: 8, trailing: 6, threshold: 16)
    }

    private func recentMeta(_ item: TransferReceiveContact) -> String {
        let direction: String
        switch (item.direction ?? "").uppercased() {
        case "TRANSFER":
            direction = "转账给对方"
        case "RECEIVE":
            direction = "从对方收款"
        default:
            direction = "-"
        }
        let amount = item.amount.map { String(format: "%.2f", $0) } ?? "-"
        let coin = item.coinName ?? "USDT"
        let dateText = formatDate(item.createdAt)
        return "\(dateText) · \(direction) · \(amount) \(coin)"
    }

    private func formatDate(_ ts: Int?) -> String {
        DateTextFormatter.yearMonthDay(fromTimestamp: ts, fallback: "-")
    }
}

private struct TransferRecentRow: Identifiable {
    let id: String
    let index: Int
    let item: TransferReceiveContact
}

private struct TransferAddressBookRow: Identifiable {
    let id: String
    let index: Int
    let item: AddressBookItem
}

#Preview("TransferAddressView") {
    NavigationStack {
        TransferAddressView(transferStore: TransferStore(appState: AppState()), onNext: {})
    }
}
