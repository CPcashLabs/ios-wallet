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
    @ObservedObject var state: AppState

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
                state: state,
                onShortcutTap: handleShortcutTap,
                onBannerTap: { state.showInfoToast("Banner 跳转功能开发中") },
                onRecentMessageTap: {
                    pushHomeRoute(.messageCenter)
                }
            )
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .fullscreenScaffold(backgroundStyle: .globalImage, hideNavigationBar: true)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .messageCenter:
                    hideTabBar(MessageCenterView(state: state))
                case .receiveSelectNetwork:
                    hideTabBar(ReceiveSelectNetworkView(state: state) {
                        pushHomeRoute(.receiveRoot)
                    })
                case .receiveRoot:
                    hideTabBar(ReceiveHomeView(state: state) { nested in
                        pushReceiveRoute(nested)
                    })
                case .receiveFAQ:
                    hideTabBar(ReceiveFAQView())
                case let .receiveAddressList(validity):
                    hideTabBar(ReceiveAddressListView(state: state, validity: validity) { nested in
                        pushReceiveRoute(nested)
                    })
                case .receiveInvalidAddress:
                    hideTabBar(ReceiveInvalidAddressView(state: state))
                case let .receiveEditAddress(orderSN):
                    hideTabBar(ReceiveAddressEditView(state: state, orderSN: orderSN))
                case .receiveDeleteAddress:
                    hideTabBar(ReceiveAddressDeleteView(state: state))
                case .receiveExpiry:
                    hideTabBar(ReceiveExpiryView(state: state))
                case let .receiveTxLogs(orderSN):
                    hideTabBar(ReceiveTxLogsView(state: state, orderSN: orderSN))
                case let .receiveShare(orderSN):
                    hideTabBar(ReceiveShareView(state: state, orderSN: orderSN))

                case .transferSelectNetwork:
                    hideTabBar(TransferSelectNetworkView(state: state) {
                        pushHomeRoute(.transferAddress)
                    })
                case .transferAddress:
                    hideTabBar(TransferAddressView(state: state) {
                        pushHomeRoute(.transferAmount)
                    })
                case .transferAmount:
                    hideTabBar(TransferAmountView(state: state) {
                        pushHomeRoute(.transferConfirm)
                    })
                case .transferConfirm:
                    hideTabBar(TransferConfirmView(state: state) {
                        pushHomeRoute(.transferReceipt)
                    })
                case .transferReceipt:
                    hideTabBar(TransferReceiptView(
                        state: state,
                        onDone: {
                            homePath = []
                        },
                        onViewOrder: { orderSN in
                            pushHomeRoute(.orderDetail(orderSN: orderSN))
                        }
                    ))

                case .billList:
                    hideTabBar(BillListView(
                        state: state,
                        onShowStatistics: {
                            pushHomeRoute(.billStatistics)
                        },
                        onSelectOrder: { orderSN in
                            pushHomeRoute(.orderDetail(orderSN: orderSN))
                        }
                    ))
                case .billStatistics:
                    hideTabBar(BillStatisticsView(state: state) { address in
                        state.setBillAddressFilter(address)
                        pushHomeRoute(.billList)
                    })
                case let .orderDetail(orderSN):
                    hideTabBar(OrderDetailView(state: state, orderSN: orderSN))
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
            MeView(state: state) { route in
                if route == .meRoot {
                    mePath = []
                } else {
                    pushMeRoute(route)
                }
            }
            .fullscreenScaffold(backgroundStyle: .globalImage, hideNavigationBar: true)
            .navigationDestination(for: MeRoute.self) { route in
                switch route {
                case .meRoot:
                    MeView(state: state) { nestedRoute in
                        pushMeRoute(nestedRoute)
                    }
                case .settings:
                    hideTabBar(SettingsView(state: state) { nestedRoute in
                        pushMeRoute(nestedRoute)
                    })
                case .billList:
                    hideTabBar(BillListView(state: state) {
                        pushMeRoute(.billStatistics)
                    } onSelectOrder: { orderSN in
                        pushMeRoute(.orderDetail(orderSN: orderSN))
                    })
                case .billStatistics:
                    hideTabBar(BillStatisticsView(state: state) { address in
                        state.setBillAddressFilter(address)
                        pushMeRoute(.billList)
                    })
                case let .orderDetail(orderSN):
                    hideTabBar(OrderDetailView(state: state, orderSN: orderSN))
                case .personal:
                    hideTabBar(PersonalView(state: state))
                case .addressBookList:
                    hideTabBar(AddressBookListView(state: state) { nestedRoute in
                        pushMeRoute(nestedRoute)
                    })
                case let .addressBookEdit(id):
                    hideTabBar(AddressBookEditView(state: state, editingId: id))
                case .settingUnit:
                    hideTabBar(SettingUnitView(state: state))
                case .totalAssets:
                    hideTabBar(TotalAssetsView(state: state))
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
            .fullscreenScaffold(backgroundStyle: .globalImage)
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
        }
    }

    private func handleShortcutTap(_ shortcut: HomeShortcut) {
        switch shortcut {
        case .transfer:
            state.resetTransferFlow()
            homePath = [.transferSelectNetwork]
        case .receive:
            homePath = [.receiveSelectNetwork]
        case .statistics:
            homePath = [.billStatistics]
        }
    }
}
