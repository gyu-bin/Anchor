//
//  BlockedSelectionSection.swift
//  Anchor
//

import FamilyControls
import SwiftUI

struct BlockedSectionHeader: View {
    @Environment(\.colorScheme) private var scheme

    let title: String
    var caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.anchorText(scheme))
            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(Color.anchorSub(scheme))
            }
        }
    }
}

struct BlockedInlineError: View {
    @Environment(\.colorScheme) private var scheme

    let message: String

    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(Color.anchorDanger(scheme))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FamilyActivityPickerSheet: View {
    @Binding var selection: FamilyActivitySelection
    @Binding var isPresented: Bool

    let title: String
    let onApply: () -> Void
    let onCancelSync: () -> Void

    var body: some View {
        NavigationStack {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(AppCopy.Common.cancel) {
                            onCancelSync()
                            isPresented = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(AppCopy.Common.apply) {
                            onApply()
                            isPresented = false
                        }
                    }
                }
        }
    }
}
