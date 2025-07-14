import SwiftUI

struct AlternativesView: View {
    let item: Any
    let itemType: ItineraryView.ItemType
    let itinerary: Itinerary?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripManager: TripManager
    
    var body: some View {
        NavigationView {
            Group {
                switch itemType {
                case .flight:
                    if let flights = item as? [FlightOption] {
                        FlightAlternativesView(flights: flights, itinerary: itinerary)
                    }
                case .hotel:
                    if let hotels = item as? [HotelOption] {
                        HotelAlternativesView(hotels: hotels, itinerary: itinerary)
                    }
                case .activity:
                    if let activities = item as? [ActivityOption] {
                        ActivityAlternativesView(activities: activities, itinerary: itinerary)
                    }
                case .transportation:
                    if let transportation = item as? [TransportationOption] {
                        TransportationAlternativesView(transportation: transportation, itinerary: itinerary)
                    }
                }
            }
            .navigationTitle("Alternative Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FlightAlternativesView: View {
    let flights: [FlightOption]
    let itinerary: Itinerary?
    
    var body: some View {
        List {
            ForEach(flights) { flight in
                FlightAlternativeRow(flight: flight)
            }
        }
    }
}

struct FlightAlternativeRow: View {
    let flight: FlightOption
    @EnvironmentObject var tripManager: TripManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(flight.airline) \(flight.flightNumber)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(flight.departureAirport) → \(flight.arrivalAirport)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(flight.price, format: .currency(code: flight.currency))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text(flight.flightClass.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Departure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(flight.departureTime, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 2) {
                    Text("\(flight.duration / 60)h \(flight.duration % 60)m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 4, height: 4)
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(height: 1)
                        
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 4, height: 4)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Arrival")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(flight.arrivalTime, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            HStack {
                Label("\(flight.stops) stop\(flight.stops > 1 ? "s" : "")", systemImage: "airplane")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let availability = flight.seatAvailability {
                    Label("\(availability) seats", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                tripManager.selectFlight(flight)
            }) {
                HStack {
                    if flight.isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Selected")
                            .fontWeight(.medium)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.blue)
                        Text("Select This Flight")
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(flight.isSelected ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                .foregroundColor(flight.isSelected ? .green : .blue)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(flight.isSelected ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

struct HotelAlternativesView: View {
    let hotels: [HotelOption]
    let itinerary: Itinerary?
    
    var body: some View {
        List {
            ForEach(hotels) { hotel in
                HotelAlternativeRow(hotel: hotel)
            }
        }
    }
}

struct HotelAlternativeRow: View {
    let hotel: HotelOption
    @EnvironmentObject var tripManager: TripManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(hotel.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(hotel.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(hotel.totalPrice, format: .currency(code: hotel.currency))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("\(hotel.starRating)★")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Check-in")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(hotel.checkInDate, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 2) {
                    Text("\(hotel.roomType)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Calendar.current.dateComponents([.day], from: hotel.checkInDate, to: hotel.checkOutDate).day ?? 0) nights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Check-out")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(hotel.checkOutDate, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            if !hotel.amenities.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(hotel.amenities, id: \.self) { amenity in
                            Text(amenity)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            if let rating = hotel.rating, let reviewCount = hotel.reviewCount {
                HStack {
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    
                    Text("\(rating, specifier: "%.1f") (\(reviewCount) reviews)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            Button(action: {
                tripManager.selectHotel(hotel)
            }) {
                HStack {
                    if hotel.isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Selected")
                            .fontWeight(.medium)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.blue)
                        Text("Select This Hotel")
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(hotel.isSelected ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                .foregroundColor(hotel.isSelected ? .green : .blue)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(hotel.isSelected ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

struct ActivityAlternativesView: View {
    let activities: [ActivityOption]
    let itinerary: Itinerary?
    
    var body: some View {
        List {
            ForEach(activities) { activity in
                ActivityAlternativeRow(activity: activity)
            }
        }
    }
}

struct ActivityAlternativeRow: View {
    let activity: ActivityOption
    @EnvironmentObject var tripManager: TripManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(activity.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(categoryColor.opacity(0.2))
                        .foregroundColor(categoryColor)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(activity.price, format: .currency(code: activity.currency))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("\(activity.duration)h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(activity.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.blue)
                    .frame(width: 16)
                
                Text(activity.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            if let rating = activity.rating, let reviewCount = activity.reviewCount {
                HStack {
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    
                    Text("\(rating, specifier: "%.1f") (\(reviewCount) reviews)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            Button(action: {
                tripManager.toggleActivity(activity)
            }) {
                HStack {
                    if activity.isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Selected")
                            .fontWeight(.medium)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.blue)
                        Text("Add to Itinerary")
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(activity.isSelected ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                .foregroundColor(activity.isSelected ? .green : .blue)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(activity.isSelected ? Color.green : Color.clear, lineWidth: 2)
        )
    }
    
    private var categoryColor: Color {
        switch activity.category {
        case .sightseeing:
            return .blue
        case .adventure:
            return .green
        case .food:
            return .orange
        case .culture:
            return .purple
        case .relaxation:
            return .pink
        case .shopping:
            return .red
        case .nightlife:
            return .indigo
        case .sports:
            return .teal
        }
    }
}

struct TransportationAlternativesView: View {
    let transportation: [TransportationOption]
    let itinerary: Itinerary?
    
    var body: some View {
        List {
            ForEach(transportation) { transport in
                TransportationAlternativeRow(transport: transport)
            }
        }
    }
}

struct TransportationAlternativeRow: View {
    let transport: TransportationOption
    @EnvironmentObject var tripManager: TripManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(transport.type.rawValue) - \(transport.provider)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(transportTypeIcon)
                        .font(.title2)
                        .foregroundColor(transportTypeColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(transport.price, format: .currency(code: transport.currency))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("\(transport.duration) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                tripManager.selectTransportation(transport)
            }) {
                HStack {
                    if transport.isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Selected")
                            .fontWeight(.medium)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.blue)
                        Text("Select This Option")
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(transport.isSelected ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                .foregroundColor(transport.isSelected ? .green : .blue)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(transport.isSelected ? Color.green : Color.clear, lineWidth: 2)
        )
    }
    
    private var transportTypeIcon: String {
        switch transport.type {
        case .taxi:
            return "🚕"
        case .rideshare:
            return "🚗"
        case .publicTransport:
            return "🚇"
        case .rentalCar:
            return "🚙"
        case .shuttle:
            return "🚌"
        case .train:
            return "🚂"
        case .bus:
            return "🚌"
        }
    }
    
    private var transportTypeColor: Color {
        switch transport.type {
        case .taxi:
            return .yellow
        case .rideshare:
            return .blue
        case .publicTransport:
            return .green
        case .rentalCar:
            return .orange
        case .shuttle:
            return .purple
        case .train:
            return .red
        case .bus:
            return .teal
        }
    }
}

#Preview {
    AlternativesView(
        item: [],
        itemType: .flight,
        itinerary: nil
    )
    .environmentObject(TripManager())
} 