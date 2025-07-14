import Foundation
import Combine

class TripManager: ObservableObject {
    @Published var currentTrip: Trip?
    @Published var tripHistory: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let tripHistoryKey = "tripHistory"
    
    init() {
        loadTripHistory()
    }
    
    func createTrip(_ trip: Trip) {
        currentTrip = trip
        saveTripHistory()
    }
    
    func updateTrip(_ trip: Trip) {
        currentTrip = trip
        saveTripHistory()
    }
    
    func deleteTrip(_ trip: Trip) {
        if currentTrip?.id == trip.id {
            currentTrip = nil
        }
        tripHistory.removeAll { $0.id == trip.id }
        saveTripHistory()
    }
    
    func clearCurrentTrip() {
        currentTrip = nil
    }
    
    func updateItinerary(_ itinerary: Itinerary) {
        currentTrip?.itinerary = itinerary
        saveTripHistory()
    }
    
    func selectFlight(_ flight: FlightOption) {
        guard var itinerary = currentTrip?.itinerary else { return }
        
        for i in itinerary.flights.indices {
            itinerary.flights[i].isSelected = false
        }
        
        if let index = itinerary.flights.firstIndex(where: { $0.id == flight.id }) {
            itinerary.flights[index].isSelected = true
        }
        
        itinerary.totalCost = calculateTotalCost(itinerary: itinerary)
        
        updateItinerary(itinerary)
    }
    
    func selectHotel(_ hotel: HotelOption) {
        guard var itinerary = currentTrip?.itinerary else { return }
        
        for i in itinerary.hotels.indices {
            itinerary.hotels[i].isSelected = false
        }
        
        if let index = itinerary.hotels.firstIndex(where: { $0.id == hotel.id }) {
            itinerary.hotels[index].isSelected = true
        }
        
        itinerary.totalCost = calculateTotalCost(itinerary: itinerary)
        
        updateItinerary(itinerary)
    }
    
    func toggleActivity(_ activity: ActivityOption) {
        guard var itinerary = currentTrip?.itinerary else { return }
        
        if let index = itinerary.activities.firstIndex(where: { $0.id == activity.id }) {
            itinerary.activities[index].isSelected.toggle()
        }
        
        itinerary.totalCost = calculateTotalCost(itinerary: itinerary)
        
        updateItinerary(itinerary)
    }
    
    func selectTransportation(_ transport: TransportationOption) {
        guard var itinerary = currentTrip?.itinerary else { return }
        
        for i in itinerary.transportation.indices {
            if itinerary.transportation[i].type == transport.type {
                itinerary.transportation[i].isSelected = false
            }
        }

        if let index = itinerary.transportation.firstIndex(where: { $0.id == transport.id }) {
            itinerary.transportation[index].isSelected = true
        }
        
        itinerary.totalCost = calculateTotalCost(itinerary: itinerary)
        
        updateItinerary(itinerary)
    }
    
    private func calculateTotalCost(itinerary: Itinerary) -> Double {
        var totalCost: Double = 0
        
        let selectedFlights = itinerary.flights.filter { $0.isSelected }
        totalCost += selectedFlights.reduce(0) { $0 + $1.price }
        
        let selectedHotels = itinerary.hotels.filter { $0.isSelected }
        totalCost += selectedHotels.reduce(0) { $0 + $1.totalPrice }
        
        let selectedActivities = itinerary.activities.filter { $0.isSelected }
        totalCost += selectedActivities.reduce(0) { $0 + $1.price }
        
        let selectedTransport = itinerary.transportation.filter { $0.isSelected }
        totalCost += selectedTransport.reduce(0) { $0 + $1.price }
        
        return totalCost
    }
    
    private func saveTripHistory() {
        if let currentTrip = currentTrip {
            if !tripHistory.contains(where: { $0.id == currentTrip.id }) {
                tripHistory.append(currentTrip)
            } else {
                if let index = tripHistory.firstIndex(where: { $0.id == currentTrip.id }) {
                    tripHistory[index] = currentTrip
                }
            }
        }
        
        if let encoded = try? JSONEncoder().encode(tripHistory) {
            userDefaults.set(encoded, forKey: tripHistoryKey)
        }
    }
    
    private func loadTripHistory() {
        if let data = userDefaults.data(forKey: tripHistoryKey),
           let decoded = try? JSONDecoder().decode([Trip].self, from: data) {
            tripHistory = decoded
        }
    }
    
    func markTripAsBooked() {
        currentTrip?.status = .booked
        saveTripHistory()
    }
    
    func markTripAsCompleted() {
        currentTrip?.status = .completed
        saveTripHistory()
    }
    
    func cancelTrip() {
        currentTrip?.status = .cancelled
        saveTripHistory()
    }
    
    func searchTrips(query: String) -> [Trip] {
        if query.isEmpty {
            return tripHistory
        }
        
        return tripHistory.filter { trip in
            trip.departureLocation.localizedCaseInsensitiveContains(query) ||
            trip.destination.localizedCaseInsensitiveContains(query)
        }
    }
    
    func filterTripsByStatus(_ status: TripStatus) -> [Trip] {
        return tripHistory.filter { $0.status == status }
    }
    
    func filterTripsByDateRange(from: Date, to: Date) -> [Trip] {
        return tripHistory.filter { trip in
            trip.startDate >= from && trip.endDate <= to
        }
    }
        
    func getTotalSpent() -> Double {
        return tripHistory
            .filter { $0.status == .completed }
            .compactMap { $0.itinerary?.totalCost }
            .reduce(0, +)
    }
    
    func getAverageTripCost() -> Double {
        let completedTrips = tripHistory.filter { $0.status == .completed }
        let totalCost = getTotalSpent()
        return completedTrips.isEmpty ? 0 : totalCost / Double(completedTrips.count)
    }
    
    func getMostVisitedDestination() -> String? {
        let destinationCounts = tripHistory
            .filter { $0.status == .completed }
            .reduce(into: [String: Int]()) { counts, trip in
                counts[trip.destination, default: 0] += 1
            }
        
        return destinationCounts.max(by: { $0.value < $1.value })?.key
    }
    
    func getTripCount() -> Int {
        return tripHistory.count
    }
    
    func getUpcomingTrips() -> [Trip] {
        let now = Date()
        return tripHistory.filter { trip in
            trip.startDate > now && trip.status == .booked
        }
    }
} 