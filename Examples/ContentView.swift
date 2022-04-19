
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
                    Text("Go to details in overlay mode")
                        .padding()
                }
                    
                NavigationLink(destination: DetailsCustom()) {
                    Text("Go to details with a custom spinner")
                        .padding()
                }
                NavigationLink(destination: DetailsView(style: .system)) {
                    Text("Go to details with system style animation")
                        .padding()
                }
                NavigationLink(destination: DetailsView(style: .system, useImage: false)) {
                    Text("Go to details with system style - no image")
                        .padding()
                }
            }
            .refresher { done in
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    refreshed += 1
                    done()
                }
            }
            .navigationTitle("Refresher")
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
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
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
        .refresher(refreshView: EmojiRefreshView.init ) { done in
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
    @State var angle: Double = 0.0
    @State var isAnimating = false
    
    var foreverAnimation: Animation {
        Animation.linear(duration: 1.0)
            .repeatForever(autoreverses: false)
    }
    
    public init(state: Binding<RefresherState>) {
        self._state = state
    }
    
    public var body: some View {
        VStack {
            switch state.mode {
            case .notRefreshing:
                Text("😂")
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        DetailsView(style: .default)
        DetailsOverlayView()
    }
}
