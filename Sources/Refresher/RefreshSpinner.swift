import Foundation
import SwiftUI

public struct RefreshSpinnerView<RefreshView: View>: View {
    var offScreenPoint: CGFloat
    var pullClipPoint: CGFloat
    var mode: RefreshMode
    var stopPoint: CGFloat
    var refreshHoldPoint: CGFloat
    var refreshView: RefreshView
    
    @Binding var headerInset: CGFloat
    var refreshAt: CGFloat
    
    func offset(_ y: CGFloat) -> CGFloat {
        let percent = normalize(from: 0, to: refreshAt, by: y)
        if case .refreshing = mode {
            return lerp(from: refreshHoldPoint, to: stopPoint, by: percent)
        }
        let normalizedPercent = normalize(from: pullClipPoint, to: 1, by: percent)
        if normalizedPercent == 0 {
            // Since the spinner view moves with the scrollview, move it
            // backwards until we are ready to start the refreshing animation
            return -headerInset + offScreenPoint * (1 + percent)
        }
        return lerp(from: -headerInset + offScreenPoint, to: stopPoint, by: normalizedPercent)
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
    var opacityClipPoint: CGFloat
    
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
                    .opacity(state.modeAnimated == .refreshing ? 1 : normalize(from: opacityClipPoint, to: 1, by: state.dragPosition))
                    .animation(.easeInOut(duration: 0.2), value: state.modeAnimated == .notRefreshing)
            }
        }
    }
}

public struct System2StyleRefreshSpinner<RefreshView: View>: View {
    var opacityClipPoint: CGFloat
    
    var state: RefresherState
    var refreshHoldPoint: CGFloat
    var refreshView: RefreshView
    
    func offset() -> CGFloat {
        switch state.mode {
        case .refreshing, .notRefreshing:
            return refreshHoldPoint
        default: return lerp(from: 0, to: refreshHoldPoint, by: state.dragPosition)
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                refreshView
                    .frame(maxWidth: .infinity)
                    .position(x: geometry.size.width / 2, y: offset())
                    .opacity(state.modeAnimated == .refreshing ? 1 : normalize(from: opacityClipPoint, to: 1, by: state.dragPosition))
                    .animation(.easeInOut(duration: 0.2), value: state.modeAnimated == .notRefreshing)
            }
        }
    }
}
