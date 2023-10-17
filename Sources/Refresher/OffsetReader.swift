import Foundation
import SwiftUI

struct OffsetReader: View {
    var onChange: (CGFloat) -> ()
    @State private var frame = CGRect()

    public var body: some View {
        GeometryReader { geometry in
            Spacer(minLength: 0)
                .onChange(of: geometry.frame(in: .global)) { value in
                    if value.integral != self.frame.integral {
                        DispatchQueue.main.async {
                            self.frame = value
                            onChange(value.minY)
                        }
                    }
                }
        }
    }
}
