import SwiftUI

struct CounterColorPicker: View {
    @Binding var selection: CounterColor
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(CounterColor.allCases) { counterColor in
                Circle().fill(counterColor.color)
                    .frame(width: 36, height: 36)
                    .overlay {
                        if counterColor == selection {
                            Circle().strokeBorder(.white, lineWidth: 3)
                            Image(systemName: "checkmark").font(.caption).fontWeight(.bold).foregroundStyle(.white)
                        }
                    }
                    .onTapGesture { selection = counterColor }
                    .accessibilityLabel(counterColor.rawValue)
                    .accessibilityAddTraits(counterColor == selection ? .isSelected : [])
            }
        }
    }
}
