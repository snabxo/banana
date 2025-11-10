import Foundation
import Combine

@MainActor
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    
    private let api = APIService.shared
    private var currentPage = 1
    private var hasMorePages = true
    
    var filteredProducts: [Product] {
        if searchText.isEmpty {
            return products
        }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func loadProducts(refresh: Bool = false) async {
        if refresh {
            currentPage = 1
            hasMorePages = true
            products = []
        }
        
        guard hasMorePages else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let endpoint = APIConstants.Products.list + "?page=\(currentPage)&page_size=20"
            let response: ProductList = try await api.request(endpoint: endpoint)
            
            if refresh {
                products = response.products
            } else {
                products.append(contentsOf: response.products)
            }
            
            hasMorePages = response.pagination.page < response.pagination.totalPages
            currentPage += 1
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteProduct(id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            struct EmptyResponse: Codable {}
            let _: EmptyResponse = try await api.request(
                endpoint: APIConstants.Products.delete + id,
                method: .delete
            )
            
            // Remove from local list
            products.removeAll { $0.id == id }
            
            isLoading = false
            
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            
            return false
        }
    }
}

