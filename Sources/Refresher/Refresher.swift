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
    @State var stopPoint: CGFloat = -50
    @State var offScreenPoint: CGFloat = -300
    @State var refreshHoldPoint: CGFloat = 0
    @State var pullClipPoint: CGFloat = 0.2
    
    @Binding var isRefreshing: Bool
    @Binding var percent: CGFloat
    @State var innerHeight: CGFloat = 0
    @Binding var headerInset: CGFloat
    @State var allowRefresh = true
    
    @State private var refreshAt: CGFloat = 120
    
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
                // Nan by default. Don't show the spinner until we have a header inset.
                if !headerInset.isNaN {
                    refreshView()
                        .frame(maxWidth: .infinity)
                        .offset(y: offset(geometry.frame(in: .global).minY - headerInset))
                }
                Spacer(minLength: 0)
                    .onChange(of: geometry.frame(in: .global).minY) { value in
                        let percent = normalize(from: 0, to: refreshAt, by: value - headerInset)
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
    @State private var headerInset: CGFloat = .nan
    
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
                    VStack(spacing: 0) {
                        if isRefreshing && !overlay {
                            Color.clear
                                .frame(height: headerShimMaxHeight * (1 - percent))
                        }
                        content()
                    }
                    RefreshControlView(isRefreshing: $isRefreshing, percent: $percent, headerInset: $headerInset, onRefresh: onRefresh, refreshView: refreshView)
                }
                .onChange(of: globalGeometry.frame(in: .global).minY) { val in
                    headerInset = val
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
