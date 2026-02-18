import Foundation

enum LoadKey: String {
    case meRoot = "me.root"
    case meMessageList = "me.message.list"
    case meMessageRead = "me.message.read"
    case meMessageReadAll = "me.message.readall"
    case meAddressbookList = "me.addressbook.list"
    case meAddressbookCreate = "me.addressbook.create"
    case meAddressbookUpdate = "me.addressbook.update"
    case meAddressbookDelete = "me.addressbook.delete"
    case meBillList = "me.bill.list"
    case meBillStat = "me.bill.stat"
    case meBillAggregate = "me.bill.aggregate"
    case meProfileNickname = "me.profile.nickname"
    case meProfileAvatar = "me.profile.avatar"
    case meSettingsRates = "me.settings.rates"
    case meSettingsTransferNotify = "me.settings.transferNotify"
    case meSettingsRewardNotify = "me.settings.rewardNotify"
    case meSettingsReceiptNotify = "me.settings.receiptNotify"
    case meSettingsBackupNotify = "me.settings.backupNotify"

    case transferSelectNetwork = "transfer.selectNetwork"
    case transferAddressCandidates = "transfer.address.candidates"
    case transferPrepare = "transfer.prepare"
    case transferPay = "transfer.pay"

    case receiveSelectNetwork = "receive.selectNetwork"
    case receiveHome = "receive.home"
    case receiveDetail = "receive.detail"
    case receiveInvalid = "receive.invalid"
    case receiveMark = "receive.mark"
    case receiveChildren = "receive.children"
    case receiveShare = "receive.share"
    case receiveExpiry = "receive.expiry"
    case receiveExpiryUpdate = "receive.expiry.update"
    case receiveAddressLimit = "receive.addressLimit"
    case receiveEditAddress = "receive.editAddress"
}

enum StableRowID {
    static func make(_ candidates: String?..., fallback: String) -> String {
        make(from: candidates, fallback: fallback)
    }

    static func make(from candidates: [String?], fallback: String) -> String {
        for candidate in candidates {
            if let normalized = normalize(candidate) {
                return normalized
            }
        }
        return fallback
    }

    static func uniqued(_ seeds: [String], separator: String = "#") -> [String] {
        var counter: [String: Int] = [:]
        return seeds.map { seed in
            let next = (counter[seed] ?? 0) + 1
            counter[seed] = next
            return next == 1 ? seed : "\(seed)\(separator)\(next)"
        }
    }

    private static func normalize(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

final class PaginationGate {
    private var inFlightTokens = Set<String>()

    func begin(token: String) -> Bool {
        if inFlightTokens.contains(token) {
            return false
        }
        inFlightTokens.insert(token)
        return true
    }

    func end(token: String) {
        inFlightTokens.remove(token)
    }

    func reset() {
        inFlightTokens.removeAll()
    }
}
