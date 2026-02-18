import BackendAPI
import Foundation

@MainActor
final class ReceiveUseCase {
    private enum FlowError: Error {
        case traceOrderCreationFailed
    }

    private unowned let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadReceiveSelectNetwork() async {
        let requestedChainId = appState.selectedChainId
        let requestedGeneration = appState.networkSelectionGeneration
        appState.setLoading(LoadKey.receiveSelectNetwork, true)
        defer { appState.setLoading(LoadKey.receiveSelectNetwork, false) }

        do {
            let query = AllowListQuery(
                groupByType: 0,
                recvCoinSymbol: "USDT",
                sendCoinSymbol: "USDT",
                recvChainName: appState.selectedChainName,
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

            let normalNetworks: [ReceiveNetworkItem]
            if let normalEntry {
                normalNetworks = [
                    ReceiveNetworkItem(
                        id: "normal:\(normalEntry.chainName ?? "CPcash")",
                        name: "CPcash",
                        logoURL: normalEntry.chainLogo,
                        chainColor: normalEntry.chainColor ?? "#1677FF",
                        category: .appChannel,
                        allowChain: nil,
                        isNormalChannel: true
                    ),
                ]
            } else {
                normalNetworks = [
                    ReceiveNetworkItem(
                        id: "normal:CPcash",
                        name: "CPcash",
                        logoURL: nil,
                        chainColor: "#1677FF",
                        category: .appChannel,
                        allowChain: nil,
                        isNormalChannel: true
                    ),
                ]
            }

            let proxyNetworks = cpList.map { item in
                ReceiveNetworkItem(
                    id: "proxy:\(item.chainName ?? appState.idGenerator.makeID())",
                    name: item.chainName ?? "-",
                    logoURL: item.chainLogo,
                    chainColor: item.chainColor ?? "#1677FF",
                    category: .proxySettlement,
                    allowChain: item,
                    isNormalChannel: false
                )
            }

            guard requestedGeneration == appState.networkSelectionGeneration,
                  requestedChainId == appState.selectedChainId
            else {
                return
            }
            appState.receiveNormalNetworks = normalNetworks
            appState.receiveProxyNetworks = proxyNetworks
            appState.receiveSelectNetworks = normalNetworks + proxyNetworks

            if let selectedId = appState.receiveSelectedNetworkId,
               !appState.receiveSelectNetworks.contains(where: { $0.id == selectedId })
            {
                appState.receiveSelectedNetworkId = nil
            }
            if appState.receiveSelectedNetworkId == nil,
               let first = appState.receiveSelectNetworks.first
            {
                configureReceiveNetwork(first)
            }
            appState.clearError(LoadKey.receiveSelectNetwork)
        } catch {
            guard requestedGeneration == appState.networkSelectionGeneration,
                  requestedChainId == appState.selectedChainId
            else {
                return
            }
            appState.setError(LoadKey.receiveSelectNetwork, error)
            appState.receiveNormalNetworks = [
                ReceiveNetworkItem(
                    id: "normal:CPcash",
                    name: "CPcash",
                    logoURL: nil,
                    chainColor: "#1677FF",
                    category: .appChannel,
                    allowChain: nil,
                    isNormalChannel: true
                ),
            ]
            appState.receiveProxyNetworks = []
            appState.receiveSelectNetworks = appState.receiveNormalNetworks
            if let first = appState.receiveSelectNetworks.first {
                configureReceiveNetwork(first)
            }
            appState.log("收款网络加载失败: \(error)")
        }
    }

    func selectReceiveNetwork(item: ReceiveNetworkItem, preloadHome: Bool = true) async {
        configureReceiveNetwork(item)
        if !item.isNormalChannel {
            if preloadHome {
                await refreshReceivePairOptions(for: item)
            } else {
                Task { [weak self] in
                    guard let self else { return }
                    await self.refreshReceivePairOptions(for: item)
                }
            }
        }
        if preloadHome {
            await loadReceiveHome(autoCreateIfMissing: true)
        }
    }

    func selectReceivePair(sendCoinCode: String, recvCoinCode: String) async {
        guard let pair = appState.receiveDomainState.availablePairs.first(where: {
            $0.sendCoinCode == sendCoinCode && $0.recvCoinCode == recvCoinCode
        }) else {
            return
        }
        applyReceivePair(pair)
        appState.receiveDomainState.individualOrderSN = nil
        appState.receiveDomainState.businessOrderSN = nil
        appState.individualTraceOrder = nil
        appState.businessTraceOrder = nil
        appState.individualTraceDetail = nil
        appState.businessTraceDetail = nil
        await loadReceiveHome(autoCreateIfMissing: true)
    }

    func setReceiveActiveTab(_ tab: ReceiveTabMode) {
        appState.receiveDomainState.activeTab = tab
    }

    func loadReceiveHome(autoCreateIfMissing: Bool) async {
        appState.setLoading(LoadKey.receiveHome, true)
        defer { appState.setLoading(LoadKey.receiveHome, false) }

        if appState.receiveDomainState.selectedIsNormalChannel {
            appState.individualTraceOrder = nil
            appState.businessTraceOrder = nil
            appState.individualTraceDetail = nil
            appState.businessTraceDetail = nil
            appState.receiveDomainState.individualOrderSN = nil
            appState.receiveDomainState.businessOrderSN = nil
            appState.receiveDomainState.receiveMinAmount = 0
            appState.receiveDomainState.receiveMaxAmount = 0
            appState.clearError(LoadKey.receiveHome)
            return
        }

        do {
            let exchange = try await appState.backend.receive.exchangeShow(
                sendCoinCode: appState.receiveDomainState.selectedSendCoinCode,
                recvCoinCode: appState.receiveDomainState.selectedRecvCoinCode,
                rateType: 1,
                env: backendEnvValue()
            )

            appState.receiveDomainState.receiveMinAmount = exchange.recvMinAmount ?? exchange.sendMinAmount ?? 10
            appState.receiveDomainState.receiveMaxAmount = exchange.recvMaxAmount ?? 0
            appState.receiveDomainState.selectedSellerId = exchange.sellerId
            appState.receiveDomainState.selectedSendCoinName = exchange.sendCoinName ?? appState.receiveDomainState.selectedSendCoinName
            appState.receiveDomainState.selectedRecvCoinName = exchange.recvCoinName ?? appState.receiveDomainState.selectedRecvCoinName

            async let individualTask = appState.backend.receive.recentValidTraces(
                page: 1,
                perPage: 20,
                orderType: "TRACE",
                sendCoinCode: appState.receiveDomainState.selectedSendCoinCode,
                recvCoinCode: appState.receiveDomainState.selectedRecvCoinCode,
                multisigWalletId: nil
            )
            async let businessTask = appState.backend.receive.recentValidTraces(
                page: 1,
                perPage: 20,
                orderType: "TRACE_LONG_TERM",
                sendCoinCode: appState.receiveDomainState.selectedSendCoinCode,
                recvCoinCode: appState.receiveDomainState.selectedRecvCoinCode,
                multisigWalletId: nil
            )
            async let invalidTask = appState.backend.receive.recentInvalidTraces(
                page: 1,
                perPage: 20,
                orderType: "TRACE",
                sendCoinCode: appState.receiveDomainState.selectedSendCoinCode,
                recvCoinCode: appState.receiveDomainState.selectedRecvCoinCode,
                multisigWalletId: nil
            )

            let individualList = try await individualTask
            let businessList = try await businessTask
            let invalidList = try await invalidTask

            appState.receiveRecentValid = individualList + businessList
            appState.receiveRecentInvalid = invalidList

            appState.individualTraceOrder = resolvePreferredOrder(from: individualList)
            appState.businessTraceOrder = resolvePreferredOrder(from: businessList)
            appState.receiveDomainState.individualOrderSN = appState.individualTraceOrder?.orderSn
            appState.receiveDomainState.businessOrderSN = appState.businessTraceOrder?.orderSn
            if appState.receiveDomainState.individualOrderSN == nil {
                appState.individualTraceDetail = nil
            }
            if appState.receiveDomainState.businessOrderSN == nil {
                appState.businessTraceDetail = nil
            }

            if appState.receiveDomainState.individualOrderSN == nil, autoCreateIfMissing {
                await createTraceOrder(isLongTerm: false, note: "", silent: true)
            } else if let orderSN = appState.receiveDomainState.activeTab == .individuals ? appState.receiveDomainState.individualOrderSN : appState.receiveDomainState.businessOrderSN {
                await refreshTraceShow(orderSN: orderSN)
            }
            appState.clearError(LoadKey.receiveHome)
        } catch {
            appState.setError(LoadKey.receiveHome, error)
            appState.log("收款主页加载失败: \(error)")
        }
    }

    func createShortTraceOrder(note: String = "") async {
        await createTraceOrder(isLongTerm: false, note: note)
    }

    func createLongTraceOrder(note: String = "") async {
        await createTraceOrder(isLongTerm: true, note: note)
    }

    func refreshTraceShow(orderSN: String) async {
        do {
            let detail = try await appState.backend.receive.traceShow(orderSN: orderSN)
            let minAmount = detail.recvMinAmount?.doubleValue ?? detail.recvAmount?.doubleValue ?? 10
            let maxAmount = detail.recvMaxAmount?.doubleValue ?? 0
            appState.receiveDomainState.receiveMinAmount = minAmount
            appState.receiveDomainState.receiveMaxAmount = maxAmount
            if appState.receiveDomainState.individualOrderSN == orderSN {
                appState.individualTraceDetail = detail
            }
            if appState.receiveDomainState.businessOrderSN == orderSN {
                appState.businessTraceDetail = detail
            }
            if appState.receiveDomainState.activeTab == .individuals,
               appState.receiveDomainState.individualOrderSN == nil
            {
                appState.individualTraceDetail = detail
            }
            if appState.receiveDomainState.activeTab == .business,
               appState.receiveDomainState.businessOrderSN == nil
            {
                appState.businessTraceDetail = detail
            }
            appState.clearError(LoadKey.receiveDetail)
        } catch {
            appState.setError(LoadKey.receiveDetail, error)
            appState.log("收款详情刷新失败: \(error)")
        }
    }

    func loadReceiveAddresses(validity: ReceiveAddressValidityState) async {
        appState.receiveDomainState.validityStatus = validity
        switch validity {
        case .valid:
            await loadReceiveHome(autoCreateIfMissing: true)
        case .invalid:
            appState.setLoading(LoadKey.receiveInvalid, true)
            defer { appState.setLoading(LoadKey.receiveInvalid, false) }
            do {
                let invalidOrderType = appState.receiveDomainState.activeTab == .business ? "TRACE_LONG_TERM" : "TRACE"
                appState.receiveRecentInvalid = try await appState.backend.receive.recentInvalidTraces(
                    page: 1,
                    perPage: 50,
                    orderType: invalidOrderType,
                    sendCoinCode: appState.receiveDomainState.selectedSendCoinCode,
                    recvCoinCode: appState.receiveDomainState.selectedRecvCoinCode,
                    multisigWalletId: nil
                )
                appState.clearError(LoadKey.receiveInvalid)
            } catch {
                appState.setError(LoadKey.receiveInvalid, error)
                appState.log("失效地址加载失败: \(error)")
            }
        }
    }

    func markTraceOrder(
        orderSN: String,
        sendCoinCode: String? = nil,
        recvCoinCode: String? = nil,
        orderType: String? = nil
    ) async {
        do {
            let resolvedSendCoinCode = sendCoinCode ?? appState.receiveDomainState.selectedSendCoinCode
            let resolvedRecvCoinCode = recvCoinCode ?? appState.receiveDomainState.selectedRecvCoinCode
            let resolvedOrderType: String
            if let orderType, !orderType.isEmpty {
                resolvedOrderType = orderType
            } else {
                resolvedOrderType = appState.receiveDomainState.activeTab == .business ? "TRACE_LONG_TERM" : "TRACE"
            }
            try await appState.backend.receive.markTraceOrder(
                orderSN: orderSN,
                sendCoinCode: resolvedSendCoinCode,
                recvCoinCode: resolvedRecvCoinCode,
                orderType: resolvedOrderType
            )
            appState.showToast("已更新默认收款地址", theme: .success)
            await loadReceiveHome(autoCreateIfMissing: true)
            appState.clearError(LoadKey.receiveMark)
        } catch {
            appState.setError(LoadKey.receiveMark, error)
            appState.showToast("更新默认地址失败", theme: .error)
            appState.log("更新默认收款地址失败: \(error)")
        }
    }

    func loadReceiveTraceChildren(orderSN: String, page: Int = 1, perPage: Int = 20) async {
        appState.setLoading(LoadKey.receiveChildren, true)
        defer { appState.setLoading(LoadKey.receiveChildren, false) }
        do {
            let pageData = try await appState.backend.receive.traceChildren(orderSN: orderSN, page: page, perPage: perPage)
            appState.receiveTraceChildren = pageData.data
            appState.clearError(LoadKey.receiveChildren)
        } catch {
            appState.setError(LoadKey.receiveChildren, error)
            appState.log("收款记录加载失败: \(error)")
        }
    }

    func loadReceiveShare(orderSN: String) async {
        appState.setLoading(LoadKey.receiveShare, true)
        defer { appState.setLoading(LoadKey.receiveShare, false) }
        do {
            appState.receiveShareDetail = try await appState.backend.receive.receiveShare(orderSN: orderSN)
            appState.clearError(LoadKey.receiveShare)
        } catch {
            appState.setError(LoadKey.receiveShare, error)
            appState.log("收款分享数据加载失败: \(error)")
        }
    }

    func loadReceiveExpiryConfig() async {
        do {
            let config = try await appState.backend.settings.traceExpiryCollection()
            if !config.durations.isEmpty {
                appState.receiveExpiryConfig = config
            }
            appState.clearError(LoadKey.receiveExpiry)
        } catch {
            appState.setError(LoadKey.receiveExpiry, error)
            appState.log("收款地址有效期配置加载失败: \(error)")
        }
    }

    func updateReceiveExpiry(duration: Int) async {
        do {
            try await appState.backend.settings.updateTraceExpiryMark(duration: duration)
            appState.receiveExpiryConfig = ReceiveExpiryConfig(
                durations: appState.receiveExpiryConfig.durations,
                selectedDuration: duration
            )
            appState.showToast("有效期已更新", theme: .success)
            appState.clearError(LoadKey.receiveExpiryUpdate)
        } catch {
            appState.setError(LoadKey.receiveExpiryUpdate, error)
            appState.showToast("有效期更新失败", theme: .error)
            appState.log("收款地址有效期更新失败: \(error)")
        }
    }

    private func configureReceiveNetwork(_ item: ReceiveNetworkItem) {
        appState.receiveSelectedNetworkId = item.id
        appState.receiveDomainState.selectedNetworkName = item.name
        appState.receiveDomainState.selectedChainColor = item.chainColor
        appState.receiveDomainState.selectedIsNormalChannel = item.isNormalChannel
        appState.receiveDomainState.activeTab = .individuals
        appState.receiveDomainState.individualOrderSN = nil
        appState.receiveDomainState.businessOrderSN = nil
        appState.individualTraceOrder = nil
        appState.businessTraceOrder = nil

        if item.isNormalChannel {
            let activeChain = appState.selectedChainId == 199 ? "BTT" : "BTT_TEST"
            appState.receiveDomainState.selectedPayChain = activeChain
            appState.receiveDomainState.selectedSendCoinCode = "USDT_\(activeChain)"
            appState.receiveDomainState.selectedRecvCoinCode = "USDT_\(activeChain)"
            appState.receiveDomainState.selectedSendCoinName = "USDT"
            appState.receiveDomainState.selectedRecvCoinName = "USDT"
            appState.receiveDomainState.selectedPairLabel = "USDT/USDT"
            appState.receiveDomainState.availablePairs = []
            appState.receiveDomainState.selectedSellerId = nil
            appState.log("收款网络已选择: \(item.name) [In-App Channel]")
            return
        }

        let payChain = item.allowChain?.chainName ?? item.name
        appState.receiveDomainState.selectedPayChain = payChain
        appState.receiveDomainState.availablePairs = item.allowChain?.exchangePairs ?? []

        if let pair = preferredReceivePair(from: item.allowChain) {
            applyReceivePair(pair)
        } else {
            appState.receiveDomainState.selectedPairLabel = "\(appState.receiveDomainState.selectedSendCoinName)/\(appState.receiveDomainState.selectedRecvCoinName)"
        }
        appState.log("收款网络已选择: \(item.name) [Proxy Settlement]")
    }

    private func applyReceivePair(_ pair: AllowExchangePair) {
        appState.receiveDomainState.selectedSendCoinCode = pair.sendCoinCode ?? appState.receiveDomainState.selectedSendCoinCode
        appState.receiveDomainState.selectedRecvCoinCode = pair.recvCoinCode ?? appState.receiveDomainState.selectedRecvCoinCode
        appState.receiveDomainState.selectedSendCoinName = pair.sendCoinName ?? pair.sendCoinSymbol ?? appState.receiveDomainState.selectedSendCoinName
        appState.receiveDomainState.selectedRecvCoinName = pair.recvCoinName ?? pair.recvCoinSymbol ?? appState.receiveDomainState.selectedRecvCoinName
        let left = pair.sendCoinSymbol ?? pair.sendCoinName ?? appState.receiveDomainState.selectedSendCoinName
        let right = pair.recvCoinSymbol ?? pair.recvCoinName ?? appState.receiveDomainState.selectedRecvCoinName
        appState.receiveDomainState.selectedPairLabel = "\(left)/\(right)"
    }

    private func preferredReceivePair(from chain: ReceiveAllowChainItem?) -> AllowExchangePair? {
        guard let pairs = chain?.exchangePairs, !pairs.isEmpty else {
            return nil
        }
        return pairs.first
    }

    private func refreshReceivePairOptions(for item: ReceiveNetworkItem) async {
        let sendChainName = item.allowChain?.chainName ?? item.name
        guard !sendChainName.isEmpty else { return }

        do {
            let query = AllowListQuery(
                groupByType: 0,
                recvCoinSymbol: "USDT",
                sendCoinSymbol: "USDT",
                sendChainName: sendChainName,
                recvChainName: appState.selectedChainId == 199 ? "BTT" : "BTT_TEST",
                env: backendEnvValue()
            )
            let list = try await appState.backend.receive.cpCashAllowList(query: query)
            guard let first = list.first else { return }

            appState.receiveDomainState.availablePairs = first.exchangePairs
            appState.receiveDomainState.selectedPayChain = first.chainName ?? sendChainName
            if let firstPair = first.exchangePairs.first {
                applyReceivePair(firstPair)
            }
            appState.log("收款交易对已刷新: chain=\(appState.receiveDomainState.selectedPayChain), pairs=\(first.exchangePairs.count)")
        } catch {
            appState.log("收款交易对刷新失败: \(error)")
        }
    }

    private func resolvePreferredOrder(from list: [TraceOrderItem]) -> TraceOrderItem? {
        if let marked = list.first(where: { $0.isMarked == true }) {
            return marked
        }
        return list.first
    }

    private func createTraceOrder(isLongTerm: Bool, note: String, silent: Bool = false) async {
        guard !appState.receiveDomainState.selectedIsNormalChannel else {
            if !silent {
                appState.showToast("In-App Channel 无需创建收款订单", theme: .info)
            }
            return
        }

        let sendCoinCode = appState.receiveDomainState.selectedSendCoinCode
        let recvCoinCode = appState.receiveDomainState.selectedRecvCoinCode
        let sellerId = appState.receiveDomainState.selectedSellerId ?? 100000001
        let receiveAddress: String
        do {
            receiveAddress = try resolvedReceiveAddress()
        } catch {
            appState.showToast("收款地址不可用，请重新登录后重试", theme: .error)
            appState.log("收款地址不可用: \(error)")
            return
        }
        let request = CreateTraceRequest(
            sellerId: sellerId,
            recvAddress: receiveAddress,
            sendCoinCode: sendCoinCode,
            recvCoinCode: recvCoinCode,
            recvAmount: appState.receiveDomainState.receiveMinAmount,
            note: note,
            env: backendEnvValue()
        )

        do {
            let result: CreateReceiptResult
            if isLongTerm {
                result = try await appState.backend.receive.createLongTrace(request: request)
                appState.receiveDomainState.activeTab = .business
                appState.receiveDomainState.businessOrderSN = result.orderSn
            } else {
                result = try await appState.backend.receive.createShortTrace(request: request)
                appState.receiveDomainState.activeTab = .individuals
                appState.receiveDomainState.individualOrderSN = result.orderSn
            }
            let resolvedOrderSN = try await resolveCreatedOrderSN(result)
            appState.lastCreatedReceiveOrderSN = resolvedOrderSN ?? result.orderSn ?? result.serialNumber ?? "-"
            if let orderSN = resolvedOrderSN ?? result.orderSn {
                if isLongTerm {
                    appState.receiveDomainState.businessOrderSN = orderSN
                } else {
                    appState.receiveDomainState.individualOrderSN = orderSN
                }
                await refreshTraceShow(orderSN: orderSN)
            } else {
                throw FlowError.traceOrderCreationFailed
            }
            await loadReceiveHome(autoCreateIfMissing: false)
            if !silent {
                appState.showToast("收款地址创建成功", theme: .success)
            }
        } catch {
            if case let BackendAPIError.serverError(code, _) = error, code == 60018 {
                appState.showToast("当前收款地址数量已达上限", theme: .error)
                appState.log("收款地址创建失败: 命中地址数量上限")
                return
            }
            if case FlowError.traceOrderCreationFailed = error {
                if !silent {
                    appState.showToast("收款地址创建处理中，请稍后刷新", theme: .error)
                }
                appState.log("收款地址创建失败: 轮询未拿到有效订单号")
                return
            }
            if !silent {
                appState.showToast("收款地址创建失败", theme: .error)
            }
            appState.log("收款地址创建失败: \(error)")
        }
    }

    private func resolveCreatedOrderSN(_ result: CreateReceiptResult) async throws -> String? {
        if let orderSN = result.orderSn, !orderSN.isEmpty {
            return orderSN
        }
        guard let serial = result.serialNumber, !serial.isEmpty else {
            return nil
        }
        appState.receiveDomainState.isPolling = true
        defer { appState.receiveDomainState.isPolling = false }

        var attempt = 0
        while attempt < 15 {
            if Task.isCancelled {
                throw CancellationError()
            }
            let detail = try await appState.backend.order.receivingShow(orderSN: serial)
            if detail.status == 1, let orderSN = detail.orderSn, !orderSN.isEmpty {
                return orderSN
            }
            if detail.status == 2 {
                throw FlowError.traceOrderCreationFailed
            }
            attempt += 1
            try await Task.sleep(nanoseconds: 2_000_000_000)
            if Task.isCancelled {
                throw CancellationError()
            }
        }
        throw FlowError.traceOrderCreationFailed
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

    private func resolvedReceiveAddress() throws -> String {
        let cached = appState.activeAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cached.isEmpty, cached != "-" {
            return cached
        }
        let secured = try appState.securityService.activeAddress().value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !secured.isEmpty else {
            throw BackendAPIError.serverError(code: 0, message: "active address unavailable")
        }
        return secured
    }
}
