import SwiftUI

struct OrderListView: View {
    @EnvironmentObject var viewModel: OrderViewModel
    
    @State private var showingFilters = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search orders...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                    
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(AppTheme.cornerRadiusM)
                .padding()
                
                // Status Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacingS) {
                        FilterPill(
                            title: "All",
                            isSelected: viewModel.selectedStatus == nil
                        ) {
                            viewModel.selectedStatus = nil
                        }
                        
                        ForEach(OrderStatus.allCases, id: \.self) { status in
                            FilterPill(
                                title: status.displayName,
                                isSelected: viewModel.selectedStatus == status
                            ) {
                                viewModel.selectedStatus = status
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                // Orders List
                if viewModel.isLoading && viewModel.orders.isEmpty {
                    VStack(spacing: AppTheme.spacingM) {
                        ProgressView()
                        Text("Loading orders...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else if viewModel.filteredOrders.isEmpty {
                    ContentUnavailableView {
                        Label("No Orders", systemImage: "bag")
                    } description: {
                        Text(viewModel.searchText.isEmpty ? "No orders found" : "No orders match your search")
                    }
                } else {
                    List {
                        ForEach(viewModel.filteredOrders) { order in
                            NavigationLink(destination: OrderDetailView(order: order)) {
                                OrderRow(order: order)
                            }
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Orders")
            .refreshable {
                await viewModel.loadOrders(refresh: true)
            }
            .task {
                if viewModel.orders.isEmpty {
                    await viewModel.loadOrders()
                }
            }
            .onChange(of: viewModel.selectedStatus) { _, _ in
                Task {
                    await viewModel.loadOrders(refresh: true)
                }
            }
        }
    }
}

struct OrderRow: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            HStack {
                Text(order.orderNumber)
                    .font(.headline)
                
                Spacer()
                
                StatusBadge(status: order.status.displayName, color: order.statusColor)
            }
            
            Text(order.displayTotal)
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Text("\(order.items.count) item\(order.items.count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(order.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, AppTheme.spacingS)
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .padding(.horizontal, AppTheme.spacingM)
                .padding(.vertical, AppTheme.spacingS)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(AppTheme.cornerRadiusL)
        }
    }
}

struct StatusBadge: View {
    let status: String
    let color: String
    
    var badgeColor: Color {
        switch color {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "indigo": return .indigo
        default: return .gray
        }
    }
    
    var body: some View {
        Text(status)
            .font(.caption.bold())
            .padding(.horizontal, AppTheme.spacingS)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.2))
            .foregroundColor(badgeColor)
            .cornerRadius(AppTheme.cornerRadiusS)
    }
}

#Preview {
    NavigationStack {
        OrderListView()
            .environmentObject(OrderViewModel())
    }
}
