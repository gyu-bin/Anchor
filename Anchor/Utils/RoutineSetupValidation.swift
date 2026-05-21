//
//  RoutineSetupValidation.swift
//  Anchor
//

import FamilyControls
import Foundation

struct RoutineSetupValidation {
    struct Result {
        let missingTodos: Bool
        let missingApps: Bool

        var isValid: Bool {
            !missingTodos && !missingApps
        }

        func scrollTargetID(for routineID: UUID) -> String? {
            if missingTodos { return "routine-todos-\(routineID)" }
            if missingApps { return "routine-apps-\(routineID)" }
            return nil
        }

        var toastMessage: String {
            switch (missingTodos, missingApps) {
            case (true, true):
                return AppCopy.Routine.validationNeedBoth
            case (true, false):
                return AppCopy.Routine.validationNeedTodos
            case (false, true):
                return AppCopy.Routine.validationNeedApps
            case (false, false):
                return ""
            }
        }
    }

    static func hasBlockedApps(_ routine: Routine) -> Bool {
        !ShieldManager.decodeSelection(routine.shieldSelectionData).applicationTokens.isEmpty
    }

    static func validate(_ routine: Routine) -> Result {
        let hasTodos = !routine.items.isEmpty
        let hasApps = hasBlockedApps(routine)
        return Result(missingTodos: !hasTodos, missingApps: !hasApps)
    }
}
