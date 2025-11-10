import SwiftUI
import Charts

struct AnalyticsDetailedView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingL) {
                    // Period Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.spacingS) {
                            ForEach(AnalyticsViewModel.SalesPeriod.allCases, id: \.self) { period in
                                Button {
                                    viewModel.selectedPeriod = period
                                    Task {
                                        await viewModel.loadSalesData()
                                    }
                                } label: {
                                    Text(period.displayName)
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, AppTheme.spacingM)
                                        .padding(.vertical, AppTheme.spacingS)
                                        .background(viewModel.selectedPeriod == period ? Color.blue : Color(.systemGray5))
                                        .foregroundColor(viewModel.selectedPeriod == period ? .white : .primary)
                                        .cornerRadius(AppTheme.cornerRadiusL)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Summary Stats
                    if !viewModel.salesData.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                            Text("Summary")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: AppTheme.spacingM) {
                                SummaryCard(
                                    title: "Total Revenue",
                                    value: "$\(viewModel.totalRevenue, default: "%.2f")",
                                    icon: "dollarsign.circle.fill",
                                    color: .green
                                )
                                
                                SummaryCard(
                                    title: "Total Orders",
                                    value: "\(viewModel.totalOrders)",
                                    icon: "bag.fill",
                                    color: .blue
                                )
                                
                                SummaryCard(
                                    title: "Avg Order Value",
                                    value: "$\(viewModel.averageOrderValue, default: "%.2f")",
                                    icon: "chart.line.uptrend.xyaxis",
                                    color: .purple
                                )
                                
                                SummaryCard(
                                    title: "Days Tracked",
                                    value: "\(viewModel.selectedPeriod.days)",
                                    icon: "calendar",
                                    color: .orange
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Revenue Chart
                    if viewModel.isLoadingSales {
                        VStack(spacing: AppTheme.spacingM) {
                            ProgressView()
                            Text("Loading sales data...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 250)
                    } else if !viewModel.salesData.isEmpty {
                        RevenueChartView(salesData: viewModel.salesData, period: viewModel.selectedPeriod)
                            .padding()
                    } else {
                        ContentUnavailableView {
                            Label("No Sales Data", systemImage: "chart.line.downtrend.xyaxis")
                        } description: {
                            Text("No sales recorded for this period")
                        }
                        .frame(height: 250)
                    }
                    
                    // Orders Chart
                    if !viewModel.salesData.isEmpty {
                        OrdersChartView(salesData: viewModel.salesData)
                            .padding()
                    }
                    
                    // Top Products
                    VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                        Text("Top Selling Products")
                            .font(.title3.bold())
                            .padding(.horizontal)
                        
                        if viewModel.isLoadingProducts {
                            VStack(spacing: AppTheme.spacingM) {
                                ProgressView()
                                Text("Loading products...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 200)
                        } else if !viewModel.topProducts.isEmpty {
                            TopProductsChartView(products: viewModel.topProducts)
                                .padding()
                        } else {
                            ContentUnavailableView {
                                Label("No Product Data", systemImage: "cube")
                            } description: {
                                Text("No products sold yet")
                            }
                            .frame(height: 200)
                        }
                    }
                    
                    // Top Products List
                    if !viewModel.topProducts.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                            Text("Product Details")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            VStack(spacing: AppTheme.spacingS) {
                                ForEach(Array(viewModel.topProducts.prefix(5).enumerated()), id: \.element.id) { index, product in
                                    TopProductRow(product: product, rank: index + 1)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Sales Analytics")
            .refreshable {
                async let sales = viewModel.loadSalesData()
                async let products = viewModel.loadTopProducts()
                await sales
                await products
            }
            .task {
                async let sales = viewModel.loadSalesData()
                async let products = viewModel.loadTopProducts()
                await sales
                await products
            }
        }
    }
}

struct RevenueChartView: View {
    let salesData: [SalesDataPoint]
    let period: AnalyticsViewModel.SalesPeriod
    
    private var chartData: [(Date, Double)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return salesData.compactMap { point in
            guard let date = formatter.date(from: point.date) else { return nil }
            return (date, point.revenue)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            Text("Revenue Trend")
                .font(.headline)
            
            Chart {
                ForEach(chartData, id: \.0) { date, revenue in
                    LineMark(
                        x: .value("Date", date),
                        y: .value("Revenue", revenue)
                    )
                    .foregroundStyle(Color.green.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", date),
                        y: .value("Revenue", revenue)
                    )
                    .foregroundStyle(Color.green.gradient.opacity(0.3))
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 250)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: period == .week ? 1 : period == .twoWeeks ? 2 : period == .month ? 5 : 15)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let revenue = value.as(Double.self) {
                            Text("$\(revenue, specifier: "%.0f")")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(AppTheme.cornerRadiusM)
    }
}

struct OrdersChartView: View {
    let salesData: [SalesDataPoint]
    
    private var chartData: [(Date, Int)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return salesData.compactMap { point in
            guard let date = formatter.date(from: point.date) else { return nil }
            return (date, point.orders)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            Text("Orders Over Time")
                .font(.headline)
            
            Chart {
                ForEach(chartData, id: \.0) { date, orders in
                    BarMark(
                        x: .value("Date", date),
                        y: .value("Orders", orders)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: chartData.count > 30 ? 7 : 3)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(AppTheme.cornerRadiusM)
    }
}

struct TopProductsChartView: View {
    let products: [TopProduct]
    
    private var topFive: [TopProduct] {
        Array(products.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            Text("Revenue by Product")
                .font(.headline)
            
            Chart {
                ForEach(topFive) { product in
                    BarMark(
                        x: .value("Revenue", product.revenue),
                        y: .value("Product", product.productName)
                    )
                    .foregroundStyle(Color.purple.gradient)
                    .annotation(position: .trailing) {
                        Text("$\(product.revenue, specifier: "%.0f")")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: CGFloat(topFive.count * 50))
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let revenue = value.as(Double.self) {
                            Text("$\(revenue, specifier: "%.0f")")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(AppTheme.cornerRadiusM)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(AppTheme.cornerRadiusM)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

struct TopProductRow: View {
    let product: TopProduct
    let rank: Int
    
    var body: some View {
        HStack {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Text("\(rank)")
                    .font(.caption.bold())
                    .foregroundColor(rankColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.productName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                HStack {
                    Text("\(product.unitsSold) sold")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(product.displayRevenue)
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(AppTheme.cornerRadiusM)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
}

#Preview {
    AnalyticsDetailedView()
}
