import Foundation
import PlayfitAPI
import PlayfitModels
import PlayfitStorage

extension PlayViewModel {
    func saveGameStateOrQueue(gameId: String, state: UserGameState) {
        guard let apiClient else {
            queueSaveGameState(gameId: gameId, state: state)
            return
        }
        Task {
            do {
                try await apiClient.saveGameState(gameId: gameId, state: state)
                storage.removePendingAction(gameId: gameId, actionType: PendingActionType.saveGameState.rawValue)
            } catch {
                queueSaveGameState(gameId: gameId, state: state)
            }
        }
    }

    func deleteGameStateOrQueue(gameId: String) {
        guard let apiClient else {
            storage.enqueuePendingAction(gameId: gameId, actionType: PendingActionType.deleteGameState.rawValue, payload: Data())
            return
        }
        Task {
            do {
                try await apiClient.deleteGameState(gameId: gameId)
                storage.removePendingAction(gameId: gameId, actionType: PendingActionType.deleteGameState.rawValue)
            } catch {
                storage.enqueuePendingAction(gameId: gameId, actionType: PendingActionType.deleteGameState.rawValue, payload: Data())
            }
        }
    }

    private func queueSaveGameState(gameId: String, state: UserGameState) {
        guard let payload = try? JSONEncoder().encode(state) else { return }
        storage.enqueuePendingAction(gameId: gameId, actionType: PendingActionType.saveGameState.rawValue, payload: payload)
    }

    func drainPendingActions() async {
        guard let apiClient else { return }
        let pending = storage.loadPendingActions()
        for action in pending {
            guard let type = PendingActionType(rawValue: action.actionType) else { continue }
            do {
                switch type {
                case .saveGameState:
                    let state = try JSONDecoder().decode(UserGameState.self, from: action.payload)
                    try await apiClient.saveGameState(gameId: action.gameId, state: state)
                case .deleteGameState:
                    try await apiClient.deleteGameState(gameId: action.gameId)
                }
                storage.removePendingAction(id: action.id)
            } catch {
                // Leave queued; it will be retried on the next sync.
            }
        }
    }

    func overlayStillPending(on serverGameStates: [String: UserGameState]) -> [String: UserGameState] {
        var merged = serverGameStates
        for action in storage.loadPendingActions() {
            guard let type = PendingActionType(rawValue: action.actionType) else { continue }
            switch type {
            case .saveGameState:
                if let state = try? JSONDecoder().decode(UserGameState.self, from: action.payload) {
                    merged[action.gameId] = state
                }
            case .deleteGameState:
                merged.removeValue(forKey: action.gameId)
            }
        }
        return merged
    }
}
