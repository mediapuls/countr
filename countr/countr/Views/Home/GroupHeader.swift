import SwiftUI
import SwiftData

struct GroupHeader: View {
    @Bindable var group: CounterGroup

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) { group.isExpanded.toggle() }
        } label: {
            HStack {
                Text(group.name).font(.headline).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                    .rotationEffect(.degrees(group.isExpanded ? 90 : 0))
                    .animation(.easeInOut(duration: 0.25), value: group.isExpanded)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(group.name), \(group.isExpanded ? "expanded" : "collapsed")")
        .accessibilityHint("Double tap to \(group.isExpanded ? "collapse" : "expand")")
    }
}
