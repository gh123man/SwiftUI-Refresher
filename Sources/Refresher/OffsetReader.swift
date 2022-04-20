import Foundation
import SwiftUI

struct OffsetReader: View {
    @Binding var offset: CGFloat
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                Spacer(minLength: 0)
                    .onChange(of: geometry.frame(in: .global).minY) { value in
                        self.offset = value
                    }
            }
        }
    }
}
