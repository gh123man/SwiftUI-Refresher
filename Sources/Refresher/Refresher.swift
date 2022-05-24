import Foundation
import SwiftUI
import Introspect

public typealias RefreshAction = (_ completion: @escaping () -> ()) -> ()

public struct Config {
    /// Drag distance needed to trigger a refresh
    public var refreshAt: CGFloat
    
    /// Max height of the spacer for the refresh spinner to sit while refreshing
    public var headerShimMaxHeight: CGFloat
    
    /// Offset where the spinner stops moving after draging
    public var defaultSpinnerSpinnerStopPoint: CGFloat
    
    /// Off screen start point for the spinner
    public var defaultSpinnerOffScreenPoint: CGFloat
    
    /// How far you have to pull (from 0 - 1) for the spinner to start moving
    public var defaultSpinnerPullClipPoint: CGFloat
    
    /// How far you have to pull (from 0 - 1) for the spinner to start becoming visible
    public var systemSpinnerOpacityClipPoint: CGFloat
    
    /// How long to hold the spinner before dismissing (a small delay is a nice UX if the refresh is VERY fast)
    public var holdTime: DispatchTimeInterval
    
    public init(
        refreshAt: CGFloat = 120,
        headerShimMaxHeight: CGFloat = 75,
        defaultSpinnerSpinnerStopPoint: CGFloat = -50,
        defaultSpinnerOffScreenPoint: CGFloat = -300,
        defaultSpinnerPullClipPoint: CGFloat = 0.2,
        systemSpinnerOpacityClipPoint: CGFloat = 0.2,
        holdTime: DispatchTimeInterval = .milliseconds(300)
    ) {
        self.refreshAt = refreshAt
        self.defaultSpinnerSpinnerStopPoint = defaultSpinnerSpinnerStopPoint
        self.headerShimMaxHeight = headerShimMaxHeight
        self.defaultSpinnerOffScreenPoint = defaultSpinnerOffScreenPoint
        self.defaultSpinnerPullClipPoint = defaultSpinnerPullClipPoint
        self.systemSpinnerOpacityClipPoint = systemSpinnerOpacityClipPoint
        self.holdTime = holdTime
    }
}

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
    
    @State private var headerInset: CGFloat = 1000000 // Somewhere far off screen
    @State var state = RefresherState()
    @State var distance: CGFloat = 0
    @State var rawDistance: CGFloat = 0
    private var style: Style
    private var config: Config
    
    @State private var uiScrollView: UIScrollView?
    @State private var isRefresherVisible = true
    @State private var isFingerDown = false
    
    init(
        axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        refreshAction: @escaping RefreshAction,
        style: Style,
        config: Config,
        refreshView: @escaping (Binding<RefresherState>) -> RefreshView,
        content: Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.refreshAction = refreshAction
        self.refreshView = refreshView
        self.content = content
        self.style = style
        self.config = config
    }
    
    private var refreshHeaderOffset: CGFloat {
        switch state.style {
        case .default, .system:
            if case .refreshing = state.modeAnimated {
                return config.headerShimMaxHeight * (1 - state.dragPosition)
            }
        default: break
        }
        
        return 0
    }
    
    private var isTracking: Bool {
        guard let scrollView = uiScrollView else { return false }
        return scrollView.isTracking
    }
    
    private var showRefreshControls: Bool {
        return isFingerDown || isRefresherVisible
    }
    
    @ViewBuilder
    private var refershSpinner: some View {
        if showRefreshControls && (state.style == .default || state.style == .overlay) {
             RefreshSpinnerView(offScreenPoint: config.defaultSpinnerOffScreenPoint,
                                pullClipPoint: config.defaultSpinnerPullClipPoint,
                                mode: state.modeAnimated,
                                stopPoint: config.defaultSpinnerSpinnerStopPoint,
                                refreshHoldPoint: config.headerShimMaxHeight / 2,
                                refreshView: refreshView($state),
                                headerInset: $headerInset,
                                refreshAt: config.refreshAt)
        }
    }
    
    @ViewBuilder
    private var systemStylerefreshSpinner: some View {
        if showRefreshControls && state.style == .system {
            SystemStyleRefreshSpinner(opacityClipPoint: config.systemSpinnerOpacityClipPoint,
                                      state: state,
                                      position: distance,
                                      refreshHoldPoint: config.headerShimMaxHeight / 2,
                                      refreshView: refreshView($state))
        }
    }
    
    public var body: some View {
        // The ordering of views and operations here is very important - things break
        // in very strange ways between iOS 14 and iOS 15.
        GeometryReader { globalGeometry in
            ScrollView(axes, showsIndicators: showsIndicators) {
                ZStack(alignment: .top) {
                    OffsetReader { val in
                        offsetChanged(val)
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
            .introspectScrollView { scrollView in
                uiScrollView = scrollView
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
    
    private func offsetChanged(_ val: CGFloat) {
        isFingerDown = isTracking
        distance = val - headerInset
        state.dragPosition = normalize(from: 0, to: config.refreshAt, by: distance)
        
        if case .refreshing = state.mode { return }
        guard distance > 0, showRefreshControls else {
            state.mode = .notRefreshing
            isRefresherVisible = false
            return
        }
        
        isRefresherVisible = true

        if distance >= config.refreshAt {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            set(mode: .refreshing)

            refreshAction {
                DispatchQueue.main.asyncAfter(deadline: .now() + config.holdTime) {
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
