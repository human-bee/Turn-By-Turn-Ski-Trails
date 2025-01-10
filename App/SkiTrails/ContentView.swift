import SwiftUI
import SkiTrailsCore

struct ContentView: View {
    @StateObject private var resortViewModel = ResortViewModel()
    
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            
            VStack {
                Text("SkiTrails")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                
                if resortViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if let error = resortViewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .padding()
                } else if let resort = resortViewModel.selectedResort {
                    Text(resort.name)
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    if let weather = resort.weather {
                        Text("\(Int(weather.temperature))°F - \(weather.conditions)")
                            .foregroundColor(.white)
                    }
                } else {
                    Text("Select a resort")
                        .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    ContentView()
} 