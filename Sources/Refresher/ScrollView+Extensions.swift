import Foundation
import SwiftUI

extension ScrollView {
    public func refresher<RefreshView>(style: Style = .default,
                                       config: Config = Config(),
                                       refreshView: @escaping (Binding<RefresherState>) -> RefreshView,
                                       action: @escaping RefreshAction) -> RefreshableScrollView<Content, RefreshView> {
        RefreshableScrollView(axes: axes,
                              showsIndicators: showsIndicators,
                              refreshAction: action,
                              style: style,
                              config: config,
                              refreshView: refreshView,
                              content: content)
    }
}

extension ScrollView {
    public func refresher(style: Style = .default,
                          config: Config = Config(),
                          action: @escaping RefreshAction) -> some View {
        RefreshableScrollView(axes: axes,
                              showsIndicators: showsIndicators,
                              refreshAction: action,
                              style: style,
                              config: config,
                              refreshView: DefaultRefreshView.init,
                              content: content)
    }
}


extension ScrollView {
    public func refresher<RefreshView>(style: Style = .default,
                                       config: Config = Config(),
                                       refreshView: @escaping (Binding<RefresherState>) -> RefreshView,
                                       action: @escaping AsyncRefreshAction) -> RefreshableScrollView<Content, RefreshView> {
        RefreshableScrollView(axes: axes,
                              showsIndicators: showsIndicators,
                              refreshAction: { done in
                                  Task { @MainActor in
                                      await action()
                                      done()
                                  }
                              },
                              style: style,
                              config: config,
                              refreshView: refreshView,
                              content: content)
    }
}

extension ScrollView {
    public func refresher(style: Style = .default,
                          config: Config = Config(),
                          action: @escaping AsyncRefreshAction) -> some View {
        RefreshableScrollView(axes: axes,
                              showsIndicators: showsIndicators,
                              refreshAction: { done in
                                  Task { @MainActor in
                                      await action()
                                      done()
                                  }
                              },
                              style: style,
                              config: config,
                              refreshView: DefaultRefreshView.init,
                              content: content)
    }
}
