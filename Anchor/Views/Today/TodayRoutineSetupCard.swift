//
//  TodayRoutineSetupCard.swift
//  Anchor
//

import SwiftUI

struct TodayRoutineSetupCard: View {
    @Environment(\.colorScheme) private var scheme

    let routine: Routine
    let onOpenRoutineTab: () -> Void

    var body: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(routine.name)
                    .font(AnchorTypography.cardTitle(scheme))
                    .foregroundStyle(Color.anchorText(scheme))

                Text(AppCopy.Today.setupItemsBody)
                    .font(.subheadline)
                    .foregroundStyle(Color.anchorSub(scheme))

                Button(AppCopy.Today.setupItemsAction, action: onOpenRoutineTab)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.anchorAccent(scheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AnchorLayout.cardPadding)
        }
    }
}
