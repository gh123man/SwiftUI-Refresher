# Refresher

A customizable, native SwiftUI refresh control for iOS 14+

## Why?

- the native SwiftUI refresh control only works on iOS 15+
- the native UIKit refresh control works with ugly wrappers, but has buggy behavior with navigation views
- I needed a refresh control that could accomodate an overlay (such as appearing on top of a static image)
- This one is very customizable

## See it in action
If you want to see it in a real app, check out [dateit](https://apps.apple.com/us/app/dateit/id1610780514)

Also works well with [ScrollViewLoader](https://github.com/gh123man/ScrollViewLoader)

## Usage 
First add the package to your project. 

```swift
import Refresher 

struct DetailsView: View {
    @State var refreshed = 0

    var body: some View {
        ScrollView {
            Text("Details!")
            Text("Refreshed: \(refreshed)")
        }
        .refresher { // Called when pulled to refresh
            await Task.sleep(seconds: 2)
            refreshed += 1
        }
    }
}
```

## Features
 - `async`/`await` compatible - even on iOS 14
 - completion callback also supported for `DispatchQueue` operations
 - `.default` and `.system` styles (see below for details)
 - customizable refresh spinner (see below for example)


## Examples and usage

See: [Examples](/Examples/) for a full sample project with multiple implementations

### Navigation view

![Navigation](/images/1.gif)

`Refresher` plays nice with both Navigation views and navigation subviews. 

![Subview](/images/3.gif)

### Detail view with overlay

`Refresher` supports an overlay mode to show a refresh indicator over fixed position content

`.refresher(overlay: true)`

![Overlay](/images/2.gif)

### System style
`Refresher`'s default animation is designed to be more flexible than the system animation style. If you want `Refresher` to behave more like they system refresh control, you can change the style:

```swift
.refresher(style: .system) { done in
```

![System](/images/5.gif)

## Customization

Refresher can take a custom spinner view. Your custom view will get a binding instances of the refresher state that contains useful properties for managing animations and translations. Here is a custom spinner that shows an emoji:

```swift
public struct EmojiRefreshView: View {
    @Binding var state: RefresherState
    @State private var angle: Double = 0.0
    @State private var isAnimating = false
    
    var foreverAnimation: Animation {
        Animation.linear(duration: 1.0)
            .repeatForever(autoreverses: false)
    }
    
    public var body: some View {
        VStack {
            switch state.mode {
            case .notRefreshing:
                Text("🤪")
                    .onAppear {
                        isAnimating = false
                    }
            case .pulling:
                Text("😯")
                    .rotationEffect(.degrees(360 * state.dragPosition))
            case .refreshing:
                Text("😂")
                    .rotationEffect(.degrees(self.isAnimating ? 360.0 : 0.0))
                        .onAppear {
                            withAnimation(foreverAnimation) {
                                isAnimating = true
                            }
                    }
            }
        }
        .scaleEffect(2)
    }
}
```

Add the custom refresherView:
```swift
.refresher(refreshView: EmojiRefreshView.init ) { done in
```

![Custom](/images/4.gif)

## Completion handler

If you prefer to call a completion to stop the refresher: 
```swift 
.refresher(style: .system) { done in
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
        refreshed += 1
        done() // Call done to stop the refresher
    }
}
```
