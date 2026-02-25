import SwiftUI

struct AddressBookEditView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var meStore: MeStore
    @ObservedObject var uiStore: UIStore
    let editingId: String?

    @State private var name = ""
    @State private var walletAddress = ""
    @State private var initialChainType = "EVM"
    @State private var scannerPresented = false

    var body: some View {
        AdaptiveReader { widthClass in
            FullscreenScaffold(backgroundStyle: .globalImage) {
                ScrollView {
                    VStack(spacing: 14) {
                        SectionCard {
                            VStack(spacing: 12) {
                                input(
                                    title: "Name",
                                    text: $name,
                                    placeholder: "Please enter a name",
                                    identifier: A11yID.Me.addressBookNameInput
                                )
                                addressInput(widthClass: widthClass)

                                if let chain = resolvedChainType {
                                    HStack(spacing: 10) {
                                        Text("Network")
                                            .font(.system(size: 14))
                                            .foregroundStyle(ThemeTokens.secondary)
                                        Spacer()
                                        HStack(spacing: 8) {
                                            Image(chain == "TRON" ? "chain_tron" : "chain_evm")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 24, height: 24)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(chain)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(ThemeTokens.title)
                                                if chain == "EVM" {
                                                    Text("Includes Layer2 and EVM networks")
                                                        .font(.system(size: 11))
                                                        .foregroundStyle(ThemeTokens.secondary)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                } else {
                                    Text("Only TRON and EVM network addresses are supported")
                                        .font(.system(size: 12))
                                        .foregroundStyle(invalidAddress ? ThemeTokens.danger : ThemeTokens.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 14)
                                }
                            }
                            .padding(14)
                        }

                        Button {
                            Task {
                                let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                                let cleanAddress = AddressInputParser.sanitize(walletAddress)
                                let chainType = resolvedChainType ?? initialChainType
                                let success: Bool
                                if let editingId {
                                    success = await meStore.updateAddressBook(
                                        id: editingId,
                                        name: cleanName,
                                        walletAddress: cleanAddress,
                                        chainType: chainType
                                    )
                                } else {
                                    success = await meStore.createAddressBook(
                                        name: cleanName,
                                        walletAddress: cleanAddress,
                                        chainType: chainType
                                    )
                                }
                                if success {
                                    dismiss()
                                }
                            }
                        } label: {
                            Text(editingId == nil ? "Add" : "Save")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: widthClass.metrics.buttonHeight)
                                .background(ThemeTokens.cpPrimary, in: Capsule())
                        }
                        .buttonStyle(.pressFeedback)
                        .disabled(saveDisabled)
                        .opacity(saveDisabled ? 0.6 : 1)
                        .accessibilityIdentifier(A11yID.Me.addressBookSaveButton)

                        if let editingId {
                            Button {
                                Task {
                                    await meStore.deleteAddressBook(id: editingId)
                                    dismiss()
                                }
                            } label: {
                                Text("Delete")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(ThemeTokens.danger)
                                    .frame(maxWidth: .infinity, minHeight: widthClass.metrics.buttonHeight)
                                    .overlay(Capsule().stroke(ThemeTokens.danger, lineWidth: 1))
                            }
                            .buttonStyle(.pressFeedback)
                            .accessibilityIdentifier(A11yID.Me.addressBookDeleteButton)
                        }
                    }
                    .padding(.horizontal, widthClass.horizontalPadding)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle(editingId == nil ? "AddAddress" : "Edit Address")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $scannerPresented) {
                QRCodeScannerSheet { value in
                    let normalized = normalizeScannedAddress(value)
                    guard !normalized.isEmpty else {
                        uiStore.showInfoToast("No valid address recognized")
                        return
                    }
                    walletAddress = normalized
                }
            }
            .onAppear {
                guard let editingId else { return }
                Task {
                    if meStore.addressBooks.isEmpty {
                        await meStore.loadAddressBooks()
                    }
                    guard let item = meStore.addressBooks.first(where: { "\($0.id ?? -1)" == editingId }) else { return }
                    name = item.name ?? ""
                    walletAddress = item.walletAddress ?? ""
                    initialChainType = item.chainType ?? "EVM"
                }
            }
            .onChange(of: walletAddress) { _, value in
                let sanitized = AddressInputParser.sanitize(value)
                if sanitized != value {
                    walletAddress = sanitized
                }
            }
        }
    }

    private var resolvedChainType: String? {
        meStore.detectAddressChainType(walletAddress) ?? (editingId != nil ? initialChainType : nil)
    }

    private var invalidAddress: Bool {
        let value = AddressInputParser.sanitize(walletAddress)
        guard !value.isEmpty else { return false }
        return meStore.detectAddressChainType(value) == nil
    }

    private var saveDisabled: Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAddress = AddressInputParser.sanitize(walletAddress)
        return cleanName.isEmpty || cleanAddress.isEmpty || invalidAddress
    }

    private func addressInput(widthClass: DeviceWidthClass) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Wallet Address")
                .font(.system(size: 13))
                .foregroundStyle(ThemeTokens.secondary)
            HStack(alignment: .top, spacing: 8) {
                TextField("Please enter a wallet address", text: $walletAddress)
                    .lineLimit(1)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: widthClass.bodySize + 1))
                    .accessibilityIdentifier(A11yID.Me.addressBookWalletInput)

                Button {
                    scannerPresented = true
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(ThemeTokens.cpPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.pressFeedback)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(ThemeTokens.inputBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(invalidAddress ? ThemeTokens.danger : ThemeTokens.divider, lineWidth: 1)
            )
        }
    }

    private func input(title: String, text: Binding<String>, placeholder: String, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(ThemeTokens.secondary)
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier(identifier)
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(ThemeTokens.inputBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(ThemeTokens.divider, lineWidth: 1)
                )
        }
    }

    private func normalizeScannedAddress(_ raw: String) -> String {
        AddressInputParser.normalizeScannedAddress(raw) { candidate in
            meStore.detectAddressChainType(candidate) != nil
        }
    }
}
