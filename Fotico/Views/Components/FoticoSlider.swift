import SwiftUI

struct FoticoSlider: View {
    let label: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let defaultValue: Double
    var step: Double = 0.01
    var formatStyle: SliderFormatStyle = .decimal

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Color.foticoPrimary)
                    .frame(width: 20)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                Text(formattedValue)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(value != defaultValue ? Color.foticoPrimary : .gray)

                if value != defaultValue {
                    Button {
                        value = defaultValue
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption2)
                            .foregroundColor(Color.foticoWarning)
                    }
                }
            }

            Slider(value: $value, in: range, step: step)
                .tint(Color.foticoPrimary)
        }
    }

    private var formattedValue: String {
        switch formatStyle {
        case .decimal:
            return value >= 0 ? "+\(String(format: "%.2f", value))" : String(format: "%.2f", value)
        case .percentage:
            return "\(Int(value * 100))%"
        case .integer:
            return "\(Int(value))"
        case .kelvin:
            return "\(Int(value))K"
        }
    }
}

enum SliderFormatStyle {
    case decimal
    case percentage
    case integer
    case kelvin
}
