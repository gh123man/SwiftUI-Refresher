
import SwiftUI
import Refresher

struct ContentView: View {
    
    @State var refreshed = 0
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("Hello, world!")
                    Text("Refreshed: \(refreshed)")
                }
                NavigationLink(destination: DetailsView(style: .default)) {
                    Text("Go to details")
                        .padding()
                }
                
                NavigationLink(destination: DetailsOverlayView()) {
                    Text("Go to details with overlay")
                        .padding()
                }
                    
                NavigationLink(destination: DetailsCustom()) {
                    Text("Go to details custom")
                        .padding()
                }
                NavigationLink(destination: DetailsView(style: .system)) {
                    Text("Go to details with system style")
                        .padding()
                }
                NavigationLink(destination: DetailsView(style: .system, useImage: false)) {
                    Text("Go to details with system style - no image")
                        .padding()
                }
                ForEach((1...200), id: \.self) { _ in
                    Text("Some test text")
                }
            }
            .refresher { done in
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    refreshed += 1
                    done()
                }
            }
            .navigationTitle("test")
        }
    }
}

struct DetailsView: View {
    @State var refreshed = 0
    var style: Style
    var useImage = true
    var body: some View {
        ScrollView {
            VStack {
                if useImage {
                    Image("photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                Text("Details!")
                Text("Refreshed: \(refreshed)")
            }
        }
        .refresher(style: style) { done in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                refreshed += 1
                done()
            }
        }
        .navigationBarTitle("", displayMode: .inline)
    }
}

struct DetailsOverlayView: View {
    @State var refreshed = 0
    var body: some View {
        ScrollView {
            VStack {
                GeometryReader { geometry in
                    Image("photo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(y: -geometry.frame(in: .global).minY)
                        
                }
                .frame(height: 180)
                Text("Details!")
                Text("Refreshed: \(refreshed)")
            }
        }
        .refresher(style: .overlay) { done in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                refreshed += 1
                done()
            }
        }
        .navigationBarTitle("", displayMode: .inline)
    }
}

struct DetailsCustom: View {
    @State var refreshed = 0
    var body: some View {
        ScrollView {
            VStack {
                Image("photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Text("Details!")
                Text("Refreshed: \(refreshed)")
            }
        }
        .refresher(refreshView: { EmojiRefreshView(state: $0, emoji: "😂") }) { done in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                refreshed += 1
                done()
            }
        }
        .navigationBarTitle("", displayMode: .inline)
    }
}

public struct EmojiRefreshView: View {
    @Binding var state: RefresherState
    private var emoji: String
    
    public init(state: Binding<RefresherState>, emoji: String) {
        self._state = state
        self.emoji = emoji
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var angle: Double = 0.0
    @State var isAnimating = false
    
    var foreverAnimation: Animation {
        Animation.linear(duration: 1.0)
            .repeatForever(autoreverses: false)
    }
    
    public var body: some View {
        VStack {
            switch state.mode {
            case .notRefreshing:
                Text(emoji)
                    .onAppear {
                        isAnimating = false
                    }
            case .pulling:
                Text(emoji)
                    .rotationEffect(.degrees(360 * state.dragPosition))
            case .refreshing:
                Text(emoji)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        DetailsView(style: .default)
        DetailsOverlayView()
    }
}
