import Foundation
import Combine

class AIService: ObservableObject {
    @Published var isPlanning = false
    @Published var planningProgress: Double = 0.0
    @Published var currentStep = ""
    @Published var errorMessage: String?
    
    private let openAIAPIKey = "your-openai-api-key"
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    func planTrip(trip: Trip) async throws -> Itinerary {
        print("[DEBUG] planTrip called with trip: \(trip)")
        await MainActor.run {
            isPlanning = true
            planningProgress = 0.0
            currentStep = "Analyzing trip requirements..."
        }
        
        await MainActor.run {
            planningProgress = 0.2
            currentStep = "Searching for flights..."
        }
        let flights = try await searchFlights(for: trip)
        
        await MainActor.run {
            planningProgress = 0.4
            currentStep = "Finding accommodations..."
        }
        let hotels = try await searchHotels(for: trip)
        
        await MainActor.run {
            planningProgress = 0.6
            currentStep = "Discovering activities..."
        }
        let activities = try await searchActivities(for: trip)
        
        await MainActor.run {
            planningProgress = 0.8
            currentStep = "Planning local transportation..."
        }
        let transportation = try await searchTransportation(for: trip)
        
        await MainActor.run {
            planningProgress = 0.9
            currentStep = "Creating daily itinerary..."
        }
        let dailySchedule = try await createDailySchedule(
            trip: trip,
            activities: activities,
            transportation: transportation
        )
        
        await MainActor.run {
            planningProgress = 1.0
            currentStep = "Finalizing itinerary..."
        }
        
        let totalCost = calculateTotalCost(
            flights: flights,
            hotels: hotels,
            activities: activities,
            transportation: transportation,
            trip: trip
        )
        
        let itinerary = Itinerary(
            flights: flights,
            hotels: hotels,
            activities: activities,
            transportation: transportation,
            dailySchedule: dailySchedule,
            totalCost: totalCost
        )
        
        await MainActor.run {
            isPlanning = false
            planningProgress = 0.0
            currentStep = ""
        }
        
        return itinerary
    }
    
    func planTripViaBackend(trip: Trip) async throws -> Itinerary {
        let url = URL(string: "http://127.0.0.1:8000/plan-trip")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(trip)
        request.httpBody = jsonData

        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("[DEBUG] Outgoing /plan-trip JSON: \(jsonString)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[DEBUG] Backend raw response: \(jsonString)")
        }
        return try decoder.decode(Itinerary.self, from: data)
    }
    
    private func searchFlights(for trip: Trip) async throws -> [FlightOption] {
        let prompt = """
        Search for flights from \(trip.departureLocation) to \(trip.destination) for \(trip.numberOfTravelers) travelers from \(formatDate(trip.startDate)) to \(formatDate(trip.endDate)).
        
        Requirements:
        - Flight class: \(trip.preferences.flightClass.rawValue)
        - Budget consideration: $\(trip.budget ?? 5000)
        - Preferred airlines: \(trip.preferences.preferredAirlines.joined(separator: ", "))
        
        Return 3-5 flight options with realistic prices, airlines, and schedules.
        """
        
        let response = try await callOpenAI(prompt: prompt)
        return parseFlightOptions(from: response, trip: trip)
    }
    
    private func searchHotels(for trip: Trip) async throws -> [HotelOption] {
        let prompt = """
        Search for hotels in \(trip.destination) for \(trip.numberOfTravelers) travelers from \(formatDate(trip.startDate)) to \(formatDate(trip.endDate)).
        
        Requirements:
        - Star rating: \(trip.preferences.hotelStarRating) stars
        - Budget consideration: $\(trip.budget ?? 5000)
        - Preferred chains: \(trip.preferences.preferredHotelChains.joined(separator: ", "))
        
        Return 3-5 hotel options with realistic prices, amenities, and ratings.
        """
        
        let response = try await callOpenAI(prompt: prompt)
        return parseHotelOptions(from: response, trip: trip)
    }

    private func searchActivities(for trip: Trip) async throws -> [ActivityOption] {
        let prompt = """
        Search for activities and attractions in \(trip.destination) for a \(trip.duration)-day trip.
        
        Requirements:
        - Number of travelers: \(trip.numberOfTravelers)
        - Include various categories: sightseeing, culture, food, adventure
        - Budget consideration: $\(trip.budget ?? 5000)
        - Duration: \(trip.duration) days
        
        Return 8-12 activity options with realistic prices and descriptions.
        """
        
        let response = try await callOpenAI(prompt: prompt)
        return parseActivityOptions(from: response, trip: trip)
    }
    
    private func searchTransportation(for trip: Trip) async throws -> [TransportationOption] {
        let prompt = """
        Search for local transportation options in \(trip.destination) for \(trip.numberOfTravelers) travelers.
        
        Requirements:
        - Duration: \(trip.duration) days
        - Include: airport transfers, local transport, car rentals
        - Budget consideration: $\(trip.budget ?? 5000)
        
        Return 3-5 transportation options with realistic prices and providers.
        """
        
        let response = try await callOpenAI(prompt: prompt)
        return parseTransportationOptions(from: response, trip: trip)
    }
    
    private func createDailySchedule(
        trip: Trip,
        activities: [ActivityOption],
        transportation: [TransportationOption]
    ) async throws -> [DaySchedule] {
        let prompt = """
        Create a detailed daily schedule for a \(trip.duration)-day trip to \(trip.destination) for \(trip.numberOfTravelers) travelers.
        
        Available activities: \(activities.map { $0.name }.joined(separator: ", "))
        Available transportation: \(transportation.map { "\($0.type.rawValue) - \($0.provider)" }.joined(separator: ", "))
        
        Requirements:
        - Include meals (breakfast, lunch, dinner) with estimated costs
        - Schedule activities logically
        - Include transportation between locations
        - Consider opening hours and travel time
        - Add realistic timing for each activity
        
        Return a day-by-day schedule with activities, meals, and transportation.
        """
        
        let response = try await callOpenAI(prompt: prompt)
        return parseDailySchedule(from: response, trip: trip, activities: activities, transportation: transportation)
    }
    
    private func callOpenAI(prompt: String) async throws -> String {
        print("[DEBUG] callOpenAI called with prompt: \n\(prompt)\n")
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a professional travel planner. Provide detailed, realistic travel options with accurate pricing and information. Format responses as structured data that can be easily parsed."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIError.apiError("Invalid response from OpenAI API")
        }
        
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = jsonResponse?["choices"] as? [[String: Any]]
        let firstChoice = choices?.first
        let message = firstChoice?["message"] as? [String: Any]
        let content = message?["content"] as? String
        
        guard let content = content else {
            throw AIError.parsingError("Could not parse OpenAI response")
        }
        
        return content
    }
    
    private func parseFlightOptions(from response: String, trip: Trip) -> [FlightOption] {
        var flights: [FlightOption] = []
        
        let mockFlights = [
            FlightOption(
                airline: "Delta Air Lines",
                flightNumber: "DL123",
                departureTime: trip.startDate,
                arrivalTime: trip.startDate.addingTimeInterval(6 * 60 * 60),
                departureAirport: "JFK",
                arrivalAirport: "NRT",
                price: 1200.0,
                flightClass: trip.preferences.flightClass,
                duration: 360,
                stops: 0,
                isSelected: true
            ),
            FlightOption(
                airline: "United Airlines",
                flightNumber: "UA456",
                departureTime: trip.startDate.addingTimeInterval(2 * 60 * 60),
                arrivalTime: trip.startDate.addingTimeInterval(8 * 60 * 60),
                departureAirport: "JFK",
                arrivalAirport: "NRT",
                price: 1100.0,
                flightClass: trip.preferences.flightClass,
                duration: 360,
                stops: 1,
                isSelected: false
            ),
            FlightOption(
                airline: "American Airlines",
                flightNumber: "AA789",
                departureTime: trip.startDate.addingTimeInterval(4 * 60 * 60),
                arrivalTime: trip.startDate.addingTimeInterval(10 * 60 * 60),
                departureAirport: "JFK",
                arrivalAirport: "NRT",
                price: 1300.0,
                flightClass: trip.preferences.flightClass,
                duration: 360,
                stops: 0,
                isSelected: false
            )
        ]
        
        return mockFlights
    }
    
    private func parseHotelOptions(from response: String, trip: Trip) -> [HotelOption] {
        // Mock hotel data
        let mockHotels = [
            HotelOption(
                name: "Hilton Tokyo",
                address: "6-6-2 Nishi-Shinjuku, Tokyo",
                starRating: 4,
                pricePerNight: 250.0,
                amenities: ["WiFi", "Pool", "Gym", "Restaurant"],
                roomType: "Deluxe Room",
                checkInDate: trip.startDate,
                checkOutDate: trip.endDate,
                totalPrice: 250.0 * Double(trip.duration),
                isSelected: true,
                images: ["hotel1.jpg", "hotel2.jpg"],
                rating: 4.5,
                reviewCount: 1250
            ),
            HotelOption(
                name: "Marriott Tokyo",
                address: "4-3-6 Kita-Aoyama, Tokyo",
                starRating: 4,
                pricePerNight: 280.0,
                amenities: ["WiFi", "Spa", "Gym", "Restaurant"],
                roomType: "Executive Room",
                checkInDate: trip.startDate,
                checkOutDate: trip.endDate,
                totalPrice: 280.0 * Double(trip.duration),
                isSelected: false,
                images: ["hotel3.jpg", "hotel4.jpg"],
                rating: 4.3,
                reviewCount: 980
            )
        ]
        
        return mockHotels
    }
    
    private func parseActivityOptions(from response: String, trip: Trip) -> [ActivityOption] {
        // Mock activity data
        let mockActivities = [
            ActivityOption(
                name: "Tsukiji Market Tour",
                description: "Explore the famous fish market and try fresh sushi",
                category: .food,
                price: 50.0,
                duration: 3,
                location: "Tsukiji, Tokyo",
                isSelected: true,
                images: ["activity1.jpg"],
                rating: 4.7,
                reviewCount: 450
            ),
            ActivityOption(
                name: "Mount Fuji Day Trip",
                description: "Visit the iconic Mount Fuji and surrounding areas",
                category: .sightseeing,
                price: 120.0,
                duration: 8,
                location: "Mount Fuji",
                isSelected: true,
                images: ["activity2.jpg"],
                rating: 4.8,
                reviewCount: 320
            ),
            ActivityOption(
                name: "Senso-ji Temple Visit",
                description: "Visit Tokyo's oldest temple and explore Asakusa",
                category: .culture,
                price: 25.0,
                duration: 2,
                location: "Asakusa, Tokyo",
                isSelected: false,
                images: ["activity3.jpg"],
                rating: 4.5,
                reviewCount: 890
            )
        ]
        
        return mockActivities
    }
    
    private func parseTransportationOptions(from response: String, trip: Trip) -> [TransportationOption] {
        // Mock transportation data
        let mockTransport = [
            TransportationOption(
                type: .taxi,
                provider: "Tokyo Taxi Co.",
                price: 80.0,
                duration: 60,
                isSelected: true
            ),
            TransportationOption(
                type: .publicTransport,
                provider: "Tokyo Metro",
                price: 20.0,
                duration: 90,
                isSelected: false
            ),
            TransportationOption(
                type: .rentalCar,
                provider: "Toyota Rent a Car",
                price: 150.0,
                duration: 60,
                isSelected: false
            )
        ]
        
        return mockTransport
    }
    
    private func parseDailySchedule(
        from response: String,
        trip: Trip,
        activities: [ActivityOption],
        transportation: [TransportationOption]
    ) -> [DaySchedule] {
        var dailySchedules: [DaySchedule] = []
        
        for dayIndex in 0..<trip.duration {
            let currentDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: trip.startDate) ?? trip.startDate
            
            let dayActivities = activities.filter { $0.isSelected }.prefix(2)
            let scheduledActivities = dayActivities.enumerated().map { index, activity in
                ScheduledActivity(
                    activity: activity,
                    startTime: Calendar.current.date(byAdding: .hour, value: 9 + (index * 3), to: currentDate) ?? currentDate,
                    endTime: Calendar.current.date(byAdding: .hour, value: 12 + (index * 3), to: currentDate) ?? currentDate,
                    location: activity.location
                )
            }
            
            let meals = [
                Meal(type: .breakfast, estimatedCost: 15.0, time: Calendar.current.date(byAdding: .hour, value: 8, to: currentDate)),
                Meal(type: .lunch, estimatedCost: 25.0, time: Calendar.current.date(byAdding: .hour, value: 13, to: currentDate)),
                Meal(type: .dinner, estimatedCost: 35.0, time: Calendar.current.date(byAdding: .hour, value: 19, to: currentDate))
            ]
            
            let dayTransport = transportation.filter { $0.isSelected }
            
            let daySchedule = DaySchedule(
                date: currentDate,
                activities: scheduledActivities,
                meals: meals,
                transportation: dayTransport
            )
            
            dailySchedules.append(daySchedule)
        }
        
        return dailySchedules
    }
    
    private func calculateTotalCost(
        flights: [FlightOption],
        hotels: [HotelOption],
        activities: [ActivityOption],
        transportation: [TransportationOption],
        trip: Trip
    ) -> Double {
        var totalCost: Double = 0
        
        let selectedFlights = flights.filter { $0.isSelected }
        totalCost += selectedFlights.reduce(0) { $0 + $1.price } * Double(trip.numberOfTravelers)
        
        let selectedHotels = hotels.filter { $0.isSelected }
        totalCost += selectedHotels.reduce(0) { $0 + $1.totalPrice }
        
        let selectedActivities = activities.filter { $0.isSelected }
        totalCost += selectedActivities.reduce(0) { $0 + $1.price } * Double(trip.numberOfTravelers)
        
        let selectedTransport = transportation.filter { $0.isSelected }
        totalCost += selectedTransport.reduce(0) { $0 + $1.price }
        
        let dailyFoodCost = 60.0
        totalCost += dailyFoodCost * Double(trip.numberOfTravelers) * Double(trip.duration)
        
        return totalCost
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

enum AIError: Error, LocalizedError {
    case invalidURL
    case apiError(String)
    case parsingError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .apiError(let message):
            return "API Error: \(message)"
        case .parsingError(let message):
            return "Parsing Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        }
    }
} 