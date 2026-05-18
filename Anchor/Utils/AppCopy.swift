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
        static let noScheduleTitle = "오늘은 예정된 루틴이 없어요"
        static let noScheduleBody = "루틴 탭에서 반복 요일이나 특정 날을 확인해 보세요"
        static let setupItemsBody = "루틴 탭에서 할 일을 추가하면 오늘부터 체크할 수 있어요"
        static let setupItemsAction = "루틴 탭으로"

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
        static let about = "앱 정보"
        static let aboutBody = "루틴이 끝날 때까지 선택한 앱을 잠가 드리고, 완료하면 바로 풀어 드려요."
        static func version(_ label: String) -> String { "버전 \(label)" }
        static let privacyPolicy = "개인정보처리방침"
        static let contact = "문의하기"
        static let openSystemSettings = "설정 앱 열기"
        static let reminderDelay = "리마인더 시점"
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
        static let lockActive = "앱 잠금 중"
        static let lockScheduled = "시작 후 잠김"
        static func lockUnlocksAt(_ time: String) -> String { "잠금 \(time)에 해제" }
        static let lockReleasedAfterDeadline = "마감 지남 · 미완료"
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
        static let deleteConfirmTitle = "루틴을 삭제할까요?"
        static let deleteConfirmMessage = "항목과 차단 설정도 함께 사라져요. 되돌릴 수 없어요."
        static let deleteConfirmAction = "삭제"
        static let duplicate = "루틴 복제"
        static let reorderItems = "항목 순서"
        static let reorderRoutines = "순서 변경"
        static func durationMinutes(_ minutes: Int) -> String { "약 \(minutes)분" }
        static func durationHours(_ hours: Int) -> String { "약 \(hours)시간" }
        static func durationHoursMinutes(hours: Int, minutes: Int) -> String {
            "약 \(hours)시간 \(minutes)분"
        }

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
        static let bestStreak = "최고 기록"
        static let monthRate = "이번 달"
        static let thisWeek = "이번 주"
        static let byItem = "항목별"
        static let noLogs = "조금만 더 하면 기록이 생겨요"
        static func weeklySummary(fullDays: Int) -> String {
            "이번 주 \(fullDays)일 루틴을 채웠어요. 정말 대단해요"
        }
        static let statusTitle = "하루 상태"
        static let legendFull = "완료"
        static let legendMissed = "마감 미완료"
        static let legendNone = "기록 없음"
        static func monthMissedDays(_ count: Int) -> String {
            "이번 달 마감 미완료 \(count)일"
        }
        static let monthMissedNone = "이번 달 마감 미완료 없음"
        static let dayDetailRoutines = "루틴"
        static let dayDetailRest = "쉬는 날이에요"
        static let dayDetailFuture = "아직 오지 않은 날이에요"
        static let dayDetailNoSchedule = "예정된 루틴이 없어요"
        static let routineCompleted = "완료"
        static let routineInProgress = "진행 중"
        static let routineMissed = "마감 미완료"
        static let routineWaiting = "대기 중"
        static let routineUpcoming = "예정"
        static func routineProgress(completed: Int, total: Int) -> String {
            "\(completed)/\(total) 완료"
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

    enum Premium {
        static let title = "전체 기능 열기"
        static let reasonRoutine = "루틴을 더 만들고 싶을 때 전체 기능을 열 수 있어요."
        static let reasonItem = "항목을 더 추가하려면 전체 기능이 필요해요."
        static let reasonApp = "막을 앱을 더 선택하려면 전체 기능을 열어 주세요."
        static let reasonWeb = "웹 차단을 더 쓰려면 전체 기능을 열어 주세요."
        static let reasonHistory = "30일이 넘은 기록을 보려면 전체 기능을 열어 주세요."
        static let reasonWeekly = "주간 요약 알림은 전체 기능에서 쓸 수 있어요."
        static let reasonGeneral = "루틴·잠금·기록 제한 없이 쓰실 수 있어요."
        static let freeTierTitle = "지금 무료로 쓰는 것"
        static let freeTierSummary = "루틴 3개 · 항목 5개 · 앱 8개 · 웹 3개 · 기록 30일"
        static let benefits = [
            "루틴·항목 무제한",
            "앱·웹 차단 무제한",
            "전체 기록·항목별 통계",
            "주간 요약 알림",
        ]
        static func purchase(price: String) -> String {
            "\(price)에 평생 열기"
        }
        static let restore = "구매 복원"
        static let footnote = "구독이 아니에요. 한 번만 결제하면 이 기기에서 계속 쓸 수 있어요."
        static let settingsTitle = "전체 기능"
        static let settingsUnlocked = "전체 기능을 쓰고 있어요"
        static let settingsLocked = "1회 결제로 제한 없이"
        static let settingsOpen = "전체 기능 열기"
        static let historyBanner = "30일이 지난 기록은 전체 기능에서 볼 수 있어요."
        static let weeklyLocked = "전체 기능"
        static let productUnavailable = "결제 정보를 불러오지 못했어요. Xcode에서 Scheme → Run → StoreKit Configuration이 Products.storekit인지 확인한 뒤 앱을 다시 실행해 주세요."
        static let loadingProduct = "결제 정보를 불러오는 중이에요…"
        static let retryLoad = "다시 불러오기"
        static let purchaseFailed = "결제에 실패했어요. 다시 시도해 주세요."
        static let purchasePending = "결제 승인을 기다리는 중이에요."
        static let restoreFailed = "복원에 실패했어요."
        static let restoreEmpty = "복원할 구매 내역이 없어요."
        static let alreadyUnlocked = "이미 열려 있어요"
        static let appLimitHint = "무료는 앱 \(PremiumLimits.maxAppsPerRoutine)개까지예요."
        static let webLimitHint = "무료는 사이트 \(PremiumLimits.maxWebDomainsPerRoutine)개까지예요."
        static let webDomainNote = "도메인 칩은 Safari 등 브라우저에서 막혀요. 차단 화면은 「사이트 선택」으로 추가해요."
    }

    enum Notification {
        static func routineStart(name: String) -> (title: String, body: String) {
            ("\(name), 시작할 시간이에요", "오늘도 천천히 함께해요")
        }
        static func reminder(name: String) -> (title: String, body: String) {
            ("아직 \(name)이 남아 있어요", "조금만 더 해볼까요?")
        }
        static let incompleteDayTitle = "오늘 루틴, 아직 남았어요"
        static let incompleteDayBody = "하루가 끝나기 전에 조금만 더 해볼까요?"
        static let dayCelebrationTitle = "오늘도 고생 많으셨어요"
        static let dayCelebrationBody = "루틴을 모두 마치셨네요. 편히 쉬세요"
        static func deadlineReminder(name: String) -> (title: String, body: String) {
            ("\(name) 마감 30분 전이에요", "아직 완료 전이라면 지금 시작해 보세요!")
        }
        static let openToday = "오늘 보기"
        static let weeklyTitle = "이번 주도 수고 많으셨어요"
        static let weeklyBodyPlaceholder = "기록 탭에서 이번 주를 확인해 보세요"
        static func weeklyBody(days: Int) -> String {
            "이번 주 \(days)일 루틴을 채웠어요. 천천히, 꾸준히 잘하고 계세요"
        }
    }
}
