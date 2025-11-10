import Foundation
import Combine

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var salesData: [SalesDataPoint] = []
    @Published var topProducts: [TopProduct] = []
    @Published var selectedPeriod: SalesPeriod = .month
    @Published var isLoadingSales = false
    @Published var isLoadingProducts = false
    @Published var errorMessage: String?
    
    private let api = APIService.shared
    
    enum SalesPeriod: Int, CaseIterable {
        case week = 7
        case twoWeeks = 14
        case month = 30
        case threeMonths = 90
        
        var displayName: String {
            switch self {
            case .week: return "7 Days"
            case .twoWeeks: return "14 Days"
            case .month: return "30 Days"
            case .threeMonths: return "90 Days"
            }
        }
        
        var days: Int {
            return self.rawValue
        }
    }
    
    func loadSalesData() async {
        isLoadingSales = true
        errorMessage = nil
        
        do {
            let endpoint = APIConstants.Analytics.sales + "?days=\(selectedPeriod.days)"
            let response: SalesData = try await api.request(endpoint: endpoint)
            salesData = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoadingSales = false
    }
    
    func loadTopProducts() async {
        isLoadingProducts = true
        errorMessage = nil
        
        do {
            struct TopProductsResponse: Codable {
                let products: [TopProduct]
            }
            
            let endpoint = APIConstants.Analytics.topProducts + "?limit=10"
            let response: TopProductsResponse = try await api.request(endpoint: endpoint)
            topProducts = response.products
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoadingProducts = false
    }
    
    var totalRevenue: Double {
        salesData.reduce(0) { $0 + $1.revenue }
    }
    
    var totalOrders: Int {
        salesData.reduce(0) { $0 + $1.orders }
    }
    
    var averageOrderValue: Double {
        guard totalOrders > 0 else { return 0 }
        return totalRevenue / Double(totalOrders)
    }
    
    var chartDataPoints: [(date: Date, value: Double)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return salesData.compactMap { point in
            guard let date = formatter.date(from: point.date) else { return nil }
            return (date, point.revenue)
        }
    }
}
