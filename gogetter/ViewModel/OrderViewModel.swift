import Foundation
import Combine

@MainActor
class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var selectedOrder: Order?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var pendingCount = 0
    @Published var selectedStatus: OrderStatus?
    @Published var searchText = ""
    
    private let api = APIService.shared
    private var currentPage = 1
    private var hasMorePages = true
    
    var filteredOrders: [Order] {
        var result = orders
        
        if let status = selectedStatus {
            result = result.filter { $0.status == status }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.orderNumber.localizedCaseInsensitiveContains(searchText) ||
                $0.shippingAddress.formatted.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    func loadOrders(refresh: Bool = false) async {
        if refresh {
            currentPage = 1
            hasMorePages = true
            orders = []
        }
        
        guard hasMorePages else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            var endpoint = APIConstants.Orders.list + "?page=\(currentPage)&page_size=20"
            if let status = selectedStatus {
                endpoint += "&status=\(status.rawValue)"
            }
            
            let response: OrderList = try await api.request(endpoint: endpoint)
            
            if refresh {
                orders = response.orders
            } else {
                orders.append(contentsOf: response.orders)
            }
            
            hasMorePages = response.pagination.page < response.pagination.totalPages
            currentPage += 1
            
            pendingCount = orders.filter { $0.status == .pending }.count
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadOrderDetails(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            selectedOrder = try await api.request(endpoint: APIConstants.Orders.detail + id)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateOrderStatus(orderId: String, newStatus: OrderStatus, notes: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = UpdateOrderStatusRequest(status: newStatus, adminNotes: notes)
            let updatedOrder: Order = try await api.request(
                endpoint: APIConstants.Orders.updateStatus + orderId + "/status",
                method: .put,
                body: request
            )
            
            if let index = orders.firstIndex(where: { $0.id == orderId }) {
                orders[index] = updatedOrder
            }
            selectedOrder = updatedOrder
            
            isLoading = false
            
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            
            return false
        }
    }
    
    func addTrackingNumber(orderId: String, trackingNumber: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = AddTrackingRequest(trackingNumber: trackingNumber)
            let updatedOrder: Order = try await api.request(
                endpoint: APIConstants.Orders.addTracking + orderId + "/tracking",
                method: .put,
                body: request
            )
            
            if let index = orders.firstIndex(where: { $0.id == orderId }) {
                orders[index] = updatedOrder
            }
            selectedOrder = updatedOrder
            
            isLoading = false
            
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            
            return false
        }
    }
}

