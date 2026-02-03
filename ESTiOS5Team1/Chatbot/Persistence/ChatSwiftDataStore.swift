//
//  ChatSwiftDataStore.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/28/26.
//

import CryptoKit
import Foundation
import SwiftData

// MARK: - Overview

/// 채팅 데이터의 로컬 영속화를 담당하는 SwiftData 저장소입니다.
///
/// 이 파일의 역할
/// - 채팅방/메시지를 SwiftData로 저장하고 다시 복원합니다.
/// - 메시지 본문은 AES.GCM으로 암호화해서 저장합니다.
/// - 암호화 키는 KeychainStore를 통해 Keychain에 보관합니다.
///
/// 연동 위치
/// - ChatRoomsViewModel: 방 목록 저장/로드, 기본 방 갱신 시 사용합니다.
/// - ChatRoomViewModel: 메시지 저장/로드, 방의 updatedAt 갱신(touch) 시 사용합니다.
/// - ChatModels: ChatRoom/ChatMessage와 authorRaw 매핑에 사용됩니다.
///
/// 구현 선택 이유
/// - actor: ModelContext는 스레드 안전하지 않으므로, 저장소 접근을 단일 실행으로 직렬화합니다.
/// - sequence: 정렬을 안정적으로 유지하기 위한 저장용 인덱스입니다.
/// - 전체 교체 저장: 데이터 규모가 크지 않고, 리셋/아카이브 등으로 메시지 구성이 자주 바뀌므로 단순한 전략을 택합니다.

// MARK: - SwiftData Models

/// SwiftData에 저장되는 채팅방 레코드입니다.
///
/// 도메인 모델(ChatRoom)과 저장 모델을 분리하는 이유
/// - UI/도메인 타입을 바꾸지 않고 저장 구조만 조정할 수 있습니다.
/// - 저장소 교체(다른 DB 등) 시 영향 범위를 줄입니다.
///
/// sequence는 정렬 안정성을 위해 저장합니다.
/// - updatedAt만으로 정렬하면 같은 시각 저장에서 순서가 흔들릴 수 있습니다.
@Model
final class ChatRoomRecord {
    @Attribute(.unique) var identifier: UUID
    var title: String
    var isDefaultRoom: Bool
    var alanClientIdentifier: String
    var updatedAt: Date
    var sequence: Int

    init(identifier: UUID, title: String, isDefaultRoom: Bool, alanClientIdentifier: String, updatedAt: Date, sequence: Int) {
        self.identifier = identifier
        self.title = title
        self.isDefaultRoom = isDefaultRoom
        self.alanClientIdentifier = alanClientIdentifier
        self.updatedAt = updatedAt
        self.sequence = sequence
    }
}

/// SwiftData에 저장되는 메시지 레코드입니다.
///
/// encryptedText로 저장하는 이유
/// - 채팅에는 개인정보/계정/민감 내용이 들어갈 수 있어 평문 저장을 피합니다.
///
/// authorRaw로 저장하는 이유
/// - enum을 직접 저장하기보다 rawValue(String)로 저장하면 디코딩 실패 위험이 줄고 마이그레이션이 단순해집니다.
///
/// roomIdentifier는 메시지가 어느 방에 속하는지 식별하는 키입니다.
@Model
final class ChatMessageRecord {
    @Attribute(.unique) var identifier: UUID
    var roomIdentifier: UUID
    var authorRaw: String
    var createdAt: Date
    var encryptedText: Data
    var sequence: Int

    init(identifier: UUID, roomIdentifier: UUID, authorRaw: String, createdAt: Date, encryptedText: Data, sequence: Int) {
        self.identifier = identifier
        self.roomIdentifier = roomIdentifier
        self.authorRaw = authorRaw
        self.createdAt = createdAt
        self.encryptedText = encryptedText
        self.sequence = sequence
    }
}

// MARK: - Store Actor

/// SwiftData 접근을 단일 흐름으로 관리하는 저장소 Actor입니다.
///
/// actor로 두는 이유
/// - ModelContext는 동시 접근에 안전하지 않습니다.
/// - ViewModel이 동시에 save/load를 호출해도 데이터 경합을 막고 결과를 예측 가능하게 합니다.
///
/// MainActor.run을 쓰는 이유
/// - 스냅샷을 값 타입으로 만들어 actor 밖으로 안전하게 넘긴 다음,
///   UI가 다루는 도메인 모델 생성은 메인 스레드에서 수행해 상태 변경 흐름을 단순화합니다.
actor ChatSwiftDataStore {
    private let keychainKey = "chat_swiftdata_aes_key_v1"
    private let context: ModelContext?

    /// actor 내부에서만 쓰는 값 타입 스냅샷입니다.
    /// - SwiftData 객체를 직접 UI로 넘기지 않고, 필요한 값만 복사합니다.
    private struct RoomSnapshot: Sendable {
        let identifier: UUID; let title: String; let isDefaultRoom: Bool
        let alanClientIdentifier: String; let updatedAt: Date; let sequence: Int
    }

    /// 복호화까지 끝난 메시지를 값으로 들고 나가기 위한 스냅샷입니다.
    private struct MessageSnapshot: Sendable {
        let identifier: UUID; let authorRaw: String; let createdAt: Date; let text: String; let sequence: Int
    }

    /// SwiftData 컨테이너 초기화입니다.
    ///
    /// 실패 시 context를 nil로 두고 빈 결과를 반환합니다.
    /// - 저장소 초기화 실패가 앱 전체 크래시로 이어지지 않게 하기 위한 방어입니다.
    init() {
        do {
            let schema = Schema([ChatRoomRecord.self, ChatMessageRecord.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [config])
            self.context = ModelContext(container)
        } catch {
            print("ChatSwiftDataStore init failed: \(error)")
            self.context = nil
        }
    }

    // MARK: - Room Logic

    /// 저장된 채팅방 목록을 로드합니다.
    ///
    /// sequence 기준으로 정렬합니다.
    /// - 저장 당시의 순서를 그대로 복원하기 위함입니다.
    func loadRooms() async -> [ChatRoom] {
        guard let context = self.context else { return [] }
        do {
            var descriptor = FetchDescriptor<ChatRoomRecord>()
            descriptor.sortBy = [SortDescriptor(\.sequence, order: .forward)]
            let records = try context.fetch(descriptor)

            let snapshots = records.map {
                RoomSnapshot(identifier: $0.identifier, title: $0.title, isDefaultRoom: $0.isDefaultRoom,
                             alanClientIdentifier: $0.alanClientIdentifier, updatedAt: $0.updatedAt, sequence: $0.sequence)
            }

            return await MainActor.run {
                snapshots.map { snap in
                    ChatRoom(identifier: snap.identifier, title: snap.title, isDefaultRoom: snap.isDefaultRoom,
                             alanClientIdentifier: snap.alanClientIdentifier, updatedAt: snap.updatedAt)
                }
            }
        } catch { return [] }
    }

    /// 채팅방 목록을 저장합니다.
    ///
    /// 전체 교체 방식인 이유
    /// - 방 수가 많지 않고, 삭제/정렬/기본 방 갱신이 빈번한 구조에서 구현이 단순합니다.
    /// - 부분 업데이트로 인한 누락/중복을 피할 수 있습니다.
    func saveRooms(_ rooms: [ChatRoom]) async {
        guard let context = self.context else { return }
        do {
            let existing = try context.fetch(FetchDescriptor<ChatRoomRecord>())
            for rec in existing { context.delete(rec) }

            for (idx, room) in rooms.enumerated() {
                let rec = ChatRoomRecord(identifier: room.identifier, title: room.title, isDefaultRoom: room.isDefaultRoom,
                                         alanClientIdentifier: room.alanClientIdentifier, updatedAt: room.updatedAt, sequence: idx)
                context.insert(rec)
            }
            try context.save()
        } catch { print("saveRooms error: \(error)") }
    }

    /// 특정 방의 updatedAt을 갱신합니다.
    ///
    /// 사용 목적
    /// - 방 목록에서 "최근 대화" 정렬에 반영하기 위함입니다.
    /// - 메시지 저장 직후 호출되면 목록 UI가 기대한 대로 갱신됩니다.
    func touchRoomUpdatedAt(roomIdentifier: UUID) async {
        guard let context = self.context else { return }
        do {
            var descriptor = FetchDescriptor<ChatRoomRecord>(predicate: #Predicate { $0.identifier == roomIdentifier })
            descriptor.fetchLimit = 1
            if let room = try context.fetch(descriptor).first {
                room.updatedAt = Date()
                try context.save()
            }
        } catch { }
    }

    // MARK: - Message Logic

    /// 특정 방의 메시지를 로드합니다.
    ///
    /// 복호화 실패를 빈 문자열로 처리하는 이유
    /// - 단일 레코드 손상으로 전체 로드가 실패하는 상황을 피하기 위함입니다.
    /// - UI는 최소한 목록을 보여주고, 필요 시 로그로 원인을 추적할 수 있습니다.
    func loadMessages(roomIdentifier: UUID) async -> [ChatMessage] {
        guard let context = self.context else { return [] }
        do {
            var descriptor = FetchDescriptor<ChatMessageRecord>(predicate: #Predicate { $0.roomIdentifier == roomIdentifier })
            descriptor.sortBy = [SortDescriptor(\.sequence, order: .forward)]
            let records = try context.fetch(descriptor)

            let key = try await loadOrCreateKey()

            let snapshots = records.map { rec in
                let decryptedText = (try? decrypt(rec.encryptedText, using: key)) ?? ""
                return MessageSnapshot(identifier: rec.identifier, authorRaw: rec.authorRaw,
                                       createdAt: rec.createdAt, text: decryptedText, sequence: rec.sequence)
            }

            return await MainActor.run {
                snapshots.map { snap in
                    ChatMessage(identifier: snap.identifier,
                                author: ChatAuthor(rawValue: snap.authorRaw) ?? .guest,
                                text: snap.text,
                                createdAt: snap.createdAt)
                }
            }
        } catch { return [] }
    }

    /// 특정 방의 메시지를 저장합니다.
    ///
    /// 전체 교체 방식인 이유
    /// - 새 채팅/아카이브/삭제 등으로 메시지 배열 전체가 바뀌는 경우가 많습니다.
    /// - append-only 최적화보다, 일관된 저장 방식이 유지보수에 유리합니다.
    ///
    /// 저장 시 text는 AES.GCM으로 암호화되어 encryptedText로 기록됩니다.
    func saveMessages(_ messages: [ChatMessage], roomIdentifier: UUID) async {
        guard let context = self.context else { return }
        do {
            let existing = try context.fetch(FetchDescriptor<ChatMessageRecord>(predicate: #Predicate { $0.roomIdentifier == roomIdentifier }))
            for rec in existing { context.delete(rec) }

            let key = try await loadOrCreateKey()
            for (idx, message) in messages.enumerated() {
                let encrypted = try encrypt(message.text, using: key)
                let rec = ChatMessageRecord(identifier: message.identifier, roomIdentifier: roomIdentifier,
                                            authorRaw: message.author.rawValue, createdAt: message.createdAt,
                                            encryptedText: encrypted, sequence: idx)
                context.insert(rec)
            }
            try context.save()
        } catch { print("saveMessages error: \(error)") }
    }

    // MARK: - Encryption & Keychain (최적화 핵심 로직)

    /// 메시지 암호화에 사용할 대칭키를 로드하거나 생성합니다.
    ///
    /// Keychain을 쓰는 이유
    /// - 앱 재실행 후에도 같은 키로 복호화가 가능해야 합니다.
    /// - UserDefaults는 보안적으로 부적절하므로 키 보관에는 Keychain이 맞습니다.
    ///
    /// base64로 저장하는 이유
    /// - KeychainStore가 문자열 저장을 제공한다는 전제에서, Data를 안전하게 직렬화하기 위함입니다.
    private func loadOrCreateKey() async throws -> SymmetricKey {
        if let b64 = await MainActor.run(body: { KeychainStore.shared.read(key: keychainKey) }),
           let raw = Data(base64Encoded: b64), raw.count == 32 {
            return SymmetricKey(data: raw)
        }

        let key = SymmetricKey(size: .bits256)
        let b64 = key.withUnsafeBytes { Data($0).base64EncodedString() }
        await MainActor.run { KeychainStore.shared.save(key: keychainKey, value: b64) }
        return key
    }

    /// AES.GCM으로 문자열을 암호화합니다.
    ///
    /// combined를 저장하는 이유
    /// - nonce/tag/ciphertext가 한 덩어리로 들어 있어 저장이 단순합니다.
    private func encrypt(_ plaintext: String, using key: SymmetricKey) throws -> Data {
        let data = Data(plaintext.utf8)
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else {
            throw NSError(
                domain: "ChatSwiftDataStore",
                code: -10,
                userInfo: [NSLocalizedDescriptionKey: "Encryption failed"]
            )
        }
        return combined
    }

    /// AES.GCM combined 데이터를 복호화합니다.
    private func decrypt(_ combined: Data, using key: SymmetricKey) throws -> String {
        let box = try AES.GCM.SealedBox(combined: combined)
        let decrypted = try AES.GCM.open(box, using: key)
        guard let text = String(bytes: decrypted, encoding: .utf8) else {
            throw NSError(
                domain: "ChatSwiftDataStore",
                code: -11,
                userInfo: [NSLocalizedDescriptionKey: "Decryption produced non-UTF8 text"]
            )
        }
        return text
    }
}
