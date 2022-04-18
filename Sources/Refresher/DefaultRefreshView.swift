import Foundation
import SwiftUI

public struct DefaultRefreshView: View {
    @Environment(\.colorScheme) var colorScheme
    
    public var body: some View {
        VStack {
            ProgressView()
                .padding(5)
        }
        .background(BlurView(style: colorScheme == .dark ? .dark : .light))
        .clipShape(Circle())
    }
}
