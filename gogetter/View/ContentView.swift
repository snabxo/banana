import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    @StateObject private var dashboardVM = DashboardViewModel()
    @StateObject private var orderVM = OrderViewModel()
    @StateObject private var productVM = ProductViewModel()
    @StateObject private var customOrderVM = CustomOrderViewModel()
    
    var body: some View {
        TabView {
            DashboardView()
                .environmentObject(dashboardVM)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
            
            OrderListView()
                .environmentObject(orderVM)
                .tabItem {
                    Label("Orders", systemImage: "bag.fill")
                }
                .badge(orderVM.pendingCount)
            
            ProductListView()
                .environmentObject(productVM)
                .tabItem {
                    Label("Products", systemImage: "cube.fill")
                }
            
            CustomOrderListView()
                .environmentObject(customOrderVM)
                .tabItem {
                    Label("Custom", systemImage: "star.fill")
                }
                .badge(customOrderVM.pendingCount)
            
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
        }
        .tint(AppTheme.primary)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
