
import SwiftUI
import Refresher

struct ContentView: View {
    
    @State var refreshed = 0
    @State var searchText = ""
    var body: some View {
        NavigationView {
            ScrollView {
                if #available(iOS 15.0, *) {
                    Text("Searching for \(searchText)")
                        .searchable(text: $searchText)
                        .navigationTitle("Searchable")
                }
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
                NavigationLink(destination: DetailsSearch()) {
                    Text("Go to details with system style and search bar in header")
                        .padding()
                }
                ForEach((1...100), id: \.self) { _ in
                    Text("asdf")
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

struct DetailsSearch: View {
    @State var refreshed = 0
    @State var searchText = ""
    var body: some View {
        ScrollView {
            VStack {
                if #available(iOS 15.0, *) {
                    Text("Searching for \(searchText)")
                        .searchable(text: $searchText)
                        .navigationTitle("Searchable")
                }
                Text("Details!")
                Text("Refreshed: \(refreshed)")
            }
        }
        .refresher(style: .system) { done in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                refreshed += 1
                done()
            }
        }
        .navigationBarTitle("", displayMode: .inline)
    }
}

struct DetailsView: View {
    @State var refreshed = 0
    var style: Style
    @State var useImage = true
    var body: some View {
        ScrollView {
            VStack {
                if useImage {
                    Image("photo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) {
                refreshed += 1
                done()
            }
        }
        .navigationBarTitle("", displayMode: .inline)
    }
}

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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        DetailsView(style: .default)
        DetailsOverlayView()
    }
}
