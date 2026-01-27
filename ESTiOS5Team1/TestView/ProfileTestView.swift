//
//  ProfileTestView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/23/26.
//

import Kingfisher
import PhotosUI
import SwiftUI

struct ProfileTestView: View {
    @StateObject private var vm = ProfileViewModel()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    var body: some View {
        VStack(spacing: 16) {
            Text("Profile Test")
                .font(.title2)

            TextField("nickname", text: $vm.nickname)
                .textFieldStyle(.roundedBorder)

            TextField("avatarUrl", text: $vm.avatarUrl)
                .textFieldStyle(.roundedBorder)

            if let url = URL(string: vm.avatarUrl), url.scheme == "https" {
                KFImage(url)
                    .placeholder {
                        ProgressView()
                            .frame(width: 120, height: 120)
                    }
                    .onFailure { error in
                        print("[KFImage] failed url=\(url) error=\(error)")
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            }

            PhotosPicker("Select Image", selection: $selectedItem, matching: .images)
                .onChange(of: selectedItem) { newItem in
                    Task {
                        selectedImageData = try? await newItem?.loadTransferable(type: Data.self)
                    }
                }

            HStack(spacing: 12) {
                Button("Create") {
                    Task { await vm.createProfile() }
                }
                Button("Get") {
                    Task { await vm.fetchProfile() }
                }
                Button("Update") {
                    Task { await vm.updateProfile() }
                }
            }

            HStack(spacing: 12) {
                Button("Presign") {
                    Task {
                        _ = await vm.presign(filename: "avatar.png", expiresIn: 900)
                    }
                }

                Button("Upload Avatar") {
                    Task {
                        await uploadSelectedImage()
                    }
                }
            }

            if let profile = vm.profile {
                Text("id: \(profile.id)")
                Text("userId: \(profile.userId)")
                Text("nickname: \(profile.nickname)")
                Text("avatarUrl: \(profile.avatarUrl)")
            }

            if !vm.errorMessage.isEmpty {
                Text(vm.errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }

    private func uploadSelectedImage() async {
        guard let data = selectedImageData else {
            vm.errorMessage = "이미지를 선택해주세요."
            return
        }

        guard let presign = await vm.presign(filename: "avatar.png", expiresIn: 900) else {
            return
        }

        let ok = await vm.uploadToPresignedUrl(presign.uploadUrl, data: data)
        guard ok else {
            vm.errorMessage = "업로드 실패"
            return
        }

        if let publicUrl = presign.publicUrl {
            print("[Upload] publicUrl=\(publicUrl)")
            vm.avatarUrl = publicUrl
        } else {
            print("[Upload] publicUrl missing in presign response")
        }
    }
}

#Preview {
    ProfileTestView()
}
