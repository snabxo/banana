import Foundation

class AuthService {
    static let shared = AuthService()
    private let api = APIService.shared
    
    private init() {}
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let request = LoginRequest(email: email, password: password)
        
        let response: AuthResponse = try await api.request(
            endpoint: APIConstants.Auth.login,
            method: .post,
            body: request,
            requiresAuth: false
        )
        
        _ = KeychainHelper.shared.saveAccessToken(response.accessToken)
        _ = KeychainHelper.shared.saveRefreshToken(response.refreshToken)
        _ = KeychainHelper.shared.saveUserEmail(response.user.email)
        
        return response
    }
    
    func refreshAccessToken() async throws {
        guard let refreshToken = KeychainHelper.shared.getRefreshToken() else {
            throw APIError.unauthorized
        }
        
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        
        let response: AuthResponse = try await api.request(
            endpoint: APIConstants.Auth.refresh,
            method: .post,
            body: request,
            requiresAuth: false
        )
        
        
        _ = KeychainHelper.shared.saveAccessToken(response.accessToken)
        _ = KeychainHelper.shared.saveRefreshToken(response.refreshToken)
    }
        
    func logout() async throws {
        struct EmptyResponse: Codable {}
        
        try? await api.request(
            endpoint: APIConstants.Auth.logout,
            method: .post
        ) as EmptyResponse
        
        KeychainHelper.shared.clearAuthTokens()
    }
    
    func isAuthenticated() -> Bool {
        return KeychainHelper.shared.getAccessToken() != nil
    }
    
    func getCurrentUser() async throws -> User {
        return try await api.request(endpoint: APIConstants.Auth.profile)
    }
}
