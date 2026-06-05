import SwiftUI
import PhotosUI
import UIKit

struct UserDetailView: View {
    @ObservedObject var gs = GlobalSettings.shared
    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var avatarErrorMessage: String?
    @State private var showReadingStats = false
    @State private var showRenameAlert = false
    @State private var draftDisplayName = ""

    var body: some View {
        List {
            profileHeaderSection

            Section(header: Text(localized("閱讀工具"))) {
                Button {
                    showReadingStats = true
                } label: {
                    HStack {
                        Label(localized("閱讀統計"), systemImage: "chart.bar.fill")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)
            }

            accountInfoSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(localized("個人資料"))
        .toolbarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showReadingStats) {
            AdaptiveSheetContainer(maxWidth: 760) {
                ReadingStatsView()
            }
        }
        .alert(localized("修改用戶名"), isPresented: $showRenameAlert) {
            TextField(localized("用戶名"), text: $draftDisplayName)
            Button(localized("儲存")) {
                gs.updateAccountDisplayName(draftDisplayName)
            }
            Button(localized("取消"), role: .cancel) {}
        } message: {
            Text(localized("這個名稱只會顯示在此裝置上。"))
        }
        .onChange(of: selectedAvatarItem) { _, newItem in
            Task {
                await updateAvatar(from: newItem)
            }
        }
    }

    private var profileHeaderSection: some View {
        Section {
            VStack(spacing: 16) {
                AccountAvatarView(size: 100)

                PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                    Label(localized("修改頭像"), systemImage: "photo")
                        .font(.system(size: 13, weight: .semibold))
                }

                VStack(spacing: 8) {
                    Text(gs.accountDisplayName.isEmpty ? localized("個人資料") : gs.accountDisplayName)
                        .font(.headline)

                    Text(localized("本機個人資料"))
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1))
                        .foregroundColor(.secondary)
                        .clipShape(Capsule())

                    if let avatarErrorMessage {
                        Text(avatarErrorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .listRowBackground(Color.white)
        }
    }

    private var accountInfoSection: some View {
        Section {
            Button {
                draftDisplayName = gs.accountDisplayName
                showRenameAlert = true
            } label: {
                HStack {
                    Text(localized("用戶名"))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(gs.accountDisplayName.isEmpty ? localized("未設定") : gs.accountDisplayName)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
        } header: {
            Text(localized("帳號資訊"))
        } footer: {
            Text(localized("這些資料只儲存在本機。"))
        }
    }

    @MainActor
    private func updateAvatar(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let avatarData = normalizedAvatarData(from: data) else {
                avatarErrorMessage = localized("無法讀取頭像圖片")
                return
            }
            avatarErrorMessage = nil
            gs.updateAccountAvatar(data: avatarData)
        } catch {
            avatarErrorMessage = error.localizedDescription
        }
    }

    private func normalizedAvatarData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxSide: CGFloat = 512
        let longestSide = max(image.size.width, image.size.height)
        let scale = min(1, maxSide / max(longestSide, 1))
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.85)
    }
}

struct AccountAvatarView: View {
    @ObservedObject private var gs = GlobalSettings.shared
    let size: CGFloat

    var body: some View {
        Group {
            if let data = gs.accountAvatarData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.secondary)
                    .padding(size * 0.08)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        UserDetailView()
    }
}
