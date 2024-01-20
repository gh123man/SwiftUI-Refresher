import Foundation
import SwiftUI

struct OffsetReader: View {
    var onChange: (CGFloat) -> ()

    public var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: OffsetPreferenceKey.self,
                            value: geometry.frame(in: .global).minY)
                .onPreferenceChange(OffsetPreferenceKey.self) { offset in
                    onChange(offset)
                }
        }
    }
}

private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue = CGFloat.zero

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
