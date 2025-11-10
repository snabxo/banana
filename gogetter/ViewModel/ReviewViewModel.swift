import Foundation
import Combine

@MainActor
class ReviewViewModel: ObservableObject {
    @Published var pendingReviews: [Review] = []
    @Published var allReviews: [Review] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: ReviewFilter = .pending
    
    private let api = APIService.shared
    private var currentPage = 1
    private var hasMorePages = true
    
    enum ReviewFilter: String, CaseIterable {
        case pending = "Pending"
        case approved = "Approved"
        case all = "All"
    }
    
    var filteredReviews: [Review] {
        switch selectedFilter {
        case .pending:
            return pendingReviews
        case .approved:
            return allReviews.filter { $0.isApproved }
        case .all:
            return allReviews
        }
    }
    
    func loadPendingReviews(refresh: Bool = false) async {
        if refresh {
            currentPage = 1
            hasMorePages = true
            pendingReviews = []
        }
        
        guard hasMorePages else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let endpoint = APIConstants.Reviews.pending + "?page=\(currentPage)&page_size=20"
            let response: ReviewList = try await api.request(endpoint: endpoint)
            
            if refresh {
                pendingReviews = response.reviews
            } else {
                pendingReviews.append(contentsOf: response.reviews)
            }
            
            hasMorePages = response.pagination.page < response.pagination.totalPages
            currentPage += 1
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func approveReview(id: String, adminResponse: String?) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = ApproveReviewRequest(adminResponse: adminResponse)
            let updatedReview: Review = try await api.request(
                endpoint: APIConstants.Reviews.approve + id + "/approve",
                method: .post,
                body: request
            )
            
            // Remove from pending
            pendingReviews.removeAll { $0.id == id }
            
            // Add to all reviews
            if !allReviews.contains(where: { $0.id == id }) {
                allReviews.append(updatedReview)
            }
            
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func rejectReview(id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            struct EmptyRequest: Encodable {}
            struct EmptyResponse: Codable {}
            
            let _: EmptyResponse = try await api.request(
                endpoint: APIConstants.Reviews.reject + id + "/reject",
                method: .delete
            )
            
            // Remove from pending
            pendingReviews.removeAll { $0.id == id }
            
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
