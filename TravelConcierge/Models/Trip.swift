import Foundation
import SwiftUI

struct Trip: Codable, Identifiable {
    let id = UUID()
    var departureLocation: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var numberOfTravelers: Int
    var budget: Double?
    var preferences: TripPreferences
    var itinerary: Itinerary?
    var status: TripStatus = .planning
    var createdAt: Date = Date()
    
    var duration: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
}

struct TripPreferences: Codable {
    var flightClass: FlightClass = .economy
    var hotelStarRating: Int = 3
    var includeActivities: Bool = true
    var includeTransportation: Bool = true
    var dietaryRestrictions: [String] = []
    var accessibilityNeeds: [String] = []
    var preferredAirlines: [String] = []
    var preferredHotelChains: [String] = []
}

enum FlightClass: String, CaseIterable, Codable {
    case economy = "Economy"
    case premiumEconomy = "Premium Economy"
    case business = "Business"
    case first = "First Class"
}

enum TripStatus: String, CaseIterable, Codable {
    case planning = "Planning"
    case planned = "Planned"
    case booked = "Booked"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

struct Itinerary: Codable, Identifiable {
    let id = UUID()
    var flights: [FlightOption]
    var hotels: [HotelOption]
    var activities: [ActivityOption]
    var transportation: [TransportationOption]
    var dailySchedule: [DaySchedule]
    var totalCost: Double
    var currency: String = "USD"
    var createdAt: Date = Date()
}

struct FlightOption: Codable, Identifiable {
    let id = UUID()
    var airline: String
    var flightNumber: String
    var departureTime: Date
    var arrivalTime: Date
    var departureAirport: String
    var arrivalAirport: String
    var price: Double
    var currency: String = "USD"
    var flightClass: FlightClass
    var duration: Int
    var stops: Int
    var isSelected: Bool = false
    var bookingLink: String?
    var seatAvailability: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, airline, flightNumber, departureTime, arrivalTime, departureAirport, arrivalAirport, price, currency, flightClass = "class", duration, stops, isSelected, bookingLink, seatAvailability
    }
}

struct HotelOption: Codable, Identifiable {
    let id = UUID()
    var name: String
    var address: String
    var starRating: Int
    var pricePerNight: Double
    var currency: String = "USD"
    var amenities: [String]
    var roomType: String
    var checkInDate: Date
    var checkOutDate: Date
    var totalPrice: Double
    var isSelected: Bool = false
    var bookingLink: String?
    var images: [String]
    var rating: Double?
    var reviewCount: Int?
}

struct ActivityOption: Codable, Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var category: ActivityCategory
    var price: Double
    var currency: String = "USD"
    var duration: Int
    var location: String
    var date: Date?
    var isSelected: Bool = false
    var bookingLink: String?
    var images: [String]
    var rating: Double?
    var reviewCount: Int?
}

enum ActivityCategory: String, CaseIterable, Codable {
    case sightseeing = "sightseeing"
    case adventure = "adventure"
    case food = "food"
    case culture = "culture"
    case relaxation = "relaxation"
    case shopping = "shopping"
    case nightlife = "nightlife"
    case sports = "sports"
}

struct TransportationOption: Codable, Identifiable {
    let id = UUID()
    var type: TransportationType
    var provider: String
    var price: Double
    var currency: String = "USD"
    var duration: Int
    var departureTime: Date?
    var arrivalTime: Date?
    var isSelected: Bool = false
    var bookingLink: String?
}

enum TransportationType: String, CaseIterable, Codable {
    case taxi = "Taxi"
    case rideshare = "Rideshare"
    case publicTransport = "Public Transport"
    case rentalCar = "Rental Car"
    case shuttle = "Shuttle"
    case train = "Train"
    case bus = "Bus"
}

struct DaySchedule: Codable, Identifiable {
    let id = UUID()
    var date: Date
    var activities: [ScheduledActivity]
    var meals: [Meal]
    var transportation: [TransportationOption]
    var notes: String?
}

struct ScheduledActivity: Codable, Identifiable {
    let id = UUID()
    var activity: ActivityOption
    var startTime: Date
    var endTime: Date
    var location: String
}

struct Meal: Codable, Identifiable {
    let id = UUID()
    var type: MealType
    var estimatedCost: Double
    var currency: String = "USD"
    var time: Date?
    var location: String?
    var dietaryNotes: String?
}

enum MealType: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}
            
struct Booking: Codable, Identifiable {
    let id = UUID()
    var tripId: UUID
    var travelerDetails: [TravelerDetail]
    var paymentMethod: PaymentMethod
    var totalAmount: Double
    var currency: String = "USD"
    var status: BookingStatus
    var confirmationNumbers: [String]
    var createdAt: Date = Date()
}

struct TravelerDetail: Codable, Identifiable {
    let id = UUID()
    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var passportNumber: String?
    var email: String
    var phone: String
    var address: Address
}

struct Address: Codable {
    var street: String
    var city: String
    var state: String
    var zipCode: String
    var country: String
}

struct PaymentMethod: Codable {
    var type: PaymentType
    var cardNumber: String?
    var expiryDate: String?
    var cvv: String?
    var billingAddress: Address
}

enum PaymentType: String, CaseIterable, Codable {
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case applePay = "Apple Pay"
    case paypal = "PayPal"
}

enum BookingStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case failed = "Failed"
    case cancelled = "Cancelled"
} 