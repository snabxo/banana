import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading && viewModel.stats == nil {
                    VStack(spacing: AppTheme.spacingM) {
                        ProgressView()
                        Text("Loading dashboard...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 100)
                } else if let stats = viewModel.stats {
                    VStack(spacing: AppTheme.spacingL) {
                        // Revenue Section
                        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                            Text("Revenue")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: AppTheme.spacingM) {
                                StatCard(
                                    title: "Today",
                                    value: "$\(stats.todayRevenue, specifier: "%.2f")",
                                    icon: "calendar",
                                    color: .green
                                )
                                
                                StatCard(
                                    title: "This Week",
                                    value: "$\(stats.weekRevenue, specifier: "%.2f")",
                                    icon: "calendar.badge.clock",
                                    color: .blue
                                )
                                
                                StatCard(
                                    title: "This Month",
                                    value: "$\(stats.monthRevenue, specifier: "%.2f")",
                                    icon: "calendar.circle",
                                    color: .purple
                                )
                                
                                StatCard(
                                    title: "Total",
                                    value: "$\(stats.totalRevenue, specifier: "%.2f")",
                                    icon: "chart.line.uptrend.xyaxis",
                                    color: .orange
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Orders Section
                        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                            Text("Orders")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: AppTheme.spacingM) {
                                StatCard(
                                    title: "Pending",
                                    value: "\(stats.pendingOrders)",
                                    icon: "clock.fill",
                                    color: .orange,
                                    highlight: stats.pendingOrders > 0
                                )
                                
                                StatCard(
                                    title: "Processing",
                                    value: "\(stats.processingOrders)",
                                    icon: "gearshape.fill",
                                    color: .purple
                                )
                                
                                StatCard(
                                    title: "Today",
                                    value: "\(stats.todayOrders)",
                                    icon: "bag.fill",
                                    color: .green
                                )
                                
                                StatCard(
                                    title: "Total",
                                    value: "\(stats.totalOrders)",
                                    icon: "chart.bar.fill",
                                    color: .blue
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Alerts Section
                        if stats.pendingReviews > 0 || stats.lowStockProducts > 0 || stats.customOrdersPending > 0 {
                            VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                                Text("Alerts")
                                    .font(.title3.bold())
                                    .padding(.horizontal)
                                
                                VStack(spacing: AppTheme.spacingS) {
                                    if stats.customOrdersPending > 0 {
                                        AlertRow(
                                            title: "Custom Order Requests",
                                            value: "\(stats.customOrdersPending)",
                                            icon: "star.circle.fill",
                                            color: .purple
                                        )
                                    }
                                    
                                    if stats.pendingReviews > 0 {
                                        AlertRow(
                                            title: "Pending Reviews",
                                            value: "\(stats.pendingReviews)",
                                            icon: "star.fill",
                                            color: .orange
                                        )
                                    }
                                    
                                    if stats.lowStockProducts > 0 {
                                        AlertRow(
                                            title: "Low Stock Products",
                                            value: "\(stats.lowStockProducts)",
                                            icon: "exclamationmark.triangle.fill",
                                            color: .red
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Quick Stats
                        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                            Text("Store Overview")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            HStack(spacing: AppTheme.spacingM) {
                                QuickStatCard(
                                    title: "Products",
                                    value: "\(stats.totalProducts)",
                                    icon: "cube.fill"
                                )
                                
                                QuickStatCard(
                                    title: "Customers",
                                    value: "\(stats.totalCustomers)",
                                    icon: "person.fill"
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label("Error Loading Dashboard", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task {
                                await viewModel.loadDashboardStats()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.loadDashboardStats()
            }
            .task {
                await viewModel.loadDashboardStats()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var highlight: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            Text(value)
                .font(.title.bold())
                .foregroundColor(highlight ? color : .primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusM)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusM)
                .stroke(highlight ? color.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

struct AlertRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusM)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        )
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(value)
                    .font(.title2.bold())
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusM)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        )
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environmentObject(DashboardViewModel())
    }
}

