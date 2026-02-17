import SwiftUI

struct AddressBookEditView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var state: AppState
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
                                input(title: "名称", text: $name, placeholder: "请输入名称")
                                addressInput(widthClass: widthClass)

                                if let chain = resolvedChainType {
                                    HStack(spacing: 10) {
                                        Text("网络")
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
                                                    Text("包含 Layer2 与 EVM 网络")
                                                        .font(.system(size: 11))
                                                        .foregroundStyle(ThemeTokens.secondary)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                } else {
                                    Text("仅支持 TRON 与 EVM 网络地址")
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
                                let cleanAddress = sanitizeAddress(walletAddress)
                                let chainType = resolvedChainType ?? initialChainType
                                let success: Bool
                                if let editingId {
                                    success = await state.updateAddressBook(
                                        id: editingId,
                                        name: cleanName,
                                        walletAddress: cleanAddress,
                                        chainType: chainType
                                    )
                                } else {
                                    success = await state.createAddressBook(
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
                            Text(editingId == nil ? "添加" : "保存")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: widthClass.metrics.buttonHeight)
                                .background(ThemeTokens.cpPrimary, in: Capsule())
                        }
                        .buttonStyle(.pressFeedback)
                        .disabled(saveDisabled)
                        .opacity(saveDisabled ? 0.6 : 1)

                        if let editingId {
                            Button {
                                Task {
                                    await state.deleteAddressBook(id: editingId)
                                    dismiss()
                                }
                            } label: {
                                Text("删除")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(ThemeTokens.danger)
                                    .frame(maxWidth: .infinity, minHeight: widthClass.metrics.buttonHeight)
                                    .overlay(Capsule().stroke(ThemeTokens.danger, lineWidth: 1))
                            }
                            .buttonStyle(.pressFeedback)
                        }
                    }
                    .padding(.horizontal, widthClass.horizontalPadding)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle(editingId == nil ? "添加地址" : "编辑地址")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $scannerPresented) {
                QRCodeScannerSheet { value in
                    let normalized = normalizeScannedAddress(value)
                    guard !normalized.isEmpty else {
                        state.showInfoToast("未识别到有效地址")
                        return
                    }
                    walletAddress = normalized
                }
            }
            .onAppear {
                guard let editingId else { return }
                if let item = state.addressBooks.first(where: { "\($0.id ?? -1)" == editingId }) {
                    name = item.name ?? ""
                    walletAddress = item.walletAddress ?? ""
                    initialChainType = item.chainType ?? "EVM"
                }
            }
            .onChange(of: walletAddress) { _, value in
                let sanitized = sanitizeAddress(value)
                if sanitized != value {
                    walletAddress = sanitized
                }
            }
        }
    }

    private var resolvedChainType: String? {
        state.detectAddressChainType(walletAddress) ?? (editingId != nil ? initialChainType : nil)
    }

    private var invalidAddress: Bool {
        let value = sanitizeAddress(walletAddress)
        guard !value.isEmpty else { return false }
        return state.detectAddressChainType(value) == nil
    }

    private var saveDisabled: Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAddress = sanitizeAddress(walletAddress)
        return cleanName.isEmpty || cleanAddress.isEmpty || invalidAddress
    }

    private func addressInput(widthClass: DeviceWidthClass) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("钱包地址")
                .font(.system(size: 13))
                .foregroundStyle(ThemeTokens.secondary)
            HStack(alignment: .top, spacing: 8) {
                TextField("请输入钱包地址", text: $walletAddress)
                    .lineLimit(1)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: widthClass.bodySize + 1))

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

    private func input(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(ThemeTokens.secondary)
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(ThemeTokens.inputBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(ThemeTokens.divider, lineWidth: 1)
                )
        }
    }

    private func sanitizeAddress(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizeScannedAddress(_ raw: String) -> String {
        let text = sanitizeAddress(raw)
        if let evm = text.range(of: "(0x|0X)[a-fA-F0-9]{40}", options: .regularExpression) {
            return sanitizeAddress(String(text[evm]))
        }
        if let tron = text.range(of: "T[a-zA-Z0-9]{33}", options: .regularExpression) {
            return sanitizeAddress(String(text[tron]))
        }
        var value = text
        if let schemeRange = value.range(of: "ethereum:", options: [.caseInsensitive, .anchored]) {
            value = String(value[schemeRange.upperBound...])
        } else if let schemeRange = value.range(of: "tron:", options: [.caseInsensitive, .anchored]) {
            value = String(value[schemeRange.upperBound...])
        }
        if let queryIndex = value.firstIndex(of: "?") {
            value = String(value[..<queryIndex])
        }
        if let chainIndex = value.firstIndex(of: "@") {
            value = String(value[..<chainIndex])
        }
        return sanitizeAddress(value)
    }
}
