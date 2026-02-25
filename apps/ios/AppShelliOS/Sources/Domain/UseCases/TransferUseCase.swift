import BackendAPI
import CoreRuntime
import Foundation

@MainActor
final class TransferUseCase {
    private unowned let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadTransferSelectNetwork() async {
        let requestedChainId = appState.selectedChainId
        let requestedGeneration = appState.networkSelectionGeneration
        appState.setLoading(LoadKey.transferSelectNetwork, true)
        defer { appState.setLoading(LoadKey.transferSelectNetwork, false) }

        do {
            let query = AllowListQuery(
                groupByType: 1,
                recvCoinSymbol: "USDT",
                sendCoinSymbol: "USDT",
                sendChainName: appState.selectedChainName,
                env: backendEnvValue()
            )

            async let cpListTask = appState.backend.receive.cpCashAllowList(query: query)
            async let normalListTask = appState.backend.receive.normalAllowList(
                chainName: nil,
                coinCode: nil,
                isSendAllowed: true,
                isRecvAllowed: true,
                coinSymbol: nil
            )

            let cpList = try await cpListTask
            let normalList = try await normalListTask

            let preferredNormalChainName = appState.selectedChainId == 199 ? "BTT" : "BTT_TEST"
            let normalEntry = normalList.first {
                ($0.chainName ?? "").uppercased() == preferredNormalChainName
            } ?? normalList.first

            let normalNetworks: [TransferNetworkItem]
            if let normalEntry {
                normalNetworks = [
                    TransferNetworkItem(
                        id: "normal:\(normalEntry.chainName ?? "CPcash")",
                        name: "CPcash",
                        logoURL: normalEntry.chainLogo,
                        chainColor: normalEntry.chainColor ?? "#1677FF",
                        category: .appChannel,
                        allowChain: nil,
                        normalChain: normalEntry,
                        isNormalChannel: true
                    ),
                ]
            } else {
                normalNetworks = [
                    TransferNetworkItem(
                        id: "normal:CPcash",
                        name: "CPcash",
                        logoURL: nil,
                        chainColor: "#1677FF",
                        category: .appChannel,
                        allowChain: nil,
                        normalChain: nil,
                        isNormalChannel: true
                    ),
                ]
            }

            let proxyNetworks = cpList.map { item in
                TransferNetworkItem(
                    id: "proxy:\(item.chainName ?? appState.idGenerator.makeID())",
                    name: item.chainName ?? "-",
                    logoURL: item.chainLogo,
                    chainColor: item.chainColor ?? "#1677FF",
                    category: .proxySettlement,
                    allowChain: item,
                    normalChain: nil,
                    isNormalChannel: false,
                    balance: chainTotalBalance(item.exchangePairs)
                )
            }

            guard requestedGeneration == appState.networkSelectionGeneration,
                  requestedChainId == appState.selectedChainId
            else {
                return
            }
            appState.transferNormalNetworks = normalNetworks
            appState.transferProxyNetworks = proxyNetworks
            appState.transferSelectNetworks = normalNetworks + proxyNetworks

            if let selectedId = appState.transferSelectedNetworkId,
               !appState.transferSelectNetworks.contains(where: { $0.id == selectedId })
            {
                appState.transferSelectedNetworkId = nil
            }
            if appState.transferSelectedNetworkId == nil,
               let first = appState.transferSelectNetworks.first
            {
                configureTransferNetwork(first)
            }
            appState.clearError(LoadKey.transferSelectNetwork)
        } catch {
            guard requestedGeneration == appState.networkSelectionGeneration,
                  requestedChainId == appState.selectedChainId
            else {
                return
            }
            appState.setError(LoadKey.transferSelectNetwork, error)
            appState.transferNormalNetworks = [
                TransferNetworkItem(
                    id: "normal:CPcash",
                    name: "CPcash",
                    logoURL: nil,
                    chainColor: "#1677FF",
                    category: .appChannel,
                    allowChain: nil,
                    normalChain: nil,
                    isNormalChannel: true
                ),
            ]
            appState.transferProxyNetworks = []
            appState.transferSelectNetworks = appState.transferNormalNetworks
            if let first = appState.transferSelectNetworks.first {
                configureTransferNetwork(first)
            }
            appState.log("TransferNetworkLoadFailed: \(error)")
        }
    }

    func selectTransferNetwork(item: TransferNetworkItem) async {
        if !item.isAvailable {
            appState.showToast("Insufficient balance, please switch to another network", theme: .error)
            return
        }
        configureTransferNetwork(item)
        appState.transferDraft = TransferDraft(mode: item.isNormalChannel ? .normal : .proxy)
        if appState.addressBooks.isEmpty {
            await appState.loadAddressBooks()
        }
        await loadTransferAddressCandidates()
    }

    func selectTransferPair(sendCoinCode: String, recvCoinCode: String) {
        guard let pair = appState.transferDomainState.availablePairs.first(where: {
            $0.sendCoinCode == sendCoinCode && $0.recvCoinCode == recvCoinCode
        }) else {
            return
        }
        applyTransferPair(pair)
        appState.transferDraft.orderSN = nil
        appState.transferDraft.orderDetail = nil
    }

    func selectTransferNormalCoin(coinCode: String) async {
        guard let coin = appState.transferDomainState.availableNormalCoins.first(where: { $0.coinCode == coinCode }) else {
            return
        }
        applyTransferNormalCoin(coin)
        do {
            let detail = try await appState.backend.receive.normalAllowCoinShow(coinCode: coinCode)
            applyTransferNormalCoin(detail)
        } catch {
            appState.log("Transfer coin details load failed: \(error)")
        }
    }

    func updateTransferRecipientAddress(_ address: String) {
        let compact = address
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        appState.transferDraft.recipientAddress = compact
    }

    func resetTransferFlow() {
        appState.transferDraft = TransferDraft(mode: appState.transferDomainState.selectedIsNormalChannel ? .normal : .proxy)
    }

    func transferAddressValidationMessage(_ address: String) -> String? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return isValidTransferAddress(trimmed) ? nil : "Please enter a valid address"
    }

    func isValidTransferAddress(_ address: String) -> Bool {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        if appState.transferDomainState.selectedIsNormalChannel {
            return isValidEvmAddress(trimmed)
        }

        let patterns = appState.transferDomainState.selectedAddressRegex
        if patterns.isEmpty {
            return false
        }
        for pattern in patterns {
            if let regex = buildTransferRegex(pattern),
               regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count)) != nil
            {
                return true
            }
        }
        return false
    }

    func transferAddressBookCandidates() -> [AddressBookItem] {
        let isTron = appState.transferDomainState.selectedPayChain.uppercased().contains("TRON")
        return appState.addressBooks.filter { item in
            let type = (item.chainType ?? "EVM").uppercased()
            return isTron ? type == "TRON" : type != "TRON"
        }
    }

    func detectAddressChainType(_ address: String) -> String? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let evm = "^(0x|0X)?[a-fA-F0-9]{40}$"
        let tron = "^T[a-zA-Z0-9]{33}$"
        if trimmed.range(of: evm, options: .regularExpression) != nil {
            return "EVM"
        }
        if trimmed.range(of: tron, options: .regularExpression) != nil {
            return "TRON"
        }
        return nil
    }

    func loadTransferAddressCandidates() async {
        let sendChain = appState.selectedChainId == 199 ? "BTT" : "BTT_TEST"
        let recvChain = appState.transferDomainState.selectedPayChain
        do {
            appState.transferRecentContacts = try await appState.backend.wallet.recentTransferReceiveList(
                sendChainName: sendChain,
                recvChainName: recvChain
            )
            appState.clearError(LoadKey.transferAddressCandidates)
            appState.log("Transfer recent contacts loaded successfully: \(appState.transferRecentContacts.count)")
        } catch {
            appState.setError(LoadKey.transferAddressCandidates, error)
            appState.transferRecentContacts = []
            appState.log("Transfer recent contacts load failed: \(error)")
        }
    }

    func prepareTransferPayment(amountText: String, note: String) async -> Bool {
        let address = appState.transferDraft.recipientAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidTransferAddress(address) else {
            appState.showToast("Invalid address format", theme: .error)
            return false
        }
        let normalizedAmount = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Decimal(string: normalizedAmount), amount > 0 else {
            appState.showToast("Please enter a valid amount", theme: .error)
            return false
        }

        appState.transferDraft.recipientAddress = address
        appState.transferDraft.amountText = normalizedAmount
        appState.transferDraft.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        appState.transferDraft.orderDetail = nil
        appState.transferDraft.orderSN = nil
        appState.transferDraft.mode = appState.transferDomainState.selectedIsNormalChannel ? .normal : .proxy

        if appState.transferDomainState.selectedIsNormalChannel {
            do {
                let detail = try await appState.backend.receive.normalAllowCoinShow(coinCode: appState.transferDomainState.selectedSendCoinCode)
                applyTransferNormalCoin(detail)
            } catch {
                appState.log("normal coin details load failed, using allow-list data fallback: \(error)")
            }
            let contract = appState.transferDomainState.selectedCoinContract ?? ""
            guard isValidEvmAddress(contract) else {
                appState.showToast("Coin configuration is invalid, please reselect the network and try again", theme: .error)
                return false
            }
            return true
        }

        appState.setLoading(LoadKey.transferPrepare, true)
        defer { appState.setLoading(LoadKey.transferPrepare, false) }
        do {
            let result = try await appState.backend.order.createPayment(
                request: CreatePaymentRequest(
                    recvAddress: address,
                    sendCoinCode: appState.transferDomainState.selectedSendCoinCode,
                    recvCoinCode: appState.transferDomainState.selectedRecvCoinCode,
                    sendAmount: NSDecimalNumber(decimal: amount).doubleValue,
                    note: appState.transferDraft.note
                )
            )
            let orderSN = try await resolveTransferOrderSN(result)
            let detail = try await appState.backend.order.detail(orderSN: orderSN)
            appState.transferDraft.orderSN = orderSN
            appState.transferDraft.orderDetail = detail
            appState.lastCreatedPaymentOrderSN = orderSN
            appState.log("Transfer order created successfully: order_sn=\(orderSN)")
            return true
        } catch {
            appState.showToast("Transfer order creation failed", theme: .error)
            appState.log("Transfer order creation failed: \(error)")
            return false
        }
    }

    func executeTransferPayment() async -> Bool {
        guard case .unlocked = appState.approvalSessionState else {
            appState.showToast("Login session expired, please sign in again", theme: .error)
            return false
        }
        guard !appState.isLoading(LoadKey.transferPay) else { return false }
        appState.setLoading(LoadKey.transferPay, true)
        defer { appState.setLoading(LoadKey.transferPay, false) }

        do {
            let payment = try buildTransferExecutionContext()
            let from = try appState.securityService.activeAddress()
            let amountMinor = toMinorUnits(amountText: payment.amountText, decimals: payment.coinPrecision)
            guard let data = erc20TransferData(to: payment.recipientAddress, amountMinor: amountMinor) else {
                throw BackendAPIError.serverError(code: -1, message: "erc20 data encode failed")
            }

            let payChainId = resolveTransferChainId(for: payment.chainName)
            let txHash = try await appState.securityService.signAndSendTransactionAsync(
                SendTxRequest(
                    source: .system(name: "wallet_transfer"),
                    from: from,
                    to: Address(payment.tokenContract),
                    value: "0",
                    data: data,
                    chainId: payChainId
                )
            )
            appState.lastTxHash = txHash.value
            appState.log("Transfer signature broadcast succeeded: tx=\(txHash.value), chain=\(payChainId)")

            let confirmation = try await appState.securityService.waitForTransactionConfirmation(
                WaitTxConfirmationRequest(
                    txHash: txHash.value,
                    chainId: payChainId,
                    timeoutSeconds: appState.transferConfirmationTimeoutSeconds,
                    pollIntervalSeconds: appState.transferConfirmationPollIntervalSeconds
                )
            )
            if let status = confirmation.status, status == 0 {
                throw BackendAPIError.serverError(code: -1, message: "On-chain confirmation failed")
            }
            appState.log("On-chain confirmation succeeded: tx=\(confirmation.txHash), block=\(confirmation.blockNumber), status=\(confirmation.status ?? -1)")

            var callbackError: Error?
            if payment.mode == .proxy, let orderSN = payment.orderSN {
                do {
                    try await appState.backend.order.ship(orderSN: orderSN, txid: txHash.value, message: nil, success: true)
                    await appState.loadOrderDetail(orderSN: orderSN)
                } catch {
                    callbackError = error
                    appState.log("Transfer succeeded but order write-back failed(proxy): \(error)")
                }
            } else {
                do {
                    let report = try await appState.backend.order.cpCashTxReport(
                        request: CpCashTxReportRequest(
                            txid: txHash.value,
                            chainName: payment.chainName,
                            coinCode: payment.coinCode,
                            success: true,
                            message: appState.transferDraft.note.isEmpty ? nil : appState.transferDraft.note,
                            direction: "TRANSFER_OUT",
                            multisigWalletId: nil,
                            buyerSendAddress: from.value,
                            buyerRecvAddress: appState.transferDraft.recipientAddress
                        )
                    )
                    if let orderSN = report.orderSn, !orderSN.isEmpty {
                        appState.transferDraft.orderSN = orderSN
                    }
                } catch {
                    callbackError = error
                    appState.log("Transfer succeeded but receipt reporting failed(normal): \(error)")
                }
            }

            await appState.refreshOrdersOnly()
            if callbackError != nil {
                appState.showToast("Payment submitted, receipt sync failed, please check bills later", theme: .info)
            } else {
                appState.showToast("Payment successful", theme: .success)
            }
            return true
        } catch {
            appState.log("Transfer payment failed: \(error)")
            let failedMessage = transferPaymentFailureMessage(error)
            if appState.transferDraft.mode == .proxy, let orderSN = appState.transferDraft.orderSN {
                do {
                    try await appState.backend.order.ship(orderSN: orderSN, txid: nil, message: failedMessage, success: false)
                } catch {
                    appState.log("Transfer failed and order write-back failed: \(error)")
                }
            } else {
                do {
                    _ = try await appState.backend.order.cpCashTxReport(
                        request: CpCashTxReportRequest(
                            txid: nil,
                            chainName: appState.transferDomainState.selectedPayChain,
                            coinCode: appState.transferDomainState.selectedSendCoinCode,
                            success: false,
                            message: failedMessage,
                            direction: "TRANSFER_OUT",
                            multisigWalletId: nil,
                            buyerSendAddress: appState.activeAddress,
                            buyerRecvAddress: appState.transferDraft.recipientAddress
                        )
                    )
                } catch {
                    appState.log("normal transfer failed write-back failed: \(error)")
                }
            }
            appState.showToast(failedMessage, theme: .error)
            return false
        }
    }

    private func configureTransferNetwork(_ item: TransferNetworkItem) {
        appState.transferSelectedNetworkId = item.id
        appState.transferDomainState.selectedNetworkName = item.name
        appState.transferDomainState.selectedChainColor = item.chainColor
        appState.transferDomainState.selectedIsNormalChannel = item.isNormalChannel
        appState.transferDomainState.availablePairs = []
        appState.transferDomainState.availableNormalCoins = []
        appState.transferDomainState.selectedSellerId = nil
        appState.transferDraft = TransferDraft(mode: item.isNormalChannel ? .normal : .proxy)

        if item.isNormalChannel {
            let activeChain = appState.selectedChainId == 199 ? "BTT" : "BTT_TEST"
            appState.transferDomainState.selectedPayChain = activeChain
            appState.transferDomainState.selectedAddressRegex = ["^(0x|0X)?[a-fA-F0-9]{40}$"]
            let normalCoins = item.normalChain?.coins.filter { ($0.isSendAllowed ?? true) && ($0.isRecvAllowed ?? true) } ?? []
            appState.transferDomainState.availableNormalCoins = normalCoins
            if let preferred = preferredTransferNormalCoin(from: normalCoins) {
                applyTransferNormalCoin(preferred)
            } else {
                appState.transferDomainState.selectedSendCoinCode = "USDT_\(activeChain)"
                appState.transferDomainState.selectedRecvCoinCode = "USDT_\(activeChain)"
                appState.transferDomainState.selectedSendCoinName = "USDT"
                appState.transferDomainState.selectedRecvCoinName = "USDT"
                appState.transferDomainState.selectedCoinSymbol = "USDT"
                appState.transferDomainState.selectedPairLabel = "USDT/USDT"
                appState.transferDomainState.selectedCoinContract = nil
                appState.transferDomainState.selectedCoinPrecision = 6
            }
            appState.log("Transfer network selected: \(item.name) [In-App Channel]")
            return
        }

        let payChain = item.allowChain?.chainName ?? item.name
        appState.transferDomainState.selectedPayChain = payChain
        appState.transferDomainState.availablePairs = item.allowChain?.exchangePairs ?? []
        appState.transferDomainState.selectedAddressRegex = item.allowChain?.chainAddressFormatRegex ?? []
        appState.transferDomainState.selectedSellerId = nil

        if let pair = preferredTransferPair(from: item.allowChain) {
            applyTransferPair(pair)
        } else {
            appState.transferDomainState.selectedPairLabel = "\(appState.transferDomainState.selectedSendCoinName)/\(appState.transferDomainState.selectedRecvCoinName)"
        }
        appState.log("Transfer network selected: \(item.name) [Proxy Settlement]")
    }

    private func preferredTransferPair(from chain: ReceiveAllowChainItem?) -> AllowExchangePair? {
        guard let pairs = chain?.exchangePairs, !pairs.isEmpty else {
            return nil
        }
        if let usdtPair = pairs.first(where: {
            ($0.sendCoinSymbol ?? "").uppercased() == "USDT" && ($0.recvCoinSymbol ?? "").uppercased() == "USDT"
        }) {
            return usdtPair
        }
        return pairs.first
    }

    private func preferredTransferNormalCoin(from coins: [NormalAllowCoin]) -> NormalAllowCoin? {
        if let usdt = coins.first(where: {
            (($0.coinSymbol ?? "").uppercased() == "USDT") || (($0.coinName ?? "").uppercased() == "USDT")
        }) {
            return usdt
        }
        return coins.first
    }

    private func applyTransferPair(_ pair: AllowExchangePair) {
        appState.transferDomainState.selectedSendCoinCode = pair.sendCoinCode ?? appState.transferDomainState.selectedSendCoinCode
        appState.transferDomainState.selectedRecvCoinCode = pair.recvCoinCode ?? appState.transferDomainState.selectedRecvCoinCode
        appState.transferDomainState.selectedSendCoinName = pair.sendCoinName ?? pair.sendCoinSymbol ?? appState.transferDomainState.selectedSendCoinName
        appState.transferDomainState.selectedRecvCoinName = pair.recvCoinName ?? pair.recvCoinSymbol ?? appState.transferDomainState.selectedRecvCoinName
        appState.transferDomainState.selectedCoinContract = pair.sendCoinContract ?? appState.transferDomainState.selectedCoinContract
        appState.transferDomainState.selectedCoinPrecision = pair.sendCoinPrecision ?? appState.transferDomainState.selectedCoinPrecision
        appState.transferDomainState.selectedCoinSymbol = pair.sendCoinSymbol ?? pair.sendCoinName ?? appState.transferDomainState.selectedCoinSymbol
        let left = pair.sendCoinSymbol ?? pair.sendCoinName ?? appState.transferDomainState.selectedSendCoinName
        let right = pair.recvCoinSymbol ?? pair.recvCoinName ?? appState.transferDomainState.selectedRecvCoinName
        appState.transferDomainState.selectedPairLabel = "\(left)/\(right)"
    }

    private func chainTotalBalance(_ pairs: [AllowExchangePair]) -> Double? {
        if pairs.isEmpty { return nil }
        var total = 0.0
        var hit = false
        for pair in pairs {
            if let number = pair.balance?.doubleValue {
                total += number
                hit = true
                continue
            }
            if let text = pair.balance?.stringValue, let value = Double(text) {
                total += value
                hit = true
            }
        }
        return hit ? total : nil
    }

    private func applyTransferNormalCoin(_ coin: NormalAllowCoin) {
        let chain = appState.transferDomainState.selectedPayChain
        let coinCode = coin.coinCode ?? appState.transferDomainState.selectedSendCoinCode
        appState.transferDomainState.selectedSendCoinCode = coinCode
        appState.transferDomainState.selectedRecvCoinCode = coinCode
        appState.transferDomainState.selectedSendCoinName = coin.coinName ?? coin.coinSymbol ?? appState.transferDomainState.selectedSendCoinName
        appState.transferDomainState.selectedRecvCoinName = coin.coinName ?? coin.coinSymbol ?? appState.transferDomainState.selectedRecvCoinName
        appState.transferDomainState.selectedCoinContract = coin.coinContract
        appState.transferDomainState.selectedCoinPrecision = coin.coinPrecision ?? appState.transferDomainState.selectedCoinPrecision
        appState.transferDomainState.selectedCoinSymbol = coin.coinSymbol ?? coin.coinName ?? appState.transferDomainState.selectedCoinSymbol
        let symbol = coin.coinSymbol ?? coin.coinName ?? "USDT"
        appState.transferDomainState.selectedPairLabel = "\(symbol)/\(symbol)"
        appState.transferDomainState.selectedPayChain = coin.chainName ?? chain
        appState.transferDomainState.selectedAddressRegex = ["^(0x|0X)?[a-fA-F0-9]{40}$"]
    }

    private func buildTransferRegex(_ rawPattern: String) -> NSRegularExpression? {
        let trimmed = rawPattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("/") && trimmed.hasSuffix("/") {
            let body = String(trimmed.dropFirst().dropLast())
            return try? NSRegularExpression(pattern: body, options: [])
        }
        return try? NSRegularExpression(pattern: trimmed, options: [])
    }

    private func resolveTransferOrderSN(_ result: CreatePaymentResult) async throws -> String {
        let knownOrderSN = result.orderSn?.trimmingCharacters(in: .whitespacesAndNewlines)
        let serial = result.serialNumber?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let serial, !serial.isEmpty else {
            if let knownOrderSN, !knownOrderSN.isEmpty {
                return knownOrderSN
            }
            throw BackendAPIError.emptyData
        }

        for attempt in 1 ... 3 {
            if Task.isCancelled {
                throw CancellationError()
            }
            try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
            if Task.isCancelled {
                throw CancellationError()
            }
            let detail = try await appState.backend.order.receivingShow(orderSN: serial)
            if detail.status == 1 {
                if let resolved = detail.orderSn, !resolved.isEmpty {
                    return resolved
                }
                if let knownOrderSN, !knownOrderSN.isEmpty {
                    return knownOrderSN
                }
            }
        }

        if let knownOrderSN, !knownOrderSN.isEmpty {
            return knownOrderSN
        }
        throw BackendAPIError.serverError(code: 0, message: "transfer order not ready")
    }

    private struct TransferExecutionContext {
        let mode: TransferPayMode
        let orderSN: String?
        let recipientAddress: String
        let amountText: String
        let tokenContract: String
        let coinPrecision: Int
        let coinCode: String
        let chainName: String
    }

    private func buildTransferExecutionContext() throws -> TransferExecutionContext {
        let trimmedAddress = appState.transferDraft.recipientAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidTransferAddress(trimmedAddress) else {
            throw BackendAPIError.serverError(code: 0, message: "invalid recipient")
        }

        if appState.transferDraft.mode == .proxy {
            guard let detail = appState.transferDraft.orderDetail else {
                throw BackendAPIError.serverError(code: 0, message: "order detail missing")
            }
            let recipient = resolveProxyRecipientAddress(from: detail)
            guard isValidEvmAddress(recipient) else {
                throw BackendAPIError.serverError(code: 0, message: "invalid deposit address")
            }
            let amountText = decimalString(from: detail.sendAmount) ?? appState.transferDraft.amountText
            let contract = detail.sendCoinContract ?? appState.transferDomainState.selectedCoinContract ?? ""
            guard isValidEvmAddress(contract) else {
                throw BackendAPIError.serverError(code: 0, message: "invalid token contract")
            }
            let precision = detail.sendCoinPrecision ?? appState.transferDomainState.selectedCoinPrecision
            let coinCode = detail.sendCoinCode ?? appState.transferDomainState.selectedSendCoinCode
            let chainName = detail.sendChainName ?? appState.transferDomainState.selectedPayChain
            return TransferExecutionContext(
                mode: .proxy,
                orderSN: appState.transferDraft.orderSN,
                recipientAddress: recipient,
                amountText: amountText,
                tokenContract: contract,
                coinPrecision: precision,
                coinCode: coinCode,
                chainName: chainName
            )
        }

        let contract = appState.transferDomainState.selectedCoinContract ?? ""
        guard isValidEvmAddress(contract) else {
            throw BackendAPIError.serverError(code: 0, message: "token contract missing")
        }
        return TransferExecutionContext(
            mode: .normal,
            orderSN: nil,
            recipientAddress: trimmedAddress,
            amountText: appState.transferDraft.amountText,
            tokenContract: contract,
            coinPrecision: appState.transferDomainState.selectedCoinPrecision,
            coinCode: appState.transferDomainState.selectedSendCoinCode,
            chainName: appState.transferDomainState.selectedPayChain
        )
    }

    private func resolveProxyRecipientAddress(from detail: OrderDetail) -> String {
        if detail.orderType == "PAYMENT_NORMAL", let receiveAddress = detail.receiveAddress, !receiveAddress.isEmpty {
            return receiveAddress
        }
        if let depositAddress = detail.depositAddress, !depositAddress.isEmpty {
            return depositAddress
        }
        return detail.receiveAddress ?? appState.transferDraft.recipientAddress
    }

    private func decimalString(from value: JSONValue?) -> String? {
        guard let value else { return nil }
        switch value {
        case let .string(text):
            return text
        case let .number(number):
            return NSDecimalNumber(value: number).stringValue
        case let .bool(flag):
            return flag ? "1" : "0"
        case .object, .array, .null:
            return nil
        }
    }

    private func erc20TransferData(to: String, amountMinor: String) -> String? {
        let toHex = sanitizeHexAddress(to)
        guard toHex.count == 40 else { return nil }
        let amountHex = decimalToHex(amountMinor)
        guard !amountHex.isEmpty else { return nil }

        let method = "a9059cbb"
        let paddedTo = String(repeating: "0", count: 64 - toHex.count) + toHex
        let paddedAmount = String(repeating: "0", count: max(0, 64 - amountHex.count)) + amountHex
        return "0x\(method)\(paddedTo)\(paddedAmount)"
    }

    private func sanitizeHexAddress(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("0x") || trimmed.hasPrefix("0X") {
            return String(trimmed.dropFirst(2)).lowercased()
        }
        return trimmed.lowercased()
    }

    private func decimalToHex(_ decimalString: String) -> String {
        var number = decimalString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !number.isEmpty else { return "" }
        if number == "0" { return "0" }
        guard number.allSatisfy({ $0.isNumber }) else { return "" }

        var hexDigits = ""
        while number != "0" {
            var quotient = ""
            var remainder = 0
            for character in number {
                guard let digit = character.wholeNumberValue else { return "" }
                let accumulator = remainder * 10 + digit
                let q = accumulator / 16
                remainder = accumulator % 16
                if !quotient.isEmpty || q != 0 {
                    quotient.append(String(q))
                }
            }
            let hex = String(remainder, radix: 16)
            hexDigits = hex + hexDigits
            number = quotient.isEmpty ? "0" : quotient
        }
        return hexDigits
    }

    private func toMinorUnits(amountText: String, decimals: Int) -> String {
        guard let amountDecimal = Decimal(string: amountText), amountDecimal >= 0 else {
            return "0"
        }
        var multiplier = Decimal(1)
        for _ in 0 ..< decimals {
            multiplier *= 10
        }
        let scaled = amountDecimal * multiplier
        let normalized = NSDecimalNumber(decimal: scaled)
        return normalized.stringValue.components(separatedBy: ".").first ?? "0"
    }

    private func resolveTransferChainId(for chainName: String) -> Int {
        let normalized = chainName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if let option = appState.networkOptions.first(where: { $0.chainName.uppercased() == normalized }) {
            return option.chainId
        }
        if normalized == "BTT" || normalized.contains("BITTORRENT") {
            return 199
        }
        if normalized == "BTT_TEST" || normalized == "BTTTEST" || normalized.contains("BTT_TEST") || normalized.contains("TESTNET") {
            return 1029
        }
        return appState.selectedChainId
    }

    private func isValidEvmAddress(_ value: String) -> Bool {
        let pattern = "^0x[a-fA-F0-9]{40}$"
        return value.range(of: pattern, options: .regularExpression) != nil
    }

    private func transferPaymentFailureMessage(_ error: Error) -> String {
        let lowered = String(describing: error).lowercased()
        if lowered.contains("confirmation timeout") {
            return "On-chain confirmation timed out, please check the result in bills later"
        }
        if lowered.contains("execution failed") {
            return "On-chain confirmation failed"
        }
        let message = appState.simplifyError(error)
        if message == "Operation failed, please try again later" {
            return "Payment failed, please try again later"
        }
        return message
    }

    private func backendEnvValue() -> String {
        switch appState.environment.tag {
        case .development:
            return "dev"
        case .staging:
            return "test"
        case .production:
            return "prod"
        }
    }
}
