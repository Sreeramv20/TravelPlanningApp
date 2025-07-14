import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var tripManager: TripManager
    @State private var showingSettings = false
    @State private var showingTripHistory = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ProfileHeaderView()
                    
                    QuickStatsView(tripManager: tripManager)
                    
                    RecentTripsView(tripManager: tripManager)
                    
                    SettingsSection(showingSettings: $showingSettings)
                    
                    SupportSection()
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingTripHistory) {
                TripHistoryView()
            }
        }
    }
}

struct ProfileHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 4) {
                Text("Travel Enthusiast")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Member since 2024")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                QuickActionButton(
                    title: "Edit Profile",
                    icon: "pencil",
                    action: { /* Edit profile */ }
                )
                
                QuickActionButton(
                    title: "Preferences",
                    icon: "slider.horizontal.3",
                    action: { /* Open preferences */ }
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickStatsView: View {
    let tripManager: TripManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Travel Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(
                    title: "Total Trips",
                    value: "\(tripManager.getTripCount())",
                    icon: "airplane",
                    color: .blue
                )
                
                StatCard(
                    title: "Total Spent",
                    value: tripManager.getTotalSpent(),
                    isCurrency: true,
                    icon: "dollarsign.circle",
                    color: .green
                )
                
                StatCard(
                    title: "Avg. Trip Cost",
                    value: tripManager.getAverageTripCost(),
                    isCurrency: true,
                    icon: "chart.bar",
                    color: .orange
                )
                
                StatCard(
                    title: "Upcoming",
                    value: "\(tripManager.getUpcomingTrips().count)",
                    icon: "calendar",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: Any
    var isCurrency: Bool = false
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            if isCurrency, let doubleValue = value as? Double {
                Text(doubleValue, format: .currency(code: "USD"))
                    .font(.title3)
                    .fontWeight(.bold)
            } else {
                Text("\(value)")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct RecentTripsView: View {
    let tripManager: TripManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Trips")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                }
                .foregroundColor(.blue)
            }
            
            if tripManager.tripHistory.isEmpty {
                EmptyTripsView()
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(tripManager.tripHistory.prefix(3))) { trip in
                        RecentTripRow(trip: trip)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecentTripRow: View {
    let trip: Trip
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(trip.departureLocation) → \(trip.destination)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(trip.startDate, style: .date) • \(trip.status.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let itinerary = trip.itinerary {
                Text(itinerary.totalCost, format: .currency(code: itinerary.currency))
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusIcon: String {
        switch trip.status {
        case .planning:
            return "clock"
        case .planned:
            return "checkmark.circle"
        case .booked:
            return "airplane"
        case .completed:
            return "checkmark.circle.fill"
        case .cancelled:
            return "xmark.circle"
        }
    }
    
    private var statusColor: Color {
        switch trip.status {
        case .planning:
            return .orange
        case .planned:
            return .blue
        case .booked:
            return .green
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
    }
}

struct EmptyTripsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No trips yet")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Start planning your first adventure!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct SettingsSection: View {
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                SettingsRow(
                    title: "Account Settings",
                    subtitle: "Manage your profile and preferences",
                    icon: "person.circle",
                    action: { showingSettings = true }
                )
                
                SettingsRow(
                    title: "Notifications",
                    subtitle: "Configure push notifications",
                    icon: "bell",
                    action: { /* Open notifications */ }
                )
                
                SettingsRow(
                    title: "Privacy & Security",
                    subtitle: "Manage your data and security",
                    icon: "lock",
                    action: { /* Open privacy settings */ }
                )
                
                SettingsRow(
                    title: "Payment Methods",
                    subtitle: "Manage saved payment options",
                    icon: "creditcard",
                    action: { /* Open payment methods */ }
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SettingsRow: View {
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

struct SupportSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support & Help")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                SettingsRow(
                    title: "Help Center",
                    subtitle: "Find answers to common questions",
                    icon: "questionmark.circle",
                    action: { /* Open help center */ }
                )
                
                SettingsRow(
                    title: "Contact Support",
                    subtitle: "Get in touch with our team",
                    icon: "message",
                    action: { /* Contact support */ }
                )
                
                SettingsRow(
                    title: "About",
                    subtitle: "App version and information",
                    icon: "info.circle",
                    action: { /* Show about */ }
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Account") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text("Travel Enthusiast")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        Text("user@example.com")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Preferences") {
                    Toggle("Push Notifications", isOn: .constant(true))
                    Toggle("Email Notifications", isOn: .constant(true))
                    Toggle("Location Services", isOn: .constant(true))
                }
                
                Section("Travel Preferences") {
                    HStack {
                        Text("Default Flight Class")
                        Spacer()
                        Text("Economy")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Default Hotel Rating")
                        Spacer()
                        Text("3+ Stars")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Data & Privacy") {
                    Button("Export My Data") {
                    }
                    
                    Button("Delete Account") {
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
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

struct TripHistoryView: View {
    @EnvironmentObject var tripManager: TripManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tripManager.tripHistory) { trip in
                    TripHistoryRow(trip: trip)
                }
            }
            .navigationTitle("Trip History")
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

struct TripHistoryRow: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(trip.departureLocation) → \(trip.destination)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(trip.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(4)
            }
            
            Text("\(trip.startDate, style: .date) - \(trip.endDate, style: .date)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let itinerary = trip.itinerary {
                Text(itinerary.totalCost, format: .currency(code: itinerary.currency))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch trip.status {
        case .planning:
            return .orange
        case .planned:
            return .blue
        case .booked:
            return .green
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(TripManager())
} 