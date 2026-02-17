import PhotosUI
import SwiftUI

struct PersonalView: View {
    @ObservedObject var state: AppState

    @State private var nickname = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var uploadingAvatar = false

    var body: some View {
        AdaptiveReader { widthClass in
            FullscreenScaffold(backgroundStyle: .globalImage) {
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
                                Text(state.meProfile?.email ?? "未绑定")
                                    .font(.system(size: widthClass.footnoteSize))
                                    .foregroundStyle(ThemeTokens.secondary)
                            }
                            .frame(minHeight: widthClass.metrics.listRowMinHeight)
                            .padding(.horizontal, 14)
                        }

                        Button {
                            Task { await state.updateNickname(nickname) }
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
            }
            .navigationTitle("个人信息")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                nickname = state.meProfile?.nickname ?? ""
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                guard let newValue else { return }
                Task {
                    uploadingAvatar = true
                    defer {
                        uploadingAvatar = false
                        selectedPhotoItem = nil
                    }
                    if let data = try? await newValue.loadTransferable(type: Data.self) {
                        await state.updateAvatar(fileData: data, fileName: "avatar.jpg", mimeType: "image/jpeg")
                    } else {
                        state.showInfoToast("头像读取失败，请重试")
                    }
                }
            }
        }
    }

    private var avatar: some View {
        Group {
            if let url = resolvedAvatarURL
            {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        avatarFallback
                    }
                }
            } else {
                avatarFallback
            }
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
                Text(String((state.meProfile?.nickname ?? "U").prefix(1)).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ThemeTokens.cpPrimary)
            }
    }

    private var shortAddress: String {
        let value = state.activeAddress
        guard value.count > 14 else { return value }
        return "\(value.prefix(8))...\(value.suffix(4))"
    }

    private var resolvedAvatarURL: URL? {
        guard let raw = state.meProfile?.avatar?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        if let absolute = URL(string: raw), absolute.scheme != nil {
            return absolute
        }
        let trimmed = raw.hasPrefix("/") ? String(raw.dropFirst()) : raw
        return state.environment.baseURL.appendingPathComponent(trimmed)
    }
}
