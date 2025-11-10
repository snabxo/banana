import Foundation
import Combine


@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        isAuthenticated = AuthService.shared.isAuthenticated()
        
        if isAuthenticated {
            Task {
                do {
                    currentUser = try await AuthService.shared.getCurrentUser()
                } catch {
                    isAuthenticated = false
                }
            }
        }
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await AuthService.shared.login(email: email, password: password)
            
            currentUser = response.user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() async {
        isLoading = true
        
        do {
            try await AuthService.shared.logout()
            
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
            
            currentUser = nil
            isAuthenticated = false
        }
        
        isLoading = false
    }
}
