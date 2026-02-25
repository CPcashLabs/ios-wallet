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
            appState.log("MepagebasedataLoadFailed: \(error)")
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
            appState.log("MessageslistLoadSucceeded: page=\(appState.messagePage), count=\(appState.messageList.count)")
        } catch {
            guard generation == appState.messageRequestGeneration else { return }
            appState.setError(LoadKey.meMessageList, error)
            appState.log("MessageslistLoadFailed: \(error)")
        }
    }

    func markMessageRead(id: String) async {
        do {
            try await appState.backend.message.markRead(id: id)
            await loadMessages(page: 1, append: false)
            appState.clearError(LoadKey.meMessageRead)
        } catch {
            appState.setError(LoadKey.meMessageRead, error)
            appState.showToast("Failed to mark as read", theme: .error)
            appState.log("Failed to mark message as read: \(error)")
        }
    }

    func markAllMessagesRead() async {
        do {
            try await appState.backend.message.markAllRead()
            await loadMessages(page: 1, append: false)
            appState.showToast("Marked all as read", theme: .success)
            appState.clearError(LoadKey.meMessageReadAll)
        } catch {
            appState.setError(LoadKey.meMessageReadAll, error)
            appState.showToast("Mark all as readFailed", theme: .error)
            appState.log("Failed to mark all as read: \(error)")
        }
    }

    func loadAddressBooks() async {
        appState.setLoading(LoadKey.meAddressbookList, true)
        defer { appState.setLoading(LoadKey.meAddressbookList, false) }
        do {
            appState.addressBooks = try await appState.backend.addressBook.list()
            appState.clearError(LoadKey.meAddressbookList)
            appState.log("Address BookLoadSucceeded: \(appState.addressBooks.count)")
        } catch {
            appState.setError(LoadKey.meAddressbookList, error)
            appState.log("Address BookLoadFailed: \(error)")
        }
    }

    func createAddressBook(name: String, walletAddress: String, chainType: String) async -> Bool {
        do {
            try await appState.backend.addressBook.create(
                request: AddressBookUpsertRequest(name: name, walletAddress: walletAddress, chainType: chainType)
            )
            appState.showToast("Address BookAddSucceeded", theme: .success)
            await loadAddressBooks()
            appState.clearError(LoadKey.meAddressbookCreate)
            return true
        } catch {
            appState.setError(LoadKey.meAddressbookCreate, error)
            appState.showToast("Address BookAddFailed", theme: .error)
            appState.log("Failed to add address book entry: \(error)")
            return false
        }
    }

    func updateAddressBook(id: String, name: String, walletAddress: String, chainType: String) async -> Bool {
        do {
            try await appState.backend.addressBook.update(
                id: id,
                request: AddressBookUpsertRequest(name: name, walletAddress: walletAddress, chainType: chainType)
            )
            appState.showToast("Address book updated successfully", theme: .success)
            await loadAddressBooks()
            appState.clearError(LoadKey.meAddressbookUpdate)
            return true
        } catch {
            appState.setError(LoadKey.meAddressbookUpdate, error)
            appState.showToast("Address book update failed", theme: .error)
            appState.log("Address book update failed: \(error)")
            return false
        }
    }

    func deleteAddressBook(id: String) async {
        do {
            try await appState.backend.addressBook.delete(id: id)
            appState.showToast("Address BookDeleteSucceeded", theme: .success)
            appState.addressBooks.removeAll { "\($0.id ?? -1)" == id }
            appState.clearError(LoadKey.meAddressbookDelete)
        } catch {
            appState.setError(LoadKey.meAddressbookDelete, error)
            appState.showToast("Address BookDeleteFailed", theme: .error)
            appState.log("Address BookDeleteFailed: \(error)")
        }
    }

    func updateNickname(_ nickname: String) async {
        do {
            try await appState.backend.profile.update(request: ProfileUpdateRequest(nickname: nickname, avatar: nil))
            appState.meProfile = try await appState.backend.auth.currentUser()
            appState.showToast("Nickname updated successfully", theme: .success)
            appState.clearError(LoadKey.meProfileNickname)
        } catch {
            appState.setError(LoadKey.meProfileNickname, error)
            appState.showToast("Nickname update failed", theme: .error)
            appState.log("Nickname update failed: \(error)")
        }
    }

    func updateAvatar(fileData: Data, fileName: String, mimeType: String) async {
        appState.setLoading(LoadKey.meProfileAvatar, true)
        defer { appState.setLoading(LoadKey.meProfileAvatar, false) }
        do {
            let upload = try await appState.backend.profile.uploadAvatar(fileData: fileData, fileName: fileName, mimeType: mimeType)
            let avatarURL = upload.url?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !avatarURL.isEmpty else {
                throw BackendAPIError.serverError(code: -1, message: "Avatar upload failed, please retry")
            }
            try await appState.backend.profile.update(request: ProfileUpdateRequest(nickname: nil, avatar: avatarURL))
            let profile = try await appState.backend.auth.currentUser()
            appState.meProfile = profile
            appState.showToast("Avatar updated successfully", theme: .success)
            appState.clearError(LoadKey.meProfileAvatar)
        } catch {
            appState.setError(LoadKey.meProfileAvatar, error)
            appState.showToast(appState.simplifyError(error), theme: .error)
            appState.log("Avatar update failed: \(error)")
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
            appState.log("Exchange rate list load failed: \(error)")
        }
    }

    func saveCurrencyUnit(currency: String) {
        appState.selectedCurrency = currency
        appState.showToast("Updated successfully", theme: .success)
    }

    func setTransferEmailNotify(_ enable: Bool) async {
        do {
            try await appState.backend.settings.setTransferEmailNotify(enable: enable)
            appState.transferEmailNotify = enable
            appState.clearError(LoadKey.meSettingsTransferNotify)
        } catch {
            appState.setError(LoadKey.meSettingsTransferNotify, error)
            appState.showToast("Transfer notification update failed", theme: .error)
        }
    }

    func setRewardEmailNotify(_ enable: Bool) async {
        do {
            try await appState.backend.settings.setRewardEmailNotify(enable: enable)
            appState.rewardEmailNotify = enable
            appState.clearError(LoadKey.meSettingsRewardNotify)
        } catch {
            appState.setError(LoadKey.meSettingsRewardNotify, error)
            appState.showToast("Reward notification update failed", theme: .error)
        }
    }

    func setReceiptEmailNotify(_ enable: Bool) async {
        do {
            try await appState.backend.settings.setReceiptEmailNotify(enable: enable)
            appState.receiptEmailNotify = enable
            appState.clearError(LoadKey.meSettingsReceiptNotify)
        } catch {
            appState.setError(LoadKey.meSettingsReceiptNotify, error)
            appState.showToast("Receipt notification update failed", theme: .error)
        }
    }

    func setBackupWalletNotify(_ enable: Bool) async {
        do {
            try await appState.backend.settings.setBackupWalletNotify(enable: enable)
            appState.backupWalletNotify = enable
            appState.clearError(LoadKey.meSettingsBackupNotify)
        } catch {
            appState.setError(LoadKey.meSettingsBackupNotify, error)
            appState.showToast("Backup notification update failed", theme: .error)
        }
    }
}
