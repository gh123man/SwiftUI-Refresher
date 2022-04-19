import Foundation
import SwiftUI

public struct DefaultRefreshView: View {
    
    @Binding var state: RefresherState
    
    public init(state: Binding<RefresherState>) {
        self._state = state
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    public var body: some View {
        VStack {
            ProgressView()
                .padding(5)
        }
        .background(BlurView(style: colorScheme == .dark ? .dark : .light))
        .clipShape(Circle())
        .onChange(of: state.dragPosition) { val in
            print(val)
        }
    }
}

