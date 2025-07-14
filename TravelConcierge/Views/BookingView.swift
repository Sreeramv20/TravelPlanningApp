import SwiftUI

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

struct BookingView: View {
    @EnvironmentObject var tripManager: TripManager
    @EnvironmentObject var bookingService: BookingService
    @State private var showingTravelerForm = false
    @State private var showingPaymentForm = false
    @State private var isProcessing = false
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            Group {
                if let trip = tripManager.currentTrip, let itinerary = trip.itinerary {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Booking Summary
                            BookingSummaryView(trip: trip, itinerary: itinerary)
                            
                            // Traveler Details
                            TravelerDetailsSection(
                                showingForm: $showingTravelerForm,
                                trip: trip
                            )
                            
                            // Payment Method
                            PaymentMethodSection(
                                showingForm: $showingPaymentForm
                            )
                            
                            // Booking Button
                            BookingButton(
                                isProcessing: $isProcessing,
                                action: processBooking
                            )
                        }
                        .padding()
                    }
                    .navigationTitle("Book Trip")
                    .navigationBarTitleDisplayMode(.inline)
                } else {
                    EmptyBookingView()
                }
            }
        }
        .sheet(isPresented: $showingTravelerForm) {
            TravelerFormView(trip: tripManager.currentTrip!)
        }
        .sheet(isPresented: $showingPaymentForm) {
            PaymentFormView()
        }
        .sheet(isPresented: $showingConfirmation) {
            BookingConfirmationView()
        }
    }
    
    private func processBooking() {
        isProcessing = true
        
        Task {
            do {
                _ = try await bookingService.createBooking(
                    trip: tripManager.currentTrip!,
                    itinerary: tripManager.currentTrip!.itinerary!
                )
                
                await MainActor.run {
                    isProcessing = false
                    showingConfirmation = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    // Handle error
                }
            }
        }
    }
}

struct BookingSummaryView: View {
    let trip: Trip
    let itinerary: Itinerary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Booking Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                SummaryRow(
                    title: "Trip",
                    value: "\(trip.departureLocation) → \(trip.destination)"
                )
                
                SummaryRow(
                    title: "Dates",
                    value: "\(dateFormatter.string(from: trip.startDate)) - \(dateFormatter.string(from: trip.endDate))"
                )
                
                SummaryRow(
                    title: "Travelers",
                    value: "\(trip.numberOfTravelers) person\(trip.numberOfTravelers > 1 ? "s" : "")"
                )
                
                SummaryRow(
                    title: "Duration",
                    value: "\(trip.duration) days"
                )
                
                Divider()
                
                SummaryRow(
                    title: "Total Cost",
                    value: itinerary.totalCost,
                    isCurrency: true,
                    currency: itinerary.currency,
                    isBold: true
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SummaryRow: View {
    let title: String
    let value: Any
    var isCurrency: Bool = false
    var currency: String = "USD"
    var isBold: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if isCurrency, let doubleValue = value as? Double {
                Text(doubleValue, format: .currency(code: currency))
                    .font(.subheadline)
                    .fontWeight(isBold ? .bold : .medium)
            } else {
                Text("\(value)")
                    .font(.subheadline)
                    .fontWeight(isBold ? .bold : .medium)
            }
        }
    }
}

struct TravelerDetailsSection: View {
    @Binding var showingForm: Bool
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Traveler Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Add") {
                    showingForm = true
                }
                .foregroundColor(.blue)
            }
            
            if trip.numberOfTravelers > 0 {
                VStack(spacing: 8) {
                    ForEach(0..<trip.numberOfTravelers, id: \.self) { index in
                        TravelerRow(index: index + 1)
                    }
                }
            } else {
                Text("No travelers added yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TravelerRow: View {
    let index: Int
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle")
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text("Traveler \(index)")
                .font(.subheadline)
            
            Spacer()
            
            Text("Not filled")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct PaymentMethodSection: View {
    @Binding var showingForm: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Payment Method")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Add") {
                    showingForm = true
                }
                .foregroundColor(.blue)
            }
            
            Text("No payment method selected")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BookingButton: View {
    @Binding var isProcessing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "creditcard.fill")
                }
                
                Text(isProcessing ? "Processing..." : "Book Now")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isProcessing)
    }
}

struct TravelerFormView: View {
    let trip: Trip
    @Environment(\.dismiss) var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = Date()
    @State private var passportNumber = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var country = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    TextField("Passport Number (Optional)", text: $passportNumber)
                }
                
                Section("Contact Information") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Address") {
                    TextField("Street", text: $street)
                    TextField("City", text: $city)
                    TextField("State/Province", text: $state)
                    TextField("ZIP/Postal Code", text: $zipCode)
                    TextField("Country", text: $country)
                }
            }
            .navigationTitle("Traveler Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save traveler details
                        dismiss()
                    }
                    .disabled(!isValidForm)
                }
            }
        }
    }
    
    private var isValidForm: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && !phone.isEmpty
    }
}

struct PaymentFormView: View {
    @Environment(\.dismiss) var dismiss
    @State private var paymentType: PaymentType = .creditCard
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var billingStreet = ""
    @State private var billingCity = ""
    @State private var billingState = ""
    @State private var billingZipCode = ""
    @State private var billingCountry = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Payment Method") {
                    Picker("Payment Type", selection: $paymentType) {
                        ForEach(PaymentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if paymentType == .creditCard || paymentType == .debitCard {
                    Section("Card Information") {
                        TextField("Card Number", text: $cardNumber)
                            .keyboardType(.numberPad)
                        
                        HStack {
                            TextField("MM/YY", text: $expiryDate)
                                .keyboardType(.numberPad)
                            
                            TextField("CVV", text: $cvv)
                                .keyboardType(.numberPad)
                        }
                    }
                }
                
                Section("Billing Address") {
                    TextField("Street", text: $billingStreet)
                    TextField("City", text: $billingCity)
                    TextField("State/Province", text: $billingState)
                    TextField("ZIP/Postal Code", text: $billingZipCode)
                    TextField("Country", text: $billingCountry)
                }
            }
            .navigationTitle("Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save payment method
                        dismiss()
                    }
                    .disabled(!isValidPaymentForm)
                }
            }
        }
    }
    
    private var isValidPaymentForm: Bool {
        if paymentType == .creditCard || paymentType == .debitCard {
            return !cardNumber.isEmpty && !expiryDate.isEmpty && !cvv.isEmpty
        }
        return true
    }
}

struct BookingConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                // Confirmation message
                VStack(spacing: 16) {
                    Text("Booking Confirmed!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Your trip has been successfully booked. You'll receive a confirmation email with all the details shortly.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Booking details
                VStack(spacing: 12) {
                    ConfirmationRow(title: "Booking Reference", value: "TC-2024-001")
                    ConfirmationRow(title: "Status", value: "Confirmed")
                    ConfirmationRow(title: "Confirmation Email", value: "Sent")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button("View Itinerary") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    
                    Button("Export to Calendar") {
                        // Export functionality
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Confirmation")
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

struct ConfirmationRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct EmptyBookingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No Trip to Book")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Plan a trip first to proceed with booking")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    BookingView()
        .environmentObject(TripManager())
        .environmentObject(BookingService())
} 