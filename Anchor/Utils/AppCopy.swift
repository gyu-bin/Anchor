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
        static let lockingAppsLabel = "잠금 중인 앱"
        static let lockScheduled = "루틴 시작 후 잠겨요"
        static let lockHeroBadge = "할 일 완료 → 잠금 해제"
        static let quickLockButton = "빠른 잠금"
        /// 오늘 탭 우측 상단 버튼 캡션
        static let quickLockCaption = "즉시잠금"
        static let quickLockActive = "즉시 잠금 중"
        static let quickLockManage = "관리"

        static func quickLockCountdown(seconds: Int) -> String {
            let h = seconds / 3600
            let m = (seconds % 3600) / 60
            let s = seconds % 60
            if h > 0 {
                return String(format: "%d:%02d:%02d 남음", h, m, s)
            }
            if m > 0 { return "\(m)분 \(s)초 남음" }
            return "\(s)초 남음"
        }

        static let emptyTitle = "아직 루틴이 없어요"
        static let emptyBody = "루틴 탭에서 +로 첫 루틴을 만들어 주세요"
        static let noScheduleTitle = "오늘은 예정된 루틴이 없어요"
        static let noScheduleBody = "루틴 탭에서 반복·기간 설정을 확인해 보세요"

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
        static let toggleFailed = "잠시 문제가 생겼어요. 다시 시도해 주세요"
        static let cannotUncheckAfterDeadline = "마감이 지난 루틴은 완료를 취소할 수 없어요"
        static let cannotCheckAfterDeadline = "마감 시간이 지났어요"
        static let liveActivityDisabled = "설정 → 키링 → 라이브 액티비티를 켜 주세요"
    }

    enum QuickLock {
        static let subtitle = "루틴 없이 지금 바로 앱을 잠가요"
        static let close = "닫기"
    }

    enum Guide {
        static let conceptBadge = "키링만의 방식"
        static let conceptTitle = "시간만 막는 앱이\n아니에요"
        static let conceptHighlight = "할 일을 다 할 때까지\n선택한 앱만 잠겨요"
        static let conceptBody = "오늘 루틴을 끝내면 잠금이 바로 풀려요.\n「조금만 더」 하다 하루가 새는 걸, 체크리스트와 함께 막아 줄게요."

        static let morningBadge = "아침"
        static let morningTitle = "눈 뜨자마자\n인스타·유튜브 보다가\n오전을 다 날린 적, 있으시죠?"
        static let morningBody = "의지만으로는 어려울 때가 많아요.\n그건 게으른 게 아니라, 습관이 그렇게 만든 거예요."

        static let eveningBadge = "저녁"
        static let eveningTitle = "눕자마자\n틱톡·유튜브 한 편 더 하다\n밤이 새버린 적도 있죠?"
        static let eveningBody = "내일을 위해 쉬고 싶은데, 손이 먼저 가는 날이에요.\n저녁 루틴이 있으면 훨씬 편해져요."

        static let reliefTitle = "걱정 마세요"
        static let reliefHighlight = "할 일이 끝나지 않으면\n앱이 열리지 않아요"
        static let reliefBody = "루틴을 다 마치면 잠금이 풀려요.\n「조금만 더」 하다 하루가 새는 일을, 시스템이 막아 줄게요."

        static let howTitle = "이렇게만 하면 돼요"
        static let howNote = "시작 시간이 되면 알림이 오고,\n그때부터 선택한 앱은 잠겨요."
        static let steps: [(icon: String, text: String)] = [
            ("list.bullet.rectangle", "루틴을 만들고, 잠금할 앱을 골라요"),
            ("checkmark.circle", "오늘 탭에서 할 일을 하나씩 체크해요"),
            ("lock.open", "다 하면 잠금이 풀려요. 그때 마음껏 쉬어도 괜찮아요"),
        ]

        static let screenTimeTitle = "잠금을 쓰려면\n한 번만 허용해 주세요"
        static let screenTimeBody = "iPhone의 Screen Time으로만 앱을 막을 수 있어요.\n키링은 선택한 앱만 잠그고, 나머지는 그대로 두어요."
        static let notificationTitle = "루틴 시작을\n놓치지 않게 알려 드릴게요"
        static let notificationBody = "시작·마감 알림만 보내요.\n광고나 소식 알림은 없어요."
        static let notificationAllow = "알림 허용하기"
        static let startTitle = "이제 아침을,\n내 루틴부터 시작해 볼까요?"
        static let startBody = "루틴 탭에서 첫 루틴을 만들어 주세요.\n기록은 이 iPhone에만 저장돼요."
        static let start = "시작하기"
        static let replayDone = "확인"
        static let replay = "앱 가이드 다시 보기"
    }

    enum Settings {
        static let title = "설정"
        static let subtitle = "알림·잠금·화면을 정해요"
        static let sectionGeneral = "일반"
        static let sectionNotifications = "알림"
        static let sectionLock = "잠금"
        static let sectionAbout = "앱 정보"
        static let appearance = "화면 모드"
        static let lockTitle = "앱 잠금"
        static let lockConnected = "연결됨"
        static let lockNeeded = "연결 필요"
        static let notificationsMaster = "알림 받기"
        static let routineStart = "루틴 시작 알림"
        static let weeklySummary = "주간 요약 (일요일)"
        static let requestNotification = "알림 허용하기"
        static let notificationOn = "알림이 켜져 있어요"
        static let notificationOff = "알림을 켜면 루틴을 놓치지 않아요"
        static let notificationDenied = "설정 앱에서 알림을 허용해 주세요"
        static let screenTimeNeedsPermission =
            "스크린타임을 보려면 위 「앱 잠금」에서 스크린 타임 연결을 허용해 주세요."
        static let screenTimeToday = "오늘"
        static let screenTimeThisWeek = "이번 주"
        static let screenTimeFootnote =
            "설정의 「스크린 타임」과 같게 이 iPhone 기준으로 맞춰요. API 특성상 1~2분 차이는 날 수 있어요."
        static let aboutBody = "루틴이 끝날 때까지 선택한 앱을 잠가 드리고, 완료하면 바로 풀어 드려요."
        static let versionRow = "버전"
        static func version(_ label: String) -> String { "버전 \(label)" }
        static let privacyPolicy = "개인정보처리방침"
        static let contact = "문의하기"
        static let openSystemSettings = "설정 앱 열기"
    }

    enum Routine {
        static let title = "루틴"
        static func subtitle(count: Int) -> String {
            count == 0 ? "첫 루틴을 함께 만들어 볼까요" : "루틴 \(count)개"
        }
        static let emptyTitle = "루틴이 비어 있어요"
        static let emptyBody = "이름과 시작 시간만 정하면 바로 시작할 수 있어요"
        static let emptyAction = "루틴 추가"
        static let addRoutinePrompt = "루틴 추가"
        static let addNewRoutine = "새로 만들기"
        static let loadTemplate = "이전 루틴 불러오기"
        static let templatePickerTitle = "이전 루틴"
        static let templateEmptyTitle = "불러올 루틴이 없어요"
        static let templateEmptyBody = "기간이 끝난 루틴이 여기에 저장돼요."
        static let addSheetTitle = "새 루틴"
        static let namePlaceholder = "예: 아침 루틴"
        static let todosSection = "할일"
        static let addTodo = "할일 추가"
        static let addTodoSheetTitle = "할일 추가"
        static let editTodoSheetTitle = "할일 편집"
        static let todoNamePlaceholder = "할 일 이름"
        static let scheduleTimeSection = "일정"
        static let scheduleRowRepeat = "반복"
        static let scheduleRowWeekdays = "요일"
        static let scheduleRowEnd = "반복 종료"
        static let scheduleEndOff = "안 함"
        static let scheduleRowAfterEnd = "끝나면"
        static let blockSection = "앱 · 웹 잠금"
        static let blockSectionHint = "미완료일 때 선택한 앱·사이트를 잠가요"
        static let blockAppsSection = "차단할 앱"
        static let blockAppsSectionHint = "미완료일 때 잠글 앱을 선택해요 (필수)"
        static let blockWebOptional = "웹 사이트 차단 (선택)"
        static let endTimeToggle = "종료 시간 설정"
        static let endTimeLabel = "종료 시간"
        static let endTimeNote = "마감 30분 전 알림 · 미완료면 마감 시각에 잠금이 풀려요"
        static let routineNameLabel = "루틴 이름"
        static let lockActive = "앱 잠금 중"
        static let lockScheduled = "시작 후 잠김"
        static let extendDeadline = "30분 연장"
        static let extendSuccess = "30분 연장했어요"
        static let extendFailed = "지금은 연장할 수 없어요"
        static let tempUnlockTenMin = "10분 해제"
        static let lockReleasedAfterDeadline = "마감 지남 · 미완료"
        static func sectionProgress(done: Int, total: Int) -> String {
            "\(done)개 / \(total)개 했어요"
        }
        static func startsAt(_ time: String) -> String {
            "\(time)에 시작해요"
        }
        static let repeatsDaily = "매일"
        static let scheduleSection = "반복"
        static let startTimeLabel = "시작 시간"
        static let weekdaySelect = "반복할 요일"
        static let periodWeekdayHint = "비우면 기간 안 매일이에요"
        static let onceDateLabel = "날짜"
        static let onceToday = "오늘로 맞추기"
        static let weekdayRequired = "요일을 하나 이상 골라 주세요"
        static let periodRangeInvalid = "종료일은 시작일과 같거나 이후여야 해요"
        static let scheduleStartLabel = "시작일"
        static let scheduleEndLabel = "종료일"
        static let scheduleEndToggle = "종료일 정하기"
        static let untilDate = "~"
        static let periodEveryDay = "기간 중 매일"
        static let weekdayPresetWeekdays = "평일"
        static let weekdayPresetWeekend = "주말"
        static let presetThisWeek = "이번 주"
        static let presetNextSevenDays = "앞으로 7일"
        static let deleteConfirmTitle = "루틴을 삭제할까요?"
        static let deleteConfirmMessage = "항목과 차단 설정도 함께 사라져요. 되돌릴 수 없어요."
        static let deleteConfirmAction = "삭제"
        static let deletedToast = "루틴이 삭제되었습니다"
        static let setupRequiredHint = "저장하려면 할 일과 차단할 앱이 필요해요"
        static let checklistTodos = "할 일"
        static let checklistApps = "앱 잠금"
        static let validationNeedTodos = "할 일을 1개 이상 추가해 주세요"
        static let validationNeedApps = "차단할 앱을 선택해 주세요"
        static let validationNeedBoth = "할 일과 차단할 앱을 설정해 주세요"
        static let saveRoutine = "저장"
        static let todosEmptyHint = "오늘 체크할 할 일을 추가해 주세요"
        static let appsEmptyHint = "미완료일 때 잠글 앱을 골라 주세요"
        static let duplicate = "루틴 복제"
        static let reorderItems = "항목 순서"
        static let reorderItemsHint = "≡ 아이콘을 끌어 순서를 바꿔요"
        static let duplicatedToast = "루틴을 복제했어요"
        static func durationMinutes(_ minutes: Int) -> String { "약 \(minutes)분" }
        static func durationHours(_ hours: Int) -> String { "약 \(hours)시간" }
        static func durationHoursMinutes(hours: Int, minutes: Int) -> String {
            "약 \(hours)시간 \(minutes)분"
        }

        enum ScheduleKind {
            static let daily = "매일"
            static let weekdays = "요일마다"
            static let period = "기간"
            static let once = "하루만"
            static let onceShort = "하루"
            static let dailyNote = "매일 같은 시간에 알림과 잠금이 적용돼요."
            static let weekdaysNote = "고른 요일마다 반복돼요. 종료일을 정하면 그날까지만 해요."
            static let periodNote = "시작~종료 사이에만 나타나요. 요일을 고르면 그날만 해요."
            static let onceNote = "고른 하루에만 오늘 탭에 나타나요."
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
        static let monthRate = "이번 달 완료율"
        static let monthRateHint = "이번 달 1일부터 오늘까지, 예정된 루틴을 끝까지 한 비율이에요"
        static func monthRateDetail(completed: Int, scheduled: Int) -> String {
            "완료 \(completed) / 예정 \(scheduled)"
        }
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
        static let apply = "적용"
        static let save = "저장"
        static let add = "추가"
    }

    enum Error {
        static let saveFailed = "저장에 실패했어요. 다시 시도해 주세요"
        static let permissionFailed = "권한 요청에 실패했어요. 설정 앱에서 허용해 주세요"
    }

    enum Onboarding {
        static let screenTimeAllow = "허용하기"
        static let screenTimeLinked = "연결됐어요"
        static let screenTimeNeeded = "연결이 필요해요"
    }

    enum Premium {
        static let title = "전체 기능 열기"
        static let reasonRoutine = "루틴을 더 만들고 싶을 때 전체 기능을 열 수 있어요."
        static let reasonItem = "항목을 더 추가하려면 전체 기능이 필요해요."
        static let reasonApp = "막을 앱을 더 선택하려면 전체 기능을 열어 주세요."
        static let reasonWeb = "웹 차단을 더 쓰려면 전체 기능을 열어 주세요."
        static let reasonHistory = "이번 달이 아닌 기록을 보려면 전체 기능을 열어 주세요."
        static let reasonWeekly = "주간 요약 알림은 전체 기능에서 쓸 수 있어요."
        static let reasonTrialExpired =
            "2주 체험이 끝났어요. 전체 기능을 계속 쓰려면 한 번만 열어 주세요."
        static let reasonGeneral = "루틴·잠금·기록 제한 없이 쓰실 수 있어요."
        static func trialActive(days: Int) -> String {
            if days <= 0 { return "오늘까지 전체 기능 체험 중" }
            if days == 1 { return "전체 기능 체험 · 내일까지" }
            return "전체 기능 체험 · \(days)일 남음"
        }
        static let trialExpiredSettings = "체험이 끝났어요. 무료 한도로 전환됐어요"
        static let settingsTrialNote =
            "처음 \(PremiumTrialStore.trialDurationDays)일은 전체 기능을 무료로 써요. 이후에는 무료 한도가 적용돼요."
        static let freeTierTitle = "지금 무료로 쓰는 것"
        static let freeTierSummary =
            "루틴 \(PremiumLimits.maxFreeRoutines)개 · 항목 \(PremiumLimits.maxItemsPerRoutine)개 · 앱 \(PremiumLimits.maxAppsPerRoutine)개 · 웹 \(PremiumLimits.maxWebDomainsPerRoutine)개 · 기록 이번 달"
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
        static let historyBanner = "지난달부터의 기록은 전체 기능에서 볼 수 있어요."
        static let weeklyLocked = "전체 기능"
        static let productUnavailable = "결제 정보를 불러오지 못했어요. 잠시 후 다시 시도해 주세요."
        static let loadingProduct = "결제 정보를 불러오는 중이에요…"
        static let retryLoad = "다시 불러오기"
        static let purchaseFailed = "결제에 실패했어요. 다시 시도해 주세요."
        static let purchasePending = "결제 승인을 기다리는 중이에요."
        static let restoreFailed = "복원에 실패했어요."
        static let restoreEmpty = "복원할 구매 내역이 없어요."
        static let alreadyUnlocked = "이미 열려 있어요"
        static let routineLimitHint = "무료는 루틴 \(PremiumLimits.maxFreeRoutines)개까지예요."
        static let itemLimitHint = "무료는 항목 \(PremiumLimits.maxItemsPerRoutine)개까지예요."
        static let appLimitHint = "무료는 앱 \(PremiumLimits.maxAppsPerRoutine)개까지예요."
        static let webLimitHint = "무료는 사이트 \(PremiumLimits.maxWebDomainsPerRoutine)개까지예요."
        static let webDomainNote = "도메인 칩은 Safari 등 브라우저에서 막혀요. 차단 화면은 「사이트 선택」으로 추가해요."
        static let quickLockAppLimitHint = "무료는 빠른 잠금에서 앱 \(PremiumLimits.maxQuickLockApps)개까지 선택할 수 있어요."
    }

    enum Notification {
        static func routineStart(name: String) -> (title: String, body: String) {
            ("\(name), 시작할 시간이에요", "오늘도 천천히 함께해요")
        }
        static func routineIncomplete(name: String) -> (title: String, body: String) {
            ("\(name), 시간이 지났어요", "아직 완료하지 않았어요. 지금이라도 마무리해볼까요?")
        }
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
