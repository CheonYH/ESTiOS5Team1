//
//  GenrePreferenceEditView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 2/2/26.
//

import SwiftUI

/// 프로필에서 선호 장르를 수정하는 시트 화면입니다.
///
/// 저장 시 `PreferenceStore`를 갱신하고 장르 변경 노티를 발행합니다.
struct GenrePreferenceEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toast: ToastManager
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

    /// 선택한 장르를 저장하고 화면을 닫습니다.
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
