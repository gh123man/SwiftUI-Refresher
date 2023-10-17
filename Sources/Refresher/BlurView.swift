#if canImport(UIKit)
import Foundation
import SwiftUI
import UIKit

struct BlurView: UIViewRepresentable {
    public typealias UIViewType = UIVisualEffectView
    
    let style: UIBlurEffect.Style
    
    init(style: UIBlurEffect.Style = .dark) {
        self.style = style
    }
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: self.style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: self.style)
    }
}
#endif
