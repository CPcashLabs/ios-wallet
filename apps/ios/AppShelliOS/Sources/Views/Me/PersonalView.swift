import PhotosUI
import SwiftUI

struct PersonalView: View {
    @ObservedObject var meStore: MeStore
    @ObservedObject var sessionStore: SessionStore
    @ObservedObject var uiStore: UIStore

    @State private var nickname = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var uploadingAvatar = false
    @State private var avatarUploadTask: Task<Void, Never>?
    @State private var saveNicknameTask: Task<Void, Never>?

    var body: some View {
        AdaptiveReader { widthClass in
            SafeAreaScreen(backgroundStyle: .globalImage) {
                ScrollView {
                    VStack(spacing: 14) {
                        SectionCard {
                            HStack {
                                Text("头像")
                                    .font(.system(size: widthClass.bodySize + 1))
                                Spacer()

                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    avatar
                                }
                            }
                            .frame(minHeight: widthClass.metrics.listRowMinHeight)
                            .padding(.horizontal, 14)

                            Divider().padding(.leading, 14)

                            HStack {
                                Text("昵称")
                                    .font(.system(size: widthClass.bodySize + 1))
                                    .accessibilityIdentifier(A11yID.Me.personalNicknameLabel)
                                TextField("输入昵称", text: $nickname)
                                    .multilineTextAlignment(.trailing)
                                    .font(.system(size: widthClass.bodySize))
                            }
                            .frame(minHeight: widthClass.metrics.listRowMinHeight)
                            .padding(.horizontal, 14)

                            Divider().padding(.leading, 14)

                            HStack {
                                Text("地址")
                                    .font(.system(size: widthClass.bodySize + 1))
                                Spacer()
                                Text(shortAddress)
                                    .font(.system(size: widthClass.footnoteSize))
                                    .foregroundStyle(ThemeTokens.secondary)
                            }
                            .frame(minHeight: widthClass.metrics.listRowMinHeight)
                            .padding(.horizontal, 14)

                            Divider().padding(.leading, 14)

                            HStack {
                                Text("邮箱")
                                    .font(.system(size: widthClass.bodySize + 1))
                                Spacer()
                                Text(meStore.profile?.email ?? "未绑定")
                                    .font(.system(size: widthClass.footnoteSize))
                                    .foregroundStyle(ThemeTokens.secondary)
                            }
                            .frame(minHeight: widthClass.metrics.listRowMinHeight)
                            .padding(.horizontal, 14)
                        }

                        Button {
                            saveNicknameTask?.cancel()
                            saveNicknameTask = Task {
                                await meStore.updateNickname(nickname)
                            }
                        } label: {
                            Text("保存")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: widthClass.metrics.buttonHeight)
                                .background(ThemeTokens.cpPrimary, in: Capsule())
                        }
                        .buttonStyle(.pressFeedback)
                    }
                    .padding(.horizontal, widthClass.horizontalPadding)
                    .padding(.vertical, 12)
                }
                .accessibilityIdentifier(A11yID.Me.personalPage)
            }
            .navigationTitle("个人信息")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                nickname = meStore.profile?.nickname ?? ""
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                guard let newValue else { return }
                avatarUploadTask?.cancel()
                avatarUploadTask = Task {
                    uploadingAvatar = true
                    defer {
                        uploadingAvatar = false
                        selectedPhotoItem = nil
                    }
                    if let data = try? await newValue.loadTransferable(type: Data.self) {
                        guard !Task.isCancelled else { return }
                        await meStore.updateAvatar(fileData: data, fileName: "avatar.jpg", mimeType: "image/jpeg")
                    } else {
                        guard !Task.isCancelled else { return }
                        uiStore.showInfoToast("头像读取失败，请重试")
                    }
                }
            }
            .onDisappear {
                avatarUploadTask?.cancel()
                saveNicknameTask?.cancel()
            }
        }
    }

    private var avatar: some View {
        RemoteImageView(
            rawURL: meStore.profile?.avatar,
            baseURL: sessionStore.environment.baseURL,
            contentMode: .fill
        ) {
            avatarFallback
        }
        .frame(width: 38, height: 38)
        .clipShape(Circle())
        .overlay {
            if uploadingAvatar {
                ProgressView()
                    .tint(ThemeTokens.cpPrimary)
                    .frame(width: 38, height: 38)
                    .background(ThemeTokens.cardBackground.opacity(0.72))
                    .clipShape(Circle())
            }
        }
    }

    private var avatarFallback: some View {
        Circle()
            .fill(ThemeTokens.cpPrimary.opacity(0.2))
            .overlay {
                Text(String((meStore.profile?.nickname ?? "U").prefix(1)).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ThemeTokens.cpPrimary)
            }
    }

    private var shortAddress: String {
        let value = sessionStore.activeAddress
        guard value.count > 14 else { return value }
        return "\(value.prefix(8))...\(value.suffix(4))"
    }
}
