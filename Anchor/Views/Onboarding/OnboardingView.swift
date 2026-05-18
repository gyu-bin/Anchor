//
//  OnboardingView.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    /// 온보딩 완료는 부모(`ContentView`)의 `@AppStorage`만 갱신해 탭 전환이 확실히 일어나게 합니다.
    var onComplete: () -> Void

    @State private var step = 0
    @State private var routineName: String = "나의 루틴"
    @State private var routineStartTime = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()

    @State private var selectedTemplates: Set<String> = []
    @State private var selectedWebs: Set<String> = []

    private let templates: [(key: String, title: String, icon: String)] = [
        ("meditation", "묵상", "brain.head.profile"),
        ("reading", "독서", "book"),
        ("workout", "운동", "figure.run"),
        ("study", "공부", "pencil"),
        ("journal", "일기", "note.text"),
    ]

    private let webPresets: [(String, String)] = [
        ("유튜브", "youtube.com"),
        ("인스타", "instagram.com"),
        ("X", "x.com"),
        ("틱톡", "tiktok.com"),
        ("넷플릭스", "netflix.com"),
    ]

    var body: some View {
        NavigationStack {
            TabView(selection: $step) {
                introPage.tag(0)
                routineSetupPage.tag(1)
                templatePage.tag(2)
                webPage.tag(3)
                finishPage.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .background(Color.anchorBg(scheme).ignoresSafeArea())
        }
    }

    private var introPage: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "anchor.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.anchorAccent(scheme))
            Text("Anchor")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.anchorText(scheme))
            Text("루틴을 끝내기 전까지 방해 요소를 소프트 잠금하고,\n완료의 순간에 바로 해제해요.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.anchorSub(scheme))
                .padding(.horizontal, 22)
            Spacer()
            Button("다음") { step = 1 }
                .buttonStyle(.borderedProminent)
                .tint(Color.anchorAccent(scheme))
                .padding(.bottom, 28)
        }
        .padding()
    }

    private var routineSetupPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("루틴 이름과 시작 시간")
                .font(.title2.bold())
                .foregroundStyle(Color.anchorText(scheme))
            Text("이름은 자유롭게 정할 수 있어요. 매일 이 시간에 시작 알림을 보낼게요.")
                .foregroundStyle(Color.anchorSub(scheme))

            TextField("루틴 이름", text: $routineName)
                .textFieldStyle(.roundedBorder)

            DatePicker("시작 시간", selection: $routineStartTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ko_KR"))

            Spacer()
            HStack {
                Button("이전") { step = 0 }
                Spacer()
                Button("다음") { step = 2 }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.anchorAccent(scheme))
            }
            .padding(.bottom, 10)
        }
        .padding(20)
    }

    private var templatePage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("추천 루틴 항목")
                .font(.title2.bold())
                .foregroundStyle(Color.anchorText(scheme))
            Text("원하는 항목을 선택하세요. 나중에 루틴 탭에서 언제든 바꿀 수 있어요.")
                .foregroundStyle(Color.anchorSub(scheme))

            VStack(spacing: 10) {
                ForEach(templates, id: \.key) { tpl in
                    let on = selectedTemplates.contains(tpl.key)
                    Button {
                        if on { selectedTemplates.remove(tpl.key) } else { selectedTemplates.insert(tpl.key) }
                    } label: {
                        HStack {
                            Image(systemName: tpl.icon)
                                .foregroundStyle(Color.anchorAccent(scheme))
                            Text(tpl.title)
                                .foregroundStyle(Color.anchorText(scheme))
                            Spacer()
                            Image(systemName: on ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(on ? Color.anchorAccent(scheme) : Color.anchorSub(scheme))
                        }
                        .padding(14)
                        .background(Color.anchorCard(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
            HStack {
                Button("이전") { step = 1 }
                Spacer()
                Button("다음") { step = 3 }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.anchorAccent(scheme))
            }
            .padding(.bottom, 10)
        }
        .padding(20)
    }

    private var webPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("차단할 웹")
                .font(.title2.bold())
                .foregroundStyle(Color.anchorText(scheme))
            Text("프리셋을 탭해 추가할 수 있어요. 실제 차단은 루틴 탭에서 사이트·앱을 선택하세요.")
                .foregroundStyle(Color.anchorSub(scheme))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(webPresets, id: \.1) { title, domain in
                    let on = selectedWebs.contains(domain)
                    Button {
                        if on { selectedWebs.remove(domain) } else { selectedWebs.insert(domain) }
                    } label: {
                        HStack {
                            Text(title)
                            Spacer()
                            if on { Image(systemName: "checkmark.circle.fill") }
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(12)
                        .background(on ? Color.anchorAccent(scheme).opacity(0.18) : Color.anchorSubBg(scheme))
                        .foregroundStyle(Color.anchorText(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
            HStack {
                Button("이전") { step = 2 }
                Spacer()
                Button("다음") { step = 4 }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.anchorAccent(scheme))
            }
            .padding(.bottom, 10)
        }
        .padding(20)
    }

    private var finishPage: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.anchorAccent(scheme))
            Text("준비 완료!")
                .font(.title.bold())
                .foregroundStyle(Color.anchorText(scheme))
            Text("이제 오늘 탭에서 루틴을 진행해보세요.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.anchorSub(scheme))
                .padding(.horizontal, 18)
            Spacer()
            Button("시작하기") {
                Task { @MainActor in
                    await finish()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.anchorAccent(scheme))
            .padding(.bottom, 28)
            .contentShape(Rectangle())
        }
        .padding()
        .contentShape(Rectangle())
    }

    @MainActor
    private func finish() async {
        let trimmedName = routineName.trimmingCharacters(in: .whitespacesAndNewlines)
        let routine = Routine(
            name: trimmedName.isEmpty ? "나의 루틴" : trimmedName,
            startTime: routineStartTime,
            order: 0,
            blockedWebs: Array(selectedWebs).sorted()
        )
        modelContext.insert(routine)

        let chosen = templates.filter { selectedTemplates.contains($0.key) }
        let effective = chosen.isEmpty ? [templates[1]] : chosen // 기본: 독서

        for (idx, tpl) in effective.enumerated() {
            let item = RoutineItem(
                name: tpl.title,
                duration: 0,
                icon: tpl.icon,
                order: idx,
                routine: routine
            )
            modelContext.insert(item)
            routine.items.append(item)
        }

        try? modelContext.save()

        // 먼저 메인 탭으로 전환 (알림 권한 대기로 UI가 막히지 않도록)
        onComplete()

        _ = await NotificationManager.requestAuthorization()
        try? NotificationManager.rescheduleAll(modelContext: modelContext)
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(PreviewData.container)
}
