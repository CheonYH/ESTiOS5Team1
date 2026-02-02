//
//  ProfileView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/23/26.
//

import SwiftUI
import PhotosUI

/// 사용자 프로필 화면입니다.
///
/// - 프로필 조회/이미지 변경
/// - 닉네임 변경
/// - 선호 장르 변경
/// - 로그아웃/회원 탈퇴
/// 기능을 한 화면에서 제공합니다.
@MainActor
struct ProfileView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var toast: ToastManager
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var tabBarState: TabBarState
    @StateObject private var profileVM = ProfileViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showDeleteAlert = false
    @State private var showNickNameAlert = false
    @State private var showNicknameErrorAlert = false
    @State private var nicknameErrorMessage = ""
    @State private var newNickname = ""
    @State private var avatarURLString: String = ""
    @State private var showRoot = false
    @State private var showGenrePreferenceSheet = false

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showPhotoPicker = false
    /// 헤더 검색 버튼 탭 콜백입니다.
    let onSearchTap: () -> Void

    var body: some View {
        // 화면 크기에 따라 스타일 묶음 구성
        let style = ProfileStyle.make(isRegular: horizontalSizeClass == .regular)

        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                let maxContentWidth = min(geo.size.width * 0.94, 900)
                VStack(spacing: 0) {
                    CustomNavigationHeader(
                        title: "프로필",
                        showSearchButton: true,
                        isSearchActive: false,
                        onSearchTap: { onSearchTap() },
                        showRoot: $showRoot
                    )

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
                            onConfirmNickname: submitNicknameChange
                        )
                        .padding(.bottom, Spacing.pv10)

                        // 하단: 액션 버튼 영역
                        ProfileActionListView(
                              style: style,
                              onNicknameTap: {
                                  showNickNameAlert = true
                              },
                              onGenrePreferenceTap: {
                                  showGenrePreferenceSheet = true
                              },
                              onLogoutTap: {
                                  let event = authVM.logout(appViewModel: appViewModel)
                                  toast.show(event)
                              },
                              onDeleteTap: {
                                  showDeleteAlert = true
                              },
                              nicknameText: profileVM.nickname,
                              showNickNameAlert: $showNickNameAlert,
                              newNickname: $newNickname,
                              onConfirmNickname: submitNicknameChange
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
        .navigationDestination(isPresented: $showRoot) {
            RootTabView()
                .onAppear { tabBarState.isHidden = true }
                .onDisappear { tabBarState.isHidden = false }
        }
        .sheet(isPresented: $showGenrePreferenceSheet) {
            GenrePreferenceEditView()
                .environmentObject(toast)
        }
        .alert("", isPresented: $showNicknameErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(nicknameErrorMessage)
        }
        .onAppear { tabBarState.isHidden = false }
    }

    private func submitNicknameChange() {
        Task {
            let event = await authVM.updateNickName(to: newNickname)
            if event.status == .success {
                toast.show(event)
                profileVM.nickname = newNickname
                await profileVM.updateProfile()
                showNickNameAlert = false
            } else {
                nicknameErrorMessage = event.message
                showNicknameErrorAlert = true
            }
        }
    }
}

#Preview {
    let toast = ToastManager()
    let authVM = AuthViewModel(service: AuthServiceImpl())
    let appVM = AppViewModel(authService: AuthServiceImpl(), toast: toast)
    let tabBarState = TabBarState()
    ProfileView(onSearchTap: {})
        .environmentObject(toast)
        .environmentObject(appVM)
        .environmentObject(authVM)
        .environmentObject(tabBarState)
}
