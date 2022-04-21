import Foundation
import SwiftUI

struct OffsetReader: View {
    @Binding var offset: CGFloat
    @State var frame = CGRect()
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                Spacer(minLength: 0)
                    .onChange(of: geometry.frame(in: .global)) { value in
                        if value.integral != self.frame.integral {
                            DispatchQueue.main.async {
                                self.frame = value
                                self.offset = value.minY
                            }
                        }
                    }
            }
        }
    }
}
