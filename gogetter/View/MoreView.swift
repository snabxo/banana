import Combine
import SwiftUI

struct MoreView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    if let user = authViewModel.currentUser {
                        HStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 50, height: 50)
                                .overlay {
                                    Text(user.email.prefix(1).uppercased())
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                if !user.fullName.isEmpty {
                                    Text(user.fullName)
                                        .font(.headline)
                                }
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(user.role.rawValue.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Analytics Section
                Section("Analytics") {
                    NavigationLink(destination: AnalyticsDetailedView()) {
                        Label("Sales Analytics", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    
                    NavigationLink(destination: LowStockView()) {
                        Label("Low Stock Products", systemImage: "exclamationmark.triangle")
                    }
                }
                
                // Reviews Section
                Section("Reviews") {
                    NavigationLink(destination: ReviewModerationView()) {
                        Label("Review Moderation", systemImage: "star.fill")
                    }
                }
                
                // Support Section
                Section("Support") {
                    Link(destination: URL(string: "https://docs.example.com")!) {
                        Label("Documentation", systemImage: "book")
                    }
                    
                    Link(destination: URL(string: "mailto:support@example.com")!) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                }
                
                // App Info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Logout
                Section {
                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Log Out", systemImage: "arrow.right.square")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("More")
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    Task {
                        await authViewModel.logout()
                    }
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}

#Preview {
    NavigationStack {
        MoreView()
            .environmentObject(AuthViewModel())
    }
}

struct LowStockView: View {
    @StateObject private var viewModel = LowStockViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(.secondary)
                }
            } else if viewModel.lowStockProducts.isEmpty {
                ContentUnavailableView {
                    Label("No Low Stock", systemImage: "checkmark.circle")
                } description: {
                    Text("All products are well stocked")
                }
            } else {
                List(viewModel.lowStockProducts) { product in
                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        Text(product.name)
                            .font(.headline)
                        
                        HStack {
                            Text("SKU: \(product.sku)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(product.stockQuantity) left")
                                .font(.subheadline.bold())
                                .foregroundColor(.red)
                        }
                        
                        Text("Threshold: \(product.lowStockThreshold)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Low Stock")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadLowStockProducts()
        }
    }
}

@MainActor
class LowStockViewModel: ObservableObject {
    @Published var lowStockProducts: [LowStockProduct] = []
    @Published var isLoading = false
    
    private let api = APIService.shared
    
    func loadLowStockProducts() async {
        isLoading = true
        
        do {
            struct Response: Codable {
                let products: [LowStockProduct]
            }
            let response: Response = try await api.request(endpoint: APIConstants.Analytics.lowStock)
            lowStockProducts = response.products
        } catch {
            print("Error loading low stock: \(error)")
        }
        
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        MoreView()
            .environmentObject(AuthViewModel())
    }
}
