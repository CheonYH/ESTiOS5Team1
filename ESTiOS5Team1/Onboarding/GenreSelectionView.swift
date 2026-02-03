//
//  GenreSelectionView.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/30/26.
//
//  온보딩 마지막 페이지: 관심 장르 선택 화면

import SwiftUI

// MARK: - Genre Selection View

/// 사용자가 관심 장르를 선택하는 화면입니다.
///
/// - Responsibilities:
///     - 2열 그리드 형태의 장르 목록 표시
///     - 최대 4개까지 장르 선택 가능
///     - 선택 완료 시 콜백 실행
///
/// - Parameters:
///     - selectedGenres: 선택된 장르 집합 바인딩
///     - onComplete: 완료 버튼 탭 시 실행할 클로저
///     - titleText: 화면 상단 제목 (기본값: "관심 장르를 선택하세요")
///     - subtitleText: 화면 상단 부제목 (기본값: "최대 4개까지 선택할 수 있어요")
///     - emptyCompleteButtonTitle: 선택 없이 완료 시 버튼 텍스트
///     - completeButtonTitle: 선택 완료 시 버튼 텍스트
///
/// - Note:
///     온보딩 화면 외에도 마이페이지 등에서 재사용할 수 있도록 설계되었습니다.
struct GenreSelectionView: View {
    @Binding var selectedGenres: Set<GenreFilterType>
    let onComplete: () -> Void
    let titleText: String
    let subtitleText: String
    let emptyCompleteButtonTitle: String
    let completeButtonTitle: String

    /// 선택 가능한 장르 목록 (전체 제외)
    private let availableGenres: [GenreFilterType] = GenreFilterType.allCases.filter { $0 != .all }

    /// 최대 선택 개수
    private let maxSelection = 4

    /// 2열 그리드
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(
        selectedGenres: Binding<Set<GenreFilterType>>,
        onComplete: @escaping () -> Void,
        titleText: String = "관심 장르를 선택하세요",
        subtitleText: String = "최대 4개까지 선택할 수 있어요",
        emptyCompleteButtonTitle: String = "건너뛰고 시작하기",
        completeButtonTitle: String = "시작하기"
    ) {
        self._selectedGenres = selectedGenres
        self.onComplete = onComplete
        self.titleText = titleText
        self.subtitleText = subtitleText
        self.emptyCompleteButtonTitle = emptyCompleteButtonTitle
        self.completeButtonTitle = completeButtonTitle
    }

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            headerSection

            // 장르 그리드
            ScrollView(showsIndicators: false) {
                genreGrid
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
            }

            Spacer()

            // 시작하기 버튼
            startButton
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(titleText)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(subtitleText)
                .font(.subheadline)
                .foregroundColor(.gray)

            // 선택 카운트
            HStack(spacing: 4) {
                ForEach(0..<maxSelection, id: \.self) { index in
                    Circle()
                        .fill(index < selectedGenres.count ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top, 8)
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
    }

    // MARK: - Genre Grid

    private var genreGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(availableGenres) { genre in
                GenreButton(
                    genre: genre,
                    isSelected: selectedGenres.contains(genre),
                    isDisabled: !selectedGenres.contains(genre) && selectedGenres.count >= maxSelection
                ) {
                    toggleGenre(genre)
                }
            }
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button(action: onComplete) {
            Text(selectedGenres.isEmpty ? emptyCompleteButtonTitle : completeButtonTitle)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: selectedGenres.isEmpty
                            ? [.gray, .gray.opacity(0.7)]
                            : [.purple, .purple.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 50)
    }

    // MARK: - Actions

    private func toggleGenre(_ genre: GenreFilterType) {
        withAnimation(.spring(response: 0.3)) {
            if selectedGenres.contains(genre) {
                selectedGenres.remove(genre)
            } else if selectedGenres.count < maxSelection {
                selectedGenres.insert(genre)
            }
        }
    }
}

// MARK: - Genre Button

/// 장르 선택 버튼 컴포넌트입니다.
///
/// - Parameters:
///     - genre: 표시할 장르 타입
///     - isSelected: 선택 상태 여부
///     - isDisabled: 비활성화 상태 여부 (최대 선택 개수 초과 시)
///     - action: 버튼 탭 시 실행할 클로저
struct GenreButton: View {
    let genre: GenreFilterType
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // 아이콘 (고정 너비로 텍스트 정렬 통일)
                Image(systemName: genre.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : (isDisabled ? .gray.opacity(0.5) : .purple))
                    .frame(width: 24, height: 24)

                // 장르 이름 (왼쪽 정렬, 아이콘과 독립적)
                Text(genre.displayName)
                    .font(.system(size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : (isDisabled ? .gray.opacity(0.5) : .white))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 선택 체크마크 (고정 너비로 레이아웃 안정화)
                Group {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    } else {
                        Color.clear
                    }
                }
                .frame(width: 20, height: 20)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.purple : Color.gray.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .disabled(isDisabled && !isSelected)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Preview

#Preview("Genre Selection") {
    ZStack {
        Color.black.ignoresSafeArea()
        GenreSelectionView(
            selectedGenres: .constant(Set<GenreFilterType>([.shooter, .rolePlaying])),
            onComplete: {}
        )
    }
}
