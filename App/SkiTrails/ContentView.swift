import SwiftUI
import SkiTrailsCore

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            
            VStack {
                Text("SkiTrails")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                
                Text("App is running!")
                    .foregroundColor(.white)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 