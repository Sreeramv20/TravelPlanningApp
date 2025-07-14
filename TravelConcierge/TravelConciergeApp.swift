import SwiftUI

@main
struct TravelConciergeApp: App {
    @StateObject private var tripManager = TripManager()
    @StateObject private var aiService = AIService()
    @StateObject private var bookingService = BookingService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tripManager)
                .environmentObject(aiService)
                .environmentObject(bookingService)
                .preferredColorScheme(.light)
        }
    }
} 