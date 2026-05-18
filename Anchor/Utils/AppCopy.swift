//
//  AppCopy.swift
//  Anchor
//

import Foundation

/// 앱 전체에서 쓰는 다정한 톤의 문구
enum AppCopy {

    enum Today {
        static func greeting(hour: Int) -> String {
            switch hour {
            case 5..<12: return "좋은 아침이에요"
            case 12..<18: return "오후도 응원할게요"
            default: return "오늘 하루도 수고 많으셨어요"
            }
        }

        static func progressTitle(completed: Int, total: Int) -> String {
            guard total > 0 else { return "오늘의 루틴" }
            if completed >= total { return "오늘, 정말 잘하셨어요" }
            if completed == 0 { return "천천히 시작해 볼까요" }
            return "잘하고 있어요"
        }

        static func progressSubtitle(completed: Int, total: Int) -> String {
            guard total > 0 else { return "" }
            return "루틴 \(completed)개 / \(total)개 끝냈어요"
        }

        static let lockActive = "지금 앱 잠금 중이에요"
        static let lockScheduled = "루틴 시작 후 잠겨요"

        static let emptyTitle = "아직 루틴이 없어요"
        static let emptyBody = "루틴 탭에서 첫 루틴을 만들어 주세요"
        static let emptyAction = "루틴 만들기"

        static let completeTitle = "오늘도 해내셨네요"
        static let completeBody = "잠금을 풀어 두었어요. 편히 쉬세요"
        static let completeCount = "완료한 항목"
        static let completeConfirm = "고마워요"

        static let restDayActive = "오늘은 쉬는 날이에요"
        static let restDayButton = "오늘은 쉴게요"
        static let restDayCancel = "쉬는 날 취소"
        static let restDayBody = "오늘은 잠금 없이 쉬어 가도 괜찮아요.\n연속 기록은 그대로 이어져요."
        static let undoMessage = "방금 체크를 되돌릴까요?"
        static let undoAction = "되돌리기"
    }

    enum Guide {
        static let welcomeBody = "루틴을 끝낼 때까지 선택한 앱을 잠그고,\n완료하면 바로 풀어 드려요."
        static let howTitle = "이렇게 써요"
        static let steps = [
            "루틴 탭에서 루틴과 할 일을 만들어요",
            "막을 앱을 고르고 시작 시간을 정해요",
            "오늘 탭에서 하나씩 체크해요",
            "다 하면 잠금이 풀려요",
        ]
        static let screenTimeTitle = "Screen Time"
        static let screenTimeBody = "앱 잠금을 쓰려면 한 번만 허용해 주세요.\n나중에 설정에서 다시 할 수 있어요."
        static let startTitle = "이제 시작해 볼까요"
        static let startBody = "루틴 탭에서 첫 루틴을 만들어 주세요.\n기록은 이 기기에만 저장돼요."
        static let start = "시작하기"
        static let replayDone = "확인"
        static let replay = "앱 가이드 다시 보기"
    }

    enum Settings {
        static let title = "설정"
        static let subtitle = "알림과 잠금 화면을 정해요"
        static let appearance = "화면 모드"
        static let dataPrivacy = "기록 저장"
        static let dataPrivacyBody = "완료 기록과 루틴은 이 iPhone에만 저장돼요. 다른 기기와 자동으로 맞춰지지 않아요."
        static let notifications = "알림"
        static let notificationsMaster = "알림 받기"
        static let routineStart = "루틴 시작 알림"
        static let reminder = "리마인더"
        static let weeklySummary = "주간 요약 (일요일)"
        static let requestNotification = "알림 허용하기"
        static let notificationOn = "알림이 켜져 있어요"
        static let notificationOff = "알림을 켜면 루틴을 놓치지 않아요"
        static let notificationDenied = "설정 앱에서 알림을 허용해 주세요"
        static let screenTime = "Screen Time"
        static let shieldTitle = "잠금 화면 문구"
        static let shieldSubtitle = "차단된 앱을 열 때 보여요"
        static let shieldTitlePlaceholder = "제목"
        static let shieldSubtitlePlaceholder = "부제"
        static let shieldSave = "문구 저장"
        static let about = "앱 정보"
        static let aboutBody = "루틴이 끝날 때까지 선택한 앱을 잠가 드리고, 완료하면 바로 풀어 드려요."
        static let contact = "문의하기"
    }

    enum Routine {
        static let title = "루틴"
        static func subtitle(count: Int) -> String {
            count == 0 ? "첫 루틴을 함께 만들어 볼까요" : "루틴 \(count)개"
        }
        static let emptyTitle = "루틴이 비어 있어요"
        static let emptyBody = "이름과 시작 시간만 정하면 바로 시작할 수 있어요"
        static let emptyAction = "루틴 추가"
        static let addSheetTitle = "새 루틴"
        static let namePlaceholder = "예: 아침 루틴"
        static let noItems = "항목을 하나만 추가해 주세요"
        static let addItem = "항목 추가"
        static let lockActive = "지금 앱 잠금 중"
        static let lockScheduled = "시작 후 잠겨요"
        static func sectionProgress(done: Int, total: Int) -> String {
            "\(done)개 / \(total)개 했어요"
        }
        static let repeatsDaily = "매일"
        static let scheduleSection = "반복"
        static let startTimeLabel = "시작 시간"
        static let weekdaySelect = "반복할 요일"
        static let onceDateLabel = "날짜"
        static let onceToday = "오늘로 맞추기"
        static let weekdayRequired = "요일을 하나 이상 골라 주세요"

        enum ScheduleKind {
            static let daily = "매일"
            static let weekdays = "요일"
            static let once = "특정 날"
            static let onceShort = "당일"
            static let dailyNote = "매일 같은 시간에 알림과 잠금이 동작해요."
            static let onceNote = "선택한 날에만 오늘 탭에 나타나요."
        }
    }

    enum History {
        static let title = "기록"
        static let subtitle = "꾸준히 쌓이고 있어요"
        static let emptyTitle = "아직 기록이 없어요"
        static let emptyBody = "오늘 탭에서 루틴을 마치면\n여기에 차곡차곡 쌓여요"
        static let emptyAction = "루틴 만들기"
        static let streak = "연속 완료"
        static let monthRate = "이번 달"
        static let thisWeek = "이번 주"
        static let byItem = "항목별"
        static let noLogs = "조금만 더 하면 기록이 생겨요"
        static func weeklySummary(fullDays: Int) -> String {
            "이번 주 \(fullDays)일 루틴을 채웠어요. 정말 대단해요"
        }
    }

    enum Common {
        static let next = "다음"
        static let back = "이전"
        static let later = "다음에 할게요"
        static let cancel = "취소"
        static let save = "저장"
        static let add = "추가"
    }

    enum Onboarding {
        static let introBody = "루틴이 끝날 때까지\n선택한 앱을 잠가 드려요.\n다 하시면 바로 풀어 드릴게요."
        static let start = "시작할게요"
        static let routineTitle = "루틴 정하기"
        static let routineSubtitle = "이름과 시작 시간만 알려 주세요. 그때 살짝 알려 드릴게요."
        static let itemsTitle = "오늘 할 일"
        static let itemsSubtitle = "골라 주세요. 나중에 언제든 바꿀 수 있어요."
        static let webTitle = "자주 가는 사이트 (선택)"
        static let webSubtitle = "메모만 해 두셔도 돼요. 실제 차단은 루틴 탭에서 설정해요."
        static let screenTimeTitle = "Screen Time"
        static let screenTimeSubtitle = "허용 후 막을 앱을 골라 주세요. 첫날부터 잠금이 동작해요."
        static let pickApps = "막을 앱 선택"
        static let pickedAppsCount = "선택한 앱"
        static let screenTimeAllow = "허용하기"
        static let screenTimeLinked = "연결됐어요"
        static let screenTimeNeeded = "연결이 필요해요"
        static let finishTitle = "이제 준비됐어요"
        static let finishBody = "오늘 탭에서 루틴을 진행하고,\n루틴 탭에서 막을 앱을 골라 주세요."
        static let finishAction = "시작하기"
        static func screenTimeCaption(approved: Bool, denied: Bool) -> String {
            if approved { return "루틴을 마치기 전까지 선택한 앱을 잠글 수 있어요." }
            if denied { return "설정 → Screen Time에서 허용해 주실 수 있어요." }
            return "한 번만 허용하시면 이후엔 자동이에요."
        }
    }

    enum Notification {
        static func routineStart(name: String) -> (title: String, body: String) {
            ("\(name), 시작할 시간이에요", "오늘도 천천히 함께해요")
        }
        static func reminder(name: String) -> (title: String, body: String) {
            ("아직 \(name)이 남아 있어요", "조금만 더 해볼까요?")
        }
        static let openToday = "오늘 보기"
        static let weeklyTitle = "이번 주도 수고 많으셨어요"
        static let weeklyBodyPlaceholder = "기록 탭에서 이번 주를 확인해 보세요"
        static func weeklyBody(days: Int) -> String {
            "이번 주 \(days)일 루틴을 채웠어요. 천천히, 꾸준히 잘하고 계세요"
        }
    }
}
