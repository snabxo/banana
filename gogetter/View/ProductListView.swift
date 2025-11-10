import SwiftUI

struct ProductListView: View {
    @EnvironmentObject var viewModel: ProductViewModel
    
    @State private var showingAddProduct = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search products...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                    
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(AppTheme.cornerRadiusM)
                .padding()
                
                // Products Grid
                if viewModel.isLoading && viewModel.products.isEmpty {
                    VStack(spacing: AppTheme.spacingM) {
                        ProgressView()
                        Text("Loading products...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else if viewModel.filteredProducts.isEmpty {
                    ContentUnavailableView {
                        Label("No Products", systemImage: "cube")
                    } description: {
                        Text(viewModel.searchText.isEmpty ? "No products found" : "No products match your search")
                    } actions: {
                        Button("Add Product") {
                            showingAddProduct = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: AppTheme.spacingM) {
                            ForEach(viewModel.filteredProducts) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    ProductCard(product: product)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Products")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddProduct = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .refreshable {
                await viewModel.loadProducts(refresh: true)
            }
            .task {
                if viewModel.products.isEmpty {
                    await viewModel.loadProducts()
                }
            }
            .sheet(isPresented: $showingAddProduct) {
                AddProductView()
                    .onDisappear {
                        // Refresh products after adding
                        Task {
                            await viewModel.loadProducts(refresh: true)
                        }
                    }
            }
        }
    }
}

struct ProductCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            // Product Image
            if let imageUrl = product.images.first {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundColor(.secondary)
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 150)
                .clipped()
                .cornerRadius(AppTheme.cornerRadiusM)
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 150)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                            .font(.largeTitle)
                    }
                    .cornerRadius(AppTheme.cornerRadiusM)
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(product.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(product.displayPrice)
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if product.isMadeToOrder {
                        Text("MTO")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(AppTheme.spacingS)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(AppTheme.cornerRadiusM)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject var viewModel: ProductViewModel
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                // Image Gallery
                if !product.images.isEmpty {
                    TabView {
                        ForEach(product.images, id: \.self) { imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                default:
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .overlay {
                                            ProgressView()
                                        }
                                }
                            }
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(.page)
                }
                
                VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                    // Basic Info
                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        Text(product.name)
                            .font(.title.bold())
                        
                        HStack {
                            Text(product.displayPrice)
                                .font(.title2.bold())
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            if product.isMadeToOrder {
                                Text("Made to Order")
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, AppTheme.spacingS)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(0.2))
                                    .foregroundColor(.purple)
                                    .cornerRadius(AppTheme.cornerRadiusS)
                            }
                        }
                        
                        Text(product.category)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(product.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Variants
                    if let variants = product.variants, !variants.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                            Text("Variants")
                                .font(.headline)
                            
                            ForEach(variants) { variant in
                                VariantRow(variant: variant)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Delete Button
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Product", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(AppTheme.cornerRadiusM)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Product", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    _ = await viewModel.deleteProduct(id: product.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete this product? This action cannot be undone.")
        }
    }
}

struct VariantRow: View {
    let variant: ProductVariant
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(variant.name)
                    .font(.subheadline.bold())
                
                Text("SKU: \(variant.sku)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if variant.priceAdjustment != 0 {
                    Text("\(variant.priceAdjustment > 0 ? "+" : "")$\(variant.priceAdjustment, specifier: "%.2f")")
                        .font(.subheadline.bold())
                }
                
                if let stock = variant.stockQuantity {
                    Text("\(stock) in stock")
                        .font(.caption)
                        .foregroundColor(variant.isLowStock ? .red : .secondary)
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(AppTheme.cornerRadiusS)
    }
}

#Preview {
    NavigationStack {
        ProductListView()
            .environmentObject(ProductViewModel())
    }
}

