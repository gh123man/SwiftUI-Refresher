import Foundation
import SwiftUI

public typealias RefreshAction = (_ completion: @escaping () -> ()) -> ()

public enum Style {
    case `default`
    case system
    case overlay
}

public enum RefreshMode {
    case notRefreshing
    case pulling
    case refreshing
}

public struct RefresherState {
    public var mode: RefreshMode = .notRefreshing
    public var dragPosition: CGFloat = 0
    public var style: Style = .default
}


public struct RefreshableScrollView<Content: View, RefreshView: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let content: Content
    let refreshAction: RefreshAction
    var refreshView: (Binding<RefresherState>) -> RefreshView
    
    @State private var headerShimMaxHeight: CGFloat = 75
    @State private var headerInset: CGFloat = .nan
    @State var state: RefresherState = RefresherState()
    @State var refreshAt: CGFloat = 120
    @State var spinnerStopPoint: CGFloat = -25
    @State var distance: CGFloat = 0
    @State var canRefresh = true
    private var style: Style
    
    init(
        axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        refreshAction: @escaping RefreshAction,
        style: Style,
        refreshView: @escaping (Binding<RefresherState>) -> RefreshView,
        content: Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.refreshAction = refreshAction
        self.refreshView = refreshView
        self.content = content
        self.style = style
    }
    
    private var refreshBanner: AnyView? {
        switch state.style {
        case .default, .system:
            if case .refreshing = state.mode {
                return AnyView(Color.clear.frame(height: headerShimMaxHeight * (1 - state.dragPosition)))
            }
        case .overlay:
            return AnyView(Color.clear.frame(height: 0))
        }
        
        return AnyView(Color.clear.frame(height: 0))
    }
    
    private var refershSpinner: AnyView? {
        return state.style == .default || state.style == .overlay
            ? AnyView(RefreshSpinnerView(mode: state.mode,
                                         stopPoint: spinnerStopPoint,
                                         refreshHoldPoint: headerShimMaxHeight / 2,
                                         refreshView: refreshView($state),
                                         headerInset: $headerInset,
                                         refreshAt: $refreshAt))
            : nil
    }
    
    private var systemStylerefreshSpinner: AnyView? {
        return state.style == .system
            ? AnyView(SystemStyleRefreshSpinner(state: state,
                                                position: distance,
                                                refreshHoldPoint: headerShimMaxHeight / 2,
                                                refreshView: refreshView($state)))
            : nil
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
                    }
                    
                    systemStylerefreshSpinner
                    
                    // Content wrapper with refresh banner
                    VStack(spacing: 0) {
                        refreshBanner
                        content
                    }
                    // renders over content
                    refershSpinner
                }
            }
            .coordinateSpace(name: "scrollView")
            .onChange(of: globalGeometry.frame(in: .global).minY) { val in
                headerInset = val
            }
            .onAppear {
                state.style = style
                DispatchQueue.main.async {
                    headerInset = globalGeometry.frame(in: .global).minY
                }
            }
        }
    }
    
    private func offsetChanged(_ newOffset: CGPoint) {
        distance = newOffset.y
        if distance < 1 {
            canRefresh = true
        }
        
        state.dragPosition = normalize(from: 0, to: refreshAt, by: distance)
        if case .refreshing = state.mode { return }
        if !canRefresh { return }

        guard newOffset.y > 0 else {
            state.mode = .notRefreshing
            return
        }

        if newOffset.y >= refreshAt {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            state.mode = .refreshing
            canRefresh = false

            refreshAction {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                    withAnimation {
                        state.mode = .notRefreshing
                    }
                }
            }

        } else if newOffset.y > 0 {
            state.mode = .pulling
        }
    }
}
