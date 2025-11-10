import SwiftUI

struct OrderDetailView: View {
    let order: Order
    @EnvironmentObject var viewModel: OrderViewModel
    
    @State private var showingStatusUpdate = false
    @State private var showingAddTracking = false
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                // Order Header
                VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                    HStack {
                        Text(order.orderNumber)
                            .font(.title2.bold())
                        
                        Spacer()
                        
                        StatusBadge(status: order.status.displayName, color: order.statusColor)
                    }
                    
                    Text("Placed \(order.createdAt.formatted(date: .long, time: .shortened))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(AppTheme.cornerRadiusM)
                
                // Action Buttons
                HStack(spacing: AppTheme.spacingM) {
                    Button {
                        showingStatusUpdate = true
                    } label: {
                        Label("Update Status", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(AppTheme.cornerRadiusM)
                    }
                    
                    if order.status == .processing || order.status == .confirmed {
                        Button {
                            showingAddTracking = true
                        } label: {
                            Label("Add Tracking", systemImage: "shippingbox")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.cornerRadiusM)
                        }
                    }
                }
                
                // Order Items
                VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                    Text("Items")
                        .font(.headline)
                    
                    ForEach(order.items) { item in
                        OrderItemRow(item: item)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text(order.displayTotal)
                            .font(.title3.bold())
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(AppTheme.cornerRadiusM)
                
                // Shipping Address
                VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text("Shipping Address")
                            .font(.headline)
                    }
                    
                    Text(order.shippingAddress.formatted)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(AppTheme.cornerRadiusM)
                
                // Tracking Info
                if let trackingNumber = order.trackingNumber {
                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                                .foregroundColor(.green)
                            Text("Tracking Number")
                                .font(.headline)
                        }
                        
                        Text(trackingNumber)
                            .font(.subheadline.monospaced())
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(AppTheme.cornerRadiusM)
                }
                
                // Admin Notes
                if let notes = order.adminNotes {
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
        .sheet(isPresented: $showingStatusUpdate) {
            UpdateOrderStatusSheet(order: order, onUpdate: { status, notes in
                Task {
                    let success = await viewModel.updateOrderStatus(
                        orderId: order.id,
                        newStatus: status,
                        notes: notes
                    )
                    if success {
                        successMessage = "Status updated successfully"
                        showingSuccessAlert = true
                    }
                }
            })
        }
        .sheet(isPresented: $showingAddTracking) {
            AddTrackingSheet(order: order, onAdd: { trackingNumber in
                Task {
                    let success = await viewModel.addTrackingNumber(
                        orderId: order.id,
                        trackingNumber: trackingNumber
                    )
                    if success {
                        successMessage = "Tracking number added"
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

struct OrderItemRow: View {
    let item: OrderItem
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.subheadline.bold())
                
                if let variantName = item.variantName {
                    Text(variantName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Qty: \(item.quantity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(item.displayPrice)
                    .font(.subheadline)
                Text(item.displaySubTotal)
                    .font(.subheadline.bold())
            }
        }
        .padding(.vertical, AppTheme.spacingS)
    }
}

struct UpdateOrderStatusSheet: View {
    let order: Order
    let onUpdate: (OrderStatus, String?) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedStatus: OrderStatus
    @State private var notes = ""
    
    init(order: Order, onUpdate: @escaping (OrderStatus, String?) -> Void) {
        self.order = order
        self.onUpdate = onUpdate
        _selectedStatus = State(initialValue: order.status)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Picker("Select Status", selection: $selectedStatus) {
                        ForEach(OrderStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Update Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        onUpdate(selectedStatus, notes.isEmpty ? nil : notes)
                        dismiss()
                    }
                    .disabled(selectedStatus == order.status)
                }
            }
        }
    }
}

struct AddTrackingSheet: View {
    let order: Order
    let onAdd: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var trackingNumber = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tracking Number") {
                    TextField("Enter tracking number", text: $trackingNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                
                Section {
                    Text("This will automatically update the order status to 'Shipped' and send a notification to the customer.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(trackingNumber)
                        dismiss()
                    }
                    .disabled(trackingNumber.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        OrderDetailView(order: Order(
            id: "1",
            orderNumber: "ORD-2024-001",
            userId: "user1",
            status: .processing,
            totalAmount: 125.00,
            items: [],
            shippingAddress: Address(
                street: "123 Main St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94105",
                country: "USA"
            ),
            trackingNumber: nil,
            adminNotes: nil,
            createdAt: Date(),
            updatedAt: Date()
        ))
        .environmentObject(OrderViewModel())
    }
}
