//
//  ChatSwiftDataStore.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/28/26.
//

import CryptoKit
import Foundation
import SwiftData

// MARK: - SwiftData Models
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
actor ChatSwiftDataStore {
    private let keychainKey = "chat_swiftdata_aes_key_v1"
    private let context: ModelContext?

    private struct RoomSnapshot: Sendable {
        let identifier: UUID; let title: String; let isDefaultRoom: Bool
        let alanClientIdentifier: String; let updatedAt: Date; let sequence: Int
    }

    private struct MessageSnapshot: Sendable {
        let identifier: UUID; let authorRaw: String; let createdAt: Date; let text: String; let sequence: Int
    }

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

    private func encrypt(_ plaintext: String, using key: SymmetricKey) throws -> Data {
        let data = Data(plaintext.utf8)
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else {
            throw NSError(domain: "ChatSwiftDataStore", code: -10, userInfo: [NSLocalizedDescriptionKey: "Encryption failed"])
        }
        return combined
    }

    private func decrypt(_ combined: Data, using key: SymmetricKey) throws -> String {
        let box = try AES.GCM.SealedBox(combined: combined)
        let decrypted = try AES.GCM.open(box, using: key)
        return String(decoding: decrypted, as: UTF8.self)
    }
}
