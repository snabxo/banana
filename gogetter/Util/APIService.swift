import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized. Please login again."
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

class APIService {
    static let shared = APIService()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        let configuration = URLSessionConfiguration.default
        
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        self.session = URLSession(configuration: configuration)
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: APIConstants.baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if required
        if requiresAuth {
            if let accessToken = KeychainHelper.shared.getAccessToken() {
                urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            } else {
                throw APIError.unauthorized
            }
        }
        
        // Add request body if present
        if let body = body {
            urlRequest.httpBody = try encoder.encode(body)
        }
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success - decode response
                do {
                    let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)
                    
                    if let data = apiResponse.data {
                        return data
                    } else if let error = apiResponse.error {
                        throw APIError.serverError(error.message)
                    } else {
                        throw APIError.invalidResponse
                    }
                } catch {
                    // If APIResponse decoding fails, try direct decoding
                    do {
                        return try decoder.decode(T.self, from: data)
                    } catch {
                        print("Decoding error: \(error)")
                        throw APIError.decodingError
                    }
                }
                
            case 401:
                // Unauthorized - try to refresh token
                if requiresAuth, KeychainHelper.shared.getRefreshToken() != nil {
                    do {
                        try await AuthService.shared.refreshAccessToken()
                        // Retry the original request
                        return try await self.request(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth)
                    } catch {
                        throw APIError.unauthorized
                    }
                } else {
                    throw APIError.unauthorized
                }
                
            case 400...499:
                // Client error
                if let apiResponse = try? decoder.decode(APIResponse<T>.self, from: data),
                   let error = apiResponse.error {
                    throw APIError.serverError(error.message)
                }
                throw APIError.serverError("Client error: \(httpResponse.statusCode)")
                
            case 500...599:
                // Server error
                throw APIError.serverError("Server error: \(httpResponse.statusCode)")
                
            default:
                throw APIError.invalidResponse
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func uploadImage(
        endpoint: String,
        imageData: Data,
        parameters: [String: String] = [:]
    ) async throws -> String {
        guard let url = URL(string: APIConstants.baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        
        // Add authorization
        if let accessToken = KeychainHelper.shared.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add parameters
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        struct UploadResponse: Codable {
            let url: String
        }
        
        let uploadResponse = try decoder.decode(APIResponse<UploadResponse>.self, from: data)
        
        guard let imageUrl = uploadResponse.data?.url else {
            throw APIError.invalidResponse
        }
        
        return imageUrl
    }
}

