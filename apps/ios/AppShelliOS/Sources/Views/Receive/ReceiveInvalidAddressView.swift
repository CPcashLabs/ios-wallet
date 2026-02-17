import SwiftUI

struct ReceiveInvalidAddressView: View {
    @ObservedObject var state: AppState

    var body: some View {
        ReceiveAddressListView(state: state, validity: .invalid)
            .navigationTitle("无效地址")
            .navigationBarTitleDisplayMode(.inline)
    }
}
