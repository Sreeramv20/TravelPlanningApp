import Foundation
import Combine

class BookingService: ObservableObject {
    @Published var isProcessing = false
    @Published var bookingStatus: BookingStatus = .pending
    @Published var errorMessage: String?
    
    private let stripeAPIKey = "your-stripe-api-key"
    private let baseURL = "https://api.stripe.com/v1"
    
    func createBooking(trip: Trip, itinerary: Itinerary) async throws -> Booking {
        await MainActor.run {
            isProcessing = true
            bookingStatus = .pending
        }
        
        try await validateBookingData(trip: trip, itinerary: itinerary)
        
        let paymentResult = try await processPayment(amount: itinerary.totalCost, currency: itinerary.currency)
        
        let booking = try await createBookingRecord(
            trip: trip,
            itinerary: itinerary,
            paymentResult: paymentResult
        )
        
        try await sendBookingConfirmation(booking: booking)
        
        await MainActor.run {
            isProcessing = false
            bookingStatus = .confirmed
        }
        
        return booking
    }
    
    private func processPayment(amount: Double, currency: String) async throws -> PaymentResult {
        guard let url = URL(string: "\(baseURL)/payment_intents") else {
            throw BookingError.invalidURL
        }
        
        let amountInCents = Int(amount * 100)
        
        let requestBody: [String: Any] = [
            "amount": amountInCents,
            "currency": currency.lowercased(),
            "automatic_payment_methods": [
                "enabled": true
            ],
            "metadata": [
                "booking_type": "travel_booking"
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(stripeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = createFormData(from: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BookingError.paymentFailed("Payment processing failed")
        }
        
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let clientSecret = jsonResponse?["client_secret"] as? String,
              let id = jsonResponse?["id"] as? String else {
            throw BookingError.paymentFailed("Invalid payment response")
        }
        
        return PaymentResult(
            paymentIntentId: id,
            clientSecret: clientSecret,
            amount: amount,
            currency: currency
        )
    }
    
    private func validateBookingData(trip: Trip, itinerary: Itinerary) async throws {
        guard !trip.departureLocation.isEmpty,
              !trip.destination.isEmpty,
              trip.startDate < trip.endDate,
              trip.numberOfTravelers > 0 else {
            throw BookingError.invalidTripData("Invalid trip information")
        }
        
        guard itinerary.totalCost > 0,
              !itinerary.flights.filter({ $0.isSelected }).isEmpty,
              !itinerary.hotels.filter({ $0.isSelected }).isEmpty else {
            throw BookingError.invalidItinerary("Invalid itinerary selection")
        }
        
        try await checkAvailability(trip: trip, itinerary: itinerary)
    }
    
    private func checkAvailability(trip: Trip, itinerary: Itinerary) async throws { 
        let selectedFlights = itinerary.flights.filter { $0.isSelected }
        for flight in selectedFlights {
            if flight.seatAvailability ?? 0 < trip.numberOfTravelers {
                throw BookingError.unavailable("Flight \(flight.flightNumber) is not available for \(trip.numberOfTravelers) travelers")
            }
        }
        
        let selectedHotels = itinerary.hotels.filter { $0.isSelected }
        for hotel in selectedHotels {
        }
    }
    
    private func createBookingRecord(
        trip: Trip,
        itinerary: Itinerary,
        paymentResult: PaymentResult
    ) async throws -> Booking {
        let bookingReference = generateBookingReference()
        
        let travelerDetails = createMockTravelerDetails(for: trip)
        
        let paymentMethod = createMockPaymentMethod()
        
        let confirmationNumbers = generateConfirmationNumbers(for: itinerary)
        
        let booking = Booking(
            tripId: trip.id,
            travelerDetails: travelerDetails,
            paymentMethod: paymentMethod,
            totalAmount: itinerary.totalCost,
            currency: itinerary.currency,
            status: .confirmed,
            confirmationNumbers: confirmationNumbers
        )
        
        try await saveBooking(booking)
        
        return booking
    }

    private func sendBookingConfirmation(booking: Booking) async throws {
        try await sendEmailConfirmation(booking: booking)
        
        try await sendPushNotification(booking: booking)
        
        try await exportToCalendar(booking: booking)
    }
    
    private func sendEmailConfirmation(booking: Booking) async throws {
        print("Sending email confirmation for booking: \(booking.id)")
    }
    
    private func sendPushNotification(booking: Booking) async throws {
        //integrate with push notification services   
        print("Sending push notification for booking: \(booking.id)")
    }
    
    private func exportToCalendar(booking: Booking) async throws {
        // integrate with calendar APIs
        print("Exporting booking to calendar: \(booking.id)")
    }
    
    private func createFormData(from dictionary: [String: Any]) -> Data {
        let pairs = dictionary.map { key, value in
            "\(key)=\(value)"
        }
        let formString = pairs.joined(separator: "&")
        return formString.data(using: .utf8) ?? Data()
    }
    
    private func generateBookingReference() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        let randomString = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
        return "TC-\(dateString)-\(randomString)"
    }
    
    private func createMockTravelerDetails(for trip: Trip) -> [TravelerDetail] {
        var travelers: [TravelerDetail] = []
        
        for i in 1...trip.numberOfTravelers {
            let traveler = TravelerDetail(
                firstName: "Traveler",
                lastName: "\(i)",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(),
                passportNumber: "P\(String(format: "%08d", i))",
                email: "traveler\(i)@example.com",
                phone: "+1-555-012\(String(format: "%02d", i))",
                address: Address(
                    street: "123 Main St",
                    city: "New York",
                    state: "NY",
                    zipCode: "10001",
                    country: "USA"
                )
            )
            travelers.append(traveler)
        }
        
        return travelers
    }
    
    private func createMockPaymentMethod() -> PaymentMethod {
        return PaymentMethod(
            type: .creditCard,
            cardNumber: "**** **** **** 1234",
            expiryDate: "12/25",
            cvv: "***",
            billingAddress: Address(
                street: "123 Main St",
                city: "New York",
                state: "NY",
                zipCode: "10001",
                country: "USA"
            )
        )
    }
    
    private func generateConfirmationNumbers(for itinerary: Itinerary) -> [String] {
        var confirmations: [String] = []
        
        // Flight confirmations
        for flight in itinerary.flights.filter({ $0.isSelected }) {
            confirmations.append("FL-\(flight.airline.prefix(2).uppercased())-\(String(format: "%06d", Int.random(in: 100000...999999)))")
        }
        
        // Hotel confirmations
        for hotel in itinerary.hotels.filter({ $0.isSelected }) {
            confirmations.append("HT-\(hotel.name.prefix(3).uppercased())-\(String(format: "%06d", Int.random(in: 100000...999999)))")
        }
        
        // Activity confirmations
        for activity in itinerary.activities.filter({ $0.isSelected }) {
            confirmations.append("AC-\(activity.name.prefix(3).uppercased())-\(String(format: "%06d", Int.random(in: 100000...999999)))")
        }
        
        return confirmations
    }
    
    private func saveBooking(_ booking: Booking) async throws {
        // save to a database
        print("Saving booking: \(booking.id)")
    }
    
    func cancelBooking(_ booking: Booking) async throws {
        await MainActor.run {
            isProcessing = true
        }
        
        try await processRefund(booking: booking)
        
//update the database
        
        await MainActor.run {
            isProcessing = false
            bookingStatus = .cancelled
        }
    }
    
    private func processRefund(booking: Booking) async throws {
        // call refund API
        print("Processing refund for booking: \(booking.id)")
    }
    
    func getBookingHistory() async throws -> [Booking] {
        // fetch from a database
        return []
    }
    
    func getBookingDetails(id: UUID) async throws -> Booking? {
        //you'd fetch from a database
        return nil
    }
}

struct PaymentResult {
    let paymentIntentId: String
    let clientSecret: String
    let amount: Double
    let currency: String
}

enum BookingError: Error, LocalizedError {
    case invalidURL
    case invalidTripData(String)
    case invalidItinerary(String)
    case unavailable(String)
    case paymentFailed(String)
    case bookingFailed(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidTripData(let message):
            return "Invalid Trip Data: \(message)"
        case .invalidItinerary(let message):
            return "Invalid Itinerary: \(message)"
        case .unavailable(let message):
            return "Unavailable: \(message)"
        case .paymentFailed(let message):
            return "Payment Failed: \(message)"
        case .bookingFailed(let message):
            return "Booking Failed: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        }
    }
} 