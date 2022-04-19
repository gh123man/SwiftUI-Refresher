import Foundation
import SwiftUI

extension ScrollView {
    public func refresher<RefreshView>(style: Style = .default, refreshView: @escaping (Binding<RefresherState>) -> RefreshView, action: @escaping RefreshAction) -> RefreshableScrollView<Content, RefreshView> {
        RefreshableScrollView(axes: axes,
                              showsIndicators: showsIndicators,
                              refreshAction: action,
                              style: style,
                              refreshView: refreshView,
                              content: content)
    }
}

extension ScrollView {
    public func refresher(style: Style = .default, action: @escaping RefreshAction) -> some View {
        RefreshableScrollView(axes: axes,
                              showsIndicators: showsIndicators,
                              refreshAction: action,
                              style: style,
                              refreshView: DefaultRefreshView.init,
                              content: content)
    }
}
