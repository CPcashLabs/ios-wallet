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
                Section("状态") {
                    Toggle("仅显示已完成", isOn: $draft.showCompletedOnly)
                }

                Section("时间范围") {
                    Picker("范围", selection: $draft.rangePreset) {
                        Text("全部时间").tag(Optional<BillPresetRange>.none)
                        Text("Today").tag(Optional(BillPresetRange.today))
                        Text("Yesterday").tag(Optional(BillPresetRange.yesterday))
                        Text("Last 7 Days").tag(Optional(BillPresetRange.last7Days))
                        Text("Monthly").tag(Optional(BillPresetRange.monthly))
                    }
                    .pickerStyle(.inline)
                }

                Section("分类ID") {
                    TextField("输入逗号分隔，例如 1,2,3", text: $categoryText)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !draft.categoryIds.isEmpty {
                        Text("当前: \(draft.categoryIds.map(String.init).joined(separator: ", "))")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("重置") {
                        draft = BillFilterDraft()
                        categoryText = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("应用") {
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
