#if canImport(UIKit)

import Foundation
import SwiftUI
import UIKit

func lerp(from: CGFloat, to: CGFloat, by: CGFloat) -> CGFloat {
    return from * (1 - by) + to * by
}

func normalize(from min: CGFloat, to max: CGFloat, by val: CGFloat) -> CGFloat {
    let v = (val - min) / (max - min)
    return v < 0 ? 0 : v > 1 ? 1 : v
}

public struct RefreshControlView<RefreshView: View>: View {
    @State var clipThresh: CGFloat = 0.5
    @State var stopPoint: CGFloat = -25
    @State var offScreenPoint: CGFloat = -300
    @State var refreshHoldPoint: CGFloat = 0
    @State var pullClipPoint: CGFloat = 0.2
    
    @Binding var isRefreshing: Bool
    @Binding var percent: CGFloat
    @State var innerHeight: CGFloat = 0
    @State var headerInset: CGFloat? = nil
    @State var allowRefresh = true
    
    @State private var refreshAt: CGFloat = 140
    
    var onRefresh: (@escaping () -> ()) -> ()
    
    var refreshView: () -> RefreshView
    
    func offset(_ y: CGFloat) -> CGFloat {
        let percent = normalize(from: 0, to: refreshAt, by: y)
        if isRefreshing {
            return lerp(from: refreshHoldPoint, to: stopPoint, by: percent)
        }
        return lerp(from: offScreenPoint, to: stopPoint, by: normalize(from: pullClipPoint, to: 1, by: percent))
    }
    
    func refresh() {
        guard !isRefreshing, allowRefresh else {
            return
        }
        allowRefresh = false
        isRefreshing = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onRefresh {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                withAnimation  {
                    isRefreshing = false
                }
            }
        }
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                if headerInset != nil {
                    refreshView()
                    .clipShape(Circle())
                        .frame(maxWidth: .infinity)
                        .offset(y: offset(geometry.frame(in: .global).minY - (headerInset ?? 0)))
                }
                Spacer(minLength: 0)
                    .onChange(of: geometry.frame(in: .global).minY) { value in
                        // Hack to get the header content inset without passing it in as a global
                        if headerInset == nil {
                            headerInset = value
                        }
                        
                        let percent = normalize(from: 0, to: refreshAt, by: value - (headerInset ?? 0))
                        DispatchQueue.main.async {
                            self.percent = percent
                        }
                        if percent >= 1 {
                            refresh()
                        }
                        if percent <= 0.1 {
                            allowRefresh = true
                        }
                    }
            }
            
        }
    }
}


public struct RefreshableScrollView<Content: View, RefreshView: View>: View {
    @State private var percent: CGFloat = 0
    @State private var headerShimMaxHeight: CGFloat = 50
    @State private var isRefreshing = false
    
    @State var overlay = false
    var content: () -> Content
    var refreshView: () -> RefreshView
    var onRefresh: (@escaping () -> ()) -> ()
    
    public init(overlay: Bool = false,
                refreshView: @escaping () -> RefreshView,
                onRefresh: @escaping (@escaping () -> ()) -> (),
                @ViewBuilder _ content: @escaping () -> Content) {
        self.overlay = overlay
        self.onRefresh = onRefresh
        self.refreshView = refreshView
        self.content = content
    }
    
    public var body: some View {
        GeometryReader { globalGeometry in
            ScrollView {
                ZStack(alignment: .top) {
                    VStack {
                        if isRefreshing && !overlay {
                            Color.clear
                                .frame(height: headerShimMaxHeight * (1 - percent))
                        }
                        content()
                    }
                    RefreshControlView(isRefreshing: $isRefreshing, percent: $percent, onRefresh: onRefresh, refreshView: refreshView)
                }
            }
        }
    }
}

extension RefreshableScrollView where RefreshView == DefaultRefreshView {
    public init(overlay: Bool = false, onRefresh: @escaping (@escaping () -> ()) -> (), @ViewBuilder _ content: @escaping () -> Content) {
        self.init(overlay: overlay, refreshView: DefaultRefreshView.init, onRefresh: onRefresh, content)
    }
}
#endif
