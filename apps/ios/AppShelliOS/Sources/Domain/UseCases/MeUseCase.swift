import BackendAPI
import Foundation

@MainActor
final class MeUseCase {
    private unowned let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadMeRootData() async {
        appState.setLoading(LoadKey.meRoot, true)
        defer { appState.setLoading(LoadKey.meRoot, false) }

        do {
            async let profileTask = appState.backend.auth.currentUser()
            async let messagesTask = appState.backend.message.list(page: 1, perPage: 10)
            async let ratesTask = appState.backend.settings.exchangeRateByUSD()

            let profile = try await profileTask
            let messages = try await messagesTask
            let rates = try await ratesTask
            appState.meProfile = profile
            appState.messageList = messages.data
            appState.messagePage = messages.page ?? 1
            appState.messageLastPage = appState.computeLastPage(page: messages.page, perPage: messages.perPage, total: messages.total)
            appState.exchangeRates = rates
            if let current = rates.first?.currency, !current.isEmpty {
                appState.selectedCurrency = current
            }
            appState.clearError(LoadKey.meRoot)
        } catch {
            appState.setError(LoadKey.meRoot, error)
            appState.log("我的页面基础数据加载失败: \(error)")
        }
    }

    func loadMessages(page: Int, append: Bool) async {
        let requestedPage = max(page, 1)
        let pageToken = "message.page.\(requestedPage)"
        if append {
            guard appState.messagePaginationGate.begin(token: pageToken) else { return }
        } else {
            appState.messagePaginationGate.reset()
            appState.messageRequestGeneration += 1
        }
        let generation = appState.messageRequestGeneration
        guard !appState.isLoading(LoadKey.meMessageList) else {
            if append {
                appState.messagePaginationGate.end(token: pageToken)
            }
            return
        }
        appState.setLoading(LoadKey.meMessageList, true)
        defer {
            appState.setLoading(LoadKey.meMessageList, false)
            if append {
                appState.messagePaginationGate.end(token: pageToken)
            }
        }
        do {
            let response = try await appState.backend.message.list(page: requestedPage, perPage: 10)
            guard generation == appState.messageRequestGeneration else { return }
            if append {
                appState.messageList = appState.mergeMessages(current: appState.messageList, incoming: response.data)
            } else {
                appState.messageList = response.data
            }
            appState.messagePage = response.page ?? requestedPage
            appState.messageLastPage = appState.computeLastPage(page: response.page, perPage: response.perPage, total: response.total)
            appState.clearError(LoadKey.meMessageList)
            appState.log("消息列表加载成功: page=\(appState.messagePage), count=\(appState.messageList.count)")
        } catch {
            guard generation == appState.messageRequestGeneration else { return }
            appState.setError(LoadKey.meMessageList, error)
            appState.log("消息列表加载失败: \(error)")
        }
    }

    func markMessageRead(id: String) async {
        do {
            try await appState.backend.message.markRead(id: id)
            await loadMessages(page: 1, append: false)
            appState.clearError(LoadKey.meMessageRead)
        } catch {
            appState.setError(LoadKey.meMessageRead, error)
            appState.showToast("标记已读失败", theme: .error)
            appState.log("标记消息已读失败: \(error)")
        }
    }

    func markAllMessagesRead() async {
        do {
            try await appState.backend.message.markAllRead()
            await loadMessages(page: 1, append: false)
            appState.showToast("已全部标记为已读", theme: .success)
            appState.clearError(LoadKey.meMessageReadAll)
        } catch {
            appState.setError(LoadKey.meMessageReadAll, error)
            appState.showToast("全部已读失败", theme: .error)
            appState.log("全部标记已读失败: \(error)")
        }
    }

    func loadAddressBooks() async {
        appState.setLoading(LoadKey.meAddressbookList, true)
        defer { appState.setLoading(LoadKey.meAddressbookList, false) }
        do {
            appState.addressBooks = try await appState.backend.addressBook.list()
            appState.clearError(LoadKey.meAddressbookList)
            appState.log("地址簿加载成功: \(appState.addressBooks.count)")
        } catch {
            appState.setError(LoadKey.meAddressbookList, error)
            appState.log("地址簿加载失败: \(error)")
        }
    }

    func createAddressBook(name: String, walletAddress: String, chainType: String) async -> Bool {
        do {
            try await appState.backend.addressBook.create(
                request: AddressBookUpsertRequest(name: name, walletAddress: walletAddress, chainType: chainType)
            )
            appState.showToast("地址簿添加成功", theme: .success)
            await loadAddressBooks()
            appState.clearError(LoadKey.meAddressbookCreate)
            return true
        } catch {
            appState.setError(LoadKey.meAddressbookCreate, error)
            appState.showToast("地址簿添加失败", theme: .error)
            appState.log("地址簿新增失败: \(error)")
            return false
        }
    }

    func updateAddressBook(id: String, name: String, walletAddress: String, chainType: String) async -> Bool {
        do {
            try await appState.backend.addressBook.update(
                id: id,
                request: AddressBookUpsertRequest(name: name, walletAddress: walletAddress, chainType: chainType)
            )
            appState.showToast("地址簿更新成功", theme: .success)
            await loadAddressBooks()
            appState.clearError(LoadKey.meAddressbookUpdate)
            return true
        } catch {
            appState.setError(LoadKey.meAddressbookUpdate, error)
            appState.showToast("地址簿更新失败", theme: .error)
            appState.log("地址簿更新失败: \(error)")
            return false
        }
    }

    func deleteAddressBook(id: String) async {
        do {
            try await appState.backend.addressBook.delete(id: id)
            appState.showToast("地址簿删除成功", theme: .success)
            appState.addressBooks.removeAll { "\($0.id ?? -1)" == id }
            appState.clearError(LoadKey.meAddressbookDelete)
        } catch {
            appState.setError(LoadKey.meAddressbookDelete, error)
            appState.showToast("地址簿删除失败", theme: .error)
            appState.log("地址簿删除失败: \(error)")
        }
    }

    func updateNickname(_ nickname: String) async {
        do {
            try await appState.backend.profile.update(request: ProfileUpdateRequest(nickname: nickname, avatar: nil))
            appState.meProfile = try await appState.backend.auth.currentUser()
            appState.showToast("昵称更新成功", theme: .success)
            appState.clearError(LoadKey.meProfileNickname)
        } catch {
            appState.setError(LoadKey.meProfileNickname, error)
            appState.showToast("昵称更新失败", theme: .error)
            appState.log("昵称更新失败: \(error)")
        }
    }

    func updateAvatar(fileData: Data, fileName: String, mimeType: String) async {
        appState.setLoading(LoadKey.meProfileAvatar, true)
        defer { appState.setLoading(LoadKey.meProfileAvatar, false) }
        do {
            let upload = try await appState.backend.profile.uploadAvatar(fileData: fileData, fileName: fileName, mimeType: mimeType)
            let avatarURL = upload.url?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !avatarURL.isEmpty else {
                throw BackendAPIError.serverError(code: -1, message: "头像上传失败，请重试")
            }
            try await appState.backend.profile.update(request: ProfileUpdateRequest(nickname: nil, avatar: avatarURL))
            let profile = try await appState.backend.auth.currentUser()
            appState.meProfile = profile
            appState.userProfile = profile
            appState.showToast("头像更新成功", theme: .success)
            appState.clearError(LoadKey.meProfileAvatar)
        } catch {
            appState.setError(LoadKey.meProfileAvatar, error)
            appState.showToast(appState.simplifyError(error), theme: .error)
            appState.log("头像更新失败: \(error)")
        }
    }

    func loadExchangeRates() async {
        appState.setLoading(LoadKey.meSettingsRates, true)
        defer { appState.setLoading(LoadKey.meSettingsRates, false) }
        do {
            appState.exchangeRates = try await appState.backend.settings.exchangeRateByUSD()
            let current = appState.selectedCurrency.uppercased()
            let hasCurrent = appState.exchangeRates.contains { ($0.currency ?? "").uppercased() == current }
            if !hasCurrent, let currency = appState.exchangeRates.first?.currency, !currency.isEmpty {
                appState.selectedCurrency = currency
            }
            appState.clearError(LoadKey.meSettingsRates)
        } catch {
            appState.setError(LoadKey.meSettingsRates, error)
            appState.log("汇率列表加载失败: \(error)")
        }
    }

    func saveCurrencyUnit(currency: String) {
        appState.selectedCurrency = currency
        appState.showToast("修改成功", theme: .success)
    }

    func setTransferEmailNotify(_ enable: Bool) async {
        do {
            try await appState.backend.settings.setTransferEmailNotify(enable: enable)
            appState.transferEmailNotify = enable
            appState.clearError(LoadKey.meSettingsTransferNotify)
        } catch {
            appState.setError(LoadKey.meSettingsTransferNotify, error)
            appState.showToast("转账通知更新失败", theme: .error)
        }
    }

    func setRewardEmailNotify(_ enable: Bool) async {
        do {
            try await appState.backend.settings.setRewardEmailNotify(enable: enable)
            appState.rewardEmailNotify = enable
            appState.clearError(LoadKey.meSettingsRewardNotify)
        } catch {
            appState.setError(LoadKey.meSettingsRewardNotify, error)
            appState.showToast("奖励通知更新失败", theme: .error)
        }
    }

    func setReceiptEmailNotify(_ enable: Bool) async {
        do {
            try await appState.backend.settings.setReceiptEmailNotify(enable: enable)
            appState.receiptEmailNotify = enable
            appState.clearError(LoadKey.meSettingsReceiptNotify)
        } catch {
            appState.setError(LoadKey.meSettingsReceiptNotify, error)
            appState.showToast("收据通知更新失败", theme: .error)
        }
    }

    func setBackupWalletNotify(_ enable: Bool) async {
        do {
            try await appState.backend.settings.setBackupWalletNotify(enable: enable)
            appState.backupWalletNotify = enable
            appState.clearError(LoadKey.meSettingsBackupNotify)
        } catch {
            appState.setError(LoadKey.meSettingsBackupNotify, error)
            appState.showToast("备份通知更新失败", theme: .error)
        }
    }
}
