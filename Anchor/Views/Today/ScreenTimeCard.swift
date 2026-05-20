//
//  ScreenTimeCard.swift
//  Anchor
//

import FamilyControls
import SwiftUI

struct ScreenTimeCard: View {
    @Environment(\.colorScheme) private var scheme
    @State private var authorizationStatus = ShieldManager.authorizationStatus()

    var body: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "hourglass")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.anchorAccent(scheme))
                    Text("스크린타임")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.anchorSub(scheme))
                }
                .padding(.horizontal, AnchorLayout.cardPadding)
                .padding(.top, AnchorLayout.cardPadding)
                .padding(.bottom, 4)

                ScreenTimeReportSection(
                    authorizationStatus: authorizationStatus,
                    onRequestAuthorization: {
                        Task {
                            try? await ShieldManager.requestAuthorization()
                            authorizationStatus = ShieldManager.authorizationStatus()
                        }
                    }
                )
            }
        }
        .onAppear {
            authorizationStatus = ShieldManager.authorizationStatus()
        }
    }
}
