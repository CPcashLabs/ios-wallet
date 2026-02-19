import Foundation

enum TestID {
    enum App {
        static let contentRoot = "app.content.root"
    }

    enum Home {
        static let shortcutTransfer = "home.shortcut.transfer"
        static let shortcutReceive = "home.shortcut.receive"
        static let shortcutStatistics = "home.shortcut.statistics"
    }

    enum Receive {
        static let networkInApp = "receive.select.network.inApp"
        static let networkProxyPrefix = "receive.select.network.proxy."
        static let drawerIndividuals = "receive.drawer.individuals"
        static let drawerBusiness = "receive.drawer.business"
        static let addressTap = "receive.card.address.tap"
        static let addressTapIndividuals = "receive.card.address.tap.individuals"
        static let addressTapBusiness = "receive.card.address.tap.business"
        static let addTitle = "receive.add.title"
        static let addHeader = "receive.add.header"
        static let addButton = "receive.add.button"
        static let invalidButton = "receive.invalid.button"
        static let addBottomBar = "receive.add.bottomBar"
        static let addEmpty = "receive.add.empty"
        static let businessRandom = "receive.business.type.random"
        static let businessRare = "receive.business.type.rare"
    }

    enum Transfer {
        static let networkNormalPrefix = "transfer.network.normal."
        static let addressInput = "transfer.address.input"
        static let addressRecentPrefix = "transfer.address.recent."
        static let addressRecentPrimary = "transfer.address.recent.0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        static let addressNext = "transfer.address.next"
        static let amountInput = "transfer.amount.input"
        static let amountNext = "transfer.amount.next"
        static let confirm = "transfer.confirm.button"
        static let receiptDone = "transfer.receipt.done"
    }

    enum Me {
        static let settings = "me.settings.button"
        static let bill = "me.entry.bill"
        static let addressBook = "me.entry.addressBook"
    }
}
