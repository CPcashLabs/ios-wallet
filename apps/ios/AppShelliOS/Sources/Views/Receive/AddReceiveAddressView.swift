import BackendAPI
import SwiftUI

struct AddReceiveAddressView: View {
    @ObservedObject var receiveStore: ReceiveStore
    var onNavigate: ((ReceiveRoute) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var isEditMode = false
    @State private var showEditSheet = false
    @State private var editingItem: TraceOrderItem?
    @State private var editRemarkName = ""
    @State private var isAddLoading = false
    @State private var showBusinessAddressSheet = false

    var body: some View {
        AdaptiveReader { widthClass in
            FullscreenScaffold(backgroundStyle: .globalImage) {
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if receiveStore.isLoading(.receiveHome) && items.isEmpty {
                                skeletonView
                            } else if items.isEmpty {
                                EmptyStateView(asset: "bill_no_data", title: "No addresses")
                                    .padding(.top, 40)
                                    .accessibilityIdentifier(A11yID.Receive.addAddressEmpty)
                            } else {
                                headerView
                                ForEach(addressRows) { row in
                                    addressCard(row.item)
                                        .onTapGesture {
                                            handleItemTap(row.item)
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, widthClass.horizontalPadding)
                        .padding(.vertical, 16)
                    }
                    .refreshable {
                        await receiveStore.loadReceiveAddresses(validity: .valid)
                        await receiveStore.loadReceiveAddressLimit()
                    }

                    bottomBar(widthClass)
                }
            }
            .navigationTitle("Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            isEditMode.toggle()
                        } label: {
                            Label(
                                isEditMode ? "Finish Editing" : "Edit Address Name",
                                systemImage: isEditMode ? "checkmark" : "pencil"
                            )
                        }
                        Button(role: .destructive) {
                            onNavigate?(.deleteAddress)
                        } label: {
                            Label("Delete Address", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                            .foregroundStyle(ThemeTokens.title)
                    }
                }
            }
            .task {
                await receiveStore.loadReceiveAddresses(validity: .valid)
                await receiveStore.loadReceiveAddressLimit()
            }
        }
        .accessibilityIdentifier(A11yID.Receive.addAddressTitle)
        .sheet(isPresented: $showEditSheet) {
            editAddressSheet
        }
        .sheet(isPresented: $showBusinessAddressSheet) {
            businessAddressTypeSheet
        }
    }

    // MARK: - Items

    private var items: [TraceOrderItem] {
        let source = receiveStore.receiveRecentValid
        return source.filter { item in
            let orderType = (item.orderType ?? "").uppercased()
            switch receiveStore.receiveDomainState.activeTab {
            case .individuals:
                return !orderType.contains("LONG")
            case .business:
                return orderType.contains("LONG")
            }
        }
    }

    private var addressRows: [AddReceiveAddressRow] {
        let seeds = items.map { item in
            StableRowID.make(
                item.orderSn,
                item.address,
                item.receiveAddress,
                fallback: "receive-add-address-row"
            )
        }
        let ids = StableRowID.uniqued(seeds)
        return Array(zip(items, ids)).map { pair in
            AddReceiveAddressRow(id: pair.1, item: pair.0)
        }
    }

    private var addressLimit: Int {
        receiveStore.receiveDomainState.receiveAddressLimit
    }

    private var isButtonDisabled: Bool {
        items.count >= addressLimit || isAddLoading
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 4) {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
            Text("\(items.count)/\(addressLimit)")
                .font(.system(size: 14, weight: .bold))
            Text("Added Addresses")
                .font(.system(size: 14))
            Spacer()
        }
        .foregroundStyle(ThemeTokens.secondary)
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(items.count)/\(addressLimit) Added Addresses")
        .accessibilityIdentifier(A11yID.Receive.addAddressHeader)
    }

    // MARK: - Skeleton

    private var skeletonView: some View {
        ForEach(0..<4, id: \.self) { _ in
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(ThemeTokens.secondary.opacity(0.15))
                        .frame(width: 120, height: 14)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(ThemeTokens.secondary.opacity(0.1))
                        .frame(width: 200, height: 12)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(ThemeTokens.secondary.opacity(0.08))
                        .frame(width: 80, height: 12)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(ThemeTokens.secondary.opacity(0.1))
                    .frame(width: 20, height: 20)
            }
            .padding(16)
            .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .redacted(reason: .placeholder)
            .accessibilityIdentifier(A11yID.Receive.addAddressSkeleton)
        }
    }

    // MARK: - Address Card

    private func addressCard(_ item: TraceOrderItem) -> some View {
        let isSelected = item.address == receiveStore.activeAddress

        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                // Name/Remark
                Text(item.addressRemarksName ?? "--")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ThemeTokens.title)
                    .lineLimit(1)

                // Always show address
                Text(item.address ?? "-")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ThemeTokens.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 8) {
                    if item.isRareAddress == 1 {
                        Text("Rare")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange, in: RoundedRectangle(cornerRadius: 12))
                    }

                    Text(formatTime(item.createdAt))
                        .font(.system(size: 12))
                        .foregroundStyle(ThemeTokens.secondary)

                    // Fixed amount display (RECEIPT_FIXED)
                    if (item.orderType ?? "").uppercased() == "RECEIPT_FIXED" {
                        Text("\(item.recvAmount?.stringValue ?? "")\(item.recvCoinName ?? "")")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ThemeTokens.secondary)
                    }
                }
            }

            Spacer()

            if isEditMode {
                Image(systemName: "pencil")
                    .font(.system(size: 18))
                    .foregroundStyle(ThemeTokens.cpPrimary)
            } else if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(ThemeTokens.cpPrimary)
            }
        }
        .padding(16)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected && !isEditMode ? ThemeTokens.cpPrimary : Color.clear, lineWidth: 1)
        )
        .accessibilityIdentifier(A11yID.Receive.addAddressCardPrefix + (item.orderSn ?? item.address ?? "unknown"))
    }

    // MARK: - Bottom Bar

    private func bottomBar(_ widthClass: DeviceWidthClass) -> some View {
        VStack(spacing: 16) {
            Divider()
            if isEditMode {
                // Edit mode: no add button
            } else {
                Button {
                    handleAddAddress()
                } label: {
                    HStack {
                        if isAddLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "plus")
                        }
                        Text("AddAddress")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        isButtonDisabled ? ThemeTokens.cpPrimary.opacity(0.5) : ThemeTokens.cpPrimary,
                        in: Capsule()
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.pressFeedback)
                .disabled(isButtonDisabled)
                .accessibilityIdentifier(A11yID.Receive.addAddressButton)
            }

            Button {
                onNavigate?(.invalidAddress)
            } label: {
                HStack {
                    Text("Invalid Addresses")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 14))
                .foregroundStyle(ThemeTokens.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(A11yID.Receive.invalidAddressButton)
        }
        .padding(.horizontal, widthClass.horizontalPadding)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(ThemeTokens.groupBackground.opacity(0.95))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(A11yID.Receive.addAddressBottomBar)
    }

    // MARK: - Business Address Type Sheet

    private var businessAddressTypeSheet: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(ThemeTokens.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 20)

            Text("Select Address Type")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(ThemeTokens.title)
                .padding(.bottom, 20)

            Button {
                showBusinessAddressSheet = false
                Task {
                    isAddLoading = true
                    await receiveStore.createLongTraceOrder()
                    await receiveStore.loadReceiveAddresses(validity: .valid)
                    isAddLoading = false
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Random Address")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(ThemeTokens.title)
                        Text("System randomly assigns a receiving address")
                            .font(.system(size: 13))
                            .foregroundStyle(ThemeTokens.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(ThemeTokens.secondary)
                }
                .padding(16)
                .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .accessibilityIdentifier(A11yID.Receive.businessTypeRandom)

            Button {
                showBusinessAddressSheet = false
                onNavigate?(.rareAddress)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Vanity Address")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(ThemeTokens.title)
                            Text("Rare")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange, in: RoundedRectangle(cornerRadius: 12))
                        }
                        Text("Choose a vanity address as receiving address")
                            .font(.system(size: 13))
                            .foregroundStyle(ThemeTokens.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(ThemeTokens.secondary)
                }
                .padding(16)
                .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .accessibilityIdentifier(A11yID.Receive.businessTypeRare)

            Spacer()
                .frame(height: 40)
        }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Edit Address Sheet

    private var editAddressSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Edit Address Name")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ThemeTokens.title)
                    .padding(.top, 12)

                if let item = editingItem {
                    Text(item.address ?? "-")
                        .font(.system(size: 13))
                        .foregroundStyle(ThemeTokens.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal, 16)
                }

                TextField("Enter address remark name", text: $editRemarkName)
                    .font(.system(size: 15))
                    .padding(14)
                    .background(ThemeTokens.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)

                Button {
                    guard let item = editingItem,
                          let orderSN = item.orderSn,
                          let address = item.address else { return }
                    showEditSheet = false
                    Task {
                        let success = await receiveStore.editAddressInfo(
                            orderSN: orderSN,
                            remarkName: editRemarkName,
                            address: address
                        )
                        if success {
                            await receiveStore.loadReceiveAddresses(validity: .valid)
                        }
                    }
                } label: {
                    Text("Confirm")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(ThemeTokens.cpPrimary, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.pressFeedback)
                .padding(.horizontal, 16)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEditSheet = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(ThemeTokens.secondary)
                    }
                }
            }
        }
        .presentationDetents([.height(320)])
    }

    // MARK: - Actions

    private func handleItemTap(_ item: TraceOrderItem) {
        if isEditMode {
            editingItem = item
            editRemarkName = item.addressRemarksName ?? ""
            showEditSheet = true
            return
        }
        selectAddress(item)
    }

    private func handleAddAddress() {
        if receiveStore.receiveDomainState.activeTab == .business {
            showBusinessAddressSheet = true
        } else {
            Task {
                isAddLoading = true
                await receiveStore.createShortTraceOrder()
                await receiveStore.loadReceiveAddresses(validity: .valid)
                isAddLoading = false
            }
        }
    }

    private func selectAddress(_ item: TraceOrderItem) {
        guard item.address != receiveStore.activeAddress, let orderSN = item.orderSn else { return }
        Task {
            await receiveStore.markTraceOrder(
                orderSN: orderSN,
                sendCoinCode: item.sendCoinCode,
                recvCoinCode: item.recvCoinCode,
                orderType: item.orderType
            )
            dismiss()
        }
    }

    private func formatTime(_ timestamp: Int?) -> String {
        guard let timestamp else { return "-" }
        return DateTextFormatter.yearMonthDay(fromTimestamp: timestamp, fallback: "-")
    }
}

private struct AddReceiveAddressRow: Identifiable {
    let id: String
    let item: TraceOrderItem
}
