#if canImport(UIKit)

import Foundation
import SwiftUI
import UIKit

public typealias RefreshAction = (_ completion: @escaping () -> ()) -> ()

func lerp(from: CGFloat, to: CGFloat, by: CGFloat) -> CGFloat {
    return from * (1 - by) + to * by
}

func normalize(from min: CGFloat, to max: CGFloat, by val: CGFloat) -> CGFloat {
    let v = (val - min) / (max - min)
    return v < 0 ? 0 : v > 1 ? 1 : v
}

public struct RefreshControlView<RefreshView: View>: View {
    @Binding var state: RefreshState
    
    @State var offScreenPoint: CGFloat = -300
    var stopPoint: CGFloat
    var refreshHoldPoint: CGFloat
    @State var pullClipPoint: CGFloat = 0.2
    
    @State var innerHeight: CGFloat = 0
    @Binding var headerInset: CGFloat
    
    @Binding var refreshAt: CGFloat
    
    var refreshView: () -> RefreshView
    
    func offset(_ y: CGFloat) -> CGFloat {
        let percent = normalize(from: 0, to: refreshAt, by: y)
        if case .refreshing = state {
            return lerp(from: refreshHoldPoint, to: stopPoint, by: percent)
        }
        return lerp(from: offScreenPoint, to: stopPoint, by: normalize(from: pullClipPoint, to: 1, by: percent))
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                // Nan by default. Don't show the spinner until we have a header inset.
                if !headerInset.isNaN {
                    refreshView()
                        .frame(maxWidth: .infinity)
                        .position(x: geometry.size.width / 2, y: offset(geometry.frame(in: .global).minY - headerInset))
                }
            }
        }
    }
}

enum RefreshState {
    case notRefreshing
    case pulling
    case refreshing
}

public struct RefreshableScrollView<Content: View, RefreshView: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let content: Content
    let refreshAction: RefreshAction
    var refreshView: () -> RefreshView
    
    @State private var headerShimMaxHeight: CGFloat = 50
    @State private var headerInset: CGFloat = .nan
    @State var state: RefreshState = .notRefreshing
    @State var refreshAt: CGFloat = 120
    @State var spinnerStopPoint: CGFloat = -25
    @State var distance: CGFloat = 0
    @State var canRefresh = true
    var overlay: Bool
    
    init(
        axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        refreshAction: @escaping RefreshAction,
        overlay: Bool,
        refreshView: @escaping () -> RefreshView,
        content: Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.refreshAction = refreshAction
        self.refreshView = refreshView
        self.content = content
        self.overlay = overlay
    }
    
    private var refreshBanner: AnyView? {
        if overlay {
            return nil
        }
        switch state {
        case .notRefreshing:
            return AnyView(Color.clear.frame(height: 0))
        case .pulling:
            return AnyView(Color.clear.frame(height: 0))
        case .refreshing:
            return AnyView(Color.clear.frame(height: headerShimMaxHeight * (1 - normalize(from: 0, to: refreshAt, by: distance))))
        }
    }
    
    public var body: some View {
        GeometryReader { globalGeometry in
            ScrollView(axes, showsIndicators: showsIndicators) {
                ZStack(alignment: .top) {
                    
                    // invisible view measures the top of the scrollview and edge insets
                    GeometryReader { geometry in
                        Color.clear.onChange(of: geometry.frame(in: .named("scrollView")).origin) { val in
                            offsetChanged(val)
                        }
                    }.frame(width: 0, height: 0)
                    
                    // Content wrapper with refresh banner
                    VStack(spacing: 0) {
                        refreshBanner
                        content
                    }
                    
                    // Refresh control - zero height, overlays all content
                    RefreshControlView(state: $state,
                                       stopPoint: spinnerStopPoint,
                                       refreshHoldPoint: headerShimMaxHeight / 2,
                                       headerInset: $headerInset,
                                       refreshAt: $refreshAt,
                                       refreshView: refreshView)
                }
            }
            .coordinateSpace(name: "scrollView")
            .onChange(of: globalGeometry.frame(in: .global).minY) { val in
                headerInset = val
            }
        }
    }
    
    private func offsetChanged(_ newOffset: CGPoint) {
        distance = newOffset.y
        if distance < 1 {
            canRefresh = true
        }
        if case .refreshing = state { return }
        if !canRefresh { return }

        guard newOffset.y > 0 else {
            state = .notRefreshing
            return
        }

        if newOffset.y >= refreshAt {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            state = .refreshing
            canRefresh = false

            refreshAction {
                DispatchQueue.main.async {
                    withAnimation {
                        state = .notRefreshing
                    }
                }
            }

        } else if newOffset.y > 0 {
            state = .pulling
        }
    }
}


extension ScrollView {
    public func refresher(overlay: Bool = false, action: @escaping RefreshAction) -> some View {
        RefreshableScrollView(axes: axes,
                              showsIndicators: showsIndicators,
                              refreshAction: action,
                              overlay: overlay,
                              refreshView: DefaultRefreshView.init,
                              content: content)
    }
}

#endif
