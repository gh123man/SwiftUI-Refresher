import Foundation
import SwiftUI

struct UIActivityView: UIViewRepresentable {
    var style: UIActivityIndicatorView.Style = .medium
    @Binding var isAnimating: Bool
    
    
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let v = UIActivityIndicatorView(style: style)
        v.hidesWhenStopped = false
        return v
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        if isAnimating {
            uiView.startAnimating()
        } else {
            uiView.stopAnimating()
        }
    }
}

public struct DefaultRefreshView: View {
    @Binding var state: RefresherState
    @State var isAnimating = false
    
    public init(state: Binding<RefresherState>) {
        self._state = state
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    public var body: some View {
        if state.style == .system || state.style == .system2 {
            VStack {
                UIActivityView(style: .large, isAnimating: $isAnimating)
                    .rotationEffect(.degrees(state.mode == .pulling ? 360 * state.dragPosition : 360))
                    .onChange(of: state.mode) { newMode in
                        isAnimating = newMode != .pulling
                    }
            }
        } else {
            VStack {
                UIActivityView(isAnimating: $isAnimating)
                    .padding(5)
                    .rotationEffect(.degrees(state.mode == .pulling ? 360 * state.dragPosition : 360))
                    .onChange(of: state.mode) { newMode in
                        isAnimating = newMode != .pulling
                    }
            }
            .background(BlurView(style: colorScheme == .dark ? .dark : .light))
                .clipShape(Circle())
            
        }
    }
}
