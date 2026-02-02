//
//  AlanCoordinator.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 2/2/26.
//

import Foundation
import Combine

@MainActor
final class AlanCoordinator: ObservableObject {
    @Published private(set) var isBusy: Bool = false
    @Published private(set) var activeRoomId: UUID?

    private let gate = Gate()

    func run<T>(
        roomId: UUID,
        _ operation: @MainActor () async throws -> T
    ) async rethrows -> T {
        await gate.acquire()

        activeRoomId = roomId
        isBusy = true

        defer {
            isBusy = false
            activeRoomId = nil
            Task { await gate.release() }
        }

        return try await operation()
    }

    func redirectActiveRoom(from sourceRoomId: UUID, to targetRoomId: UUID) {
        guard activeRoomId == sourceRoomId else { return }
        activeRoomId = targetRoomId
    }
}

private actor Gate {
    private var isLocked = false

    func acquire() async {
        while isLocked {
            try? await Task.sleep(nanoseconds: 30_000_000) // 30ms
        }
        isLocked = true
    }

    func release() {
        isLocked = false
    }
}
