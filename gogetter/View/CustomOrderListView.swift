import SwiftUI

struct CustomOrderListView: View {
    @EnvironmentObject var viewModel: CustomOrderViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacingS) {
                        FilterPill(
                            title: "All",
                            isSelected: viewModel.selectedStatus == nil
                        ) {
                            viewModel.selectedStatus = nil
                        }
                        
                        ForEach(CustomOrderStatus.allCases, id: \.self) { status in
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
                .padding(.vertical)
                
                // Custom Orders List
                if viewModel.isLoading && viewModel.customOrders.isEmpty {
                    VStack(spacing: AppTheme.spacingM) {
                        ProgressView()
                        Text("Loading custom orders...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else if viewModel.filteredOrders.isEmpty {
                    ContentUnavailableView {
                        Label("No Custom Orders", systemImage: "star")
                    } description: {
                        Text("No custom order requests found")
                    }
                } else {
                    List {
                        ForEach(viewModel.filteredOrders) { order in
                            NavigationLink(destination: CustomOrderDetailView(customOrder: order)) {
                                CustomOrderRow(customOrder: order)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Custom Orders")
            .refreshable {
                await viewModel.loadCustomOrders(refresh: true)
            }
            .task {
                if viewModel.customOrders.isEmpty {
                    await viewModel.loadCustomOrders()
                }
            }
            .onChange(of: viewModel.selectedStatus) { _, _ in
                Task {
                    await viewModel.loadCustomOrders(refresh: true)
                }
            }
        }
    }
}

struct CustomOrderRow: View {
    let customOrder: CustomOrder
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            HStack {
                if let productName = customOrder.productName {
                    Text(productName)
                        .font(.headline)
                } else {
                    Text("Custom Request")
                        .font(.headline)
                }
                
                Spacer()
                
                StatusBadge(status: customOrder.status.displayName, color: customOrder.statusColor)
            }
            
            Text(customOrder.specialInstructions)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if let price = customOrder.displayPrice {
                Text("Est. \(price)")
                    .font(.subheadline.bold())
                    .foregroundColor(.green)
            }
            
            Text(customOrder.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, AppTheme.spacingS)
    }
}

struct CustomOrderDetailView: View {
    let customOrder: CustomOrder
    @EnvironmentObject var viewModel: CustomOrderViewModel
    @State private var showingApprovalSheet = false
    @State private var showingRejectionSheet = false
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                // Header
                VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                    HStack {
                        Text("Custom Order")
                            .font(.title2.bold())
                        
                        Spacer()
                        
                        StatusBadge(status: customOrder.status.displayName, color: customOrder.statusColor)
                    }
                    
                    if let productName = customOrder.productName {
                        Text("Based on: \(productName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Requested \(customOrder.createdAt.formatted(date: .long, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(AppTheme.cornerRadiusM)
                
                // Action Buttons (only for pending orders)
                if customOrder.status == .pending {
                    HStack(spacing: AppTheme.spacingM) {
                        Button {
                            showingApprovalSheet = true
                        } label: {
                            Label("Approve", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.cornerRadiusM)
                        }
                        
                        Button {
                            showingRejectionSheet = true
                        } label: {
                            Label("Reject", systemImage: "xmark.circle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.cornerRadiusM)
                        }
                    }
                }
                
                // Special Instructions
                VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundColor(.blue)
                        Text("Customer Instructions")
                            .font(.headline)
                    }
                    
                    Text(customOrder.specialInstructions)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(AppTheme.cornerRadiusM)
                
                // Estimated Price (if approved)
                if let price = customOrder.estimatedPrice {
                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.green)
                            Text("Estimated Price")
                                .font(.headline)
                        }
                        
                        Text("$\(price, specifier: "%.2f")")
                            .font(.title2.bold())
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(AppTheme.cornerRadiusM)
                }
                
                // Admin Notes
                if let notes = customOrder.adminNotes {
                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.orange)
                            Text("Admin Notes")
                                .font(.headline)
                        }
                        
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(AppTheme.cornerRadiusM)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingApprovalSheet) {
            ApproveCustomOrderSheet(customOrder: customOrder, onApprove: { price, notes in
                Task {
                    let success = await viewModel.approveCustomOrder(
                        id: customOrder.id,
                        price: price,
                        notes: notes
                    )
                    if success {
                        successMessage = "Custom order approved successfully"
                        showingSuccessAlert = true
                    }
                }
            })
        }
        .sheet(isPresented: $showingRejectionSheet) {
            RejectCustomOrderSheet(customOrder: customOrder, onReject: { reason in
                Task {
                    let success = await viewModel.rejectCustomOrder(
                        id: customOrder.id,
                        reason: reason
                    )
                    if success {
                        successMessage = "Custom order rejected"
                        showingSuccessAlert = true
                    }
                }
            })
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }
    }
}

struct ApproveCustomOrderSheet: View {
    let customOrder: CustomOrder
    let onApprove: (Double, String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var price = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Estimated Price") {
                    TextField("0.00", text: $price)
                        .keyboardType(.decimalPad)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section {
                    Text("This will send a price quote to the customer.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Approve Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Approve") {
                        if let priceValue = Double(price) {
                            onApprove(priceValue, notes)
                            dismiss()
                        }
                    }
                    .disabled(price.isEmpty || Double(price) == nil)
                }
            }
        }
    }
}

struct RejectCustomOrderSheet: View {
    let customOrder: CustomOrder
    let onReject: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var reason = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reason for Rejection") {
                    TextEditor(text: $reason)
                        .frame(height: 150)
                }
                
                Section {
                    Text("Provide a clear explanation for the customer.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Reject Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Reject") {
                        onReject(reason)
                        dismiss()
                    }
                    .disabled(reason.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CustomOrderListView()
            .environmentObject(CustomOrderViewModel())
    }
}
