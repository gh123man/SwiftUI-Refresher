import Foundation
import SwiftUI

public typealias RefreshAction = (_ completion: @escaping () -> ()) -> ()

public enum Style {
    
    /// Spinner pulls down and centers on a padding view above the scrollview
    case `default`
    
    /// Mimic the system refresh controller as close as possible
    case system
    
    /// Overlay the spinner onto the cotained view - good for static images
    case overlay
}

public enum RefreshMode {
    case notRefreshing
    case pulling
    case refreshing
}

public struct RefresherState {
    
    /// Updated without animation - NOTE: Both modes are always updated in sequence (this one is first)
    public var mode: RefreshMode = .notRefreshing
    
    /// Updated with animation (this one is second)
    public var modeAnimated: RefreshMode = .notRefreshing
    
    /// Value from 0 - 1. 0 is resting state, 1 is refresh trigger point - use this value for custom translations
    public var dragPosition: CGFloat = 0
    
    /// the configuration style - useful if you want your custom spinner to change behavior based on the style
    public var style: Style = .default
}


public struct RefreshableScrollView<Content: View, RefreshView: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let content: Content
    let refreshAction: RefreshAction
    var refreshView: (Binding<RefresherState>) -> RefreshView
    
    @State private var headerShimMaxHeight: CGFloat = 75
    @State private var headerInset: CGFloat = 1000000 // Somewhere far off screen
    @State var state: RefresherState = RefresherState()
    @State var refreshAt: CGFloat = 120
    @State var spinnerStopPoint: CGFloat = -25
    @State var distance: CGFloat = 0
    @State var rawDistance: CGFloat = 0
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
    
    private var refreshHeaderOffset: CGFloat {
        switch state.style {
        case .default, .system:
            if case .refreshing = state.modeAnimated {
                return headerShimMaxHeight * (1 - state.dragPosition)
            }
        default: break
        }
        
        return 0
    }
    
    private var refershSpinner: AnyView? {
        return (state.style == .default || state.style == .overlay)
            ? AnyView(RefreshSpinnerView(mode: state.modeAnimated,
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
        // The ordering of views and operations here is very important - things break
        // in very strange ways between iOS 14 and iOS 15.
        GeometryReader { globalGeometry in
            ScrollView(axes, showsIndicators: showsIndicators) {
                ZStack(alignment: .top) {
                    OffsetReader { val in
                        distance = val - headerInset
                        offsetChanged()
                    }
                    systemStylerefreshSpinner
                    
                    // Content wrapper with refresh banner
                    VStack(spacing: 0) {
                        content
                            .offset(y: refreshHeaderOffset)
                    }
                    // renders over content
                    refershSpinner
                }
            }
            .onChange(of: globalGeometry.frame(in: .global)) { val in
                headerInset = val.minY
            }
            .onAppear {
                state.style = style
                DispatchQueue.main.async {
                    headerInset = globalGeometry.frame(in: .global).minY
                }
            }
        }
    }
    
    private func offsetChanged() {
        if distance < 1 {
            canRefresh = true
        }
        
        state.dragPosition = normalize(from: 0, to: refreshAt, by: distance)
        if case .refreshing = state.mode { return }
        if !canRefresh { return }

        guard distance > 0 else {
            set(mode: .notRefreshing)
            return
        }

        if distance >= refreshAt {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            set(mode: .refreshing)
            canRefresh = false

            refreshAction {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                    set(mode: .notRefreshing)
                }
            }

        } else if distance > 0 {
            set(mode: .pulling)
        }
    }
    
    func set(mode: RefreshMode) {
        state.mode = mode
        withAnimation {
            state.modeAnimated = mode
        }
    }
}
