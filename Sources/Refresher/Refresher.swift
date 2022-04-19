import Foundation
import SwiftUI

public typealias RefreshAction = (_ completion: @escaping () -> ()) -> ()

func lerp(from: CGFloat, to: CGFloat, by: CGFloat) -> CGFloat {
    return from * (1 - by) + to * by
}

func normalize(from min: CGFloat, to max: CGFloat, by val: CGFloat) -> CGFloat {
    let v = (val - min) / (max - min)
    return v < 0 ? 0 : v > 1 ? 1 : v
}

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
}

public struct RefreshSpinnerView<RefreshView: View>: View {
    @Binding var state: RefreshMode
    @State var offScreenPoint: CGFloat = -300
    var stopPoint: CGFloat
    var refreshHoldPoint: CGFloat
    @State var pullClipPoint: CGFloat = 0.2
    @Binding var headerInset: CGFloat
    @Binding var refreshAt: CGFloat
    var refreshView: RefreshView
    
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
                    refreshView
                        .frame(maxWidth: .infinity)
                        .position(x: geometry.size.width / 2, y: offset(geometry.frame(in: .global).minY - headerInset))
                }
            }
        }
    }
}

public struct SystemStyleRefreshSpinner<RefreshView: View>: View {
    var position: CGFloat
    var refreshView: RefreshView
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                refreshView
                    .frame(maxWidth: .infinity)
                    .offset(y: -position)
            }
        }
    }
}

public struct RefreshableScrollView<Content: View, RefreshView: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let content: Content
    let refreshAction: RefreshAction
    var refreshView: (Binding<RefresherState>) -> RefreshView
    
    @State private var headerShimMaxHeight: CGFloat = 50
    @State private var headerInset: CGFloat = .nan
    @State var state: RefresherState = RefresherState()
    @State var refreshAt: CGFloat = 120
    @State var spinnerStopPoint: CGFloat = -25
    @State var distance: CGFloat = 0
    @State var canRefresh = true
    var style: Style
    
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
        switch style {
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
        switch style {
        case .default, .overlay:
            return AnyView(RefreshSpinnerView(state: $state.mode,
                                      stopPoint: spinnerStopPoint,
                                      refreshHoldPoint: headerShimMaxHeight / 2,
                                      headerInset: $headerInset,
                                      refreshAt: $refreshAt,
                                      refreshView: refreshView($state)))
        default:
            return nil
        }
    }
    
    private var systemRefershSpinner: AnyView? {
        switch style {
        case .system:
            return AnyView(SystemStyleRefreshSpinner(position: distance,
                                                     refreshView: refreshView($state)))
        default:
            return nil
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
                    
                    systemRefershSpinner
                    // Content wrapper with refresh banner
                    VStack(spacing: 0) {
                        refreshBanner
                        content
                    }
                    refershSpinner
                }
            }
            .coordinateSpace(name: "scrollView")
            .onChange(of: globalGeometry.frame(in: .global).minY) { val in
                headerInset = val
            }
            .onAppear {
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
