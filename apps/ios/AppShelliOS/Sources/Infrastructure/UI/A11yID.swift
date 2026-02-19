import Foundation

enum A11yID {
    enum App {
        static let contentRoot = "app.content.root"
    }

    enum Shell {
        static let tabHome = "shell.tab.home"
        static let tabMe = "shell.tab.me"
    }

    enum Login {
        static let passkeyLoginButton = "login.passkey.button"
        static let registerButton = "login.register.button"
    }

    enum Home {
        static let shortcutTransfer = "home.shortcut.transfer"
        static let shortcutReceive = "home.shortcut.receive"
        static let shortcutStatistics = "home.shortcut.statistics"
        static let recentMessageButton = "home.recent.message"
    }

    enum Receive {
        static let selectNetworkInApp = "receive.select.network.inApp"
        static let selectNetworkProxyPrefix = "receive.select.network.proxy."
        static let homeMenuButton = "receive.home.menu"
        static let drawerIndividuals = "receive.drawer.individuals"
        static let drawerBusiness = "receive.drawer.business"
        static let cardAddressTap = "receive.card.address.tap"
        static let cardAddressTapIndividuals = "receive.card.address.tap.individuals"
        static let cardAddressTapBusiness = "receive.card.address.tap.business"
        static let addAddressTitle = "receive.add.title"
        static let addAddressHeader = "receive.add.header"
        static let addAddressButton = "receive.add.button"
        static let invalidAddressButton = "receive.invalid.button"
        static let addAddressBottomBar = "receive.add.bottomBar"
        static let addAddressEmpty = "receive.add.empty"
        static let addAddressSkeleton = "receive.add.skeleton"
        static let addAddressCardPrefix = "receive.add.card."
        static let addressListActionPrefix = "receive.address.action."
        static let expiryConfirmButton = "receive.expiry.confirm"
        static let businessTypeRandom = "receive.business.type.random"
        static let businessTypeRare = "receive.business.type.rare"
    }

    enum Transfer {
        static let networkNormalPrefix = "transfer.network.normal."
        static let networkProxyPrefix = "transfer.network.proxy."
        static let addressInput = "transfer.address.input"
        static let addressRecentPrefix = "transfer.address.recent."
        static let addressNextButton = "transfer.address.next"
        static let amountInput = "transfer.amount.input"
        static let amountNextButton = "transfer.amount.next"
        static let confirmButton = "transfer.confirm.button"
        static let receiptDoneButton = "transfer.receipt.done"
    }

    enum Me {
        static let personalEntry = "me.entry.personal"
        static let personalPage = "me.personal.page"
        static let personalNicknameLabel = "me.personal.nickname.label"
        static let copyAddressButton = "me.personal.copyAddress"
        static let settingsButton = "me.settings.button"
        static let billEntry = "me.entry.bill"
        static let addressBookEntry = "me.entry.addressBook"
        static let totalAssetsEntry = "me.entry.totalAssets"
        static let billMoreButton = "me.bill.more"
        static let billFilterButton = "me.bill.filter"
        static let billRowPrefix = "me.bill.row."
        static let addressBookAddButton = "me.addressBook.add"
        static let addressBookRowPrefix = "me.addressBook.row."
        static let addressBookNameInput = "me.addressBook.input.name"
        static let addressBookWalletInput = "me.addressBook.input.wallet"
        static let addressBookSaveButton = "me.addressBook.save"
        static let addressBookDeleteButton = "me.addressBook.delete"
        static let messageAllReadButton = "me.message.allRead"
        static let settingsCurrencyRow = "me.settings.row.currency"
    }

    enum OrderDetail {
        static let root = "order.detail.root"
        static let summaryCard = "order.detail.summary"
        static let transactionCard = "order.detail.transaction"
        static let addressCard = "order.detail.address"
        static let chainCard = "order.detail.chain"
        static let timeCard = "order.detail.time"
        static let empty = "order.detail.empty"
    }
}
