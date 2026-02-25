import BackendAPI
import SwiftUI

struct BillFilterDraft: Equatable {
    var showCompletedOnly: Bool = false
    var categoryIds: [Int] = []
    var rangePreset: BillPresetRange? = nil
}

struct BillFilterSheetView: View {
    @Binding var draft: BillFilterDraft
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var categoryText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Toggle("Show Completed Only", isOn: $draft.showCompletedOnly)
                }

                Section("Time Range") {
                    Picker("Range", selection: $draft.rangePreset) {
                        Text("All Time").tag(Optional<BillPresetRange>.none)
                        Text("Today").tag(Optional(BillPresetRange.today))
                        Text("Yesterday").tag(Optional(BillPresetRange.yesterday))
                        Text("Last 7 Days").tag(Optional(BillPresetRange.last7Days))
                        Text("Monthly").tag(Optional(BillPresetRange.monthly))
                    }
                    .pickerStyle(.inline)
                }

                Section("Category IDs") {
                    TextField("Enter comma-separated values, e.g. 1,2,3", text: $categoryText)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !draft.categoryIds.isEmpty {
                        Text("Current: \(draft.categoryIds.map(String.init).joined(separator: ", "))")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        draft = BillFilterDraft()
                        categoryText = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        draft.categoryIds = parseCategoryIds(categoryText)
                        onApply()
                        dismiss()
                    }
                }
            }
            .onAppear {
                categoryText = draft.categoryIds.map(String.init).joined(separator: ",")
            }
        }
    }

    private func parseCategoryIds(_ text: String) -> [Int] {
        text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap(Int.init)
    }
}
