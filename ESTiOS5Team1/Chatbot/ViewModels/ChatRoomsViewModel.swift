//
//  ChatRoomsViewModel.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation
import Combine

// MARK: - Overview

/// 채팅방 목록(방 선택/편집/삭제/새 채팅)을 관리하는 ViewModel입니다.
///
/// 이 ViewModel의 책임
/// - “기본 채팅방(New Chat)”을 항상 유지하고, 필요 시 아카이브 방을 생성합니다.
/// - 방 목록 정렬/선택 상태(selectedRoomId)와 편집 모드(다중 선택/삭제)를 관리합니다.
/// - 저장/복원은 ChatSwiftDataStore(actor)에 위임하고, 여기서는 UI 상태와 정책만 다룹니다.
///
/// 연동 위치
/// - ChatRoomsView: 방 목록 UI(선택/편집/삭제) 바인딩
/// - ChatRoomViewModel: 현재 선택된 방 정보를 받아 메시지 화면을 구성
/// - ChatSwiftDataStore: 방/메시지 저장과 로드(암호화 포함)는 전부 store가 담당
///
/// @MainActor를 사용하는 이유
/// - @Published 프로퍼티가 SwiftUI와 직접 연결되므로, 상태 변경을 메인 스레드로 고정해 UI 일관성을 유지합니다.
@MainActor
final class ChatRoomsViewModel: ObservableObject {

    /// 아카이브된 채팅방 목록입니다.
    /// - defaultRoom은 별도로 관리하고, 여기에는 기본 방을 제외한 방들을 주로 담습니다.
    @Published private(set) var rooms: [ChatRoom] = []

    /// 항상 존재하는 기본 채팅방입니다.
    /// - 사용자는 “항상 같은 입력 화면에서 새 채팅 시작” UX를 가지며,
    ///   이전 대화는 필요할 때 아카이브 방으로 분리됩니다.
    @Published private(set) var defaultRoom: ChatRoom

    /// 현재 선택된 방 id입니다.
    /// - defaultRoom.identifier와 같으면 기본 방이 선택된 상태로 해석합니다.
    @Published var selectedRoomId: UUID

    /// 방 편집 모드 여부입니다.
    /// - true면 다중 선택/삭제 UI를 활성화합니다.
    @Published var isEditing: Bool = false

    /// 편집 모드에서 선택된 방들의 id 집합입니다.
    @Published var selectedRoomIds: Set<UUID> = []

    /// SwiftData 기반 저장소(actor)입니다.
    /// - SwiftData 접근/암호화(AES)/키 관리(Keychain)는 store 내부 책임입니다.
    private let store: ChatSwiftDataStore

    /// 기본 방 타이틀/정책 값입니다.
    /// - title: 기본 방은 항상 동일한 표시명을 유지합니다.
    /// - maxMessages: 기본 방이 너무 길어지면 자동 아카이브로 UX/성능을 보호합니다.
    /// - maxIdleSeconds: 마지막 메시지 이후 오래되면 새 대화로 분리해 문맥 오염을 줄입니다.
    private let defaultRoomTitle: String = "New Chat"
    private let defaultRoomMaxMessages: Int = 40
    private let defaultRoomMaxIdleSeconds: TimeInterval = 60 * 30

    /// store 주입형 초기화입니다.
    /// - ViewModel은 “저장소 구현”을 몰라도 되고, 테스트 시 다른 store로 대체 가능합니다.
    init(store: ChatSwiftDataStore) {
        self.store = store

        let createdDefaultRoom = ChatRoom(
            identifier: UUID(),
            title: defaultRoomTitle,
            isDefaultRoom: true,
            alanClientIdentifier: "ios-\(UUID().uuidString)",
            updatedAt: Date()
        )

        self.defaultRoom = createdDefaultRoom
        self.selectedRoomId = createdDefaultRoom.identifier
    }

    /// 앱 시작/화면 진입 시 저장된 방 목록을 로드합니다.
    ///
    /// 동작 요약
    /// - 저장소에 defaultRoom이 있으면 그 값을 사용(식별자/updatedAt 유지)
    /// - 없으면 현재 생성된 defaultRoom을 저장소에 저장
    /// - rooms를 최신 상태로 갱신하고, 선택된 방이 없으면 기본 방을 선택
    /// - 기본 방이 너무 커졌다면 자동 아카이브를 수행
    func load() async {
        let storedRooms = await store.loadRooms()

        if let existingDefault = storedRooms.first(where: { $0.isDefaultRoom }) {
            defaultRoom = existingDefault
        } else {
            await store.saveRooms([defaultRoom])
        }

        await refreshRooms()

        if selectedRoom() == nil {
            selectedRoomId = defaultRoom.identifier
        }

        await autoArchiveDefaultRoomIfNeeded()
    }

    /// 저장소에서 방 목록을 다시 읽어와 UI 상태를 갱신합니다.
    ///
    /// 정렬 정책
    /// - updatedAt 내림차순(최근 대화가 위)
    /// - 실제 updatedAt 갱신은 store.touchRoomUpdatedAt 또는 방 업데이트 시점에 수행됩니다.
    func refreshRooms() async {
        let storedRooms = await store.loadRooms()
        rooms = storedRooms.sorted { $0.updatedAt > $1.updatedAt }
    }

    /// 현재 선택된 방 모델을 반환합니다.
    /// - 기본 방이 선택된 경우 defaultRoom을 그대로 반환합니다.
    func selectedRoom() -> ChatRoom? {
        if defaultRoom.identifier == selectedRoomId { return defaultRoom }
        return rooms.first(where: { $0.identifier == selectedRoomId })
    }

    /// 방을 선택합니다.
    /// - ChatRoomViewModel이 이 값을 기준으로 메시지를 로드/표시하게 됩니다.
    func select(room: ChatRoom) {
        selectedRoomId = room.identifier
    }

    /// 기본 방에서 “새 채팅 시작”을 수행합니다.
    ///
    /// 핵심 정책
    /// - 기본 방에 메시지가 있으면: 해당 메시지를 새 아카이브 방으로 복사 저장
    /// - 그 다음 기본 방은 초기화: 메시지 삭제 + title/alanClientIdentifier 교체 + updatedAt 갱신
    ///
    /// alanClientIdentifier를 교체하는 이유
    /// - 서버(Alan)의 client_id가 문맥(세션) 키 역할을 하므로,
    ///   새 대화 시작 시 서버 문맥이 섞이지 않게 분리합니다.
    ///
    /// 반환값(archivedRoom)
    /// - 아카이브가 실제로 발생했을 때만 새로 만든 방을 반환합니다.
    @discardableResult
    func startNewConversation() async -> ChatRoom? {
        let defaultMessages = await store.loadMessages(roomIdentifier: defaultRoom.identifier)

        var archivedRoom: ChatRoom?

        if defaultMessages.isEmpty == false {
            let room = makeArchivedRoom(from: defaultMessages)
            archivedRoom = room

            await store.saveMessages(defaultMessages, roomIdentifier: room.identifier)

            var storedRooms = await store.loadRooms()

            if storedRooms.contains(where: { $0.identifier == defaultRoom.identifier }) == false {
                storedRooms.append(defaultRoom)
            }

            storedRooms.append(room)
            await store.saveRooms(storedRooms)
        }

        defaultRoom.title = defaultRoomTitle
        defaultRoom.alanClientIdentifier = "ios-\(UUID().uuidString)"
        defaultRoom.updatedAt = Date()

        await store.saveMessages([], roomIdentifier: defaultRoom.identifier)
        await store.touchRoomUpdatedAt(roomIdentifier: defaultRoom.identifier)

        var roomsAfterReset = await store.loadRooms()
        if let idx = roomsAfterReset.firstIndex(where: { $0.identifier == defaultRoom.identifier }) {
            roomsAfterReset[idx] = defaultRoom
        } else {
            roomsAfterReset.append(defaultRoom)
        }
        await store.saveRooms(roomsAfterReset)

        selectedRoomId = defaultRoom.identifier
        isEditing = false
        selectedRoomIds.removeAll()

        await refreshRooms()
        return archivedRoom
    }

    /// 기본 방이 너무 커졌을 때 자동으로 아카이브합니다.
    ///
    /// 사용 이유
    /// - 기본 방에 메시지가 계속 쌓이면 로딩/렌더링 비용이 증가합니다.
    /// - 대화 문맥이 너무 길어지면 분류/프롬프트 품질도 흔들릴 수 있어 상한이 필요합니다.
    private func autoArchiveDefaultRoomIfNeeded() async {
        let defaultMessages = await store.loadMessages(roomIdentifier: defaultRoom.identifier)
        guard defaultMessages.isEmpty == false else { return }

        guard defaultMessages.count >= defaultRoomMaxMessages else { return }

        let archivedRoom = makeArchivedRoom(from: defaultMessages)
        await store.saveMessages(defaultMessages, roomIdentifier: archivedRoom.identifier)

        var storedRooms = await store.loadRooms()
        storedRooms.append(archivedRoom)
        await store.saveRooms(storedRooms)

        await store.saveMessages([], roomIdentifier: defaultRoom.identifier)
        await store.touchRoomUpdatedAt(roomIdentifier: defaultRoom.identifier)

        await refreshRooms()
    }

    /// 메시지 배열로부터 아카이브 방 메타를 생성합니다.
    ///
    /// title 생성 규칙
    /// - 첫 guest 메시지를 우선 사용(사용자 입장에서 가장 의미 있는 제목)
    /// - 없으면 첫 메시지 텍스트, 그것도 없으면 빈 문자열로 폴백
    private func makeArchivedRoom(from messages: [ChatMessage]) -> ChatRoom {
        let firstGuest = messages.first(where: { $0.author == .guest })
        let candidate = (firstGuest?.text ?? messages.first?.text ?? "")
        let title = normalizeRoomTitle(candidate)

        return ChatRoom(
            identifier: UUID(),
            title: title,
            isDefaultRoom: false,
            alanClientIdentifier: "ios-\(UUID().uuidString)",
            updatedAt: Date()
        )
    }

    /// 방 제목을 UI 친화적으로 정리합니다.
    ///
    /// 정책
    /// - 공백/개행 정리 후 24자 제한
    /// - 비어 있으면 "Archived Chat"
    ///
    /// 제목을 제한하는 이유
    /// - 방 리스트에서 한 줄로 안정적으로 보여주기 위함입니다.
    private func normalizeRoomTitle(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let compact = trimmed
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        let base = compact.isEmpty ? "Archived Chat" : compact
        let maxChars = 24
        if base.count <= maxChars { return base }
        return String(base.prefix(maxChars))
    }

    /// 편집 모드를 토글합니다.
    /// - 편집 모드를 끄면 선택 집합을 비워, 다음 진입 시 상태가 섞이지 않게 합니다.
    func toggleEditing() {
        isEditing.toggle()
        if isEditing == false {
            selectedRoomIds.removeAll()
        }
    }

    /// 편집 모드에서 특정 방을 선택/해제합니다.
    func toggleSelected(room: ChatRoom) {
        if selectedRoomIds.contains(room.identifier) {
            selectedRoomIds.remove(room.identifier)
        } else {
            selectedRoomIds.insert(room.identifier)
        }
    }

    /// 단일 방을 삭제합니다.
    ///
    /// 정책
    /// - 기본 방은 삭제하지 않습니다(항상 존재해야 UI 흐름이 단순해짐).
    /// - 방 레코드 삭제 후, 해당 방 메시지도 함께 삭제합니다.
    /// - 삭제 대상이 현재 선택된 방이면 기본 방으로 선택을 되돌립니다.
    func delete(room: ChatRoom) async {
        guard room.isDefaultRoom == false else { return }

        var storedRooms = await store.loadRooms()
        storedRooms.removeAll { $0.identifier == room.identifier }
        await store.saveRooms(storedRooms)

        await store.saveMessages([], roomIdentifier: room.identifier)

        selectedRoomIds.remove(room.identifier)

        if selectedRoomId == room.identifier {
            selectedRoomId = defaultRoom.identifier
        }

        await refreshRooms()
    }

    /// 선택된 방들을 일괄 삭제합니다.
    ///
    /// 동작
    /// - rooms에서 선택된 항목 제거(기본 방 제외)
    /// - 각 방의 메시지 삭제
    /// - 현재 선택 방이 삭제 대상이면 기본 방을 선택
    /// - 편집 상태 초기화 후 목록 갱신
    func deleteSelectedRooms() async {
        guard selectedRoomIds.isEmpty == false else { return }

        var storedRooms = await store.loadRooms()
        storedRooms.removeAll { room in
            selectedRoomIds.contains(room.identifier) && room.isDefaultRoom == false
        }
        await store.saveRooms(storedRooms)

        for roomId in selectedRoomIds {
            if roomId == defaultRoom.identifier { continue }
            await store.saveMessages([], roomIdentifier: roomId)
        }

        if selectedRoomIds.contains(selectedRoomId) {
            selectedRoomId = defaultRoom.identifier
        }

        selectedRoomIds.removeAll()
        isEditing = false

        await refreshRooms()
    }

    /// 기본 방이 오래 idle 상태면 자동으로 새 대화를 시작합니다.
    ///
    /// 사용하는 이유
    /// - 장시간 후 같은 기본 방에서 이어서 질문하면 서버 문맥/사용자 의도가 섞일 수 있습니다.
    /// - idle 기준을 두면 “자연스러운 세션 분리”가 됩니다.
    func maybeArchiveDefaultRoomByIdleTime() async {
        let defaultMessages = await store.loadMessages(roomIdentifier: defaultRoom.identifier)
        guard let last = defaultMessages.last else { return }

        let idle = Date().timeIntervalSince(last.createdAt)
        guard idle >= defaultRoomMaxIdleSeconds else { return }

        await startNewConversation()
    }
}
