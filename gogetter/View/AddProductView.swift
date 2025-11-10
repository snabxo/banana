import SwiftUI
import PhotosUI

struct AddProductView: View {
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var viewModel = AddProductViewModel()
    
    @State private var name = ""
    @State private var description = ""
    @State private var category = ""
    @State private var basePrice = ""
    @State private var isMadeToOrder = false
    @State private var processingTime = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var variants: [ProductVariantInput] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingVariantSheet = false
    
    private let categories = ["Pottery", "Jewelry", "Textiles", "Home Decor", "Art", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section("Basic Information") {
                    TextField("Product Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        Text("Select Category").tag("")
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        Text("Description")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                    }
                    
                    HStack {
                        Text("$")
                        TextField("0.00", text: $basePrice)
                            .keyboardType(.decimalPad)
                    }
                }
                
                // Product Type
                Section("Product Type") {
                    Toggle("Made to Order", isOn: $isMadeToOrder)
                    
                    if isMadeToOrder {
                        HStack {
                            TextField("Processing Time (days)", text: $processingTime)
                                .keyboardType(.numberPad)
                            Text("days")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Images
                Section {
                    VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                        Text("Product Images")
                            .font(.headline)
                        
                        if !viewModel.selectedPhotos.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.spacingS) {
                                    ForEach(Array(viewModel.selectedPhotos.enumerated()), id: \.offset) { index, photo in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: photo)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                                .cornerRadius(AppTheme.cornerRadiusS)
                                            
                                            Button {
                                                viewModel.selectedPhotos.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .background(Circle().fill(Color.red))
                                            }
                                            .offset(x: 8, y: -8)
                                        }
                                    }
                                }
                            }
                        }
                        
                        HStack(spacing: AppTheme.spacingM) {
                            Button {
                                showingCamera = true
                            } label: {
                                Label("Camera", systemImage: "camera")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(AppTheme.cornerRadiusM)
                            }
                            
                            Button {
                                showingImagePicker = true
                            } label: {
                                Label("Photos", systemImage: "photo.on.rectangle")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(AppTheme.cornerRadiusM)
                            }
                        }
                        
                        Text("Add up to 5 images")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Variants
                Section {
                    VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                        HStack {
                            Text("Variants")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                showingVariantSheet = true
                            } label: {
                                Label("Add Variant", systemImage: "plus.circle.fill")
                                    .font(.subheadline)
                            }
                        }
                        
                        if variants.isEmpty {
                            Text("No variants added")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(Array(variants.enumerated()), id: \.offset) { index, variant in
                                VariantInputRow(variant: variant) {
                                    variants.remove(at: index)
                                }
                            }
                        }
                    }
                }
                
                // Validation Errors
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProduct()
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: AppTheme.spacingM) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text(viewModel.uploadProgress)
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .padding(AppTheme.spacingXL)
                        .background(Color(.systemBackground).opacity(0.9))
                        .cornerRadius(AppTheme.cornerRadiusL)
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotosPicker(
                    selection: $selectedImages,
                    maxSelectionCount: 5 - viewModel.selectedPhotos.count,
                    matching: .images
                ) {
                    Text("Select Photos")
                }
                .onChange(of: selectedImages) { _, newItems in
                    Task {
                        await viewModel.loadPhotos(from: newItems)
                        selectedImages = []
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { image in
                    viewModel.selectedPhotos.append(image)
                    showingCamera = false
                }
            }
            .sheet(isPresented: $showingVariantSheet) {
                AddVariantSheet { variant in
                    variants.append(variant)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !description.isEmpty &&
        !category.isEmpty &&
        !basePrice.isEmpty &&
        Double(basePrice) != nil &&
        (!isMadeToOrder || !processingTime.isEmpty)
    }
    
    private func createProduct() {
        guard let price = Double(basePrice) else { return }
        
        let processingDays = isMadeToOrder ? Int(processingTime) : nil
        
        Task {
            let success = await viewModel.createProduct(
                name: name,
                description: description,
                category: category,
                basePrice: price,
                isMadeToOrder: isMadeToOrder,
                processingTime: processingDays,
                variants: variants
            )
            
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views
struct VariantInputRow: View {
    let variant: ProductVariantInput
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(variant.name)
                    .font(.subheadline.bold())
                
                HStack {
                    if variant.priceAdjustment != 0 {
                        Text("\(variant.priceAdjustment > 0 ? "+" : "")$\(variant.priceAdjustment, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if let stock = variant.stockQuantity {
                        Text("Stock: \(stock)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(AppTheme.cornerRadiusS)
    }
}

struct AddVariantSheet: View {
    @Environment(\.dismiss) var dismiss
    let onAdd: (ProductVariantInput) -> Void
    
    @State private var name = ""
    @State private var sku = ""
    @State private var priceAdjustment = ""
    @State private var hasStock = true
    @State private var stockQuantity = ""
    @State private var lowStockThreshold = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Variant Details") {
                    TextField("Variant Name (e.g., Blue - Large)", text: $name)
                    TextField("SKU", text: $sku)
                        .textInputAutocapitalization(.characters)
                }
                
                Section("Pricing") {
                    HStack {
                        Text("Price Adjustment")
                        Spacer()
                        Text("$")
                        TextField("0.00", text: $priceAdjustment)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Text("Additional cost above base price (use negative for discount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Inventory") {
                    Toggle("Track Stock", isOn: $hasStock)
                    
                    if hasStock {
                        HStack {
                            Text("Stock Quantity")
                            Spacer()
                            TextField("0", text: $stockQuantity)
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Low Stock Alert")
                            Spacer()
                            TextField("5", text: $lowStockThreshold)
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .navigationTitle("Add Variant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let adjustment = Double(priceAdjustment) ?? 0
                        let stock = hasStock ? Int(stockQuantity) : nil
                        let threshold = hasStock ? Int(lowStockThreshold) : nil
                        
                        let variant = ProductVariantInput(
                            name: name,
                            sku: sku,
                            priceAdjustment: adjustment,
                            stockQuantity: stock,
                            lowStockThreshold: threshold
                        )
                        
                        onAdd(variant)
                        dismiss()
                    }
                    .disabled(name.isEmpty || sku.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddProductView()
}
