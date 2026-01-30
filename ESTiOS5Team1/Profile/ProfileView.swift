//
//  ProfileView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/23/26.
//

import SwiftUI
import PhotosUI

@MainActor
struct ProfileView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var toast: ToastManager
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var profileVM = ProfileViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showDeleteAlert = false
    @State private var showNickNameAlert = false
    @State private var newNickname = ""
    @State private var avatarURLString: String = ""

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showPhotoPicker = false

    var body: some View {
        // 화면 크기에 따라 스타일 묶음 구성
        let style = ProfileStyle.make(isRegular: horizontalSizeClass == .regular)

        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                let maxContentWidth = min(geo.size.width * 0.94, 900)
                VStack {
                    // 상단: 아바타/닉네임/편집
                    ProfileHeaderView(
                        style: style,
                        avatarURLString: avatarURLString,
                        nicknameText: profileVM.nickname.isEmpty ? "닉네임" : profileVM.nickname,
                        showPhotoPicker: $showPhotoPicker,
                        selectedItem: $selectedItem,
                        onPhotoPicked: { newItem in
                            Task {
                                selectedImageData = try? await newItem?.loadTransferable(type: Data.self)
                                if let data = selectedImageData {
                                    let ok = await profileVM.updateAvatar(with: data)
                                    if ok {
                                        avatarURLString = profileVM.avatarUrl
                                        toast.show(FeedbackEvent(.profile, .success, "프로필 이미지 변경 완료"))
                                    } else {
                                        toast.show(FeedbackEvent(.profile, .error, profileVM.errorMessage.isEmpty ? "이미지 업로드 실패" : profileVM.errorMessage))
                                    }
                                }
                            }
                        },
                        showNickNameAlert: $showNickNameAlert,
                        newNickname: $newNickname,
                        onConfirmNickname: {
                            Task {
                                let event = await authVM.updateNickName(to: newNickname)
                                toast.show(event)
                                if event.status == .success {
                                    profileVM.nickname = newNickname
                                    await profileVM.updateProfile()
                                }
                            }
                        }
                    )

                    // 하단: 액션 버튼 영역
                    ProfileActionListView(
                        style: style,
                        onNicknameTap: {},
                        onLogoutTap: {
                            let event = authVM.logout(appViewModel: appViewModel)
                            toast.show(event)
                        },
                        onDeleteTap: {
                            showDeleteAlert = true
                        }
                    )
                    .padding(.horizontal)
                    .alert("회원 탈퇴", isPresented: $showDeleteAlert) {
                        Button("취소", role: .cancel) {}
                        Button("탈퇴하기", role: .destructive) {
                            Task {
                                let event = await authVM.deleteAccount(appViewModel: appViewModel)
                                toast.show(event)
                            }
                        }
                    } message: {
                        Text("계정이 비활성화됩니다. 정말 탈퇴하시겠어요?")
                    }
                }
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, Spacing.pv10 * 2)
                .padding(.top, style.topPadding)
            }

            if profileVM.isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView("로딩 중…")
                        .progressViewStyle(.circular)
                        .tint(.purplePrimary)
                        .foregroundStyle(.textPrimary)
                }
            }
        }
        .task {
            await profileVM.fetchProfile()
            avatarURLString = profileVM.avatarUrl
        }
    }

}

#Preview {
    let toast = ToastManager()
    let authVM = AuthViewModel(service: AuthServiceImpl())
    let appVM = AppViewModel(authService: AuthServiceImpl(), toast: toast)
    ProfileView()
        .environmentObject(toast)
        .environmentObject(appVM)
        .environmentObject(authVM)
}
