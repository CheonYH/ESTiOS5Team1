//
//  AlanCoordinator.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 2/2/26.
//

import Foundation
import Combine

/// Alan API 호출(또는 그에 준하는 비동기 작업)의 동시 실행을 제어하는 코디네이터입니다.
///
/// 이 파일의 역할
/// - 한 번에 하나의 전송만 수행되도록 직렬화합니다.
/// - 현재 처리 중인 방(activeRoomId)과 상태(isBusy)를 UI에 노출합니다.
///
/// 연동 위치
/// - ChatRoomViewModel: sendMessage 내부에서 run으로 감싸 중복 요청을 막습니다.
/// - ChatRoomView: isBusy/activeRoomId를 보고 입력 비활성화 및 타이핑 표시를 제어합니다.
/// - ChatRoomsViewModel: 새 채팅 시작(기본 방 → 아카이브 이동) 시 redirectActiveRoom로 로딩 표시가 엇갈리지 않게 보정합니다.
///
/// 구현 선택 이유
/// - @MainActor: Published 상태가 SwiftUI 바인딩과 직접 연결되므로 메인 스레드에서 일관되게 변경합니다.
/// - Gate(actor): 코디네이터는 메인에서 동작하지만, “진입 순서”는 직렬화가 필요해서 별도 락을 둡니다.
/// - defer: 성공/실패와 무관하게 isBusy/activeRoomId가 항상 복구되게 해서 UI가 stuck 되는 상황을 막습니다.
@MainActor
final class AlanCoordinator: ObservableObject {
    @Published private(set) var isBusy: Bool = false
    @Published private(set) var activeRoomId: UUID?

    private let gate = Gate()

    /// roomId 단위로 작업을 실행합니다.
    ///
    /// - roomId: 현재 작업이 속한 방(로딩 표시/입력 잠금의 기준)
    /// - operation: 실제 네트워크 호출/저장 처리 등을 포함한 작업
    ///
    /// 동작
    /// - acquire로 진입을 막고, 작업 중에는 isBusy/activeRoomId를 설정합니다.
    /// - 종료 시에는 defer에서 상태 복구 후 release로 다음 작업을 허용합니다.
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

    /// 처리 중인 작업의 방 식별자를 다른 방으로 바꿉니다.
    ///
    /// 사용 목적
    /// - 기본 방에서 "새 채팅"을 눌러 과거 메시지를 아카이브 방으로 옮길 때,
    ///   이미 진행 중인 요청의 로딩 표시와 결과 귀속이 엇갈릴 수 있습니다.
    /// - 그 상황에서 activeRoomId를 새 방으로 바꿔 UI 표시(typing) 기준을 맞춥니다.
    func redirectActiveRoom(from sourceRoomId: UUID, to targetRoomId: UUID) {
        guard activeRoomId == sourceRoomId else { return }
        activeRoomId = targetRoomId
    }
}

/// AlanCoordinator 내부에서만 사용하는 단순 락 actor입니다.
///
/// 왜 actor로 락을 두나
/// - acquire/release가 동시에 호출될 수 있는 경로를 안전하게 직렬화하기 위함입니다.
///
/// 30ms sleep을 두는 이유
/// - busy-wait로 CPU를 계속 점유하지 않도록, 짧은 backoff를 줍니다.
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
