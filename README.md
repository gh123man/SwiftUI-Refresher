# Refresher

A native swift UI refresh control for ios 14+

## Why?

- the native SwiftUI refresh control only works on iOS 15+
- the native UIKit refresh control works with ugly wrappers, but has buggy behavior with navigation views
- I needed a refresh control that could accomodate an overlay (such as appearing on top of a static image)

## Usage 

`RefreshableScrollView` wraps a `ScrollView`
```swift
struct MyView: View {
    @State var refreshed = 0
    var body: some View {
        RefreshableScrollView(onRefresh: { done in 
            // Do som expensive task
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                refreshed += 1
                done() // Done refreshing
            }
        }) {
            VStack {
                Image("photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Text("Details!")
                Text("Refreshed: \(refreshed)")
            }
        }
    }
}

```

## Options

### Navigation view
![bla](/images/nav.gif)


### Detail view (no overlay)

`RefreshableScrollView(overlay: false)` (false is the default)

![bla](/images/details1.gif)


### Detail view with overlay

`RefreshableScrollView(overlay: true)`

![bla](/images/details2.gif)