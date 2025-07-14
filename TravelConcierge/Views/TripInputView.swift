import SwiftUI

struct TripInputView: View {
    @EnvironmentObject var tripManager: TripManager
    @EnvironmentObject var aiService: AIService
    
    @State private var departureLocation = ""
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60) 
    @State private var numberOfTravelers = 1
    @State private var budget: Double = 5000
    @State private var flightClass: FlightClass = .economy
    @State private var hotelStarRating = 3
    @State private var includeActivities = true
    @State private var includeTransportation = true
    @State private var isPlanning = false
    @State private var showingPreferences = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Plan Your Dream Trip")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Tell us where you want to go and we'll create the perfect itinerary")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            CustomTextField(
                                title: "From",
                                placeholder: "Departure city",
                                text: $departureLocation,
                                icon: "airplane.departure"
                            )
                            
                            CustomTextField(
                                title: "To",
                                placeholder: "Destination city",
                                text: $destination,
                                icon: "airplane.arrival"
                            )
                        }
                        
                        VStack(spacing: 16) {
                            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            
                            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "person.2")
                                    .foregroundColor(.blue)
                                Text("Number of Travelers")
                                Spacer()
                                Stepper("\(numberOfTravelers)", value: $numberOfTravelers, in: 1...10)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            HStack {
                                Image(systemName: "dollarsign.circle")
                                    .foregroundColor(.blue)
                                Text("Budget")
                                Spacer()
                                TextField("Budget", value: $budget, format: .currency(code: "USD"))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingPreferences = true
                        }) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                Text("Customize Preferences")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                    
                    Button(action: planTrip) {
                        HStack {
                            if isPlanning {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            Text(isPlanning ? "Planning Your Trip..." : "Plan My Trip")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidInput ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isValidInput || isPlanning)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Plan Trip")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPreferences) {
                PreferencesView(
                    flightClass: $flightClass,
                    hotelStarRating: $hotelStarRating,
                    includeActivities: $includeActivities,
                    includeTransportation: $includeTransportation
                )
            }
        }
    }
    
    private var isValidInput: Bool {
        !departureLocation.isEmpty && 
        !destination.isEmpty && 
        startDate < endDate &&
        numberOfTravelers > 0 &&
        budget > 0
    }
    
    private func planTrip() {
        isPlanning = true
        
        let preferences = TripPreferences(
            flightClass: flightClass,
            hotelStarRating: hotelStarRating,
            includeActivities: includeActivities,
            includeTransportation: includeTransportation
        )
        
        let trip = Trip(
            departureLocation: departureLocation,
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            numberOfTravelers: numberOfTravelers,
            budget: budget,
            preferences: preferences
        )
        
        Task {
            do {
                let itinerary = try await aiService.planTripViaBackend(trip: trip)
                print("[DEBUG] Received itinerary: \(itinerary)")
                await MainActor.run {
                    tripManager.currentTrip = trip
                    tripManager.currentTrip?.itinerary = itinerary
                    print("[DEBUG] tripManager.currentTrip set: \(String(describing: tripManager.currentTrip))")
                    isPlanning = false
                }
            } catch {
                print("[DEBUG] planTripViaBackend error: \(error)")
                await MainActor.run {
                    isPlanning = false      
                }
            }
        }
    }
}

struct CustomTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct PreferencesView: View {
    @Binding var flightClass: FlightClass
    @Binding var hotelStarRating: Int
    @Binding var includeActivities: Bool
    @Binding var includeTransportation: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Flight Preferences") {
                    Picker("Flight Class", selection: $flightClass) {
                        ForEach(FlightClass.allCases, id: \.self) { flightClass in
                            Text(flightClass.rawValue).tag(flightClass)
                        }
                    }
                }
                
                Section("Hotel Preferences") {
                    Stepper("Star Rating: \(hotelStarRating)★", value: $hotelStarRating, in: 1...5)
                }
                
                Section("Additional Services") {
                    Toggle("Include Activities", isOn: $includeActivities)
                    Toggle("Include Transportation", isOn: $includeTransportation)
                }
            }
            .navigationTitle("Preferences")
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
    TripInputView()
        .environmentObject(TripManager())
        .environmentObject(AIService())
} 