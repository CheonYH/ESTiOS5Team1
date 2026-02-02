//
//  GenrePreferenceEditView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 2/2/26.
//

import SwiftUI

/// 프로필에서 선호 장르를 수정하는 화면입니다.
///
/// 온보딩에서 사용하는 `GenreSelectionView`를 재사용하며,
/// 저장 시 선호 장르 스토어 업데이트 후 갱신 알림을 발행합니다.
struct GenrePreferenceEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toast: ToastManager
    /// 사용자가 선택한 장르 상태입니다.
    @State private var selectedGenres: Set<GenreFilterType> = []

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            GenreSelectionView(
                selectedGenres: $selectedGenres,
                onComplete: saveAndClose,
                titleText: "선호 장르를 변경하세요",
                subtitleText: "최대 4개까지 선택할 수 있어요",
                emptyCompleteButtonTitle: "선택 없이 저장",
                completeButtonTitle: "저장하기"
            )

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .padding(.leading, 16)
            .padding(.top, 12)
        }
        .onAppear {
            selectedGenres = GenrePreferenceStore.load()
        }
    }

    private func saveAndClose() {
        GenrePreferenceStore.save(selectedGenres)
        GenrePreferenceStore.notifyDidChange()
        toast.show(FeedbackEvent(.profile, .success, "선호 장르가 저장되었습니다."))
        dismiss()
    }
}

#Preview {
    GenrePreferenceEditView()
        .environmentObject(ToastManager())
}
