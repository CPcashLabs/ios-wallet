import BackendAPI

enum ReceiveRoute: Hashable {
    case root
    case selectNetwork
    case faq
    case addressList(validity: ReceiveAddressValidityState)
    case invalidAddress
    case editAddress(orderSN: String)
    case deleteAddress
    case expiry
    case txLogs(orderSN: String)
    case share(orderSN: String)
    case addAddress
    case editAddressName
    case rareAddress
}
