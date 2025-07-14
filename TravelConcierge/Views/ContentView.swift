import SwiftUI

struct ContentView: View {
    @EnvironmentObject var tripManager: TripManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TripInputView()
                .tabItem {
                    Image(systemName: "airplane.departure")
                    Text("Plan Trip")
                }
                .tag(0)
            
            ItineraryView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Itinerary")
                }
                .tag(1)
            
            PricingBreakdownView()
                .tabItem {
                    Image(systemName: "dollarsign.circle")
                    Text("Pricing")
                }
                .tag(2)
            
            BookingView()
                .tabItem {
                    Image(systemName: "creditcard")
                    Text("Book")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onReceive(tripManager.$currentTrip) { trip in
            print("[DEBUG] onReceive tripManager.$currentTrip: \(String(describing: trip))")
            if trip != nil && selectedTab == 0 {
                selectedTab = 1 // Auto-navigate to itinerary when trip is created
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TripManager())
        .environmentObject(AIService())
        .environmentObject(BookingService())
} 