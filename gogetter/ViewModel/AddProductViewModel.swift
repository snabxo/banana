import Combine
import SwiftUI
import PhotosUI

struct ProductVariantInput: Identifiable {
    let id = UUID()
    let name: String
    let sku: String
    let priceAdjustment: Double
    let stockQuantity: Int?
    let lowStockThreshold: Int?
}

@MainActor
class AddProductViewModel: ObservableObject {
    @Published var selectedPhotos: [UIImage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var uploadProgress = "Preparing..."
    
    private let api = APIService.shared
    
    func loadPhotos(from items: [PhotosPickerItem]) async {
        for item in items {
            guard selectedPhotos.count < 5 else { break }
            
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // Compress image
                if let compressedImage = compressImage(image) {
                    selectedPhotos.append(compressedImage)
                }
            }
        }
    }
    
    func createProduct(
        name: String,
        description: String,
        category: String,
        basePrice: Double,
        isMadeToOrder: Bool,
        processingTime: Int?,
        variants: [ProductVariantInput]
    ) async -> Bool {
        guard !selectedPhotos.isEmpty else {
            errorMessage = "Please add at least one image"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        uploadProgress = "Uploading images..."
        
        do {
            // Upload images first
            var imageUrls: [String] = []
            for (index, image) in selectedPhotos.enumerated() {
                uploadProgress = "Uploading image \(index + 1) of \(selectedPhotos.count)..."
                
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    continue
                }
                
                let url = try await api.uploadImage(
                    endpoint: APIConstants.Products.uploadImage,
                    imageData: imageData,
                    parameters: [:]
                )
                imageUrls.append(url)
            }
            
            guard !imageUrls.isEmpty else {
                throw APIError.serverError("Failed to upload images")
            }
            
            uploadProgress = "Creating product..."
            
            // Create product
            let productVariants = variants.map { variant in
                CreateProductVariant(
                    name: variant.name,
                    sku: variant.sku,
                    priceAdjustment: variant.priceAdjustment,
                    stockQuantity: variant.stockQuantity,
                    lowStockThreshold: variant.lowStockThreshold
                )
            }
            
            let request = CreateProductRequest(
                name: name,
                description: description,
                category: category,
                basePrice: basePrice,
                images: imageUrls,
                isMadeToOrder: isMadeToOrder,
                processingTime: processingTime,
                variants: productVariants.isEmpty ? nil : productVariants
            )
            
            let _: Product = try await api.request(
                endpoint: APIConstants.Products.create,
                method: .post,
                body: request
            )
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    private func compressImage(_ image: UIImage, maxSizeKB: Int = 500) -> UIImage? {
        var compression: CGFloat = 0.9
        var imageData = image.jpegData(compressionQuality: compression)
        
        while let data = imageData, data.count > maxSizeKB * 1024 && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - Request Models
struct CreateProductRequest: Encodable {
    let name: String
    let description: String
    let category: String
    let basePrice: Double
    let images: [String]
    let isMadeToOrder: Bool
    let processingTime: Int?
    let variants: [CreateProductVariant]?
    
    enum CodingKeys: String, CodingKey {
        case name, description, category, images, variants
        case basePrice = "base_price"
        case isMadeToOrder = "is_made_to_order"
        case processingTime = "processing_time"
    }
}

struct CreateProductVariant: Encodable {
    let name: String
    let sku: String
    let priceAdjustment: Double
    let stockQuantity: Int?
    let lowStockThreshold: Int?
    
    enum CodingKeys: String, CodingKey {
        case name, sku
        case priceAdjustment = "price_adjustment"
        case stockQuantity = "stock_quantity"
        case lowStockThreshold = "low_stock_threshold"
    }
}
