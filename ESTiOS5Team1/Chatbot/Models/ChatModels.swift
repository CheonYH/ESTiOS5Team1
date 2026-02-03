//
//  ChatModels.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation

// MARK: - Overview

/// 채팅 기능에서 공통으로 사용하는 도메인 모델 모음입니다.
///
/// 이 파일을 따로 두는 이유
/// - ViewModel, Store, Rendering 계층이 같은 타입을 공유해야 합니다.
/// - 화면(SwiftUI)과 저장소(SwiftData) 사이에서 모델이 흔들리면, 저장 포맷/표시 로직이 분리되지 않고 엉키기 쉽습니다.
/// - Codable을 유지하면 UserDefaults/파일 저장/테스트 더블 생성 등으로 확장하기 쉽습니다.
///
/// 연동 구조에서의 위치
/// - ChatRoomViewModel: messages/room 상태로 사용합니다.
/// - ChatRoomsViewModel: 방 목록과 기본 방(defaultRoom)을 관리합니다.
/// - ChatSwiftDataStore: 이 모델을 레코드 형태로 변환해 저장합니다.
/// - MessageGate/TextClassifierAdapter: 입력 분류 결과를 아래 Label 타입으로 표준화합니다.

/// 메시지 작성자 구분입니다.
///
/// 사용 목적
/// - UI: 말풍선 좌/우 정렬, 배경 스타일, 아바타 표시를 결정합니다.
/// - 저장: enum rawValue를 저장하면 마이그레이션이 단순해지고, 디코딩 실패 위험이 줄어듭니다.
///
/// 연동 포인트
/// - ChatMessage.author로 사용됩니다.
/// - ChatMessageRendering에서 author에 따라 말풍선 모양과 정렬이 갈립니다.
/// - ChatSwiftDataStore에서 authorRaw(String)로 직렬화될 수 있습니다.
enum ChatAuthor: String, Codable, Hashable {
    case guest
    case bot
}

/// 단일 채팅 메시지 모델입니다.
///
/// 설계 이유
/// - Identifiable: SwiftUI ForEach에서 안정적인 diff를 위해 필요합니다.
/// - identifier를 별도로 둠: 저장/복원 시 동일 id를 유지해야 스크롤 앵커/중복 렌더링 문제가 줄어듭니다.
/// - createdAt: 목록 정렬, 타임스탬프 표시, idle 판정(기본 방 자동 아카이브) 등에 사용됩니다.
///
/// 연동 구조
/// - ChatRoomViewModel.sendMessage에서 사용자의 입력/봇 응답을 메시지로 만들어 messages에 append합니다.
/// - ChatSwiftDataStore.saveMessages/loadMessages에서 영속화 대상이 됩니다.
/// - ChatMessageRendering에서 본문 전처리(TextCleaner/LinkSegmenter) 후 화면에 표시됩니다.
struct ChatMessage: Codable, Hashable, Identifiable {
    var identifier: UUID = UUID()
    var author: ChatAuthor
    var text: String
    var createdAt: Date = Date()

    /// SwiftUI에서 사용하는 식별자입니다.
    ///
    /// id를 identifier에 매핑해 둔 이유
    /// - 외부에서 identifier를 고정해 주입할 수 있어 테스트/마이그레이션에 유리합니다.
    /// - 저장 모델에서 identifier를 unique key로 쓰기 쉬워집니다.
    var id: UUID { identifier }

    init(
        identifier: UUID = UUID(),
        author: ChatAuthor,
        text: String,
        createdAt: Date = Date()
    ) {
        self.identifier = identifier
        self.author = author
        self.text = text
        self.createdAt = createdAt
    }
}

/// 채팅방(대화 스레드) 메타데이터입니다.
///
/// 이 앱의 방 구조 핵심
/// - 기본 방(default room)은 항상 존재하며, 사용자가 "새 채팅"을 누를 때 과거 메시지를 아카이브 방으로 분리합니다.
/// - 이렇게 하면 사용자 경험은 "항상 같은 입력 창에서 새 대화를 시작"하는 흐름이 되고,
///   저장된 기록은 별도 방 목록으로 관리할 수 있습니다.
///
/// alanClientIdentifier의 역할
/// - Alan API가 client_id 기준으로 대화 문맥(세션)을 유지한다는 전제에서, 방 단위로 서버 문맥을 분리하는 키입니다.
/// - 새 채팅 시작 시 alanClientIdentifier를 교체하면, 서버 측 문맥이 섞이는 문제를 원천 차단할 수 있습니다.
///
/// 연동 포인트
/// - ChatRoomsViewModel: defaultRoom/rooms 목록을 구성하고 선택 상태(selectedRoomId)를 관리합니다.
/// - ChatRoomViewModel: 현재 방(room)을 들고 메시지를 저장/로드하며, 서버 문맥 초기화 여부를 방 기준으로 판단합니다.
/// - AlanAPIClient: ask/reset-state 호출 시 client_id로 전달될 수 있습니다(프로젝트 구성에 따라 사용처가 결정됩니다).
struct ChatRoom: Codable, Hashable, Identifiable {
    var identifier: UUID
    var title: String
    var isDefaultRoom: Bool
    var alanClientIdentifier: String
    var updatedAt: Date

    /// SwiftUI에서 사용하는 식별자입니다.
    ///
    /// id를 identifier에 매핑하는 이유
    /// - 목록 화면에서 방 선택/삭제/정렬 시 안정적인 참조를 유지하기 위함입니다.
    var id: UUID { identifier }

    init(
        identifier: UUID = UUID(),
        title: String,
        isDefaultRoom: Bool = false,
        alanClientIdentifier: String = "ios-\(UUID().uuidString)",
        updatedAt: Date = Date()
    ) {
        self.identifier = identifier
        self.title = title
        self.isDefaultRoom = isDefaultRoom
        self.alanClientIdentifier = alanClientIdentifier
        self.updatedAt = updatedAt
    }
}

/// 입력이 "게임 도메인"인지 여부를 판별하기 위한 표준 라벨입니다.
///
/// 이 타입이 필요한 이유
/// - CoreML 모델이 반환하는 라벨 문자열은 모델 교체 시 변경될 수 있습니다.
/// - 앱 내부에서는 game/non_game/unknown의 세 가지로만 판단하면 되므로,
///   도메인 라벨을 고정해 두고 모델 라벨은 여기서만 매핑합니다.
///
/// 연동 포인트
/// - MessageGate: 최종 allow/block 판단을 이 라벨 기준으로 수행합니다.
/// - TextClassifierAdapter: 모델 라벨 문자열을 반환하고, 여기서 앱 표준 라벨로 변환됩니다.
enum GameDomainLabel: String, CaseIterable, Sendable {
    case game
    case nonGame = "non_game"
    case unknown

    /// CoreML 모델이 반환한 문자열 라벨을 앱 표준 라벨로 변환합니다.
    ///
    /// unknown을 별도로 두는 이유
    /// - 모델 라벨이 예상과 다르거나, 버전 변경으로 키가 바뀌었을 때 앱이 즉시 크래시하지 않게 하기 위함입니다.
    /// - 게이트 정책에서 unknown을 보수적으로 처리할 수 있습니다.
    static func fromModelLabel(_ label: String) -> GameDomainLabel {
        GameDomainLabel(rawValue: label) ?? .unknown
    }

    /// game 여부를 읽기 쉽게 표현합니다.
    ///
    /// 코드리뷰에서 조건문이 길어지는 것을 막고, 정책 변경 시 수정 포인트를 줄입니다.
    var isGame: Bool { self == .game }
    var isNonGameOrUnknown: Bool { self != .game }
}

/// 게임 질문의 "의도"를 분류하기 위한 표준 라벨입니다.
///
/// 의도 분류가 필요한 이유
/// - 같은 게임 질문이라도 공략/정보/추천은 답변 톤과 출력 포맷이 달라야 합니다.
/// - 모델에게 intent를 명시하면, 응답 품질이 안정되고 일관된 UX를 만들기 쉽습니다.
///
/// 연동 포인트
/// - ChatRoomViewModel: 입력 텍스트를 의도 분류한 뒤 ChatbotPrompts에 넘겨 프롬프트를 구성합니다.
/// - ChatbotPrompts: [Intent] 헤더에 rawValue를 넣어 서버(모델)에 명확히 지시합니다.
enum GameIntentLabel: String, CaseIterable, Sendable {
    case gameGuide = "game_guide"
    case gameInfo = "game_info"
    case gameRecommend = "game_recommend"
    case nonGame = "non_game"
    case unknown

    /// CoreML 모델이 반환한 문자열 라벨을 앱 표준 라벨로 변환합니다.
    ///
    /// intent는 응답 스타일을 좌우하므로, 매핑 실패 시 unknown으로 안전하게 떨어뜨립니다.
    static func fromModelLabel(_ label: String) -> GameIntentLabel {
        GameIntentLabel(rawValue: label) ?? .unknown
    }

    /// "게임 도메인 내부 intent"인지 판단합니다.
    ///
    /// 이 프로퍼티가 필요한 이유
    /// - 분류 결과가 non_game/unknown일 때는 보수적으로 기본 스타일로 폴백해야 합니다.
    /// - ViewModel에서 switch가 반복되는 것을 줄이고, 정책 변경 시 수정 포인트를 줄입니다.
    var isInGameDomain: Bool {
        switch self {
        case .gameGuide, .gameInfo, .gameRecommend:
            return true
        case .nonGame, .unknown:
            return false
        }
    }
}
