import SwiftUI
import Refresher

struct ContentView: View {
    
    @State var refreshed = 0
    var body: some View {
        NavigationView {
            RefreshableScrollView(onRefresh: { done in
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    refreshed += 1
                    done()
                }
            }) {
                VStack {
                    Text("Hello, world!")
                    Text("Refreshed: \(refreshed)")
                }
                NavigationLink(destination: DetailsView()) {
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
            }
            .navigationTitle("test")
        }
    }
}

struct DetailsView: View {
    @State var refreshed = 0
    var body: some View {
        RefreshableScrollView(onRefresh: { done in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                refreshed += 1
                done()
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
        .navigationBarTitle("", displayMode: .inline)
    }
}

struct DetailsOverlayView: View {
    @State var refreshed = 0
    var body: some View {
        RefreshableScrollView(overlay: true, onRefresh: { done in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                refreshed += 1
                done()
            }
        }) {
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
        .navigationBarTitle("", displayMode: .inline)
    }
}

struct DetailsCustom: View {
    @State var refreshed = 0
    var body: some View {
        RefreshableScrollView(refreshView: {
            Text("Refreshing...")
        }, onRefresh: { done in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                refreshed += 1
                done()
            }
        } ) {
            VStack {
                Image("photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Text("Details!")
                Text("Refreshed: \(refreshed)")
            }
        }
        .navigationBarTitle("", displayMode: .inline)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        DetailsView()
        DetailsOverlayView()
    }
}
