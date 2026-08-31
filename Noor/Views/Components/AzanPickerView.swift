import SwiftUI

struct AzanPickerView: View {
    @EnvironmentObject var viewModel: PrayerTimeViewModel
    @StateObject private var azanService = AzanService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    viewModel.showAzanPicker = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Kembali")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.noorTeal)

                Spacer()

                Text("Suara Azan")
                    .font(.headline)

                Spacer()

                Text("Kembali")
                    .font(.subheadline)
                    .opacity(0)
            }
            .padding()

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 1) {
                    ForEach(AzanOption.all) { option in
                        AzanOptionRow(
                            option: option,
                            isSelected: azanService.selectedAzanId == option.id,
                            onSelect: {
                                azanService.select(option.id)
                            },
                            onPreview: {
                                azanService.preview(option.id)
                            }
                        )
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding()
            }
        }
        .frame(width: 320, height: 480)
        .background(.ultraThinMaterial)
    }
}

struct AzanOptionRow: View {
    let option: AzanOption
    let isSelected: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(option.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .medium : .regular)
                Text(option.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                if !option.isSilent {
                    Button(action: onPreview) {
                        Image(systemName: "play.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Color.noorTeal : .secondary.opacity(0.3))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(isSelected ? Color.noorTeal.opacity(0.08) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}
