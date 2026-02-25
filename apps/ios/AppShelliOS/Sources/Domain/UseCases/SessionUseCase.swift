import BackendAPI
import CoreRuntime
import Foundation
import LocalAuthentication
import SecurityCore

@MainActor
final class SessionUseCase {
    private unowned let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func boot() {
        do {
            let address = try appState.securityService.activeAddress()
            appState.activeAddress = address.value
            refreshPasskeyAccounts()
            appState.restoreSelectedChain()
            appState.log("Wallet is ready: \(address.value)")
            appState.log("Currentbackendenvironment: \(appState.environment.tag.rawValue) -> \(appState.environment.baseURL.absoluteString)")
            let state = appState
            Task {
                await state.refreshNetworkOptions()
                await state.loadReceiveExpiryConfig()
                await state.loadTransferSelectNetwork()
            }
        } catch {
            appState.log("Wallet initialization failed: \(error)")
        }
    }

    func refreshPasskeyAccounts() {
        appState.passkeyAccounts = appState.passkeyService.accounts()
        if appState.selectedPasskeyRawId.isEmpty {
            appState.selectedPasskeyRawId = appState.passkeyAccounts.first?.rawId ?? ""
        }
    }

    func registerPasskey(displayName: String) async {
        guard beginLoginFlow() else { return }
        defer { endLoginFlow() }

        do {
            let normalizedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            let account = try await appState.passkeyService.register(displayName: normalizedName.isEmpty ? "CPCash" : normalizedName)
            let address = try appState.securityService.importAccount(EncryptedImportBlob(payload: account.privateKeyHex))
            try appState.passkeyService.updateAddress(rawId: account.rawId, address: address.value)
            refreshPasskeyAccounts()
            appState.selectedPasskeyRawId = account.rawId
            appState.activeAddress = address.value
            appState.log("Passkey RegisterSucceeded: \(account.displayName) / \(address.value)")
            try await performSignInFlow()
        } catch {
            handleLoginFailure(error)
        }
    }

    func loginWithPasskey(rawId: String?) async {
        guard beginLoginFlow() else { return }
        defer { endLoginFlow() }

        do {
            let account = try await appState.passkeyService.login(rawId: rawId)
            let importedAddress = try appState.securityService.importAccount(EncryptedImportBlob(payload: account.privateKeyHex))
            if account.address != importedAddress.value {
                try? appState.passkeyService.updateAddress(rawId: account.rawId, address: importedAddress.value)
            }
            appState.activeAddress = importedAddress.value
            appState.log("Passkey authenticationSucceeded: \(account.displayName) / \(importedAddress.value)")
            try await performSignInFlow()
        } catch {
            handleLoginFailure(error)
        }
    }

    func signOutToLogin() {
        appState.isAuthenticated = false
        appState.approvalSessionState = .locked
        appState.backend.executor.clearToken()
        appState.selectedOrderDetail = nil
        appState.activeOrderDetailRequestSN = nil
        appState.messageList = []
        appState.homeRecentMessages = []
        appState.addressBooks = []
        appState.billList = []
        appState.billAddressFilter = nil
        appState.billAddressAggList = []
        appState.receiveSelectNetworks = []
        appState.receiveNormalNetworks = []
        appState.receiveProxyNetworks = []
        appState.receiveSelectedNetworkId = nil
        appState.receiveDomainState = ReceiveDomainState()
        appState.receiveRecentValid = []
        appState.receiveRecentInvalid = []
        appState.receiveTraceChildren = []
        appState.individualTraceDetail = nil
        appState.businessTraceDetail = nil
        appState.transferSelectNetworks = []
        appState.transferNormalNetworks = []
        appState.transferProxyNetworks = []
        appState.transferSelectedNetworkId = nil
        appState.transferDomainState = TransferDomainState()
        appState.transferDraft = TransferDraft()
        appState.transferRecentContacts = []
        appState.messagePaginationGate.reset()
        appState.billPaginationGate.reset()
    }

    #if DEBUG
    func cycleEnvironmentForDebug() {
        let next: EnvironmentConfig
        switch appState.environment.tag {
        case .development:
            next = .staging
        case .staging:
            next = .production
        case .production:
            next = .development
        }
        appState.environment = next
        appState.backend = appState.backendFactory(next)
        appState.log("Debug environmentswitchDone: \(next.tag.rawValue) -> \(next.baseURL.absoluteString)")
    }
    #endif

    private func performSignInFlow() async throws {
        let address = try appState.securityService.activeAddress()
        let message = loginMessage(address: address.value)
        let source = RequestSource.system(name: "message_signature_login")

        let signature = try appState.securityService.signPersonalMessage(
            SignMessageRequest(
                source: source,
                account: address,
                message: message,
                chainId: appState.selectedChainId
            )
        )

        _ = try await appState.backend.auth.signIn(
            signature: signature.value,
            address: address.value,
            message: message
        )
        appState.log("Sign in succeeded, token updated")
        appState.isAuthenticated = true
        appState.approvalSessionState = .unlocked(lastVerifiedAt: appState.clock.now)
        appState.loginErrorKind = nil
        appState.showToast("Sign InSucceeded", theme: .success)
        await appState.refreshHomeData()
    }

    private func beginLoginFlow() -> Bool {
        let now = appState.clock.now
        if appState.loginBusy {
            appState.log("Sign Inrequestignored: Currentrequest is still running")
            return false
        }
        if let cooldown = appState.loginCooldownUntil, now < cooldown {
            appState.log("Sign Inrequestignored: 2  secondsdebounce active")
            return false
        }
        appState.loginBusy = true
        appState.loginCooldownUntil = now.addingTimeInterval(2)
        appState.loginErrorKind = nil
        return true
    }

    private func endLoginFlow() {
        appState.loginBusy = false
    }

    private func handleLoginFailure(_ error: Error) {
        let kind = classifyLoginError(error)
        appState.loginErrorKind = kind
        appState.approvalSessionState = .locked
        appState.isAuthenticated = false
        appState.showToast(messageForLoginError(kind), theme: .error)
        appState.log("Sign InFailed[\(kind.rawValue)]: \(error)")
    }

    private func classifyLoginError(_ error: Error) -> LoginErrorKind {
        if let local = error as? LocalPasskeyError {
            switch local {
            case .biometricUnavailable, .biometricFailed, .accountNotFound:
                return .authFailed
            }
        }

        if let la = error as? LAError {
            switch la.code {
            case .userCancel, .systemCancel, .appCancel, .userFallback:
                return .rejectSign
            default:
                return .authFailed
            }
        }

        if let backendError = error as? BackendAPIError {
            switch backendError {
            case .unauthorized:
                return .authFailed
            case let .serverError(code, _):
                if code == 401 {
                    return .authFailed
                }
                return .networkFailed
            case .httpStatus, .invalidURL, .invalidEnvironmentHost, .emptyData:
                return .networkFailed
            }
        }

        if error is URLError {
            return .networkFailed
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkFailed
        }

        let lowercased = String(describing: error).lowercased()
        if lowercased.contains("network") || lowercased.contains("timed out") || lowercased.contains("offline") {
            return .networkFailed
        }
        return .authFailed
    }

    private func messageForLoginError(_ kind: LoginErrorKind) -> String {
        switch kind {
        case .rejectSign:
            return "User rejected this request"
        case .authFailed:
            return "Identity verification failed"
        case .networkFailed:
            return "Network connection failed"
        }
    }

    private func loginMessage(address: String) -> String {
        let loginTime = Int(appState.clock.now.timeIntervalSince1970 * 1000)
        let payload: [String: String] = [
            "address": address,
            "login_time": String(loginTime),
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
              let text = String(data: data, encoding: .utf8)
        else {
            return "{\"address\":\"\(address)\",\"login_time\":\"\(loginTime)\"}"
        }

        return text
    }
}
