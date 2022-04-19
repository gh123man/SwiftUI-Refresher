import Foundation
import SwiftUI

public struct RefreshSpinnerView<RefreshView: View>: View {
    var offScreenPoint: CGFloat = -300
    var pullClipPoint: CGFloat = 0.2
    
    var mode: RefreshMode
    var stopPoint: CGFloat
    var refreshHoldPoint: CGFloat
    var refreshView: RefreshView
    
    @Binding var headerInset: CGFloat
    @Binding var refreshAt: CGFloat
    
    func offset(_ y: CGFloat) -> CGFloat {
        let percent = normalize(from: 0, to: refreshAt, by: y)
        if case .refreshing = mode {
            return lerp(from: refreshHoldPoint, to: stopPoint, by: percent)
        }
        return lerp(from: offScreenPoint, to: stopPoint, by: normalize(from: pullClipPoint, to: 1, by: percent))
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                refreshView
                    .frame(maxWidth: .infinity)
                    .position(x: geometry.size.width / 2, y: offset(geometry.frame(in: .global).minY - headerInset))
            }   
        }
    }
}

public struct SystemStyleRefreshSpinner<RefreshView: View>: View {
    var opacityClipPoint: CGFloat = 0.2
    
    var state: RefresherState
    var position: CGFloat
    var refreshHoldPoint: CGFloat
    var refreshView: RefreshView
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                refreshView
                    .frame(maxWidth: .infinity)
                    .position(x: geometry.size.width / 2, y: -position + refreshHoldPoint)
                    .opacity(state.mode == .refreshing ? 1 : normalize(from: opacityClipPoint, to: 1, by: state.dragPosition))
            }
        }
    }
}
