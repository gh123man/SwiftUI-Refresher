import Foundation
import SwiftUI

struct LockedRenderView<Content: View>: View {
    struct LockedView: View, Equatable {
        @Binding var lock: Bool
        @ViewBuilder var content: Content
        
        static func == (lhs: LockedView, rhs: LockedView) -> Bool {
            if rhs.lock {
                return true
            }
            return false
        }
        
        var body: some View {
            content
        }
    }
    
    init(lock: Binding<Bool>, content: () -> Content) {
        self._lock = lock
        self.content = content()
    }
    
    @Binding var lock: Bool
    @ViewBuilder var content: Content
    
    public var body: some View {
        return LockedView(lock: $lock) {
            content
        }.equatable()
    }
}
