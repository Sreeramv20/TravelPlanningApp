import SwiftUI

struct ItineraryView: View {
    @EnvironmentObject var tripManager: TripManager
    @State private var selectedDayIndex = 0
    @State private var showingAlternatives = false
    @State private var selectedItem: Any?
    @State private var selectedItemType: ItineraryView.ItemType = .flight
    
    enum ItemType {
        case flight, hotel, activity, transportation
    }
    
    var body: some View {
        NavigationView {
            Group {
                if let trip = tripManager.currentTrip, let itinerary = trip.itinerary {
                    ScrollView {
                        VStack(spacing: 20) {
                            TripSummaryHeader(trip: trip, itinerary: itinerary)
                            
                            DayScheduleView(
                                dailySchedule: itinerary.dailySchedule,
                                selectedDayIndex: $selectedDayIndex
                            )
                            
                            SelectedItemsSummary(itinerary: itinerary)
                            
                            AlternativeOptionsSection(
                                itinerary: itinerary,
                                showingAlternatives: $showingAlternatives,
                                selectedItem: $selectedItem,
                                selectedItemType: $selectedItemType
                            )
                        }
                        .padding()
                    }
                    .navigationTitle("Your Itinerary")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Export") {
                                exportItinerary()
                            }
                        }
                    }
                } else {
                    EmptyItineraryView()
                }
            }
        }
        .sheet(isPresented: $showingAlternatives) {
            if let item = selectedItem {
                AlternativesView(
                    item: item,
                    itemType: selectedItemType,
                    itinerary: tripManager.currentTrip?.itinerary
                )
            }
        }
    }
    
    private func exportItinerary() {
        // Export functionality
    }
}

struct TripSummaryHeader: View {
    let trip: Trip
    let itinerary: Itinerary
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(trip.departureLocation) → \(trip.destination)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(trip.numberOfTravelers) traveler\(trip.numberOfTravelers > 1 ? "s" : "") • \(trip.duration) days")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(itinerary.totalCost, format: .currency(code: itinerary.currency))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Total Cost")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("\(trip.startDate, style: .date) - \(trip.endDate, style: .date)")
                    .font(.subheadline)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DayScheduleView: View {
    let dailySchedule: [DaySchedule]
    @Binding var selectedDayIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Schedule")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(dailySchedule.enumerated()), id: \.element.id) { index, day in
                        DaySelectorButton(
                            day: day,
                            isSelected: selectedDayIndex == index,
                            action: { selectedDayIndex = index }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            if !dailySchedule.isEmpty {
                DayDetailsView(day: dailySchedule[selectedDayIndex])
            }
        }
    }
}

struct DaySelectorButton: View {
    let day: DaySchedule
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("Day \(Calendar.current.component(.day, from: day.date))")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(day.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}

struct DayDetailsView: View {
    let day: DaySchedule
    
    var body: some View {
        VStack(spacing: 16) {
            if !day.activities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activities")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(day.activities) { activity in
                        ActivityRowView(activity: activity)
                    }
                }
            }
            
            if !day.meals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meals")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(day.meals) { meal in
                        MealRowView(meal: meal)
                    }
                }
            }
            
            if !day.transportation.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transportation")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(day.transportation) { transport in
                        TransportationRowView(transport: transport)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ActivityRowView: View {
    let activity: ScheduledActivity
    
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.activity.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(activity.startTime, style: .time) - \(activity.endTime, style: .time) • \(activity.location)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(activity.activity.price, format: .currency(code: activity.activity.currency))
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct MealRowView: View {
    let meal: Meal
    
    var body: some View {
        HStack {
            Image(systemName: "fork.knife")
                .foregroundColor(.orange)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let location = meal.location {
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(meal.estimatedCost, format: .currency(code: meal.currency))
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct TransportationRowView: View {
    let transport: TransportationOption
    
    var body: some View {
        HStack {
            Image(systemName: "car.fill")
                .foregroundColor(.green)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(transport.type.rawValue) - \(transport.provider)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(transport.duration) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(transport.price, format: .currency(code: transport.currency))
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct SelectedItemsSummary: View {
    let itinerary: Itinerary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Selected Items")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if let selectedFlight = itinerary.flights.first(where: { $0.isSelected }) {
                    SelectedItemRow(
                        title: "Flight",
                        subtitle: "\(selectedFlight.airline) \(selectedFlight.flightNumber)",
                        price: selectedFlight.price,
                        currency: selectedFlight.currency,
                        icon: "airplane"
                    )
                }
                
                if let selectedHotel = itinerary.hotels.first(where: { $0.isSelected }) {
                    SelectedItemRow(
                        title: "Hotel",
                        subtitle: selectedHotel.name,
                        price: selectedHotel.totalPrice,
                        currency: selectedHotel.currency,
                        icon: "bed.double"
                    )
                }
            
                let selectedActivities = itinerary.activities.filter { $0.isSelected }
                if !selectedActivities.isEmpty {
                    SelectedItemRow(
                        title: "Activities",
                        subtitle: "\(selectedActivities.count) selected",
                        price: selectedActivities.reduce(0) { $0 + $1.price },
                        currency: itinerary.currency,
                        icon: "star"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SelectedItemRow: View {
    let title: String
    let subtitle: String
    let price: Double
    let currency: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(price, format: .currency(code: currency))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

struct AlternativeOptionsSection: View {
    let itinerary: Itinerary
    @Binding var showingAlternatives: Bool
    @Binding var selectedItem: Any?
    @Binding var selectedItemType: ItineraryView.ItemType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Alternative Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                AlternativeOptionButton(
                    title: "Flights",
                    subtitle: "\(itinerary.flights.count) options available",
                    icon: "airplane",
                    action: {
                        selectedItem = itinerary.flights
                        selectedItemType = ItineraryView.ItemType.flight
                        showingAlternatives = true
                    }
                )
                
                AlternativeOptionButton(
                    title: "Hotels",
                    subtitle: "\(itinerary.hotels.count) options available",
                    icon: "bed.double",
                    action: {
                        selectedItem = itinerary.hotels
                        selectedItemType = ItineraryView.ItemType.hotel
                        showingAlternatives = true
                    }
                )
                
                AlternativeOptionButton(
                    title: "Activities",
                    subtitle: "\(itinerary.activities.count) options available",
                    icon: "star",
                    action: {
                        selectedItem = itinerary.activities
                        selectedItemType = ItineraryView.ItemType.activity
                        showingAlternatives = true
                    }
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AlternativeOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyItineraryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No Itinerary Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start by planning your trip in the Plan Trip tab")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ItineraryView()
        .environmentObject(TripManager())
} 