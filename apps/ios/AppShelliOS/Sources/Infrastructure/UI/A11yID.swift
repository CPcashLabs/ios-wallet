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
        static let settingsButton = "me.settings.button"
        static let billEntry = "me.entry.bill"
        static let addressBookEntry = "me.entry.addressBook"
    }
}
