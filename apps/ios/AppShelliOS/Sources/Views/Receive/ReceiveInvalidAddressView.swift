import SwiftUI

struct ReceiveInvalidAddressView: View {
    @ObservedObject var receiveStore: ReceiveStore

    var body: some View {
        ReceiveAddressListView(receiveStore: receiveStore, validity: .invalid)
            .navigationTitle("无效地址")
            .navigationBarTitleDisplayMode(.inline)
    }
}
