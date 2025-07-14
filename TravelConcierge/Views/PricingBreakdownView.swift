import SwiftUI

struct PricingBreakdownView: View {
    @EnvironmentObject var tripManager: TripManager
    @State private var selectedCurrency = "USD"
    @State private var showingCurrencyPicker = false
    
    var body: some View {
        NavigationView {
            Group {
                if let trip = tripManager.currentTrip, let itinerary = trip.itinerary {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Total Cost Summary
                            TotalCostSummary(itinerary: itinerary, currency: selectedCurrency)
                            
                            // Detailed Breakdown
                            DetailedBreakdownView(itinerary: itinerary, trip: trip)
                            
                            // Cost Analysis
                            CostAnalysisView(itinerary: itinerary, trip: trip)
                            
                            // Savings Opportunities
                            SavingsOpportunitiesView(itinerary: itinerary)
                            
                            // Budget Comparison
                            BudgetComparisonView(trip: trip, itinerary: itinerary)
                        }
                        .padding()
                    }
                    .navigationTitle("Pricing Breakdown")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(selectedCurrency) {
                                showingCurrencyPicker = true
                            }
                        }
                    }
                } else {
                    EmptyPricingView()
                }
            }
        }
        .sheet(isPresented: $showingCurrencyPicker) {
            CurrencyPickerView(selectedCurrency: $selectedCurrency)
        }
    }
}

struct TotalCostSummary: View {
    let itinerary: Itinerary
    let currency: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Trip Cost")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(itinerary.totalCost, specifier: "%.2f") \(currency)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Per Person")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let perPerson = itinerary.totalCost / max(Double(itinerary.dailySchedule.first?.activities.count ?? 1), 1)
                    Text("\(perPerson, specifier: "%.2f") \(currency)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            
            // Cost trend indicator
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Prices are current as of today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DetailedBreakdownView: View {
    let itinerary: Itinerary
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cost Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                let selectedFlights = itinerary.flights.filter { $0.isSelected }
                let flightCost = selectedFlights.reduce(0) { $0 + $1.price }
                CostBreakdownRow(
                    title: "Flights",
                    subtitle: "\(selectedFlights.count) flight\(selectedFlights.count > 1 ? "s" : "")",
                    cost: flightCost,
                    currency: itinerary.currency,
                    icon: "airplane",
                    color: .blue,
                    percentage: itinerary.totalCost > 0 ? (flightCost / itinerary.totalCost) * 100 : 0
                )
                
                let selectedHotels = itinerary.hotels.filter { $0.isSelected }
                let hotelCost = selectedHotels.reduce(0) { $0 + $1.totalPrice }
                CostBreakdownRow(
                    title: "Accommodation",
                    subtitle: "\(selectedHotels.count) hotel\(selectedHotels.count > 1 ? "s" : "")",
                    cost: hotelCost,
                    currency: itinerary.currency,
                    icon: "bed.double",
                    color: .purple,
                    percentage: itinerary.totalCost > 0 ? (hotelCost / itinerary.totalCost) * 100 : 0
                )
                
                let selectedActivities = itinerary.activities.filter { $0.isSelected }
                let activityCost = selectedActivities.reduce(0) { $0 + $1.price }
                CostBreakdownRow(
                    title: "Activities",
                    subtitle: "\(selectedActivities.count) activity\(selectedActivities.count > 1 ? "ies" : "y")",
                    cost: activityCost,
                    currency: itinerary.currency,
                    icon: "star",
                    color: .orange,
                    percentage: itinerary.totalCost > 0 ? (activityCost / itinerary.totalCost) * 100 : 0
                )
                
                let selectedTransport = itinerary.transportation.filter { $0.isSelected }
                let transportCost = selectedTransport.reduce(0) { $0 + $1.price }
                CostBreakdownRow(
                    title: "Transportation",
                    subtitle: "Local transport",
                    cost: transportCost,
                    currency: itinerary.currency,
                    icon: "car",
                    color: .green,
                    percentage: itinerary.totalCost > 0 ? (transportCost / itinerary.totalCost) * 100 : 0
                )
                
                let foodCost = calculateFoodCost(trip: trip)
                CostBreakdownRow(
                    title: "Food & Dining",
                    subtitle: "Estimated daily meals",
                    cost: foodCost,
                    currency: itinerary.currency,
                    icon: "fork.knife",
                    color: .red,
                    percentage: itinerary.totalCost > 0 ? (foodCost / itinerary.totalCost) * 100 : 0
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func calculateFoodCost(trip: Trip) -> Double {
        let dailyFoodCost = 60.0 // Average daily food cost per person
        return dailyFoodCost * Double(trip.numberOfTravelers) * Double(trip.duration)
    }
}

struct CostBreakdownRow: View {
    let title: String
    let subtitle: String
    let cost: Double
    let currency: String
    let icon: String
    let color: Color
    let percentage: Double
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(cost, specifier: "%.2f") \(currency)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(percentage, specifier: "%.1f")%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CostAnalysisView: View {
    let itinerary: Itinerary
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cost Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                AnalysisRow(
                    title: "Daily Average",
                    value: itinerary.totalCost / max(Double(trip.duration), 1),
                    currency: itinerary.currency,
                    icon: "calendar",
                    color: .blue
                )
                
                AnalysisRow(
                    title: "Per Person",
                    value: itinerary.totalCost / max(Double(trip.numberOfTravelers), 1),
                    currency: itinerary.currency,
                    icon: "person",
                    color: .green
                )
                
                AnalysisRow(
                    title: "Per Person/Day",
                    value: itinerary.totalCost / max(Double(trip.numberOfTravelers), 1) / max(Double(trip.duration), 1),
                    currency: itinerary.currency,
                    icon: "chart.bar",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AnalysisRow: View {
    let title: String
    let value: Double
    let currency: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(value, specifier: "%.2f") \(currency)")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

struct SavingsOpportunitiesView: View {
    let itinerary: Itinerary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Savings Opportunities")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if let cheapestFlight = itinerary.flights.min(by: { $0.price < $1.price }),
                   let selectedFlight = itinerary.flights.first(where: { $0.isSelected }),
                   cheapestFlight.id != selectedFlight.id {
                    SavingsRow(
                        title: "Switch to cheaper flight",
                        savings: selectedFlight.price - cheapestFlight.price,
                        currency: itinerary.currency,
                        description: "\(cheapestFlight.airline) for \(String(format: "%.2f", cheapestFlight.price)) \(itinerary.currency)"
                    )
                }
                
                if let cheapestHotel = itinerary.hotels.min(by: { $0.totalPrice < $1.totalPrice }),
                   let selectedHotel = itinerary.hotels.first(where: { $0.isSelected }),
                   cheapestHotel.id != selectedHotel.id {
                    SavingsRow(
                        title: "Switch to cheaper hotel",
                        savings: selectedHotel.totalPrice - cheapestHotel.totalPrice,
                        currency: itinerary.currency,
                        description: "\(cheapestHotel.name) for \(String(format: "%.2f", cheapestHotel.totalPrice)) \(itinerary.currency)"
                    )
                }
                
                let expensiveActivities = itinerary.activities.filter { $0.price > 100 }
                if !expensiveActivities.isEmpty {
                    SavingsRow(
                        title: "Skip expensive activities",
                        savings: expensiveActivities.reduce(0) { $0 + $1.price },
                        currency: itinerary.currency,
                        description: "Save \(expensiveActivities.count) high-cost activities"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SavingsRow: View {
    let title: String
    let savings: Double
    let currency: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.green)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Save \(savings, specifier: "%.2f") \(currency)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct BudgetComparisonView: View {
    let trip: Trip
    let itinerary: Itinerary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Comparison")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Your Budget")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(trip.itinerary?.totalCost ?? 0, specifier: "%.2f") \(trip.itinerary?.currency ?? "USD")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Total Cost")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(itinerary.totalCost, specifier: "%.2f") \(itinerary.currency)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Divider()
                
                HStack {
                    Text("Remaining")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    let remaining = (trip.budget ?? 0) - itinerary.totalCost
                    Text("\(remaining, specifier: "%.2f") \(itinerary.currency)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(remaining >= 0 ? .green : .red)
                }
                    
                if let budget = trip.budget, budget > 0 {
                    let progress = min(itinerary.totalCost / budget, 1.0)
                    ProgressView(value: progress.isNaN || progress.isInfinite ? 0 : progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: itinerary.totalCost > budget ? .red : .green))
                        .scaleEffect(y: 2)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmptyPricingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No Pricing Data")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Plan a trip first to see detailed pricing breakdown")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct CurrencyPickerView: View {
    @Binding var selectedCurrency: String
    @Environment(\.dismiss) var dismiss
    
    let currencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY"]
    
    var body: some View {
        NavigationView {
            List(currencies, id: \.self) { currency in
                Button(action: {
                    selectedCurrency = currency
                    dismiss()
                }) {
                    HStack {
                        Text(currency)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedCurrency == currency {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Currency")
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

#Preview {
    PricingBreakdownView()
        .environmentObject(TripManager())
} 