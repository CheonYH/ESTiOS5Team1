//
//  ChatSwiftDataStore.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/28/26.
//

//
//  ChatSwiftDataStore.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/28/26.
//

import CryptoKit
import Foundation
import SwiftData

// SwiftData에 저장되는 레코드 모델
@Model
final class ChatRoomRecord {
    @Attribute(.unique) var identifier: UUID
    var title: String
    var isDefaultRoom: Bool
    var alanClientIdentifier: String
    var updatedAt: Date
    var sequence: Int

    init(
        identifier: UUID,
        title: String,
        isDefaultRoom: Bool,
        alanClientIdentifier: String,
        updatedAt: Date,
        sequence: Int
    ) {
        self.identifier = identifier
        self.title = title
        self.isDefaultRoom = isDefaultRoom
        self.alanClientIdentifier = alanClientIdentifier
        self.updatedAt = updatedAt
        self.sequence = sequence
    }
}

@Model
final class ChatMessageRecord {
    @Attribute(.unique) var identifier: UUID
    var roomIdentifier: UUID
    var authorRaw: String
    var createdAt: Date
    var encryptedText: Data
    var sequence: Int

    init(
        identifier: UUID,
        roomIdentifier: UUID,
        authorRaw: String,
        createdAt: Date,
        encryptedText: Data,
        sequence: Int
    ) {
        self.identifier = identifier
        self.roomIdentifier = roomIdentifier
        self.authorRaw = authorRaw
        self.createdAt = createdAt
        self.encryptedText = encryptedText
        self.sequence = sequence
    }
}

actor ChatSwiftDataStore {
    // 키체인에 저장되는 AES 키 식별자(향후 로테이션을 고려해 버전 포함)
    private let keychainKey = "chat_swiftdata_aes_key_v1"

    private let context: ModelContext?

    // SwiftData 타입을 그대로 밖으로 내보내면 Sendable 관련 문제가 생길 수 있어
    // 값 타입 스냅샷으로 변환해서 반환한다.
    private struct RoomSnapshot: Sendable {
        let identifier: UUID
        let title: String
        let isDefaultRoom: Bool
        let alanClientIdentifier: String
        let updatedAt: Date
        let sequence: Int
    }

    private struct MessageSnapshot: Sendable {
        let identifier: UUID
        let authorRaw: String
        let createdAt: Date
        let text: String
        let sequence: Int
    }

    init() {
        do {
            let schema = Schema([ChatRoomRecord.self, ChatMessageRecord.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [config])
            self.context = ModelContext(container)
        } catch {
            print("ChatSwiftDataStore init failed:", error)
            self.context = nil
        }
    }

    // 채팅방 목록을 로드한다.
    func loadRooms() async -> [ChatRoom] {
        guard let context else { return [] }

        do {
            var descriptor = FetchDescriptor<ChatRoomRecord>()
            descriptor.sortBy = [SortDescriptor(\.sequence, order: .forward)]
            let records = try context.fetch(descriptor)

            let snapshots: [RoomSnapshot] = records.map {
                RoomSnapshot(
                    identifier: $0.identifier,
                    title: $0.title,
                    isDefaultRoom: $0.isDefaultRoom,
                    alanClientIdentifier: $0.alanClientIdentifier,
                    updatedAt: $0.updatedAt,
                    sequence: $0.sequence
                )
            }

            return await MainActor.run {
                snapshots
                    .sorted(by: { $0.sequence < $1.sequence })
                    .map {
                        ChatRoom(
                            identifier: $0.identifier,
                            title: $0.title,
                            isDefaultRoom: $0.isDefaultRoom,
                            alanClientIdentifier: $0.alanClientIdentifier,
                            updatedAt: $0.updatedAt
                        )
                    }
            }
        } catch {
            return []
        }
    }

    // 채팅방 목록을 통째로 저장한다(간단한 동기화 방식).
    func saveRooms(_ rooms: [ChatRoom]) async {
        guard let context else { return }

        do {
            let existing = try context.fetch(FetchDescriptor<ChatRoomRecord>())
            for rec in existing {
                context.delete(rec)
            }

            for (idx, room) in rooms.enumerated() {
                let rec = ChatRoomRecord(
                    identifier: room.identifier,
                    title: room.title,
                    isDefaultRoom: room.isDefaultRoom,
                    alanClientIdentifier: room.alanClientIdentifier,
                    updatedAt: room.updatedAt,
                    sequence: idx
                )
                context.insert(rec)
            }

            try context.save()
        } catch {
            // 저장 실패는 상위에서 UX로 처리하지 않는 정책이라면 여기서는 조용히 실패한다.
        }
    }

    // 특정 방의 메시지를 로드한다.
    func loadMessages(roomIdentifier: UUID) async -> [ChatMessage] {
        guard let context else { return [] }

        do {
            var descriptor = FetchDescriptor<ChatMessageRecord>(
                predicate: #Predicate { $0.roomIdentifier == roomIdentifier }
            )
            descriptor.sortBy = [SortDescriptor(\.sequence, order: .forward)]
            let records = try context.fetch(descriptor)

            let key = try await loadOrCreateKey()

            let snapshots: [MessageSnapshot] = records.map { rec in
                let decryptedText = (try? decrypt(rec.encryptedText, using: key)) ?? ""
                return MessageSnapshot(
                    identifier: rec.identifier,
                    authorRaw: rec.authorRaw,
                    createdAt: rec.createdAt,
                    text: decryptedText,
                    sequence: rec.sequence
                )
            }

            return await MainActor.run {
                snapshots
                    .sorted(by: { $0.sequence < $1.sequence })
                    .map { snap in
                        let author = ChatAuthor(rawValue: snap.authorRaw) ?? .guest
                        return ChatMessage(
                            identifier: snap.identifier,
                            author: author,
                            text: snap.text,
                            createdAt: snap.createdAt
                        )
                    }
            }
        } catch {
            return []
        }
    }

    // 특정 방의 메시지를 통째로 저장한다.
    func saveMessages(_ messages: [ChatMessage], roomIdentifier: UUID) async {
        guard let context else { return }

        do {
            let existing = try context.fetch(
                FetchDescriptor<ChatMessageRecord>(
                    predicate: #Predicate { $0.roomIdentifier == roomIdentifier }
                )
            )
            for rec in existing {
                context.delete(rec)
            }

            let key = try await loadOrCreateKey()

            for (idx, message) in messages.enumerated() {
                let encrypted = try encrypt(message.text, using: key)
                let rec = ChatMessageRecord(
                    identifier: message.identifier,
                    roomIdentifier: roomIdentifier,
                    authorRaw: message.author.rawValue,
                    createdAt: message.createdAt,
                    encryptedText: encrypted,
                    sequence: idx
                )
                context.insert(rec)
            }

            try context.save()
        } catch {
            // 저장 실패는 상위에서 UX로 처리하지 않는 정책이라면 여기서는 조용히 실패한다.
        }
    }

    // 채팅방의 updatedAt을 현재 시각으로 갱신한다.
    func touchRoomUpdatedAt(roomIdentifier: UUID) async {
        guard let context else { return }

        do {
            var descriptor = FetchDescriptor<ChatRoomRecord>(
                predicate: #Predicate { $0.identifier == roomIdentifier }
            )
            descriptor.fetchLimit = 1

            if let room = try context.fetch(descriptor).first {
                room.updatedAt = Date()
                try context.save()
            }
        } catch {
            // no-op
        }
    }

    // 키체인에서 AES 키를 읽고, 없으면 새로 만들어 저장한다.
    private func loadOrCreateKey() async throws -> SymmetricKey {
        if let b64 = await MainActor.run(resultType: String?.self, body: {
            KeychainStore.shared.read(key: keychainKey)
        }),
        let raw = Data(base64Encoded: b64),
        raw.count == 32 {
            return SymmetricKey(data: raw)
        }

        let key = SymmetricKey(size: .bits256)
        let raw = key.withUnsafeBytes { Data($0) }
        let b64 = raw.base64EncodedString()

        _ = await MainActor.run(resultType: Void.self, body: {
            KeychainStore.shared.save(key: keychainKey, value: b64)
        })

        return key
    }

    private func encrypt(_ plaintext: String, using key: SymmetricKey) throws -> Data {
        let data = Data(plaintext.utf8)
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else {
            throw NSError(domain: "ChatSwiftDataStore", code: -10)
        }
        return combined
    }

    private func decrypt(_ combined: Data, using key: SymmetricKey) throws -> String {
        let box = try AES.GCM.SealedBox(combined: combined)
        let decrypted = try AES.GCM.open(box, using: key)
        return String(decoding: decrypted, as: UTF8.self)
    }
}
