import Foundation
import Combine

@MainActor
class CustomOrderViewModel: ObservableObject {
    @Published var customOrders: [CustomOrder] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var pendingCount = 0
    @Published var selectedStatus: CustomOrderStatus?
    
    private let api = APIService.shared
    private var currentPage = 1
    private var hasMorePages = true
    
    var filteredOrders: [CustomOrder] {
        if let status = selectedStatus {
            return customOrders.filter { $0.status == status }
        }
        
        return customOrders
    }
    
    func loadCustomOrders(refresh: Bool = false) async {
        if refresh {
            currentPage = 1
            hasMorePages = true
            customOrders = []
        }
        
        guard hasMorePages else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            var endpoint = APIConstants.CustomOrders.list + "?page=\(currentPage)&page_size=20"
            
            if let status = selectedStatus {
                endpoint += "&status=\(status.rawValue)"
            }
            
            let response: CustomOrderList = try await api.request(endpoint: endpoint)
            
            if refresh {
                customOrders = response.customOrders
            } else {
                customOrders.append(contentsOf: response.customOrders)
            }
            
            hasMorePages = response.pagination.page < response.pagination.totalPages
            currentPage += 1
            
            // Update pending count
            pendingCount = customOrders.filter { $0.status == .pending }.count
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func approveCustomOrder(id: String, price: Double, notes: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = ApproveCustomOrderRequest(estimatedPrice: price, adminNotes: notes)
            
            let updatedOrder: CustomOrder = try await api.request(
                endpoint: APIConstants.CustomOrders.approve + id + "/approve",
                method: .post,
                body: request
            )
            
            // Update local order
            if let index = customOrders.firstIndex(where: { $0.id == id }) {
                customOrders[index] = updatedOrder
            }
            
            isLoading = false
            
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            
            return false
        }
    }
    
    func rejectCustomOrder(id: String, reason: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = RejectCustomOrderRequest(adminNotes: reason)
            
            let updatedOrder: CustomOrder = try await api.request(
                endpoint: APIConstants.CustomOrders.reject + id + "/reject",
                method: .post,
                body: request
            )
            
            // Update local order
            if let index = customOrders.firstIndex(where: { $0.id == id }) {
                customOrders[index] = updatedOrder
            }
            
            isLoading = false
            
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            
            return false
        }
    }
}
