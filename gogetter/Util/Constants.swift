import SwiftUI

struct APIConstants {
    #if DEBUG
    static let baseURL: String = "http://192.168.1.100:8080/api/v1"  // replace with Mac's IP for testing
    #else
    static let baseURL = "https://api.sniffle.com/api/v1"
    #endif
    
    struct Auth {
        static let login = "/auth/login"
        static let refresh = "/auth/refresh"
        static let logout = "/auth/logout"
        static let profile = "/auth/profile"
    }
    
    struct Orders {
        static let list = "/admin/orders"
        static let detail = "/admin/orders/"
        static let updateStatus = "/admin/orders/"
        static let addTracking = "/admin/orders/"
    }
    
    struct Products {
        static let list = "/products"
        static let create = "/admin/products"
        static let detail = "/products/"
        static let update = "/admin/products/"
        static let delete = "/admin/products/"
        static let uploadImage = "/admin/products/upload-image"
    }
    
    struct CustomOrders {
        static let list = "/admin/custom-orders"
        static let detail = "/custom-orders/"
        static let approve = "/admin/custom-orders/"
        static let reject = "/admin/custom-orders/"
        static let updateStatus = "/admin/custom-orders/"
    }
    
    struct Reviews {
        static let pending = "/admin/reviews/pending"
        static let approve = "/admin/reviews/"
        static let reject = "/admin/reviews/"
    }
    
    struct Analytics {
        static let dashboard = "/admin/analytics/dashboard"
        static let sales = "/admin/analytics/sales"
        static let topProducts = "/admin/analytics/top-products"
        static let lowStock = "/admin/analytics/low-stock"
    }
}

struct AppTheme {
    static let primary = Color.blue
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    
    static let cornerRadiusS: CGFloat = 8
    static let cornerRadiusM: CGFloat = 12
    static let cornerRadiusL: CGFloat = 16
    
    static let shadowRadius: CGFloat = 8
    static let shadowOpacity: Float = 0.1
}

struct KeychainKeys {
    static let accessToken = "com.sniffle.accessToken"
    static let refreshToken = "com.sniffle.refreshToken"
    static let userEmail = "com.sniffle.userEmail"
}

struct UserDefaultsKeys {
    static let hasSeenOnboarding = "hasSeenOnboarding"
    static let preferredTheme = "preferredTheme"
}
