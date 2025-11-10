import Foundation

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: APIErrorResponse?
}

struct APIErrorResponse: Codable {
    let message: String
    let code: String?
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct UpdateOrderStatusRequest: Encodable {
    let status: OrderStatus
    let adminNotes: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case adminNotes = "admin_notes"
    }
}

struct AddTrackingRequest: Encodable {
    let trackingNumber: String
    
    enum CodingKeys: String, CodingKey {
        case trackingNumber = "tracking_number"
    }
}

struct ApproveCustomOrderRequest: Encodable {
    let estimatedPrice: Double
    let adminNotes: String
    
    enum CodingKeys: String, CodingKey {
        case estimatedPrice = "estimated_price"
        case adminNotes = "admin_notes"
    }
}

struct RejectCustomOrderRequest: Encodable {
    let adminNotes: String
    
    enum CodingKeys: String, CodingKey {
        case adminNotes = "admin_notes"
    }
}

struct ApproveReviewRequest: Encodable {
    let adminResponse: String?
    
    enum CodingKeys: String, CodingKey {
        case adminResponse = "admin_response"
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?
    let role: UserRole
    let createdAt: Date
    
    var fullName: String {
        [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }
    
    enum CodingKeys: String, CodingKey {
        case id, email, role
        case firstName = "first_name"
        case lastName = "last_name"
        case createdAt = "created_at"
    }
}

enum UserRole: String, Codable {
    case customer = "customer"
    case admin = "admin"
    case superAdmin = "super_admin"
}

struct Product: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let category: String
    let basePrice: Double
    let images: [String]
    let variants: [ProductVariant]?
    let isMadeToOrder: Bool
    let processingTime: Int?
    let createdAt: Date
    let updatedAt: Date
    
    var displayPrice: String {
        "$\(String(format: "%.2f", basePrice))"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, images, variants
        case basePrice = "base_price"
        case isMadeToOrder = "is_made_to_order"
        case processingTime = "processing_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ProductVariant: Codable, Identifiable {
    let id: String
    let sku: String
    let name: String
    let priceAdjustment: Double
    let stockQuantity: Int?
    let lowStockThreshold: Int?
    
    var isLowStock: Bool {
        guard let stock = stockQuantity, let threshold = lowStockThreshold else {
            return false
        }
        return stock <= threshold
    }
    
    enum CodingKeys: String, CodingKey {
        case id, sku, name
        case priceAdjustment = "price_adjustment"
        case stockQuantity = "stock_quantity"
        case lowStockThreshold = "low_stock_threshold"
    }
}

struct ProductList: Codable {
    let products: [Product]
    let pagination: Pagination
}

struct Order: Codable, Identifiable {
    let id: String
    let orderNumber: String
    let userId: String
    let status: OrderStatus
    let totalAmount: Double
    let items: [OrderItem]
    let shippingAddress: Address
    let trackingNumber: String?
    let adminNotes: String?
    let createdAt: Date
    let updatedAt: Date
    
    var statusColor: String {
        status.color
    }
    
    var displayTotal: String {
        "$\(String(format: "%.2f", totalAmount))"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, status, items
        case orderNumber = "order_number"
        case userId = "user_id"
        case totalAmount = "total_amount"
        case shippingAddress = "shipping_address"
        case trackingNumber = "tracking_number"
        case adminNotes = "admin_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct OrderItem: Codable, Identifiable {
    let id: String
    let productId: String
    let productName: String
    let variantId: String?
    let variantName: String?
    let quantity: Int
    let price: Double
    let subTotal: Double
    
    var displayPrice: String {
        "$\(String(format: "%.2f", price))"
    }
    
    var displaySubTotal: String {
        "$\(String(format: "%.2f", subTotal))"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, quantity, price, subTotal
        case productId = "product_id"
        case productName = "product_name"
        case variantId = "variant_id"
        case variantName = "variant_name"
    }
}

enum OrderStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case confirmed = "confirmed"
    case processing = "processing"
    case shipped = "shipped"
    case delivered = "delivered"
    case cancelled = "cancelled"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .confirmed: return "blue"
        case .processing: return "purple"
        case .shipped: return "indigo"
        case .delivered: return "green"
        case .cancelled: return "red"
        }
    }
}

struct Address: Codable {
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    
    var formatted: String {
        "\(street)\n\(city), \(state) \(zipCode)\n\(country)"
    }
    
    enum CodingKeys: String, CodingKey {
        case street, city, state, country
        case zipCode = "zip_code"
    }
}

struct OrderList: Codable {
    let orders: [Order]
    let pagination: Pagination
}

struct CustomOrder: Codable, Identifiable {
    let id: String
    let userId: String
    let productId: String
    let productName: String?
    let status: CustomOrderStatus
    let specialInstructions: String
    let estimatedPrice: Double?
    let adminNotes: String?
    let createdAt: Date
    let updatedAt: Date
    
    var statusColor: String {
        status.color
    }
    
    var displayPrice: String? {
        guard let price = estimatedPrice else { return nil }
        return "$\(String(format: "%.2f", price))"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, status
        case userId = "user_id"
        case productId = "product_id"
        case productName = "product_name"
        case specialInstructions = "special_instructions"
        case estimatedPrice = "estimated_price"
        case adminNotes = "admin_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum CustomOrderStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case inProduction = "in_production"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .inProduction: return "In Production"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "blue"
        case .rejected: return "red"
        case .inProduction: return "purple"
        case .completed: return "green"
        case .cancelled: return "gray"
        }
    }
}

struct CustomOrderList: Codable {
    let customOrders: [CustomOrder]
    let pagination: Pagination
    
    enum CodingKeys: String, CodingKey {
        case customOrders = "custom_orders"
        case pagination
    }
}

struct Review: Codable, Identifiable {
    let id: String
    let productId: String
    let userId: String
    let rating: Int
    let title: String
    let comment: String
    let verifiedPurchase: Bool
    let isApproved: Bool
    let adminResponse: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, rating, title, comment
        case productId = "product_id"
        case userId = "user_id"
        case verifiedPurchase = "verified_purchase"
        case isApproved = "is_approved"
        case adminResponse = "admin_response"
        case createdAt = "created_at"
    }
}

struct ReviewList: Codable {
    let reviews: [Review]
    let pagination: Pagination
}

struct DashboardStats: Codable {
    let todayRevenue: Double
    let weekRevenue: Double
    let monthRevenue: Double
    let totalRevenue: Double
    let todayOrders: Int
    let pendingOrders: Int
    let processingOrders: Int
    let totalOrders: Int
    let totalCustomers: Int
    let pendingReviews: Int
    let lowStockProducts: Int
    let totalProducts: Int
    let customOrdersPending: Int
    
    enum CodingKeys: String, CodingKey {
        case todayRevenue = "today_revenue"
        case weekRevenue = "week_revenue"
        case monthRevenue = "month_revenue"
        case totalRevenue = "total_revenue"
        case todayOrders = "today_orders"
        case pendingOrders = "pending_orders"
        case processingOrders = "processing_orders"
        case totalOrders = "total_orders"
        case totalCustomers = "total_customers"
        case pendingReviews = "pending_reviews"
        case lowStockProducts = "low_stock_products"
        case totalProducts = "total_products"
        case customOrdersPending = "custom_orders_pending"
    }
}

struct SalesData: Codable {
    let period: Int
    let data: [SalesDataPoint]
}

struct SalesDataPoint: Codable, Identifiable {
    let date: String
    let revenue: Double
    let orders: Int
    
    var id: String { date }
}

struct TopProduct: Codable, Identifiable {
    let productId: String
    let productName: String
    let unitsSold: Int
    let revenue: Double
    
    var id: String { productId }
    var displayRevenue: String {
        "$\(String(format: "%.2f", revenue))"
    }
    
    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case productName = "product_name"
        case unitsSold = "units_sold"
        case revenue
    }
}

struct LowStockProduct: Codable, Identifiable {
    let id: String
    let name: String
    let sku: String
    let stockQuantity: Int
    let lowStockThreshold: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, sku
        case stockQuantity = "stock_quantity"
        case lowStockThreshold = "low_stock_threshold"
    }
}

struct Pagination: Codable {
    let page: Int
    let pageSize: Int
    let totalPages: Int
    let totalItems: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case pageSize = "page_size"
        case totalPages = "total_pages"
        case totalItems = "total_items"
    }
}
