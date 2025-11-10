import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var stats: DashboardStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let api = APIService.shared
    
    func loadDashboardStats() async {
        isLoading = true
        errorMessage = nil
        
        do {
            stats = try await api.request(endpoint: APIConstants.Analytics.dashboard)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
