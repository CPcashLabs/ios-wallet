import BackendAPI
import SwiftUI

private enum HomeShellTab: Hashable {
    case home
    case me
}

enum HomeRoute: Hashable {
    case messageCenter
    case receiveSelectNetwork
    case receiveRoot
    case receiveFAQ
    case receiveAddressList(validity: ReceiveAddressValidityState)
    case receiveInvalidAddress
    case receiveEditAddress(orderSN: String)
    case receiveDeleteAddress
    case receiveExpiry
    case receiveTxLogs(orderSN: String)
    case receiveShare(orderSN: String)
    case receiveAddAddress
    case receiveEditAddressName
    case receiveRareAddress

    case transferSelectNetwork
    case transferAddress
    case transferAmount
    case transferConfirm
    case transferReceipt

    case billList
    case billStatistics
    case orderDetail(orderSN: String)
}

enum MeRoute: Hashable {
    case meRoot
    case settings
    case billList
    case billStatistics
    case orderDetail(orderSN: String)
    case personal
    case addressBookList
    case addressBookEdit(id: String?)
    case settingUnit
    case totalAssets
    case invite
    case inviteCode
    case about
    case userGuide
}

struct HomeShellView: View {
    let appStore: AppStore

    @State private var selectedTab: HomeShellTab = .home
    @StateObject private var navigationGuard = NavigationGuard()
    @State private var mePath: [MeRoute] = []
    @State private var homePath: [HomeRoute] = []

    var body: some View {
        TabView(selection: $selectedTab) {
            homeTab
                .tabItem { Label("首页", systemImage: "house.fill") }
                .tag(HomeShellTab.home)

            meTab
                .tabItem { Label("我的", systemImage: "person.fill") }
                .tag(HomeShellTab.me)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            GlobalFullscreenBackground()
        }
        .toolbarBackground(.hidden, for: .tabBar)
        .background(Color.clear)
        .sensoryFeedback(.selection, trigger: selectedTab)
        .onChange(of: selectedTab) { _, _ in
            Haptics.tabSelection()
        }
    }

    private var homeTab: some View {
        NavigationStack(path: $homePath) {
            HomeView(
                sessionStore: appStore.sessionStore,
                homeStore: appStore.homeStore,
                onShortcutTap: handleShortcutTap,
                onBannerTap: { appStore.uiStore.showInfoToast("Banner 跳转功能开发中") },
                onRecentMessageTap: {
                    pushHomeRoute(.messageCenter)
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(homePath.isEmpty ? .hidden : .visible, for: .navigationBar)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .messageCenter:
                    hideTabBar(MessageCenterView(meStore: appStore.meStore))
                case .receiveSelectNetwork:
                    hideTabBar(ReceiveSelectNetworkView(
                        sessionStore: appStore.sessionStore,
                        receiveStore: appStore.receiveStore,
                        uiStore: appStore.uiStore
                    ) {
                        pushHomeRoute(.receiveRoot)
                    })
                case .receiveRoot:
                    hideTabBar(ReceiveHomeView(receiveStore: appStore.receiveStore, uiStore: appStore.uiStore) { nested in
                        pushReceiveRoute(nested)
                    })
                case .receiveFAQ:
                    hideTabBar(ReceiveFAQView())
                case let .receiveAddressList(validity):
                    hideTabBar(ReceiveAddressListView(receiveStore: appStore.receiveStore, validity: validity) { nested in
                        pushReceiveRoute(nested)
                    })
                case .receiveInvalidAddress:
                    hideTabBar(ReceiveInvalidAddressView(receiveStore: appStore.receiveStore))
                case let .receiveEditAddress(orderSN):
                    hideTabBar(ReceiveAddressEditView(receiveStore: appStore.receiveStore, orderSN: orderSN))
                case .receiveDeleteAddress:
                    hideTabBar(ReceiveAddressDeleteView(receiveStore: appStore.receiveStore))
                case .receiveExpiry:
                    hideTabBar(ReceiveExpiryView(receiveStore: appStore.receiveStore))
                case let .receiveTxLogs(orderSN):
                    hideTabBar(ReceiveTxLogsView(receiveStore: appStore.receiveStore, orderSN: orderSN))
                case let .receiveShare(orderSN):
                    hideTabBar(ReceiveShareView(
                        sessionStore: appStore.sessionStore,
                        receiveStore: appStore.receiveStore,
                        uiStore: appStore.uiStore,
                        orderSN: orderSN
                    ))
                case .receiveAddAddress:
                    hideTabBar(AddReceiveAddressView(
                        receiveStore: appStore.receiveStore,
                        onNavigate: { pushReceiveRoute($0) }
                    ))
                case .receiveEditAddressName:
                    hideTabBar(Text("Edit Address Name")) // Placeholder
                case .receiveRareAddress:
                    hideTabBar(Text("Rare Address")) // Placeholder

                case .transferSelectNetwork:
                    hideTabBar(TransferSelectNetworkView(
                        sessionStore: appStore.sessionStore,
                        transferStore: appStore.transferStore,
                        uiStore: appStore.uiStore
                    ) {
                        pushHomeRoute(.transferAddress)
                    })
                case .transferAddress:
                    hideTabBar(TransferAddressView(transferStore: appStore.transferStore) {
                        pushHomeRoute(.transferAmount)
                    })
                case .transferAmount:
                    hideTabBar(TransferAmountView(transferStore: appStore.transferStore) {
                        pushHomeRoute(.transferConfirm)
                    })
                case .transferConfirm:
                    hideTabBar(TransferConfirmView(transferStore: appStore.transferStore) {
                        pushHomeRoute(.transferReceipt)
                    })
                case .transferReceipt:
                    hideTabBar(TransferReceiptView(
                        transferStore: appStore.transferStore,
                        onDone: {
                            homePath = []
                        },
                        onViewOrder: { orderSN in
                            pushHomeRoute(.orderDetail(orderSN: orderSN))
                        }
                    ))

                case .billList:
                    hideTabBar(BillListView(
                        meStore: appStore.meStore,
                        uiStore: appStore.uiStore,
                        onShowStatistics: {
                            pushHomeRoute(.billStatistics)
                        },
                        onSelectOrder: { orderSN in
                            pushHomeRoute(.orderDetail(orderSN: orderSN))
                        }
                    ))
                case .billStatistics:
                    hideTabBar(BillStatisticsView(meStore: appStore.meStore) { address in
                        appStore.meStore.setBillAddressFilter(address)
                        pushHomeRoute(.billList)
                    })
                case let .orderDetail(orderSN):
                    hideTabBar(OrderDetailView(meStore: appStore.meStore, uiStore: appStore.uiStore, orderSN: orderSN))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            GlobalFullscreenBackground()
        }
        .background(Color.clear)
    }

    private var meTab: some View {
        NavigationStack(path: $mePath) {
            MeView(
                sessionStore: appStore.sessionStore,
                meStore: appStore.meStore,
                uiStore: appStore.uiStore
            ) { route in
                if route == .meRoot {
                    mePath = []
                } else {
                    pushMeRoute(route)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(mePath.isEmpty ? .hidden : .visible, for: .navigationBar)
            .navigationDestination(for: MeRoute.self) { route in
                switch route {
                case .meRoot:
                    MeView(
                        sessionStore: appStore.sessionStore,
                        meStore: appStore.meStore,
                        uiStore: appStore.uiStore
                    ) { nestedRoute in
                        pushMeRoute(nestedRoute)
                    }
                case .settings:
                    hideTabBar(SettingsView(
                        meStore: appStore.meStore,
                        sessionStore: appStore.sessionStore,
                        uiStore: appStore.uiStore
                    ) { nestedRoute in
                        pushMeRoute(nestedRoute)
                    })
                case .billList:
                    hideTabBar(BillListView(meStore: appStore.meStore, uiStore: appStore.uiStore) {
                        pushMeRoute(.billStatistics)
                    } onSelectOrder: { orderSN in
                        pushMeRoute(.orderDetail(orderSN: orderSN))
                    })
                case .billStatistics:
                    hideTabBar(BillStatisticsView(meStore: appStore.meStore) { address in
                        appStore.meStore.setBillAddressFilter(address)
                        pushMeRoute(.billList)
                    })
                case let .orderDetail(orderSN):
                    hideTabBar(OrderDetailView(meStore: appStore.meStore, uiStore: appStore.uiStore, orderSN: orderSN))
                case .personal:
                    hideTabBar(PersonalView(
                        meStore: appStore.meStore,
                        sessionStore: appStore.sessionStore,
                        uiStore: appStore.uiStore
                    ))
                case .addressBookList:
                    hideTabBar(AddressBookListView(meStore: appStore.meStore) { nestedRoute in
                        pushMeRoute(nestedRoute)
                    })
                case let .addressBookEdit(id):
                    hideTabBar(AddressBookEditView(meStore: appStore.meStore, uiStore: appStore.uiStore, editingId: id))
                case .settingUnit:
                    hideTabBar(SettingUnitView(meStore: appStore.meStore))
                case .totalAssets:
                    hideTabBar(TotalAssetsView(
                        sessionStore: appStore.sessionStore,
                        homeStore: appStore.homeStore,
                        meStore: appStore.meStore
                    ))
                case .invite:
                    hideTabBar(MePlaceholderView(title: "邀请好友", description: "邀请功能在下一批次继续对齐"))
                case .inviteCode:
                    hideTabBar(MePlaceholderView(title: "邀请码", description: "邀请码功能在下一批次继续对齐"))
                case .about:
                    hideTabBar(AboutView())
                case .userGuide:
                    hideTabBar(UserGuideView())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            GlobalFullscreenBackground()
        }
        .background(Color.clear)
    }

    private func hideTabBar<Content: View>(_ content: Content) -> some View {
        content
            .toolbar(.hidden, for: .tabBar)
    }

    private func pushHomeRoute(_ route: HomeRoute) {
        guard navigationGuard.allow("home.\(route)", cooldown: 0.4) else { return }
        if homePath.last == route {
            return
        }
        homePath.append(route)
    }

    private func pushMeRoute(_ route: MeRoute) {
        guard navigationGuard.allow("me.\(route)", cooldown: 0.4) else { return }
        if mePath.last == route {
            return
        }
        mePath.append(route)
    }

    private func pushReceiveRoute(_ route: ReceiveRoute) {
        switch route {
        case .root:
            pushHomeRoute(.receiveRoot)
        case .selectNetwork:
            pushHomeRoute(.receiveSelectNetwork)
        case .faq:
            pushHomeRoute(.receiveFAQ)
        case let .addressList(validity):
            pushHomeRoute(.receiveAddressList(validity: validity))
        case .invalidAddress:
            pushHomeRoute(.receiveInvalidAddress)
        case let .editAddress(orderSN):
            pushHomeRoute(.receiveEditAddress(orderSN: orderSN))
        case .deleteAddress:
            pushHomeRoute(.receiveDeleteAddress)
        case .expiry:
            pushHomeRoute(.receiveExpiry)
        case let .txLogs(orderSN):
            pushHomeRoute(.receiveTxLogs(orderSN: orderSN))
        case let .share(orderSN):
            pushHomeRoute(.receiveShare(orderSN: orderSN))
        case .addAddress:
            pushHomeRoute(.receiveAddAddress)
        case .editAddressName:
            pushHomeRoute(.receiveEditAddressName)
        case .rareAddress:
            pushHomeRoute(.receiveRareAddress)
        }
    }

    private func handleShortcutTap(_ shortcut: HomeShortcut) {
        switch shortcut {
        case .transfer:
            appStore.transferStore.resetTransferFlow()
            homePath = [.transferSelectNetwork]
        case .receive:
            homePath = [.receiveSelectNetwork]
        case .statistics:
            homePath = [.billStatistics]
        }
    }
}
