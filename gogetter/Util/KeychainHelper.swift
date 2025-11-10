import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    
    private init() {}
    
    @discardableResult
    func saveAccessToken(_ token: String) -> Bool {
        return save(key: KeychainKeys.accessToken, value: token)
    }
    
    @discardableResult
    func saveRefreshToken(_ token: String) -> Bool {
        return save(key: KeychainKeys.refreshToken, value: token)
    }
    
    @discardableResult
    func saveUserEmail(_ email: String) -> Bool {
        return save(key: KeychainKeys.userEmail, value: email)
    }
    
    func getAccessToken() -> String? {
        return get(key: KeychainKeys.accessToken)
    }
    
    func getRefreshToken() -> String? {
        return get(key: KeychainKeys.refreshToken)
    }
    
    func getUserEmail() -> String? {
        return get(key: KeychainKeys.userEmail)
    }
    
    @discardableResult
    func deleteAccessToken() -> Bool {
        return delete(key: KeychainKeys.accessToken)
    }
    
    @discardableResult
    func deleteRefreshToken() -> Bool {
        return delete(key: KeychainKeys.refreshToken)
    }
    
    @discardableResult
    func deleteUserEmail() -> Bool {
        return delete(key: KeychainKeys.userEmail)
    }
    
    func clearAuthTokens() {
        deleteAccessToken()
        deleteRefreshToken()
        deleteUserEmail()
    }
    
    private func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        return status == errSecSuccess
    }
    
    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else { return nil }
        
        return value
    }
    
    @discardableResult
    private func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

