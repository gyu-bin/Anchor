//
//  OnboardingView.swift
//  Anchor
//

import FamilyControls
import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    var onComplete: () -> Void

    @State private var step = 0
    @State private var routineName: String = "나의 루틴"
    @State private var routineStartTime = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
    @State private var selectedTemplates: Set<String> = []
    @State private var selectedWebs: Set<String> = []
    @State private var screenTimeStatus: AuthorizationStatus = .notDetermined
    @State private var onboardingAppSelection = FamilyActivitySelection()
    @State private var showOnboardingAppPicker = false

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
                screenTimePage.tag(4)
                finishPage.tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .anchorScreenBackground()
            .onAppear {
                screenTimeStatus = ShieldManager.authorizationStatus()
            }
            .sheet(isPresented: $showOnboardingAppPicker) {
                NavigationStack {
                    FamilyActivityPicker(selection: $onboardingAppSelection)
                        .navigationTitle(AppCopy.Onboarding.pickApps)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button(AppCopy.Common.save) { showOnboardingAppPicker = false }
                            }
                        }
                }
            }
        }
    }

    private var introPage: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.anchorAccent(scheme).opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: "key.fill")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(Color.anchorAccent(scheme))
                    .symbolRenderingMode(.hierarchical)
            }
            VStack(spacing: 12) {
                Text(AppBrand.displayName)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.anchorText(scheme))
                Text(AppCopy.Onboarding.introBody)
                    .font(.body)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.anchorSub(scheme))
                    .padding(.horizontal, 28)
            }
            Spacer()
            Button(AppCopy.Onboarding.start) { step = 1 }
                .buttonStyle(AnchorButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
        }
    }

    private var routineSetupPage: some View {
        OnboardingPageShell(
            title: AppCopy.Onboarding.routineTitle,
            subtitle: AppCopy.Onboarding.routineSubtitle,
            content: {
                VStack(spacing: 14) {
                    TextField("루틴 이름", text: $routineName)
                        .font(.body)
                        .anchorInsetField()
                    DatePicker("시작 시간", selection: $routineStartTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "ko_KR"))
                }
            },
            showsBack: true,
            primaryTitle: AppCopy.Common.next,
            onBack: { step = 0 },
            onPrimary: { step = 2 }
        )
    }

    private var templatePage: some View {
        OnboardingPageShell(
            title: AppCopy.Onboarding.itemsTitle,
            subtitle: AppCopy.Onboarding.itemsSubtitle,
            content: {
                VStack(spacing: 8) {
                    ForEach(templates, id: \.key) { tpl in
                        AnchorSelectionRow(
                            icon: tpl.icon,
                            title: tpl.title,
                            isSelected: selectedTemplates.contains(tpl.key)
                        ) {
                            if selectedTemplates.contains(tpl.key) {
                                selectedTemplates.remove(tpl.key)
                            } else {
                                selectedTemplates.insert(tpl.key)
                            }
                        }
                    }
                }
            },
            showsBack: true,
            primaryTitle: AppCopy.Common.next,
            onBack: { step = 1 },
            onPrimary: { step = 3 }
        )
    }

    private var webPage: some View {
        OnboardingPageShell(
            title: AppCopy.Onboarding.webTitle,
            subtitle: AppCopy.Onboarding.webSubtitle,
            content: {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                    ForEach(webPresets, id: \.1) { title, domain in
                        AnchorChip(
                            title: title,
                            isSelected: selectedWebs.contains(domain)
                        ) {
                            if selectedWebs.contains(domain) {
                                selectedWebs.remove(domain)
                            } else {
                                selectedWebs.insert(domain)
                            }
                        }
                    }
                }
            },
            showsBack: true,
            primaryTitle: AppCopy.Common.next,
            onBack: { step = 2 },
            onPrimary: { step = 4 }
        )
    }

    private var screenTimePage: some View {
        OnboardingPageShell(
            title: AppCopy.Onboarding.screenTimeTitle,
            subtitle: AppCopy.Onboarding.screenTimeSubtitle,
            content: {
                VStack(spacing: 14) {
                    AnchorCard(elevated: false) {
                        HStack(spacing: 14) {
                            Image(systemName: screenTimeStatus == .approved ? "checkmark.shield.fill" : "lock.shield")
                                .font(.title2)
                                .foregroundStyle(
                                    screenTimeStatus == .approved ? Color.anchorSuccess(scheme) : Color.anchorAccent(scheme)
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                Text(screenTimeStatus == .approved ? AppCopy.Onboarding.screenTimeLinked : AppCopy.Onboarding.screenTimeNeeded)
                                    .font(AnchorTypography.cardTitle(scheme))
                                    .foregroundStyle(Color.anchorText(scheme))
                                Text(statusCaption)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.anchorSub(scheme))
                            }
                            Spacer()
                        }
                        .padding(AnchorLayout.cardPadding)
                    }

                    if screenTimeStatus != .approved {
                        Button(AppCopy.Onboarding.screenTimeAllow) {
                            Task { await requestScreenTime() }
                        }
                        .buttonStyle(AnchorSecondaryButtonStyle())
                    } else {
                        Button(AppCopy.Onboarding.pickApps) {
                            showOnboardingAppPicker = true
                        }
                        .buttonStyle(AnchorSecondaryButtonStyle())

                        if !onboardingAppSelection.applicationTokens.isEmpty {
                            Text("\(AppCopy.Onboarding.pickedAppsCount) \(onboardingAppSelection.applicationTokens.count)개")
                                .font(.caption)
                                .foregroundStyle(Color.anchorSub(scheme))
                        }
                    }
                }
            },
            showsBack: true,
            primaryTitle: screenTimeStatus == .approved ? AppCopy.Common.next : AppCopy.Common.later,
            onBack: { step = 3 },
            onPrimary: { step = 5 }
        )
    }

    private var statusCaption: String {
        AppCopy.Onboarding.screenTimeCaption(
            approved: screenTimeStatus == .approved,
            denied: screenTimeStatus == .denied
        )
    }

    private var finishPage: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.anchorSuccess(scheme).opacity(0.14))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.anchorSuccess(scheme))
                    .symbolRenderingMode(.hierarchical)
            }
            VStack(spacing: 10) {
                Text(AppCopy.Onboarding.finishTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.anchorText(scheme))
                Text(AppCopy.Onboarding.finishBody)
                    .font(.body)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.anchorSub(scheme))
                    .padding(.horizontal, 28)
            }
            Spacer()
            Button(AppCopy.Onboarding.finishAction) {
                Task { @MainActor in await finish() }
            }
            .buttonStyle(AnchorButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
    }

    @MainActor
    private func requestScreenTime() async {
        try? await ShieldManager.requestAuthorization()
        screenTimeStatus = ShieldManager.authorizationStatus()
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
        let effective = chosen.isEmpty ? [templates[1]] : chosen

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

        if !onboardingAppSelection.applicationTokens.isEmpty {
            try? ShieldManager.saveSelection(onboardingAppSelection, for: routine, modelContext: modelContext)
        }

        try? modelContext.save()

        onComplete()

        if ShieldManager.authorizationStatus() != .approved {
            try? await ShieldManager.requestAuthorization()
        }
        _ = await NotificationManager.requestAuthorization()
        try? NotificationManager.rescheduleAll(modelContext: modelContext)
        await ShieldManager.refresh(modelContext: modelContext)
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(PreviewData.container)
}
